---
author: Christian Kniep
layout: post
title: "dssh: Multi-host version running xhpcg"
date: 2016-04-03
tags: eng docker blog dssh
---

After a quick [Proof of Concept](/2016/03/31/dssh/) I pushed it to my little HPC setup with physical nodes and InfiniBand.

Next I aimed to run HPCG within containers instead of a bare-metal run.

## The Plan

The big plan was to run a slurm-cluster on bare metal and instantiate the mpi-tasks within containers.

![](/pics/2016-04-03/multihost_dssh.png)

All nodes report as slurm clients (in an attempted to update venus003 and venus003 they didn't come up again).

{% highlight bash %}
[root@venus001 ~]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
venus*       up   infinite      6   idle venus[001,004-008]
[root@venus001 ~]#
{% endhighlight %}

## Images

The images are rather minimalistic.

{% highlight bash %}
[root@venus001 docker]# cat docker-fedora/Dockerfile
###### Updated version of fedora (22)
FROM fedora:22
MAINTAINER "Christian Kniep <christian@qnib.org>"

# Solution for 'ping: icmp open socket: Operation not permitted'
RUN ln -sf /usr/share/zoneinfo/Europe/Paris /etc/localtime

ADD etc/yum.conf /etc/yum.conf
RUN dnf install -y python-dnf-plugins-extras-migrate && dnf-2 migrate && \
    echo "2015-03-24"; dnf clean all && \
    dnf update -y -x systemd -x systemd-libs -x iputils && \
    dnf install -y wget vim curl
[root@venus001 docker]# cat docker-openmpi/Dockerfile
### QNIBTerminal Image
FROM qnib/fedora

ENV PATH=/usr/lib64/openmpi/bin/:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
RUN dnf install -y openmpi bc libmlx4
ADD docker-latest /usr/local/bin/docker
[root@venus001 docker]#
{% endhighlight %}

No slurm, no ssh, I just added docker to be able to call the docker cli. I could even get rid of this.

## HPCG 

The input data for HPCG is the following: 

{% highlight bash %}
[root@venus001 ~]# cat /scratch/hpcg.dat
HPCG benchmark input file
Sandia National Laboratories; University of Tennessee, Knoxville
104 104 104
300
{% endhighlight %}

A wrapper shifts through the list of nodes:


{% highlight bash %}
#!/bin/bash
HOSTLIST="venus004,venus005,venus006,venus007,venus008"

function shift_hostlist() {
    HEAD=$(echo ${1} |awk -F, '{print $1}')
    TAIL=$(echo ${1} |awk -F, '{$1=""; print $0}' |sed -e 's/^[[:space:]]*//' |tr ' ' ',')
    echo "${TAIL},${HEAD}"
}

EXE=${1}
RUNS=${2-3}
DOCKER=${3}

if [ ! -z ${DOCKER} ];then
    MCA_OPTS="-mca plm_rsh_agent /scratch/bin/dssh"
fi


CNT=0
while [ true ]; do
    if [ ${CNT} -eq ${RUNS} ];then
       break
    fi
    SUBHOSTS=$(echo ${HOSTLIST} |cut -d,  -f-4 |tr ' ' ',')
    echo "# --host ${SUBHOSTS} ${MCA_OPTS}"
    time mpirun --allow-run-as-root ${MCA_OPTS} --host ${SUBHOSTS} --np 32 ${EXE}
    HOSTLIST=$(shift_hostlist ${HOSTLIST})
    CNT=$(echo ${CNT} + 1|bc)
done
{% endhighlight %}

The goal is not to stage a complete and fair comparison. Since I do not care about the OpenMP settings, I am pretty sure that the results are borderline accurate.
As seen below in the `htop` pics the number of forked processes differs - that does not look similar. So don't pin me down on this... :)

### Bare-metal run

As a baseline I compiled HPCG on CentOS7.2 (the bare metal installation) and ran it.

{% highlight bash %}
[root@venus001 scratch]# ./bin/shuf_xhpcg.sh /scratch/src/hpcg-3.0/Linux_MPI/bin/xhpcg
# --host venus004,venus005,venus006,venus007
real    13m20.755s
# --host venus005,venus006,venus007,venus008
real    13m39.780s
# --host venus006,venus007,venus008,venus004
real    13m41.473s
[root@venus001 scratch]#
{% endhighlight %}

{% highlight bash %}[root@venus001 scratch]# grep "a GFLOP" HPCG-Benchmark-3.0_2016.04*
HPCG-Benchmark-3.0_2016.04.03.13.33.06.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.76119
HPCG-Benchmark-3.0_2016.04.03.13.46.42.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.70451
HPCG-Benchmark-3.0_2016.04.03.14.00.40.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.68913
[root@venus001 scratch]#
{% endhighlight %}
  
### Running with `dssh`

First I ran it on CentOS 7.2.

{% highlight bash %}
[root@venus001 ~]# clush -w venus00[4-8] 'docker -H localhost:2376 ps |grep -v CONTAINER'|sort
venus004: 0d77a2f202f1        192.168.12.11:5000/qnib/openmpi:cos7   "tail -f /dev/null"   3 hours ago         Up 3 hours                              venus004-ompi
venus005: 0f84e9660f8e        192.168.12.11:5000/qnib/openmpi:cos7   "tail -f /dev/null"   3 hours ago         Up 3 hours                              venus005-ompi
venus006: 434e269e4177        192.168.12.11:5000/qnib/openmpi:cos7   "tail -f /dev/null"   3 hours ago         Up 3 hours                              venus006-ompi
venus007: 1e435510e91d        192.168.12.11:5000/qnib/openmpi:cos7   "tail -f /dev/null"   3 hours ago         Up 3 hours                              venus007-ompi
venus008: 345a1b9859d1        192.168.12.11:5000/qnib/openmpi:cos7   "tail -f /dev/null"   3 hours ago         Up 3 hours                              venus008-ompi
[root@venus001 ~]#
{% endhighlight %}

{% highlight bash %}
[root@venus001 scratch]# /scratch/bin/shuf_xhpcg.sh /scratch/src/hpcg-3.0/COS7_MPI/bin/xhpcg 5 docker
Sun Apr  3 16:09:44 CEST 2016 # --host venus004,venus005,venus006,venus007 -mca plm_rsh_agent /scratch/bin/dssh
+ docker -H venus007:2376 exec -i venus007-ompi orted --hnp-topo-sig 0N:2S:0L3:4L2:8L1:8C:8H:x86_64 -mca ess '"env"' -mca orte_ess_jobid '"1496711168"' -mca orte_ess_vpid 4 -mca orte_ess_num_procs '"5"' -mca orte_hnp_uri '"1496711168.0;tcp://192.168.12.181,10.0.0.181,172.18.0.1,172.17.0.1,172.19.0.1:52992"' --tree-spawn -mca plm_rsh_agent '"/scratch/bin/dssh"' -mca plm '"rsh"' --tree-spawn
*snip*
real    13m33.880s
*snip*
Sun Apr  3 16:23:23 CEST 2016 # --host venus005,venus006,venus007,venus008 -mca plm_rsh_agent /scratch/bin/dssh
{% endhighlight %}

Which yields similar results to the bare-metal run, since it's the same user land.

{% highlight bash %}
[root@venus001 scratch]# grep "a GFLOP" HPCG-Benchmark-3.0_2016.04*
HPCG-Benchmark-3.0_2016.04.03.16.18.37.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.72324
HPCG-Benchmark-3.0_2016.04.03.16.32.13.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.70897
HPCG-Benchmark-3.0_2016.04.03.16.46.11.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.70728
HPCG-Benchmark-3.0_2016.04.03.17.00.07.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.69402
HPCG-Benchmark-3.0_2016.04.03.17.13.42.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.67581
[root@venus001 scratch]#
{% endhighlight %}

#### Second run with Fedora 22

Restart the container using the Fedora 22 tag.

{% highlight bash %}
[root@venus001 docker-openmpi]# clush -w venus00[4-8] /scratch/bin/restart_openmpi fd22
venus008: venus008-ompi
venus007: venus007-ompi
venus004: venus004-ompi
venus006: venus006-ompi
venus005: venus005-ompi
venus004: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:fd22
venus007: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:fd22
venus008: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:fd22
venus005: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:fd22
venus007: f1bddbbd0cadac7a730afdfd0b2f154837518939857e4e3daab227e887278274
venus004: 32596bdc0983b205032bc9abb10ca756617bf0b5a821207bd0b3d56f62870650
venus008: 30b79640f8b9713445a2014254407931d7f0b25d3220346dfdaf8bcb4b0e8518
venus006: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:fd22
venus005: 01cb8cee27341242db37998dc954cf3988368d98c8989c629c9c5892eeaf7828
venus006: d087242878903f2175fb7a49bf8afc144da82ffe2d11976fa1ec0eb51ecb245f
[root@venus001 docker-openmpi]#
{% endhighlight %}

And off we go...

{% highlight bash %}
[root@venus001 scratch]# /scratch/bin/shuf_xhpcg.sh /scratch/src/hpcg-3.0/FD22_MPI/bin/xhpcg 5 docker
Sun Apr  3 17:43:33 CEST 2016 # --host venus004,venus005,venus006,venus007 -mca plm_rsh_agent /scratch/bin/dssh
+ docker -H venus005:2376 exec -i venus005-ompi orted --hnp-topo-sig 0N:2S:0L3:4L2:8L1:8C:8H:x86_64 -mca ess '"env"' -mca orte_ess_jobid '"1418657792"' -mca orte_ess_vpid 2 -mca orte_ess_num_procs '"5"' -mca orte_hnp_uri '"1418657792.0;tcp://192.168.12.181,10.0.0.181,172.18.0.1,172.17.0.1,172.19.0.1:35529"' --tree-spawn -mca plm_rsh_agent '"/scratch/bin/dssh"' -mca plm '"rsh"' --tree-spawn
*snip*
real    13m13.720s
Sun Apr  3 17:56:51 CEST 2016 # --host venus005,venus006,venus007,venus008 -mca plm_rsh_agent /scratch/bin/dssh
{% endhighlight %}

It's a bit faster (~100 MFLOP/s, ~3%) then the CentOS7 run.

{% highlight bash %}
[root@venus001 docker-login]# grep "a GFLOP" /scratch/HPCG-Benchmark-3.0_2016.04*
/scratch/HPCG-Benchmark-3.0_2016.04.03.17.52.05.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.78578
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.05.20.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.79691
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.18.58.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.77254
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.32.30.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.78048
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.45.39.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.79036
[root@venus001 docker-login]#
{% endhighlight %}

#### Ubuntu 15.10

For the fun of it I created a Ubuntu 15.10 image...

{% highlight bash %}
[root@venus001 docker-openmpi]# clush -w venus00[4-8] /scratch/bin/restart_openmpi u15.10
venus007: venus007-ompi
venus008: venus008-ompi
venus006: venus006-ompi
venus005: venus005-ompi
venus004: venus004-ompi
venus005: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:u15.10
venus004: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:u15.10
venus008: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:u15.10
venus006: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:u15.10
venus007: Status: Downloaded newer image for 192.168.12.11:5000/qnib/openmpi:u15.10
venus005: 65f8a28997be9902f69a0d35d871aa3bb486434ceb77242476827f1ba087a73f
venus006: b983a9b043d2935ca64ae61169f3387d0b69951125abb9240c69a93599c06817
venus004: e611123b77298776d221ca816ddb4509728a4ae2327b04463e52ef5918abdb29
venus008: adf7ebec267ee477d19052b4c534e233f28ebe9195c0065b6aff979481cb6f42
venus007: 0142e7a65a2d84242205e0b57f84c0673171052e983b6973b84e43c0a723b40d
[root@venus001 docker-openmpi]#
{% endhighlight %}

With a rather poor result... :)

