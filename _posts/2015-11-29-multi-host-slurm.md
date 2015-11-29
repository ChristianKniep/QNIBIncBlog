---
author: Christian Kniep
layout: post
title: "Simple multi-host Docker SLURM cluster"
date: 2015-11-29
tags: eng docker blog slurm hpc
---

I was asked twice recently how I would transform the stacks I am using into a of-the-shelf Docker HPC cluster.

For starters I will go with a pretty minimalistic approach of leveraging the blog post about [docker networking](http://qnib.org/2015/11/18/docker-networking/) I did and expand it on physical machines.

![](/pics/2015-11-29/multi_host.png)

Since I do not have a cluster under my fingertips, I will mock-up the setup with docker-machines.

{% highlight bash %}
$ for x in login node0 node1 node2;do machine create -d virtualbox ${x};done
{% endhighlight %}

If you see a command like `eval $(machine env login)` it's just me setting the DOCKER_HOST to the target (here the `login` node), in the physical world you point the `DOCKER_HOST` variable to the corresponding ip address.

## Login Node

You might call it `head-node`, `master-node` or whatever. It could even be one of the compute node, the thing is that this fella will hold the key/value store for Docker Networking and is not going to be part of the cluster.

Install `docker` on it and run the compose file from the ['Docker Networking 101'](http://qnib.org/2015/11/18/docker-networking/) post.


{% highlight bash %}
$ git clone https://github.com/ChristianKniep/orchestra.git
$ cd orchestra/docker-networking/
$ eval $(machine env login)
login $ docker-compose up -d
Pulling consul (qnib/consul:latest)...
latest: Pulling from qnib/consul
*snip*
Status: Downloaded newer image for qnib/consul:latest
Creating consul
login $
{% endhighlight %}

The login node should present a nice Consul WebUI at `<login_ip>:8500`.

![](/pics/2015-11-29/consul_login.png)

## Compute nodes

The computes node must run `docker` in version 1.9 (or higher) as to be able to use docker networking.

#### Setup Docker Engine

In order to use dockers networking capabilities we are going to add the following option to the docker engines on the compute hosts.

{% highlight bash %}
--cluster-store=consul://<login_ip>:8500/network
{% endhighlight %}

Since boot2docker uses `eth0` for NAT and `eth1` as the host-only network the following option has to be set in a boot2docker environment (on my MacBook, that is - not the physical setup).

{% highlight bash %}
--cluster-advertise=eth1:2376
{% endhighlight %}

Depending on your Linux flavour it might be set in `/etc/default/docker`, `/etc/sysconfig/docker` or somewhere else.

For the `docker-machine`s it comes down to the following:

{% highlight bash %}
$ machine ssh node0
                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/
 _                 _   ____     _            _
| |__   ___   ___ | |_|___ \ __| | ___   ___| | _____ _ __
| '_ \ / _ \ / _ \| __| __) / _` |/ _ \ / __| |/ / _ \ '__|
| |_) | (_) | (_) | |_ / __/ (_| | (_) | (__|   <  __/ |
|_.__/ \___/ \___/ \__|_____\__,_|\___/ \___|_|\_\___|_|
Boot2Docker version 1.9.0, build master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015
Docker version 1.9.0, build 76d6bc9
docker@node0:~$ sudo vi /var/lib/boot2docker/profile
docker@node0:~$ grep 192 -B2 /var/lib/boot2docker/profile
EXTRA_ARGS='
--label provider=virtualbox
--cluster-store=consul://192.168.99.103:8500/network --cluster-advertise=eth1:2376
docker@node0:~$ exit
$ 
{% endhighlight %}

After the change I restart the `machine`, restarting the service will do as well.

{% highlight bash %}
$ machine restart node0
Restarted machines may have new IP addresses. You may need to re-run the `docker-machine env` command.
$
{% endhighlight %}

For the physical version just do: `service docker restart`

As shown in the blog post, `node0` (it's IP address) now appears in the KV store, hence he is part of the docker networking family.

![](/pics/2015-11-29/consul_kv_init.png)

After all nodes are treated it looks like this:

![](/pics/2015-11-29/consul_kv_all.png)

#### Overlay network

Now that all nodes are present we are adding one global overlay network.

{% highlight bash %}
$ docker $(machine config node0) network create -d overlay global
67343b2a61b1617c847351b680de7fc2426d8113dba093c3812f4322a23003b6
{% endhighlight %}

Et voila, the network show up on each nodes network list.

{% highlight bash %}
$ for x in node{0..2}; do echo ">> ${x}" ; docker $(machine config ${x}) network ls;done
>> node0
NETWORK ID          NAME                DRIVER
67343b2a61b1        global              overlay
b2f3267f8a1b        none                null
62765c4d843b        host                host
8f2be59bfe1d        bridge              bridge
>> node1
NETWORK ID          NAME                DRIVER
67343b2a61b1        global              overlay
b993e28a9485        none                null
69ce0ddd1d1c        host                host
11328d6e3578        bridge              bridge
>> node2
NETWORK ID          NAME                DRIVER
67343b2a61b1        global              overlay
ecb749ac7744        none                null
0839f1b397a6        host                host
81bc08e36dd4        bridge              bridge
$
{% endhighlight %}

## Spawn SLURM cluster

OK, so far I just rewrote the blog post about docker networking.

Now let's add some meat...

### Consul, slurmctld and the first compute node

Let's put the `consul` and the `slurmctld` on `node0`. It would be nice if this container could also life on the `login` node, but remind you - the `login` node is not part of the overlay network.

{% highlight bash %}
node0 $ cd orchestra/multihost-slurm/node0/
node0 $ docker-compose up -d
*snip*
Status: Downloaded newer image for qnib/slurmctld:latest
Creating slurmctld
*snip*
Status: Downloaded newer image for qnib/slurmd:latest
Creating fd20_0
node0 $
{% endhighlight %}

After the service has settled Consul should look like this...

![](/pics/2015-11-29/consul_slurm_node0.png)

Slurm should be up and running and `sinfo` provides one node...

{% highlight bash %}
node0 $ docker exec -ti fd20_0 sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
all*         up   infinite      1   idle fd20_0
even         up   infinite      1   idle fd20_0
node0 $
{% endhighlight %}

### Additional Nodes

Now that the environment variable `CONSUL_IP` is set we can start additional nodes.

{% highlight bash %}
node0 $ cd ../nodes/
node0 $ eval $(machine env node1)
node1 $ cd ../nodes/
node1 $ ./up.sh
Which SUFFIX should we provide fd20_x? 1
+ CNT=1
+ docker-compose up -d
Creating fd20_1
node1 $ docker exec -ti fd20_1 sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
all*         up   infinite      2   idle fd20_[0-1]
odd          up   infinite      1   idle fd20_1
even         up   infinite      1   idle fd20_0
node1 $ docker exec -ti fd20_1 srun -N2 hostname
fd20_1
fd20_0
node1 $
{% endhighlight %}

Last but not least, let's bring up `node2`

{% highlight bash %}
node1 $ eval $(machine env node2)
node2 $ cd ../nodes/
node2 $ ./up.sh
Which SUFFIX should we provide fd20_x? 2
+ CNT=2
+ docker-compose up -d
Creating fd20_2
node2 $ docker exec -ti fd20_2 sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
all*         up   infinite      3   idle fd20_[0-2]
odd          up   infinite      1   idle fd20_1
even         up   infinite      2   idle fd20_[0,2]
node2 $ docker exec -ti fd20_2 srun -N3 hostname
fd20_1
fd20_0
fd20_2
node2 $
{% endhighlight %}

## Future Work

Ok, that was a fun ride so far, but what's missing?


- **Shared FS** The containers do not share a volume or a underlying filesystem. On a HPC cluster here should be something present, therefore just uncomment and adjust the `volume` part in `base.yml`.
- **User Consolidation** I talked to a guy at the DockerCon, who was using a `nscld`-socket to introduce the cluster users to the containers; that I like - I have to rediscover his mail address. No matter how, somehow the users have to be present within the containers. AFAIK the promised `USER_NAMESPACE` is not going to help, since it just defines a mapping of UID and GID from within to outside of the container, but to make this fun, all groups of a user have to be known within.
- **Volumes** I haven't played around with volumes yet, but this might be also one way of having a shared filesystem. Or maybe providing access to the (read-only) input deck could be done like this. We'll see.
- **MPI & Interconnect** Sure we want to  run some distributed applications, therefore IB would be nice. But that's trivial, once I got my hands on it again. I will share this to make it clear.
- **More distributions** It would be fun to provide more distributions to let them compete with each other (as Robert mentioned, the reason why I am blogging about it). That's for another post.
- **SWARM** Swarm would make the constant changing of Docker targets obsolet. As my [docker swarm blog post](http://qnib.org/2015/11/18/docker-swarm/) showed, it's not even hard to use it.
- **Stuff I forgot** I am quite sure I forgot something, but the post is long enough already... Ahh, Providing a stack to process all logs and metrics would be cool... Another time. :)

## Conclusion

It's not that hard to compose a simple HPC cluster to use Docker containers. 

Enjoy!


