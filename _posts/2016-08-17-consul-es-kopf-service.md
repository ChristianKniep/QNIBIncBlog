---
author: Christian Kniep
layout: post
title: "Elasticsearch/Kopf as a Distributed (Docker) Service"
date: 2016-08-17
tags: eng docker blog
---

Running Docker services on single nodes is quite boring, so let's boot up three boxes with the latest version of docker.

This is a blog post to accompany the talk I gave a the [Berlin Docker Meetup](https://www.meetup.com/Lieferando-Tech-Events-Berlin/events/233138777/):

<iframe width="560" height="315" src="https://www.youtube.com/embed/g-YNST-COdI" frameborder="0" allowfullscreen></iframe>

## Create multi-host Docker SWARM

For this little the boxes are only equipped with 1GB of RAM and one core, for Elasticsearch this is quite small...
If you like to change it look into the `Vagrantfile`.

{% highlight bash %}
$ git clone https://github.com/qnib/vagrant-orchestration.git
Cloning into 'vagrant-orchestration'...
remote: Counting objects: 11, done.
remote: Compressing objects: 100% (9/9), done.
remote: Total 11 (delta 1), reused 7 (delta 0), pack-reused 0
Unpacking objects: 100% (11/11), done.
Checking connectivity... done.
$ cd vagrant-orchestration/docker-1.12
$ vagrant up
Bringing machine 'swarm0' up with 'virtualbox' provider...
Bringing machine 'swarm1' up with 'virtualbox' provider...
Bringing machine 'swarm2' up with 'virtualbox' provider...
==> swarm0: Importing base box 'btexpress/ubuntu64-16.04'...
==> swarm0: Matching MAC address for NAT networking...
*snip*
==> swarm2:   inflating: consul-template
==> swarm2: Created symlink from /etc/systemd/system/multi-user.target.wants/docker.service to /lib/systemd/system/docker.service.
==> swarm2: export DOCKER_HOST=:2376 ; unset DOCKER_TLS_VERIFY ; unset DOCKER_CERT_PATH
$
{% endhighlight %}

Now we just need to create a swarm out of them:

{% highlight bash %}
$ export DOCKER_HOST=192.168.100.10:2376
$ docker swarm init --advertise-addr=192.168.100.10
Swarm initialized: current node (4qoc5xmwadimvvlkpw49vyau2) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join \
    --token SWMTKN-1-3lzna54jxjosmfbxprg3shcm9qspp6js50xgr9d9mnz6t67t26-b6chdyqxm7xfa0oun4jyu5a1u \
    192.168.100.10:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
$ docker -H 192.168.100.11:2376 swarm join --advertise-addr=192.168.100.11 --token SWMTKN-1-3lzna54jxjosmfbxprg3shcm9qspp6js50xgr9d9mnz6t67t26-b6chdyqxm7xfa0oun4jyu5a1u 192.168.100.10:2377
This node joined a swarm as a worker.
$ docker -H 192.168.100.12:2376 swarm join --advertise-addr=192.168.100.12 --token SWMTKN-1-3lzna54jxjosmfbxprg3shcm9qspp6js50xgr9d9mnz6t67t26-b6chdyqxm7xfa0oun4jyu5a1u 192.168.100.10:2377
This node joined a swarm as a worker.
$ docker node ls
ID                           HOSTNAME  STATUS  AVAILABILITY  MANAGER STATUS
07qihqioh09i92apn9zurnpu0    swarm2    Ready   Active
4qoc5xmwadimvvlkpw49vyau2 *  swarm0    Ready   Active        Leader
9wyqn6x9c9nkmuawxmll9d60p    swarm1    Ready   Active
$
{% endhighlight %}

## Docker Services

The goal in this post is to create docker services for...

- **Consul**: To base stacks on 
- **Elasticsearch**: As a log backend
- **Kopf**: As a frontend to check what is going on in ES

### Consul

As the embedded DNS server only resolves complete service names and not the individual tasks in a deterministic manner (the tasks include the task-ID, which is not known in advance), I came up with a two step approach (see: [Consul as a Service](http://qnib.org/2016/08/11/consul-service/)).

{% highlight bash %}
$ docker network create -d overlay consul-net
2133n6h6ke23c7k2li9frac0r
$ docker service create --name consul-blue --replicas=1 --publish=8501:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-blue,consul-green \
                            --network consul-net \
                            qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
d24opk96vmlbxp5pueyxxmebq
$ sleep 15 ; docker service ls
ID            NAME         REPLICAS  IMAGE                                                                                     COMMAND
d24opk96vmlb  consul-blue  1/1       qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
$
{% endhighlight %}

After a couple of seconds an empty consul UI should be available at [http://192.168.100.10:8501/ui/#/dc1/nodes](http://192.168.100.10:8501/ui/#/dc1/nodes).

![](/pics/2016-08-17/consul_empty.png)

After the seed is planted one group can be fully started.

{% highlight bash %}
$ docker service create --name consul-green --mode=global --publish=8500:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-blue,consul-green \
                            --network consul-net \
                            qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
5k8fotte9ofs73v0rwky744vn
$
{% endhighlight %}


As the cluster reaches the quorum, it bootstraps itself.

![](/pics/2016-08-17/consul_init.png)

Now we recreate the `consul-blue` service as well as a global service.

{% highlight bash %}
$ docker service rm consul-blue
$ sleep 15 # to wait for the tasks to finish
$ docker service create --name consul-blue --mode=global --publish=8501:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-blue,consul-green \
                            --network consul-net \
                            qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
3xglxrb69iqmlhzfle00g4rcu
$
{% endhighlight %}

Et voila, we got six consul nodes...

![](/pics/2016-08-17/consul_ready.png)

{% highlight bash %}
$ docker exec $(docker ps --format '{{.ID}}' |head -n1) consul members
Node          Address        Status  Type    Build  Protocol  DC
0415081a1d18  10.0.0.8:8301  alive   server  0.6.4  2         dc1
3461f4621444  10.0.0.9:8301  alive   server  0.6.4  2         dc1
34f41ff6b55f  10.0.0.6:8301  alive   server  0.6.4  2         dc1
88d0a6e5b04b  10.0.0.7:8301  alive   server  0.6.4  2         dc1
9099affaf49e  10.0.0.5:8301  alive   server  0.6.4  2         dc1
f203f17e4b59  10.0.0.3:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}

### Elasticsearch

Elasticsearch docks onto the consul services and runs in global mode.

{% highlight bash %}
$ docker service create --name elasticsearch --mode=global --publish=9200:9200 --publish=9300:9300 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-blue,consul-green \
                            --network consul-net \
                            qnib/alpn-elasticsearch@sha256:f06e9a6bacea23096306fc99df0d3edc11275c12b0fc85b24b835730345f9064
6x4kyxuisgq5jyyo4x3phyncm
$ docker service ls
ID            NAME           REPLICAS  IMAGE                                                                                            COMMAND
3xglxrb69iqm  consul-blue    global    qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
5k8fotte9ofs  consul-green   global    qnib/alpn-consul@sha256:9006ef36441f8f45e01682a4f61ef213ab345dfde9680bb7e225c435e4c878e5
6x4kyxuisgq5  elasticsearch  global    qnib/alpn-elasticsearch@sha256:f06e9a6bacea23096306fc99df0d3edc11275c12b0fc85b24b835730345f9064
$ sleep 45
$ echo -e 'NAME\t\t\t\t\t\tSTATUS' ;  docker ps --format '{{ .Names }}\t\t{{ .Status }}'
NAME						                STATUS
elasticsearch.0.6urtk1lhkzmysnkf2i5sqp3o4   Up 4 minutes (healthy)
consul-blue.0.b0rd0ktvofswbe7lrkrsboo8g     Up 9 minutes (healthy)
consul-green.0.60v4dtutijhapp9pmz566g9zz    Up 12 minutes (healthy)
$
{% endhighlight %}

After some time the cluster should be p'n'running...

{% highlight bash %}
$ curl -s 192.168.100.10:9200/_cluster/health |jq .
{
  "cluster_name": "qnib",
  "status": "green",
  "timed_out": false,
  "number_of_nodes": 3,
  "number_of_data_nodes": 3,
  "active_primary_shards": 0,
  "active_shards": 0,
  "relocating_shards": 0,
  "initializing_shards": 0,
  "unassigned_shards": 0,
  "delayed_unassigned_shards": 0,
  "number_of_pending_tasks": 0,
  "number_of_in_flight_fetch": 0,
  "task_max_waiting_in_queue_millis": 0,
  "active_shards_percent_as_number": 100
}
$
{% endhighlight %}

### Kopf

To get an idea what is going on within the cluster, let us start a kopf service. Load balanced across two tasks should be enough.


{% highlight bash %}
$ docker service create --name kopf --replicas=2 --publish=80:80 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-blue,consul-green \
                            --network consul-net \
                            qnib/kopf@sha256:1536e4cfe052b8ff2268823996000bbe45edd5cdbb021997e22593391044ec36
4tgwrs3z9m418l1200xxig6g9
$ docker service ls
$ docker service ls
ID            NAME           REPLICAS  IMAGE                                                                                            COMMAND
3xglxrb69iqm  consul-blue    global    qnib/alpn-consul@sha256:900*snip*
4irbxjiid8rb  elasticsearch  global    qnib/alpn-elasticsearch@sha256:f06*snip*
5k8fotte9ofs  consul-green   global    qnib/alpn-consul@sha256:900*snip*
drv2gl2kq231  kopf           2/2       qnib/kopf@sha256:153*snip*
$$
{% endhighlight %}

## Use It

Now let's push some data...

{% highlight bash %}
$ curl -XPUT 'http://192.168.100.10:9200/twitter/tweet/1' -d '{
    "user" : "kimchy",
    "post_date" : "2016-08-16T14:12:12",
    "message" : "trying out Elasticsearch"
}'
{"_index":"twitter","_type":"tweet","_id":"1","_version":1,"_shards":{"total":2,"successful":1,"failed":0},"created":true}$
{% endhighlight %}

And kopf reports something back... :)

![](/pics/2016-08-17/kopf.png)

## Future Work

From here on the sky is the limit... Put logstash next to it, or dump wikipedia into ES - kibana4 would be nice as well.

It's all so fresh. :)