{% highlight bash %}
[root@venus001 docker-openmpi]# grep "a GFLOP" /scratch/HPCG-Benchmark-3.0_2016.04*
/scratch/HPCG-Benchmark-3.0_2016.04.03.17.39.50.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.35045
/scratch/HPCG-Benchmark-3.0_2016.04.03.17.55.36.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.32825
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.11.43.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.33404
{% endhighlight %}

#### Ubuntu 14.04

How about 14.04...?

{% highlight bash %}
[root@venus001 scratch]# grep "a GFLOP" /scratch/HPCG-Benchmark-3.0_2016.04*
/scratch/HPCG-Benchmark-3.0_2016.04.03.18.49.18.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.34876
/scratch/HPCG-Benchmark-3.0_2016.04.03.19.05.04.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.32608
/scratch/HPCG-Benchmark-3.0_2016.04.03.19.21.12.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.3275
{% endhighlight %}

OK, enough... :) I made the point about different user-lands and how they can be tailored to gain performance in contrast to the bare-metal installation in December 2014:
[Containerized MPI Workloads](/qnibterminal/2014/12/02/Containerized-MPI-workloads-Interview/)

Here are the results as a chart (min: 2 GFLOP/s):
![](/pics/2016-04-03/hpcg_result.png)

## Slurm vs mpirun

