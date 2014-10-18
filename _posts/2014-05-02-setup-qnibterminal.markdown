---
layout: post
title:  "Setup a basic QNIBTerminal"
date:   2014-05-02
categories: qnibterminal
tags: blog eng cluster docker osdc isc
---

![container](/pics/2014-05-01/dock_container.png "dock")
[Jaxport@Flickr][cont_pic]

In my [previous post][last_post] I described what drove me to give docker a spin and create a
virtual HPC cluster stack.

This post provides a step by step guide to run a basic QNIBTerminal with four nodes.
To get this one going there is no need for a lot of horsepower. I ran it on a 3-core AMD
machine from back in the days. Even a VM should be able to lift it.

Recap Docker
=======================

Unlike all the 'heavy' virtualization techniques out there, running a dedicated kernel in an (more or less) emulated
a x86 environment, Docker (like BSD jails, Solaris zone, OpenVZ) is kind of 'chroot on steroids'.

The process spawned within a container uses the same kernel then the host system; but [sic!] it
is encapsulated in terms of processes (PID namespace), mount points (mount namespace),
network (net namepsace), interprocess communication (ICS namespace).
As if this alone wouldn't be awesome enough containers can be strangled by cgroups.

Anyway, one might forget the last two paragraphs and just pretend it is a strangely fast VM.

Bootstrap Docker
==================

Personally I use RedHat derivates, currently fedora20, since it should be close to
RHEL7, which will be the Linux derivate of choice within HPC (at least the HPC environment I work in, sorry SUSE).

Installing docker is quite simple
{% highlight bash %}
$ yum install -y docker-io lxc
{% endhighlight %}

