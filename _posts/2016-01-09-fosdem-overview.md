---
author: Christian Kniep
layout: post
title: "FOSDEM #1 - HPC in a box"
date: 2016-01-09
tags: eng docker blog 
---

Happy new year, y'all! 

To kick of 2016 I am going to contribute to FOSDEM by talking about a [Multi-host containerised HPC cluster](https://fosdem.org/2016/schedule/event/hpc_bigdata_hpc_cluster/). And since the [HPC Advisory Council](http://www.hpcadvisorycouncil.com/) was so nice to provide an actual [HPC resource](http://www.hpcadvisorycouncil.com/cluster_center.php) I will present a 2.0 version of the talk (lessons learned after FOSDEM) at the [HPC Advisory Council Workshop](http://www.hpcadvisorycouncil.com/events/2016/stanford-workshop/agenda.php) in Stanford.

The talks are limited in time (25min / 45min), therefore I thought it would be nice to provide some information in a series of blog posts. This one should set the scene a bit. Subsequent posts focus on how everything was setup (spoiler: ansible), the way I monitor it (Sensu on an external server), how the docker networking performs and so on. We'll see what pops into my head. :)

All the code is going to be released on github; in fact it's already there, but I use an external cluster with RabbitMQ credentials. Have to sanitise it first... 

## The Cluster

I got access to the Venus cluster I used before: [Containerized MPI Workloads](http://localhost:4000/qnibterminal/2014/12/02/Containerized-MPI-workloads-Interview/)

The cluster has eight SunFire 2250 nodes, with 32GB (even though some nodes are degenerated to 28GB) memory and dual socket Xeon Quad-core X5472 each. All of which are connected by Mellanox ConnectX-2 cards (QDR 40Gbit/s) using a Mellanox 36port switch.

![](/pics/2016-01-09/venus.jpg)

All nodes were installed with CentOS 7.2, the installation I used back in the days.

## Baselines

### Computation

An initial HPCG benchmark came back with `5.3` GFLOP/s. Above 144 I run out of memory, since some of the nodes are degraded to 27GB.

{% highlight bash %}
$ export MPI_HOSTS=venus001,venus002,venus003,venus004,venus005,venus006,venus007,venus008
$ mpirun -np 64 --allow-run-as-root --host ${MPI_HOSTS} /scratch/jobs/xhpcg
$ egrep "(GFLOP/s rat|^\s+nx)" HPCG-Benchmark-3.0_2016.01.08.1*
HPCG-Benchmark-3.0_2016.01.08.13.53.05.yaml:  nx: 104
HPCG-Benchmark-3.0_2016.01.08.13.53.05.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.28937
HPCG-Benchmark-3.0_2016.01.08.14.10.46.yaml:  nx: 104
HPCG-Benchmark-3.0_2016.01.08.14.10.46.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.30873
HPCG-Benchmark-3.0_2016.01.08.14.59.14.yaml:  nx: 144
HPCG-Benchmark-3.0_2016.01.08.14.59.14.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.34622
HPCG-Benchmark-3.0_2016.01.08.17.13.03.yaml:  nx: 144
HPCG-Benchmark-3.0_2016.01.08.17.13.03.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.33844
HPCG-Benchmark-3.0_2016.01.08.18.03.10.yaml:  nx: 144
HPCG-Benchmark-3.0_2016.01.08.18.03.10.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.34506
$
{% endhighlight %}


### Network

Ethernet provides close to 1GBit/s...

{% highlight bash %}
$ iperf -c venus001 -d -t 120
*snip* ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  13.1 GBytes   938 Mbits/sec
[  4]  0.0-120.0 sec  13.1 GBytes   937 Mbits/sec
{% endhighlight %}

IPoIB is much faster then that, even though not close to the 40GBit/s InfiniBand offers.

{% highlight bash %}
$ iperf -c 10.0.0.181 -d -t 120
*snip*
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  88.9 GBytes  6.37 Gbits/sec
[  4]  0.0-120.0 sec  79.6 GBytes  5.69 Gbits/sec
$
{% endhighlight %}

InfiniBand itself provides the promised 40GBit/s.

{% highlight bash %}
$ qperf venus001 -t 120 rc_bi_bw
rc_bi_bw:
    bw  =  5.09 GB/sec
$
{% endhighlight %}

## Setup

OK, now that we established some rough baselines... 

To be able to use [Docker Networking](https://docs.docker.com/engine/userguide/networking/dockernetworks/) the docker-engines need to connect to a global Key/Value store. I showed a [simple setup the other day](http://qnib.org/2015/11/29/multi-host-slurm/). This time around I create a Consul cluster in which each server has its own Consul agent running in server mode. All of them form one Consul cluster.

{% highlight bash %}
[root@venus001 ~]# consul members
Node      Address              Status  Type    Build  Protocol  DC
venus001  192.168.12.181:8301  alive   server  0.6.0  2         vagrant
venus002  192.168.12.182:8301  alive   server  0.6.0  2         vagrant
venus003  192.168.12.183:8301  alive   server  0.6.0  2         vagrant
venus004  192.168.12.184:8301  alive   server  0.6.0  2         vagrant
venus005  192.168.12.185:8301  alive   server  0.6.0  2         vagrant
venus006  192.168.12.186:8301  alive   server  0.6.0  2         vagrant
venus007  192.168.12.187:8301  alive   server  0.6.0  2         vagrant
venus008  192.168.12.188:8301  alive   server  0.6.0  2         vagrant
[root@venus001 ~]#
{% endhighlight %}

The nice property of this is (at least in my view), that the docker-engine can connect to the local Consul agent and does not rely on another machine. A reboot of a node turns out nicely, since the Consul agent rejoins the cluster and everything is fine.

{% highlight bash %}
[root@venus001 jobs]# cat /etc/sysconfig/docker
OPTIONS="-H tcp://0.0.0.0:2376 --cluster-store=consul://127.0.0.1:8500/network --cluster-advertise=enp4s0f0:2376"
[root@venus001 jobs]#
{% endhighlight %}

By doing so, all docker-engines share the same overlay network via the ethernet interface.

{% highlight bash %}
[root@venus001 jobs]# docker network create  -d overlay global
8d2943e84f6d2f2ae9a9036f3ec25fd054d4e33bbc595afb1d7d0fdd702bb139
[root@venus001 ~]# docker network ls
NETWORK ID          NAME                DRIVER
8d2943e84f6d        global              overlay
6756095cb2c8        bridge              bridge
d9072e5b2492        none                null
e5b17208d64a        host                host
07342005436a        docker_gwbridge     bridge
[root@venus001 ~]#
{% endhighlight %}

{% highlight bash %}
[root@venus004 ~]# docker network ls
NETWORK ID          NAME                DRIVER
8d2943e84f6d        global              overlay
b0eaee7ded62        bridge              bridge
7bceab756aff        docker_gwbridge     bridge
6d46041083fa        none                null
941f89e50815        host                host
[root@venus004 ~]#
{% endhighlight %}

## Container

For this first benchmark the [qnib/ib-bench:cos7](https://github.com/qnib/docker-ib-bench) image is used on each host. It introduces an ssh-server, InfiniBand libraries and two IB-Benchmarks: [HPCG](http://www.hpcg-benchmark.org/software/index.html) + [OMB](https://www.nersc.gov/users/computational-systems/cori/nersc-8-procurement/trinity-nersc-8-rfp/nersc-8-trinity-benchmarks/omb-mpi-tests/)

In general I favour `docker-compose` for starting the container, but it seems `docker-compose` has some trouble with `memlocks` (github [issue](https://github.com/docker/compose/issues/2607)). Therefore I start the containers by hand...

{% highlight bash %}
[root@venus001 slurm]# cd ../hpcg
[root@venus001 hpcg]# ./start.sh up
> export DOCKER_HOST=tcp://venus001:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
a863b176043faf560eb19ef13d351f1be42c6916fc16653cb08e303ac6135836
> export DOCKER_HOST=tcp://venus002:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
473c412374e38c5b0d1e9d80b387c90ab597f829d697084e65bb3968f4afdf0c
> export DOCKER_HOST=tcp://venus003:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
b4caa4977f7416014a0db1b24b561a757c10fdb23c4939348c9abe0a793b490b
> export DOCKER_HOST=tcp://venus004:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
5f3aa0d85609692c5a8c8222ae12191a505fbf1c738df03ece2bf75c53026b57
> export DOCKER_HOST=tcp://venus005:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
d616f65fdb9c704b2d388103f278a30167d77103d43a6151d5d751deb52e0f55
> export DOCKER_HOST=tcp://venus006:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
07a475ccf3833458dc209fd1951b6c59f78a48af9e6a0044106da626ebd5c67e
> export DOCKER_HOST=tcp://venus007:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
d5e3104cf2358772515628af90de505b4011295498ab5951be0b6d6d0a461108
> export DOCKER_HOST=tcp://venus008:2376
> docker run -d ... --ulimit memlock='68719476736' qnib/ib-bench:cos7 /opt/qnib/sshd/bin/start.sh
cbb9d04f0ca8cd63bdd7ad096f78eb422d6f2428df61a513d698807815bef958
[root@venus001 hpcg]#{% endhighlight %}

The containers are started with the command `/opt/qnib/sshd/bin/start.sh`, which does not start all services, but just the sshd daemon.

{% highlight bash %}
[root@venus001 ~]# docker exec -ti hpcg1 bash
[root@hpcg1 /]# ps -ef
UID        PID  PPID  C STIME TTY          TIME CMD
root         1     0  0 20:18 ?        00:00:00 /bin/bash /opt/qnib/sshd/bin/start.sh
root        17     1  0 20:18 ?        00:00:00 /sbin/sshd -D
root        18     0  6 20:23 ?        00:00:00 bash
root        58    18  0 20:23 ?        00:00:00 ps -ef
[root@hpcg1 /]#
{% endhighlight %}

## Benchmarks

The Ethernet performance is slightly smaller...

{% highlight bash %}
[root@hpcg2 /]# iperf -c hpcg1 -d -t 120
*snip*
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  10.4 GBytes   745 Mbits/sec
[  4]  0.0-120.0 sec  11.8 GBytes   847 Mbits/sec
[root@hpcg2 /]#
{% endhighlight %}

That's why we love RDMA and InfiniBand... :)

{% highlight bash %}
[root@hpcg2 /]# qperf hpcg1 -t 120 rc_bi_bw
rc_bi_bw:
    bw  =  5.07 GB/sec
[root@hpcg2 /]#
{% endhighlight %}

And compute-wise... This time with the user `bob`, since he is able to login password-less.

Furthermore I had to reduce the size to `104`, due to a lack of memory. The services started need memory themselves.

{% highlight bash %}
[root@venus001 hpcg]# docker exec -ti hpcg1 bash
[root@hpcg1 jobs]# su - bob
[bob@hpcg1 ~]$ cd /scratch/jobs/
[bob@hpcg1 jobs]$ export MPI_HOSTS=hpcg1,hpcg2,hpcg3,hpcg4,hpcg5,hpcg6,hpcg7,hpcg8
[bob@hpcg1 jobs]$ mpirun -np 64 --host ${MPI_HOSTS} /opt/hpcg-3.0/Linux_MPI/bin/xhpcg
[bob@hpcg1 cos7]$ egrep "(GFLOP/s rat|^\s+nx)" HPCG-Benchmark-3.0_2016.01*
HPCG-Benchmark-3.0_2016.01.09.11.52.11.yaml:  nx: 104
HPCG-Benchmark-3.0_2016.01.09.11.52.11.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.39522
HPCG-Benchmark-3.0_2016.01.09.12.25.15.yaml:  nx: 104
HPCG-Benchmark-3.0_2016.01.09.12.25.15.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.38519
HPCG-Benchmark-3.0_2016.01.09.13.30.21.yaml:  nx: 104
HPCG-Benchmark-3.0_2016.01.09.13.30.21.yaml:  HPCG result is VALID with a GFLOP/s rating of: 5.4443
[bob@hpcg1 cos7]$
{% endhighlight %}

Compared to the bare-metal run - it's even a little bit faster. :)

## Conlusion so far

With docker networking it's easy as pie to create a small cluster. I haven't mentioned it, but the hostnames are dynamically added to all `/etc/hosts` files, which make all containers addressable out of the box.

After I ran the benchmark within the containers I stopped `docker-engine` and `consul` and benchmarked the bare-metal again.

{% highlight bash %}
[root@venus001 ~]# cd /scratch/jobs/bare
[root@venus001 bare]# export MPI_HOSTS=venus001,venus002,venus003,venus004,venus005,venus006,venus007,venus008
[root@venus001 bare]# mpirun --allow-run-as-root -np 64 --host ${MPI_HOSTS} /scratch/jobs/bare/xhpcg
[root@venus001 bare]#  egrep "(GFLOP/s rat|^\s+nx)" HPCG-Benchmark-3.0_2016.01*
  nx: 104
  HPCG result is VALID with a GFLOP/s rating of: 5.31681
[root@venus001 bare]#
{% endhighlight %}

Still, a bit slower - most likely due to an installation I messed with. The container images are a bit cleaner; that's why I like them in the first place...

So long!

A little spoiler in regards of my monitoring setup, the IB traffic is not trustable - I use a super-simple approach. I did much better in the past. :)

![](/pics/2016-01-09/grafana.png)