I have to admit, I am afraid I was wrong before. If I am not mistaken, `slurmd` takes care of the remote execution of the MPI ranks, not `sshd`.

{% highlight bash %}
[root@venus001 scratch]# cat /scratch/bin/run_hpcg.sh
#!/bin/bash
#SBATCH --workdir /scratch/
#SBATCH --ntasks-per-node 8

mpirun --allow-run-as-root /scratch/bin/xhpcg
[root@venus001 scratch]# ln -s /scratch/src/hpcg-3.0/COS7_MPI/bin/xhpcg /scratch/bin/
[root@venus001 scratch]# sbatch -w venus004,venus005,venus006,venus007 /scratch/bin/run_hpcg.sh
Submitted batch job 752
[root@venus001 scratch]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
venus*       up   infinite      4  alloc venus[004-007]
venus*       up   infinite      2   idle venus[001,008]
[root@venus001 scratch]#
{% endhighlight %}

![](/pics/2016-04-03/htop_slurmstepd.png)

Whereas within by using `dssh` and - bottom line - `docker exec`, `orted` is started as a child of the first process within the container.

![](/pics/2016-04-03/htop_docker_exec.png)


My evil plan was to use the SLURM cluster on bare metal to tell `dssh` which nodes are available, spawn the container on each node, run the job within the container and remove the container afterwards.

