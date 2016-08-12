---
author: Christian Kniep
layout: post
title: "Consul as a (Docker) Service"
date: 2016-08-11
tags: eng docker blog
---

After a couple of month being busy, it's time for a blog post about Docker Services.  

As I stated often - I became a big fan of Consul for service orchestration, service discovery and as a K/V store in my docker stacks.

Since Docker Engine 1.11 the necessary DNS feature to be able to use a 127.0.0.1 address was somewhat kicked, so I had a hard nut to crack. My workaround was to not care about local resolution and use the consul servers as DNS resource. Anyway...

## Hello Docker Service

When trying to apply consul to Docker Services I encountered another problem.
A Docker service name is addressable via the embedded DNS of the Docker engine.
So reaching service *A*  from service *B* is easy by just issuing `$ ping A`.

### How about Consul

The first attempt might be to just spin up a service with three replicas and tell them to join the service name.

{% highlight bash %}
$ docker service create --name consul --replicas=3 --publish=8500:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul \
                            --network consul-net \
                            qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5
bx2nrlhdc86unt2zwzm5ms7hd
{% endhighlight %}

The problem (as far as I can tell for now) is, that the members are not able to resolve the cluster mates DNS name `consul`, as they are all part of it. But how to bootstrap a consul cluster if you can not address the rest of the 'team'?

### Blue/Green

My current solution is quite simple. I just spin up a seed-consul cluster.
{% highlight bash %}
$ docker service create --name consul-seed --replicas=1 --publish=8501:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-seed,consul \
                            --network consul-net \
                            qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5
{% endhighlight %}

It is suffixed `-seed`, uses a slightly different port and won't never lift off by itself, as it needs at least three servers to bootstrap. The cluster peers to join are `consul-seed` and `consul`.

It creates a DC and lingers around, waiting for more servers to join.

{% highlight bash %}
$ docker ps 
CONTAINER ID        IMAGE                                                                                      COMMAND                  CREATED             STATUS              PORTS                               NAMES
48fce13c478c        qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5   "/opt/qnib/supervisor"   4 seconds ago       Up 2 seconds        8300-8301/tcp, 8400/tcp, 8500/tcp   consul-seed.1.89001zsr2luzxqvtlmystiy9m
$ docker exec -ti 48fce13c478c consul members
Node          Address        Status  Type    Build  Protocol  DC
48fce13c478c  10.0.1.3:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}

Now I start the real consul service which uses the same `CONSUL_CLUSTER_IPS` setting, so it will at least join the `consul-seed` service, as this one is up and running and reachable.

{% highlight bash %}
$ docker service create --name consul --replicas=3 --publish=8500:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-seed,consul \
                            --network consul-net \
                            qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5
{% endhighlight %}

Now I got four servers in my dc.

{% highlight bash %}
$ docker ps
CONTAINER ID        IMAGE                                                                                      COMMAND                  CREATED             STATUS              PORTS                               NAMES
98b283409afe        qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5   "/opt/qnib/supervisor"   22 seconds ago      Up 19 seconds       8300-8301/tcp, 8400/tcp, 8500/tcp   consul.2.39i6ztgsh2yhoefo0w2l9y43m
9493c8528e05        qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5   "/opt/qnib/supervisor"   22 seconds ago      Up 20 seconds       8300-8301/tcp, 8400/tcp, 8500/tcp   consul.1.2mdx44un16xonzbncdmyl5kf2
0fe68cddca78        qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5   "/opt/qnib/supervisor"   22 seconds ago      Up 20 seconds       8300-8301/tcp, 8400/tcp, 8500/tcp   consul.3.eqx7fubo4dxp8p17bmatyvtxw
48fce13c478c        qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5   "/opt/qnib/supervisor"   3 minutes ago       Up 3 minutes        8300-8301/tcp, 8400/tcp, 8500/tcp   consul-seed.1.89001zsr2luzxqvtlmystiy9m
$ docker exec -ti 48fce13c478c consul members
Node          Address        Status  Type    Build  Protocol  DC
0fe68cddca78  10.0.1.7:8301  alive   server  0.6.4  2         dc1
48fce13c478c  10.0.1.3:8301  alive   server  0.6.4  2         dc1
9493c8528e05  10.0.1.5:8301  alive   server  0.6.4  2         dc1
98b283409afe  10.0.1.6:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}

