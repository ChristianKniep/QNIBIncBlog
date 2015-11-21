---
author: Christian Kniep
layout: post
title: "Docker SWARM 101"
date: 2015-11-18
tags: eng docker blog consul
---

This post will spin up a SWARM cluster backed by a single Consul container on a separat `docker-machine`.

# Checkout the repository

The stack is available on github to provide the files needed.

{% highlight bash %}
$ git clone https://github.com/ChristianKniep/orchestra.git
$ cd orchestra/docker-swarm/
$ ls
{% endhighlight %}

# Bootstrap KV store

{% highlight bash %}
$ docker-machine create -d virtualbox kvstore
INFO[0000] Creating SSH key...
*snip*
$ eval "$(docker-machine env kvstore)"
kvstore $ cd kvstore
{% endhighlight %}

Create the initial Consul server
{% highlight bash %}
kvstore $ cd kvstore/
kvstore $ docker-compose up -d
Pulling consul (qnib/consul:latest)...
Creating consul_init
kvstore $ docker ps
NAMES               IMAGE                             COMMAND                  PORTS
consul         192.168.99.101:5000/qnib/consul   "/opt/qnib/bin/start_"   0.0.0.0:8500->8500/tcp
kvstore $
{% endhighlight %}

The Consul WebUI will appear under the address of the kvstore and port `:8500`.

![](/pics/2015-11-18/consul_init.png)

## Create SWARM Cluster

#### SWARM master

Next up - the SWARM master is created using the Consul cluster on `kvstore` as a backend.

{% highlight bash %}
$ docker-machine create \
    -d virtualbox \
    --swarm --swarm-image="swarm" --swarm-master \
    --swarm-discovery="consul://$(docker-machine ip kvstore):8500" \
    --engine-opt="cluster-store=consul://$(docker-machine ip kvstore):8500" \
    --engine-opt="cluster-advertise=eth1:2376" \
    swarm-master
{% endhighlight %}

`docker-machine` now shows two hosts.

{% highlight bash %}
$ docker-machine ls
NAME           ACTIVE   DRIVER       STATE     URL                         SWARM
kvstore        -        virtualbox   Running   tcp://192.168.99.102:2376
swarm-master   -        virtualbox   Running   tcp://192.168.99.109:2376   swarm-master (master)
{% endhighlight %}

The master itself (the docker engine of the master) runs two containers.

{% highlight bash %}
$ eval "$(machine env swarm-master)"
swarm-master $ docker ps
NAMES                IMAGE               COMMAND                  PORTS
swarm-agent          swarm               "/swarm join --advert"   2375/tcp
swarm-agent-master   swarm               "/swarm manage --tlsv"   2375/tcp, 0.0.0.0:3376->3376/tcp
swarm-master $
{% endhighlight %}


After the `swarm-master` is created the Key/Value store holds some information about it.

{% highlight bash %}
kvstore $ curl -s $(machine ip kvstore):8500/v1/kv/docker/nodes/?keys | jq .
[
  "docker/nodes/192.168.99.114:2376"
]
kvstore $
{% endhighlight %}

#### SWARM client 0-2

Since a master is nothing without some workers, let's create three swarm nodes. This took a couple of minutes on my poor MacBook; so please be patient.

{% highlight bash %}
$ for cnt in {0..2};do docker-machine create -d virtualbox \
           --swarm --swarm-image="swarm:1.0.0-rc2" \
           --swarm-discovery="consul://$(docker-machine ip kvstore):8500" \
           --engine-opt="cluster-store=consul://$(docker-machine ip kvstore):8500" \
           --engine-opt="cluster-advertise=eth1:2376" \
           swarm-${cnt}
done
$ 
{% endhighlight %}

Each client runs one container, the `swarm-agent`:

{% highlight bash %}
$ eval "$(machine env swarm-0)"
swarm-0 $ docker ps
NAMES               IMAGE               COMMAND                  PORTS
swarm-agent         swarm:1.0.0-rc2     "/swarm join --advert"   2375/tcp
{% endhighlight %}

Now there are even more nodes showing up in `docker-machine ls`...

{% highlight bash %}
$ docker-machine ls
NAME           ACTIVE   DRIVER       STATE     URL                         SWARM
kvstore        -        virtualbox   Running   tcp://192.168.99.113:2376
swarm-0        -        virtualbox   Running   tcp://192.168.99.115:2376   swarm-master
swarm-1        -        virtualbox   Running   tcp://192.168.99.116:2376   swarm-master
swarm-2        -        virtualbox   Running   tcp://192.168.99.117:2376   swarm-master
swarm-master   *        virtualbox   Running   tcp://192.168.99.114:2376   swarm-master (master)
{% endhighlight %}

...and in the KV store.

{% highlight bash %}
kvstore $ curl -s $(machine ip kvstore):8500/v1/kv/docker/nodes/?keys|jq .
[
  "docker/nodes/192.168.99.114:2376",
  "docker/nodes/192.168.99.115:2376",
  "docker/nodes/192.168.99.116:2376",
  "docker/nodes/192.168.99.117:2376"
]
kvstore $
{% endhighlight %}

### Check out SWARM

Congrats! SWARM is up and running...

{% highlight bash %}
$ eval "$(machine env --swarm swarm-master)"
swarm-cluster $ docker info
Containers: 5
Images: 4
Role: primary
Strategy: spread
Filters: health, port, dependency, affinity, constraint
Nodes: 4
 swarm-0: 192.168.99.115:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.021 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.1.12-boot2docker, operatingsystem=Boot2Docker 1.9.0 (TCL 6.4); master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015, provider=virtualbox, storagedriver=aufs
 swarm-1: 192.168.99.116:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.021 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.1.12-boot2docker, operatingsystem=Boot2Docker 1.9.0 (TCL 6.4); master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015, provider=virtualbox, storagedriver=aufs
 swarm-2: 192.168.99.117:2376
  └ Containers: 1
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.021 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.1.12-boot2docker, operatingsystem=Boot2Docker 1.9.0 (TCL 6.4); master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015, provider=virtualbox, storagedriver=aufs
 swarm-master: 192.168.99.114:2376
  └ Containers: 2
  └ Reserved CPUs: 0 / 1
  └ Reserved Memory: 0 B / 1.021 GiB
  └ Labels: executiondriver=native-0.2, kernelversion=4.1.12-boot2docker, operatingsystem=Boot2Docker 1.9.0 (TCL 6.4); master : 16e4a2a - Tue Nov  3 19:49:22 UTC 2015, provider=virtualbox, storagedriver=aufs
CPUs: 4
Total Memory: 4.086 GiB
Name: 5c5a5cdeaeaa
swarm-cluster $
{% endhighlight %}

And off we go...