But if I try `-mca plm_rsh_agent /scratch/bin/dssh` within the SLURM batch script it does not have an effect, as `slurmstepd` execute the remote `orted`. :(

I guess I have to compile slurm without Open MPI support to get an effect. Hmm...

Btw. The result of the SLURM run on bare-metal...

{% highlight bash %}
[root@venus001 docker-login]# grep "a GFLOP" /scratch/HPCG-Benchmark-3.0_2016.04*
/scratch/HPCG-Benchmark-3.0_2016.04.03.19.01.32.yaml:  HPCG result is VALID with a GFLOP/s rating of: 2.73566
[root@venus001 docker-login]#
{% endhighlight %}


## Appendix

The hpcg binaries were build for each distribution:

{% highlight bash %}
root@venus001:/# cd /scratch/src/hpcg-3.0/
root@venus001:/scratch/src/hpcg-3.0# mkdir U15.10_MPI
root@venus001:/scratch/src/hpcg-3.0# cd U15.10_MPI/
root@venus001:/scratch/src/hpcg-3.0/U15.10_MPI# ../configure Linux_MPI
root@venus001:/scratch/src/hpcg-3.0/U15.10_MPI# make -j2
mpicxx -c -DHPCG_NO_OPENMP -I./src -I./src/Linux_MPI  -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 -I../src ../src/main.cpp -o src/main.o
*snip*
mpicxx -c -DHPCG_NO_OPENMP -I./src -I./src/Linux_MPI  -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 -I../src ../src/init.cpp -o src/init.o
mpicxx -c -DHPCG_NO_OPENMP -I./src -I./src/Linux_MPI  -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 -I../src ../src/finalize.cpp -o src/finalize.o
mpicxx -DHPCG_NO_OPENMP -I./src -I./src/Linux_MPI  -O3 -ffast-math -ftree-vectorize -ftree-vectorizer-verbose=0 src/main.o src/CG.o src/CG_ref.o src/TestCG.o src/ComputeResidual.o src/ExchangeHalo.o src/GenerateGeometry.o src/GenerateProblem.o src/GenerateProblem_ref.o src/CheckProblem.o src/MixedBaseCounter.o src/OptimizeProblem.o src/ReadHpcgDat.o src/ReportResults.o src/SetupHalo.o src/SetupHalo_ref.o src/TestSymmetry.o src/TestNorms.o src/WriteProblem.o src/YAML_Doc.o src/YAML_Element.o src/ComputeDotProduct.o src/ComputeDotProduct_ref.o src/mytimer.o src/ComputeOptimalShapeXYZ.o src/ComputeSPMV.o src/ComputeSPMV_ref.o src/ComputeSYMGS.o src/ComputeSYMGS_ref.o src/ComputeWAXPBY.o src/ComputeWAXPBY_ref.o src/ComputeMG_ref.o src/ComputeMG.o src/ComputeProlongation_ref.o src/ComputeRestriction_ref.o src/CheckAspectRatio.o src/GenerateCoarseProblem.o src/init.o src/finalize.o  -o bin/xhpcg
{% endhighlight %}


{% highlight bash %}
{% endhighlight %}