I tweaked my supervisor parent a bit, so that it forwards the `SIGTERM` signal in case a container is stopped. This signal is used to gracefully stop a consul container. He simply has `trap "consul leave" SIGTERM TERM` set in the consul start script and as supervisor passes this down to all services he is going to leave when I kill the no longer needed `consul-seed` service.

{% highlight bash %}
$ docker service rm consul-seed
consul-seed
$ docker exec -ti 98b283409afe consul members
Node          Address        Status  Type    Build  Protocol  DC
0fe68cddca78  10.0.1.7:8301  alive   server  0.6.4  2         dc1
48fce13c478c  10.0.1.3:8301  left    server  0.6.4  2         dc1
9493c8528e05  10.0.1.5:8301  alive   server  0.6.4  2         dc1
98b283409afe  10.0.1.6:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}

### Rolling Update

In case I need to update or scale my consul service I will just start the `consul-seed` service. This is going to be the common entry point which will allow everyone to bond.

{% highlight bash %}
$ docker service create --name consul-seed --replicas=1 --publish=8501:8500 \
                            -e CONSUL_BOOTSTRAP_EXPECT=3 \
                            -e CONSUL_SKIP_CURL=true \
                            -e CONSUL_CLUSTER_IPS=consul-seed,consul \
                            --network consul-net \
                            qnib/alpn-consul@sha256:846d2005c527d8b764e985166d8c92fd60b9116ea436787f9d289dbc5f0756f5
46u291ex1zx720ob4qk08vcph
$ sleep 30 ; docker exec -ti 98b283409afe consul members
Node          Address        Status  Type    Build  Protocol  DC
0fe68cddca78  10.0.1.7:8301  alive   server  0.6.4  2         dc1
139fce7cdb17  10.0.1.3:8301  alive   server  0.6.4  2         dc1
48fce13c478c  10.0.1.3:8301  left    server  0.6.4  2         dc1
9493c8528e05  10.0.1.5:8301  alive   server  0.6.4  2         dc1
98b283409afe  10.0.1.6:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}

No I scale the real service, and kill the `seed` afterwards.

{% highlight bash %}
$ docker service update --replicas=4 consul
consul
$ docker exec -ti 98b283409afe consul members
Node          Address        Status  Type    Build  Protocol  DC
0fe68cddca78  10.0.1.7:8301  alive   server  0.6.4  2         dc1
139fce7cdb17  10.0.1.3:8301  alive   server  0.6.4  2         dc1
48fce13c478c  10.0.1.3:8301  left    server  0.6.4  2         dc1
569a327b4360  10.0.1.8:8301  alive   server  0.6.4  2         dc1
9493c8528e05  10.0.1.5:8301  alive   server  0.6.4  2         dc1
98b283409afe  10.0.1.6:8301  alive   server  0.6.4  2         dc1
$ docker service rm consul-seed
consul-seed
$ docker exec -ti 98b283409afe consul members
Node          Address        Status  Type    Build  Protocol  DC
0fe68cddca78  10.0.1.7:8301  alive   server  0.6.4  2         dc1
139fce7cdb17  10.0.1.3:8301  left    server  0.6.4  2         dc1
48fce13c478c  10.0.1.3:8301  left    server  0.6.4  2         dc1
569a327b4360  10.0.1.8:8301  alive   server  0.6.4  2         dc1
9493c8528e05  10.0.1.5:8301  alive   server  0.6.4  2         dc1
98b283409afe  10.0.1.6:8301  alive   server  0.6.4  2         dc1
$
{% endhighlight %}



