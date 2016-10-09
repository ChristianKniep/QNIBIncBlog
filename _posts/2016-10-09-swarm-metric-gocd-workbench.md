---
author: Christian Kniep
layout: post
title: "GOCD + metric stacks via Docker Services"
date: 2016-10-09
tags: eng docker blog
---

I won't apologise for the log delay between posts again, busy times...

But that should discourage you from checking in every once in a while - I got something nice today, at least I think so. :)

## Hardware Update

I've been busy looking hard on Docker Services and how to use them to orchestrate stuff. As this week-end in Berlin brought bad weather - hence some time on my plate to revisit my little home-server setup.

I bought a new machine with more oomph to supply my little video-capture setup [Shuttle DS57U](http://www.shuttle.eu/products/slim/ds57u/).

This bugger has a 14nm Celeron instead of the old 22nm Celeron J1900 ([Shuttle XS36v4](http://www.shuttle.eu/products/slim/xs36v4/overview/)). Even though it has four cores it was sweating catching up with the video decoding. The new one even got encoder/decoder within the Chipset.

## Docker Services Server

Anyway, so I was able to kick out my Raspi3 and use the aforementioned XS36v4 to supply my home automation system (based on OpenHABA, but that is for another post).

This weekend I refined my setup, so that I spin up a couple of Docker Services. The beauty is, that Docker Services survive a reboot. The Docker SWARM will come up and will make sure that all services are started.
Furthermore I could employ the DS57U to spin up and connect to the SWARM cluster to help out on tasks.

### Basic setup

The setup is pretty simple: 

- Download your favourite Linux distro and install it on the machine
- Install the latest docker-engine (>1.12)

That is basically it. I will show the little walkthrough creating services on my macbook, but any docker-engine will do.

### Create a SWARM

Simply do this...

{% highlight bash %}
$ docker swarm init
Swarm initialized: current node (akp0y81cjkoqzbylidgnpwxq3) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-577ue6408olgvjik6udaerh8qqk7lia75crjb27vr3bfu943ou-eco4gev0hnu0mhnjph34vepam \
    192.168.65.2:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.

$
{% endhighlight %}

That's that.

### Create the services

Clone my `service-orchestration` and `service-scripts` repository:

{% highlight bash %}
$ git clone https://github.com/qnib/service-orchestration.git
$ git clone https://github.com/qnib/service-scripts.git
{% endhighlight %}

**Be aware**: Creating a service means that the image has to be downloaded from the interweb. Even though my images are quite small - YMMV.

{% highlight bash %}
$ docker images |egrep "voodoo-query with manual removal"
qnib/influxdb              latest              b14dae6e20ff        5 hours ago         171.6 MB
qnib/d12-alpn-gocd-agent   latest              872cb4fb5f16        19 hours ago        858.3 MB
qnib/qcollect              latest              0080d849c817        2 weeks ago         153.9 MB
qnib/grafana3              latest              f2a16cecc247        3 weeks ago         1.078 GB
qnib/d12-alpn-gocd-agent   latest              872cb4fb5f16        19 hours ago        858.3 MB
$
{% endhighlight %}

Looking at it, there is some room for improvement - 1GB? Srsly!?...

#### Docker Application Bundle
I created a little script that turns `docker-compose.yml` files into docker services as the Docker Application Bundle lacks some features. In the future the script should be unnecessary, but if you try to create a bundle from this:

{% highlight bash %}
version: '2'
services:
  gocd-server: #1
    image: qnib/d12-gocd-server
    networks:
     - consul-net
    ports:
     - 8153:8153
    environment:
     - DC_NAME=swarm
     - GOCD_SERVER_CLEAN_WORKSPACE=false
     - CONSUL_CLUSTER_IPS=consul
     # if more then one service is started, this is going to cause trouble
     - CONSUL_NODE_NAME=gocd-server
    labels:
      - "org.qnib.service.depend_on=consul"
    volumes:
     - /srv/go-server/serverBackups/:/opt/go-server/artifacts/serverBackups/
     - /srv/go-server/pipelines/:/srv/go-server/pipelines/

networks:
  consul-net:
    external: true
{% endhighlight %}

It will complain about all the stuff that is currently not implemented (which is OK, it's an iterative approach and only the first iteration).

{% highlight bash %}
$ docker-compose bundle
WARNING: Unsupported top level key 'networks' - ignoring
WARNING: Unsupported key 'volumes' in services.gocd-agent - ignoring
WARNING: Unsupported key 'volumes' in services.gocd-server - ignoring
Wrote bundle to gocd.dab
$ jq . gocd.dab 
{
  "Services": {
    "gocd-server": {
      "Env": [
        "DC_NAME=swarm",
        "GOCD_SERVER_CLEAN_WORKSPACE=false",
        "CONSUL_CLUSTER_IPS=consul",
        "CONSUL_NODE_NAME=gocd-server"
      ],
      "Image": "qnib/d12-gocd-server@sha256:0548acc49bafe03c0fba1a91620ca6f734a37c85aa3de1b2b7fd28ffa1a2f03e",
      "Labels": {
        "org.qnib.service.depend_on": "consul"
      },
      "Networks": [
        "consul-net"
      ],
      "Ports": [
        {
          "Port": 8153,
          "Protocol": "tcp"
        }
      ]
    }
  },
  "Version": "0.1"
}
{% endhighlight %}

It at least misses out on the volumes and the compose-file has not yet the notion of replication level. Therefore I will stick with a script that turns a docker compose file into a `docker service create` command.

#### Consul

By firing up the `start-service.sh` script, it will transform the YAML into JSON (easier to use with `jq`), parse some stuff and assemble a `docker service create` command.

{% highlight bash %}
$ cd ../consul
$ bash ../../service-scripts/service-scripts/swarm/bin/start-service.sh docker-compose.yaml
>> COMPOSE_FILE=docker-compose.yaml
>> COMPOSE_JSON=docker-compose.json
>> Looking into Service 'consul', expected scale '1'
Error: no such service: consul
>>> Create consul-net: docker network create -d overlay consul-net
99if8j509wjvvlq9d38bbhup4
jq: error (at docker-compose.json:27): Cannot iterate over null (null)
[PROCEED] No service running...
>>> docker service create --name consul -e DC_NAME=swarm -e CONSUL_BOOTSTRAP_EXPECT=1 -e CONSUL_SKIP_CURL=true -e CONSUL_NODE_NAME=consul \
                --mode=replicated --replicas=1  --network consul-net \
                 --publish 8500:8500 \
                 --mount type=bind,source=/etc/hostname,target=/etc/docker-hostname \
                 \
                qnib/alpn-consul:d12
4fkvajoecqzs0r3x3qjgzm69g
$
{% endhighlight %}

After a couple of seconds the consul service will be up'n'running and reachable under [localhost:8500](http://localhost:8500) (YMMV depending on the IP address of your docker-engine).

![](/pics/2016-10-09/consul.png)

#### InfluxDB

I updated my InfluxDB stack to use Alpine and the latest version.


{% highlight bash %}
$ cd ../influxdb
$ bash ../../service-scripts/service-scripts/swarm/bin/start-service.sh docker-compose.yaml
>> COMPOSE_FILE=docker-compose.yaml
>> COMPOSE_JSON=docker-compose.json
>> Looking into Service 'influxdb', expected scale '1'
Error: no such service: influxdb
>>> Network consul-net already existing...
jq: error (at docker-compose.json:26): Cannot iterate over null (null)
[PROCEED] Service dependency 'consul' is running, off we go..
[PROCEED] No service running...
>>> docker service create --name influxdb -e DC_NAME=swarm -e CONSUL_NODE_NAME=influxdb -e COLLECT_METRICS=false -e INFLUXDB_DATABASES=qcollect -e CONSUL_CLUSTER_IPS=consul -e INFLUXDB_META_LOGGING=true \
                --mode=replicated --replicas=1  --network consul-net \
                 --publish 2003:2003 --publish 8083:8083 --publish 8086:8086 \
                 \
                 \
                qnib/influxdb
3f9dsaa0hwzldxkuz4dvg5pg3
$ docker service ls
ID            NAME      REPLICAS  IMAGE                 COMMAND
3f9dsaa0hwzl  influxdb  0/1       qnib/influxdb
4fkvajoecqzs  consul    1/1       qnib/alpn-consul:d12
$
{% endhighlight %}

After a couple of seconds you should be able to reach [localhost:8083](http://localhost:8083).

![](/pics/2016-10-09/influxdb_init.png)

Make sure to change the Database in the upper right to `qcollect`.

#### qcollect

What is a metrics back-end without some metrics? Therefore, we spin up qcollect - my fullerite fork.

{% highlight bash %}
$ cd ../qcollect
$ bash ../../service-scripts/service-scripts/swarm/bin/start-service.sh docker-compose.yaml
>> COMPOSE_FILE=docker-compose.yaml
>> COMPOSE_JSON=docker-compose.json
>> Looking into Service 'qcollect', expected scale 'global'
Error: no such service: qcollect
>>> Network consul-net already existing...
jq: error (at docker-compose.json:26): Cannot iterate over null (null)
[PROCEED] Service dependency 'influxdb' is running, off we go..
[PROCEED] No service running...
>>> docker service create --name qcollect -e CONSUL_DC_NAME=swarm -e DC_NAME=swarm -e QCOLLECT_INFLUXDB_ENABLED=true -e QCOLLECT_INFLUXDB_SERVER=influxdb -e DOCKER_HOST=unix:///var/run/docker.sock -e QCOLLECT_INTERVAL=2 -e CONSUL_CLUSTER_IPS=consul -e CONSUL_NODE_NAME=qcollect \
                --mode global  --network consul-net \
                 \
                 --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
                 \
                qnib/qcollect
cona63mc69s339gy2brsbkpwi
$ docker service ls
ID            NAME      REPLICAS  IMAGE                 COMMAND
3f9dsaa0hwzl  influxdb  1/1       qnib/influxdb
4fkvajoecqzs  consul    1/1       qnib/alpn-consul:d12
cona63mc69s3  qcollect  global    qnib/qcollect
$
{% endhighlight %}

If we now wait a sec' - there will be metrics flowing in...

![](/pics/2016-10-09/influxdb_qcollect.png)

#### Grafana3

OK, but metrics to look at is nothing without something to visualise it.

{% highlight bash %}
$ cd ../grafana3
$ bash ../../service-scripts/service-scripts/swarm/bin/start-service.sh docker-compose.yaml
>> COMPOSE_FILE=docker-compose.yaml
>> COMPOSE_JSON=docker-compose.json
>> Looking into Service 'grafana3', expected scale '1'
Error: no such service: grafana3
>>> Network consul-net already existing...
jq: error (at docker-compose.json:22): Cannot iterate over null (null)
[PROCEED] Service dependency 'consul' is running, off we go..
[PROCEED] Service dependency 'influxdb' is running, off we go..
[PROCEED] No service running...
>>> docker service create --name grafana3 -e DC_NAME=swarm -e COLLECT_METRICS=false -e CONSUL_CLUSTER_IPS=consul -e CONSUL_NODE_NAME=grafana3 \
                --mode=replicated --replicas=1  --network consul-net \
                 --publish 3000:3000 \
                 \
                 \
                qnib/grafana3
67dsx4pa9byj9a6l9p3qf56jx
$ docker service ls
ID            NAME      REPLICAS  IMAGE                 COMMAND
3f9dsaa0hwzl  influxdb  1/1       qnib/influxdb
4fkvajoecqzs  consul    1/1       qnib/alpn-consul:d12
67dsx4pa9byj  grafana3  0/1       qnib/grafana3
cona63mc69s3  qcollect  global    qnib/qcollect
$
{% endhighlight %}

After it is downloaded (that's true for the rest of the services as well), that is...

{% highlight bash %}
$ docker service ps grafana3
ID                         NAME        IMAGE          NODE  DESIRED STATE  CURRENT STATE             ERROR
50zhx77p00and3835dm0z4z3u  grafana3.1  qnib/grafana3  moby  Running        Preparing 55 seconds ago
$
{% endhighlight %}

Afterwards just open [localhost:3000](http://localhost:3000), login with `admin/admin` and open the predefined dashboard.

![](/pics/2016-10-09/grafana.png)


#### GoCD

Last I need something to free me from keeping track of what I have build and how - a Continuous Integration platform like GoCD will do.
This one defines two services and will start them both.

{% highlight bash %}
$ cd ../gocd
$ bash ../../service-scripts/service-scripts/swarm/bin/start-service.sh docker-compose.yaml
>> COMPOSE_FILE=docker-compose.yaml
>> COMPOSE_JSON=docker-compose.json
>> Looking into Service 'gocd-server', expected scale '1'
Error: no such service: gocd-server
>>> Network consul-net already existing...
[PROCEED] Service dependency 'consul' is running, off we go..
[PROCEED] No service running...
>>> docker service create --name gocd-server -e DC_NAME=swarm -e GOCD_SERVER_CLEAN_WORKSPACE=false -e CONSUL_CLUSTER_IPS=consul -e CONSUL_NODE_NAME=gocd-server \
                --mode=replicated --replicas=1  --network consul-net \
                 --publish 8153:8153 \
                 \
                 \
                qnib/d12-gocd-server
8l5v3tzroi2t03qc4zrzhvzh0
>> Looking into Service 'gocd-agent', expected scale 'global'
Error: no such service: gocd-agent
>>> Network consul-net already existing...
jq: error (at docker-compose.json:49): Cannot iterate over null (null)
[PROCEED] Service dependency 'consul' is running, off we go..
[PROCEED] Service dependency 'gocd-server' is running, off we go..
[PROCEED] No service running...
>>> docker service create --name gocd-agent -e DC_NAME=swarm -e GO_SERVER=gocd-server -e GOCD_LOCAL_DOCKERENGINE=false -e CONSUL_CLUSTER_IPS=consul \
                --mode global  --network consul-net --network consul-net \
                 \
                 --mount type=bind,source=/var/run/docker.sock,target=/var/run/docker.sock \
                 \
                qnib/d12-alpn-gocd-agent
8smpngduu56jx4fxwj4znluxr
$
{% endhighlight %}

Btw, a recently realised that `$(docker ps -ql)` comes in handy, as it will show you the container_id of the last started container.

{% highlight bash %}
$ docker service ps gocd-server
ID                         NAME           IMAGE                 NODE  DESIRED STATE  CURRENT STATE           ERROR
1aiq3s15anidplqyz70qyy0aq  gocd-server.1  qnib/gocd-server:d12  moby  Running        Starting 4 seconds ago
$ docker inspect $(docker ps -ql) |jq ".[] |.Config.Healthcheck"{
  "Test": [
    "CMD-SHELL",
    "/opt/qnib/gocd/server/bin/healthcheck.sh"
  ],
  "Interval": 5000000000,
  "Timeout": 2000000000,
  "Retries": 120
}
$
{% endhighlight %}

As the GoCD server is a heavy java8 process (I am waiting for the day, when everyone comes fresh from university and fancies something less heavy [*duck'n'cover*]).

But once, it is up hit [localhost:8153](http://localhost:8153) to get the first screen...

![](/pics/2016-10-09/gocd.png)

How to set it up with the stack - that's another post (as said before).

Enjoy!


### The end

That's it, the services should hum along and even survive a reboot, as the containers are stop at shutdown and just started by SWARM when the system comes up again. :)

{% highlight bash %}
$ docker service ls                                                                                                                                                                                                                                                                                                    git:(master↑3|✚1
ID            NAME         REPLICAS  IMAGE                     COMMAND
3f9dsaa0hwzl  influxdb     1/1       qnib/influxdb
4fkvajoecqzs  consul       1/1       qnib/alpn-consul:d12
67dsx4pa9byj  grafana3     1/1       qnib/grafana3
8l5v3tzroi2t  gocd-server  1/1       qnib/d12-gocd-server
8smpngduu56j  gocd-agent   global    qnib/d12-alpn-gocd-agent
cona63mc69s3  qcollect     global    qnib/qcollect
$
{% endhighlight %}

So long
Christian