If installed on a remote machine it comes in handy to expose a tcp-socket to everyone
(or localhost and use a ssh-tunnel, don't try this in production).
Furthermore I make sure that docker don't automatically restarts images and I like to put
the docker directory onto a SSD to have better IO performance. With '-e lxc' docker uses
the LXC backend in favor of the 'libcontainer' (directly talking to the kernel) backend,
which allows the use of cgroups.

{% highlight bash %}
$ vim /usr/lib/systemd/system/docker.service
## edit ExecStart to
ExecStart=/usr/bin/docker -d --restart=false -H tcp://0.0.0.0:6000 -e lxc -g /speed/docker
$ systemctl daemon-reload
$ systemctl start docker.service
{% endhighlight %}

And thats about it... Now one should be able to use docker.

{% highlight bash %}
# localhost might differ if your host is not... localhost
$ eport DOCKER_HOST=tcp://localhost:6000
$ docker ps -a
CONTAINER ID   IMAGE   COMMAND   CREATED    STATUS        PORTS     NAMES
$ docker images
REPOSITORY     TAG     IMAGE ID  CREATED    VIRTUAL SIZE
{% endhighlight %}

Start QNIBTerminal
===================

{% highlight bash %}
$ export HOST_SHARE=/speed/
{% endhighlight %}

After cloning the github repository the bashrc provides useful function to spawn the cluster.
First pulling all the images needed for QNIBTerminal. Depending on your internet connection
you might give a dime; but my wopping 1.5MB/s is a reason to preload and do something else in the meantime.


{% highlight bash %}
$ git clone git@github.com:ChristianKniep/QNIBTerminal.git
Cloning into 'QNIBTerminal'...
remote: Counting objects: 10, done.
remote: Compressing objects: 100% (8/8), done.
remote: Total 10 (delta 3), reused 6 (delta 2)
Receiving objects: 100% (10/10), done.
Resolving deltas: 100% (3/3), done.
Checking connectivity... done.
$ cd QNIBTerminal
$ source bashrc
$ d_pullall
Sun Apr 27 19:18:10 CEST 2014
*snip*
b69335c437a4: Download complete
Sun Apr 27 19:45:31 CEST 2014
{% endhighlight %}

OK, now we are talking...

{% highlight bash %}
14 13:56:02 rc=0 DOCKER:localhost QNIBTerminal $ docker images|grep qnib
qnib/slurm          latest              3cf7f9614746        15 hours ago        1.187 GB
qnib/helixdns       latest              bf63f948f8b9        16 hours ago        807.8 MB
qnib/etcd           latest              3ea82ae02faa        19 hours ago        645.6 MB
qnib/supervisor     latest              1da5684a6f79        19 hours ago        613.1 MB
qnib/fd20           latest              803582e382a8        20 hours ago        585.4 MB
qnib/graphite       latest              7f936a42e88d        2 days ago          1.23 GB
qnib/elk            latest              97e2c22e8b0f        2 days ago          1.185 GB
{% endhighlight %}



Containerize all the things!
==============================

qnib/helixdns
-------------------------

The basic building block of QNIBTerminal is the dns image, which also might serve as inventory in the future.
'1' as an argument attaches a bash to the container.
Once spawned we start supervisord in detached mode.

{% highlight bash %}
15 13:56:10 rc=0 DOCKER:localhost QNIBTerminal $ start_dns 1
bash-4.2# su -
[root@dns ~]# ./bin/supervisor_daemonize.sh
[root@dns ~]# supervisorctl status
etcd                             RUNNING   pid 35, uptime 0:00:26
helixdns                         RUNNING   pid 34, uptime 0:00:26
setup                            EXITED    May 02 01:58 PM
startup                          EXITED    May 02 01:58 PM
[root@dns ~]#
{% endhighlight %}

Neat, the first part is already up and running.

qnib/elk
-------------------------

Next up: The log managment container.

{% highlight bash %}
7 14:02:05 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ start_elk 1
bash-4.2# su -
[root@elk ~]# ./bin/supervisor_daemonize.sh
[root@elk ~]# supervisorctl status
diamond                          RUNNING   pid 35, uptime 0:00:20
elasticsearch                    RUNNING   pid 34, uptime 0:00:20
logstash                         RUNNING   pid 39, uptime 0:00:20
nginx                            RUNNING   pid 37, uptime 0:00:20
setup                            EXITED    May 02 02:02 PM
syslog-ng                        RUNNING   pid 36, uptime 0:00:20
[root@elk ~]#
{% endhighlight %}

And only with this two containers we are able to see stuff under port 81.

![ELK dashboard](/pics/2014-05-01/docker_elk_screen.png "ELK dashboard")

qnib/graphite
-------------------------

Now we start the graphite image to get some metrics.
I do not intend to interact with this container much, so I start it detached.


{% highlight bash %}
1 14:06:03 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ start_graphite
a1e288d677633d31e3e5383ac88ce068be3fd46f609f3f0d6bdca0cf80c78a76
2 14:06:15 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ docker ps
CONTAINER ID  IMAGE                  COMMAND       CREATED       STATUS         PORTS   NAMES
a1e288d67763  qnib/graphite   /bin/sh -c /bin/supe 8 seconds ago Up 6 seconds   *snip*  graphite
c83c43026a4c  qnib/elk        /bin/bash            3 minutes ago Up 3 minutes   *snip*  elk
1bcda38c456e  qnib/helixdns   /bin/bash            8 minutes ago Up 7 minutes           dns
3 14:06:21 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $
{% endhighlight %}

Graphite-web is now available under port 80 of the docker host (user/passwd: admin/admin).

![Graphite-web](/pics/2014-05-01/graphite_screen.png "graphite-web")

docker host
------------
To get metrics from the docker server we set up python-diamond and rename the host to 'docker'
as to fit it into the predefined graphs within the qnib/graphite image.

If this is skipped, there are going to be no metrics present, so it's optional.

{% highlight bash %}
# cd
# git clone https://github.com/ChristianKniep/docker-terminal.git
# yum install -y docker-terminal/yum-cache/diamond/python-*
# yum install -y lm_sensors
# cp /etc/diamond/diamond.conf.example /etc/diamond/diamond.conf
# sed -i -e s'/^handlers =.*/handlers = diamond.handler.graphite.GraphiteHandler/' \
      /etc/diamond/diamond.conf
# sed -i -e '/# hostname          = `hostname`/a \hostname=docker' \
      /etc/diamond/diamond.conf
# cat << \EOF > /etc/diamond/collectors/DiskUsageCollector.conf
enabled = True
path_suffix = ""
ttl_multiplier = 2
measure_collector_time = False
byte_unit = byte,
sector_size = 512
send_zero = False
devices = sd[a-z]+$
EOF
# echo "enabled = False" > /etc/diamond/collectors/MemoryCollector.conf
# echo "enabled = False" > /etc/diamond/collectors/HttpdCollector.conf
# cat << \EOF > /etc/diamond/collectors/NetworkCollector.conf
> enabled = True
> path_suffix = ""
> ttl_multiplier = 2
> measure_collector_time = False
> byte_unit = bit, byte
> interfaces = eth, bond, em, p1p
> greedy = true
> EOF
# export GRAPHITE_IP=$(docker inspect -f '{{ .NetworkSettings.IPAddress }}' graphite)
# sed -i -e "s/host =.*/host = ${GRAPHITE_IP}/" /etc/diamond/handlers/GraphiteHandler.conf
# sed -i -e 's/# interval =.*/interval = 5/' /etc/diamond/diamond.conf
# mkdir -p /var/log/diamond
### check if it works
# diamond -f -l
### if it does, fire up the daemon
# diamond
{% endhighlight %}

Now the graphite metrics of the host flowing in and are shown in the predefined
graphs.

![carbon/diskio metrics](/pics/2014-05-01/graphite_carbon_metrics.png "carbon/diskio metrics")

qnib/slurm
-----------

{% highlight bash %}
3 14:06:21 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ start_slurm 1
bash-4.2# su -
[root@slurm ~]# ./bin/supervisor_daemonize.sh; sleep 25
[root@slurm ~]# supervisorctl status
confd_update_slurm               RUNNING   pid 43, uptime 0:00:23
confd_watch_nodes                RUNNING   pid 39, uptime 0:00:23
diamond                          RUNNING   pid 36, uptime 0:00:23
munge                            RUNNING   pid 41, uptime 0:00:23
setup                            EXITED    May 02 02:16 PM
slurmctld                        RUNNING   pid 338, uptime 0:00:15
syslog-ng                        RUNNING   pid 38, uptime 0:00:23
[root@slurm ~]# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
docker*      up   infinite      1   unk* compute0
[root@slurm ~]#
{% endhighlight %}

And slurmctld is already complaining about something.

![valid complains of slurmctld](/pics/2014-05-01/docker_elk_slurmctld.png "valid complains of slurmctld")

But that is alright. If no compute node is found, the start-script of slurmctld will
create a dummy node 'compute0'. Since it is not available, it is not reachable.

qnib/compute
-------------------------

The compute nodes are spawned.
{% highlight bash %}
29 14:28:55 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ for x in {0..3};do start_compute compute${x};done
30 14:30:44 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ docker ps --since-id=54de5513e355
CONTAINER ID   IMAGE          COMMAND                CREATED             STATUS         PORTS    NAMES
8af57317a37a   qnib/compute   /bin/sh -c /bin/supe   45 seconds ago      Up 42 seconds           compute3
973e82c0d968   qnib/compute   /bin/sh -c /bin/supe   50 seconds ago      Up 46 seconds           compute2
bc9871a5f5ac   qnib/compute   /bin/sh -c /bin/supe   56 seconds ago      Up 52 seconds           compute1
1510fdea0f11   qnib/compute   /bin/sh -c /bin/supe   59 seconds ago      Up 56 seconds           compute0
31 14:30:49 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $
{% endhighlight %}

Back to the slurm node we should see the slurm configuration adapt dynamically.

{% highlight bash %}
[root@slurm ~]# su - cluser
[cluser@slurm ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
docker*      up   infinite      4   idle compute[0-3]
[cluser@slurm ~]$
{% endhighlight %}

To test the cluster the command 'hostname' is send to all nodes using the interactive
'srun' command.

{% highlight bash %}
[cluser@slurm ~]$ srun -N4 hostname
compute0
compute2
compute3
compute1
{% endhighlight %}

![graphite srun](/pics/2014-05-01/graphite_srun.png "srun command issued")

Matrix Multiplication
================

4 nodes
--------

A more complex workload than 'hostname' is a application which was kindly provided
by a co-worker of mine, [Jean-Noel Quintin][jnq_link].
The program multiplies two matrizes in a smart way by split the work up (read: I do not know the details).

In the real-world (on bare metal), the programm saturates the resources of the host to
be as fast as possible. Since QNIBTerminal overprovisions the host heavily, I introduced a
line of sleep as to slow down the computation.

{% highlight bash %}
[cluser@slurm ~]$ sbatch -N4 /usr/local/bin/gemm.sh
Submitted batch job 3
[cluser@slurm ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 3    docker  gemm.sh   cluser  R       0:09      4 compute[0-3]
[cluser@slurm ~]$
{% endhighlight %}

This results in a fairly small job. The matrix size is not big.

![gemm 16k job runs](/pics/2014-05-01/docker_gemm_job_graphite.png "gemm jobs with K=16k")

A bigger job consumes more memory, and the nodes are by default limited to 125MB.
{% highlight bash %}
35 14:40:56 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ env|grep MAX
MAX_MEMORY=125M
{% endhighlight %}

{% highlight bash %}
[cluser@slurm ~]$ sbatch -N4 /usr/local/bin/gemm.sh 32768
Submitted batch job 4
[cluser@slurm ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 4    docker  gemm.sh   cluser  R       0:07      4 compute[0-3]
[cluser@slurm ~]$
{% endhighlight %}

![gemm job with 32k](/pics/2014-05-01/graphite_gemm_job_32k.png "32k gemm jobs")

By increasing the size of the matrix the job grows. But be aware of your memory limit.

{% highlight bash %}
40 14:43:38 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ top -b -n1 |egrep "(PID|gemm)"
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
15302 cluser    20   0  283076  87296    796 S  12.4  2.2   0:10.53 gemm_block_mpi_
15301 cluser    20   0  283076  99344    788 S   6.2  2.5   0:07.28 gemm_block_mpi_
15304 cluser    20   0  283076  90096    840 S   6.2  2.2   0:05.69 gemm_block_mpi_
15303 cluser    20   0  283076  62580    816 S   0.0  1.5   0:07.18 gemm_block_mpi_
{% endhighlight %}

RES is shown in KiB which is close to 100MB.

16 nodes
--------

12 more nodes would allow the job to run on 16 nodes (it should be a power of two).

{% highlight bash %}
41 14:43:55 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ for x in {4..15};do start_compute compute${x};done
{% endhighlight %}

The nodes are creating some load and more lines in the network graph.

![12 nodes starting](/pics/2014-05-01/graphite_nodes_start.png "12 more nodes")

3 Core...
---------
To bad, the function assigns cpuid 2 to compute{0..9} and cpuid 3 to compute{10..19}.

Since I am working on a 3 core AMD, my machine only got up to coreid 2.

{% highlight bash %}
49 14:57:06 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ docker logs compute10
lxc-start: Invalid argument - write /sys/fs/cgroup/cpuset/lxc/*snip*/cpuset.cpus : Invalid argument
lxc-start: Error setting cpuset.cpus to 3 for lxc/*snip*
{% endhighlight %}

Therefore I assign the cpuid for the upper compute nodes by myself.

{% highlight bash %}
58 15:01:50 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ for x in {10..15};do start_compute compute${x} 0 2;done
# compute${x} => name
# 0           => detached
# 2           => cpuid
{% endhighlight %}

And here we go...

{% highlight bash %}
[cluser@slurm ~]$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
docker*      up   infinite     16   idle compute[0-15]
[cluser@slurm ~]$
{% endhighlight %}

16 node jobs
--------------

Now we submit a small job.

{% highlight bash %}
[cluser@slurm ~]$ sbatch -N16 /usr/local/bin/gemm.sh 32768
Submitted batch job 6
[cluser@slurm ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 6    docker  gemm.sh   cluser  R       1:25     16 compute[0-15]
[cluser@slurm ~]$
{% endhighlight %}

This job only consumes 40MB per node.

{% highlight bash %}
62 16:05:04 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ top -b -n1 |egrep "(PID|gemm)"
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
16315 cluser    20   0  183684  41716   4764 S   9.9  1.0   0:03.29 gemm_block_mpi_
16311 cluser    20   0  183844  41716   4764 S   5.0  1.0   0:04.34 gemm_block_mpi_
*snip*
{% endhighlight %}

![16 nodes 32k job](/pics/2014-05-01/graphite_16nodes_32k.png "32k job on 16 nodes")

Doubling the size of the input deck...

{% highlight bash %}
[cluser@slurm ~]$ sbatch -N16 /usr/local/bin/gemm.sh 65536
Submitted batch job 7
[cluser@slurm ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 7    docker  gemm.sh   cluser  R       0:21     16 compute[0-15]
[cluser@slurm ~]$
{% endhighlight %}

![16 nodes 65k job](/pics/2014-05-01/graphite_16nodes_65k.png "65k job on 16 nodes")

... close to doubles the memory usage.

{% highlight bash %}
71 16:08:20 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ top -b -n1 |egrep "(PID|gemm)"
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
20780 cluser    20   0  216452  73276   3568 S   0.0  1.8   0:01.76 gemm_block_mpi_
20781 cluser    20   0  216260  72772   3216 S   0.0  1.8   0:02.01 gemm_block_mpi_
{% endhighlight %}

Another doubeling...

{% highlight bash %}
[cluser@slurm ~]$ sbatch -N16 /usr/local/bin/gemm.sh 131072
Submitted batch job 8
[cluser@slurm ~]$ squeue
             JOBID PARTITION     NAME     USER ST       TIME  NODES NODELIST(REASON)
                 8    docker  gemm.sh   cluser  R       0:52     16 compute[0-15]
{% endhighlight %}

![16 nodes 131k job](/pics/2014-05-01/graphite_16nodes_131k.png "131k job on 16 nodes")

... gets me close to the cliff.

{% highlight bash %}
92 16:23:31 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ top -b -n1 |egrep "(PID|gemm)"
  PID USER      PR  NI    VIRT    RES    SHR S  %CPU %MEM     TIME+ COMMAND
31932 cluser    20   0  281796  83096    396 S   0.0  2.1   0:02.51 gemm_block_mpi_
31933 cluser    20   0  281796  88716    832 S   0.0  2.2   0:02.71 gemm_block_mpi_
31934 cluser    20   0  281988  76132    888 S   0.0  1.9   0:02.42 gemm_block_mpi_
31935 cluser    20   0  281796  85628    864 S   0.0  2.1   0:03.01 gemm_block_mpi_
31936 cluser    20   0  281796  83940    820 S   0.0  2.1   0:02.73 gemm_block_mpi_
31937 cluser    20   0  281796  68608    844 S   0.0  1.7   0:02.65 gemm_block_mpi_
31938 cluser    20   0  281796  68468    856 S   0.0  1.7   0:02.54 gemm_block_mpi_
31939 cluser    20   0  281796  91644    880 S   0.0  2.3   0:02.48 gemm_block_mpi_
31940 cluser    20   0  281796  72520    864 S   0.0  1.8   0:01.84 gemm_block_mpi_
31941 cluser    20   0  281988 101244    412 S   0.0  2.5   0:02.62 gemm_block_mpi_
{% endhighlight %}

![16 nodes 131k job](/pics/2014-05-01/memfree_16nodes_131k.png "131k job on 16 nodes")

The host starts swapping... :(

![16 nodes 131k job](/pics/2014-05-01/htop_16nodes_131k.png "131k job on 16 nodes")

So, that is basically it. A 4GB 3 core AMD node houses a 16node MPI cluster with 4 service nodes.

{% highlight bash %}
95 16:27:15 kniepbert@AIIX3 rc=0 DOCKER:localhost ~ $ docker ps
CONTAINER ID        IMAGE                  PORTS                                 NAMES
0a5d06847143        qnib/compute                                                 compute15
dc72d54800f7        qnib/compute                                                 compute14
91746138e462        qnib/compute                                                 compute13
84d6ab2a9b85        qnib/compute                                                 compute12
d1eb37b776fe        qnib/compute                                                 compute11
4495302dff22        qnib/compute                                                 compute10
7922f80b53b2        qnib/compute                                                 compute9
d1eccf71cabf        qnib/compute                                                 compute8
677548c1ea95        qnib/compute                                                 compute7
8ce797d795e6        qnib/compute                                                 compute6
cb2774c75667        qnib/compute                                                 compute5
1dc52f423f9e        qnib/compute                                                 compute4
8af57317a37a        qnib/compute                                                 compute3
973e82c0d968        qnib/compute                                                 compute2
bc9871a5f5ac        qnib/compute                                                 compute1
1510fdea0f11        qnib/compute                                                 compute0
54de5513e355        qnib/slurm                                                   slurm
a1e288d67763        qnib/graphite   0.0.0.0:80->80/tcp                           graphite
c83c43026a4c        qnib/elk        0.0.0.0:81->80/tcp, 0.0.0.0:9200->9200/tcp   elk
1bcda38c456e        qnib/helixdns                                                dns
{% endhighlight %}



[last_post]: http://blog.qnib.org/qnibterminal/eng/cluster/docker/2014/04/11/qnibterminal-virtual-hpc.html
[cont_pic]: https://www.flickr.com/photos/jaxport/3077543062!
[jnq_link]: http://www.researchgate.net/profile/Jean-Noel_Quintin
