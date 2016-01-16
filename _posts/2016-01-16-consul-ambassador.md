---
author: Christian Kniep
layout: post
title: Consul Ambassador Pattern
date: 2016-01-16 11:00
tags: eng docker blog consul
---

Did I mention I love Open-Source software? I do - I really do! :)
Using a pull request on Consul, I get closer to a nice setup: [github isse](https://github.com/hashicorp/consul/issues/1552)

So what I am talking about here? As you readers should already know I use Consul as the backend for my service/node discovery stuff and user related topics.

## NAT

Let's assume we got three containers (`int{1..3}`) within a DC which is accessible to other DC going through a load-balancer (`server`). An external node (`ext0`) has no direct access to the internal network.

![](/pics/2016-01-16/nat.png)

The purple boxes are Consul agents running as server, the others are simple clients.

### Start the stack

{% highlight bash %}
$ sh start.sh
## Networks
[global] > docker network inspect global >/dev/null                        > exists?
[global] > already there (SUB: "10.0.0.0/24")
[int] > docker network inspect int >/dev/null                              > exists?
[int] > already there (SUB: "192.168.1.0/24")
#### Start stack
[server]         > docker-compose up -d server                  > Start
Creating server
[server]         > docker network connect int server            > Connect to int network
[server]         > docker exec -ti server  ip -o -4 addr        > Display ip addresses
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
652: eth0    inet 10.0.0.2/24 scope global eth0\       valid_lft forever preferred_lft forever
654: eth1    inet 192.168.1.2/24 scope global eth1\       valid_lft forever preferred_lft forever
[ext0,int{1..3}] > docker-compose up -d ext0 int1 int2 int3     > Start
Creating ext0
Creating int1
Creating int3
Creating int2
$
{% endhighlight %}

### Look at what we've done

Within DC1 the members look like this:

{% highlight bash %}
$ docker exec -ti server consul members
Node    Address           Status  Type    Build  Protocol  DC
int1    192.168.1.3:8301  alive   client  0.6.0  2         dc1
int2    192.168.1.5:8301  alive   client  0.6.0  2         dc1
int3    192.168.1.4:8301  alive   client  0.6.0  2         dc1
server  10.0.0.2:8301     alive   server  0.6.0  2         dc1
$
{% endhighlight %}

`ext0` is connected only to `server` as a WAN-buddy:

{% highlight bash %}
$ docker exec -ti server consul members -wan
Node        Address        Status  Type    Build  Protocol  DC
ext0.dc2    10.0.0.3:8302  alive   server  0.6.0  2         dc2
server.dc1  10.0.0.2:8302  alive   server  0.6.0  2         dc1
$
{% endhighlight %}

But, `ext0` uses WAN addresses instead of internal addresses to resolve names:

{% highlight bash %}
$ docker exec -ti ext0 grep translate /etc/consul.json
    "translate_wan_addrs": true,
$
{% endhighlight %}

The setup has the following WAN addresses configured:

- **int1**:`""` Default behaviour
- **int2**: `"8.8.8.8"` As if the container is a placeholder for an external service
- **int3**: `"10.0.0.2"` As if the container is hidden behind a load-balancer

Therefore pinging the host, leads to different outcomes.

### Int1

This container is not reachable, since the network is not routed:

{% highlight bash %}
$ docker exec -ti ext0 ping -w1 -c1 int1.node.dc1.consul
PING int1.node.dc1.consul (192.168.1.3) 56(84) bytes of data.

--- int1.node.dc1.consul ping statistics ---
1 packets transmitted, 0 received, 100% packet loss, time 0ms
$
{% endhighlight %}

### Int2

Nice as a placeholder for not yet containerised external services.

{% highlight bash %}
$ docker exec -ti ext0 ping -w1 -c1 int2.node.dc1.consul
PING int2.node.dc1.consul (8.8.8.8) 56(84) bytes of data.
64 bytes from google-public-dns-a.google.com (8.8.8.8): icmp_seq=1 ttl=61 time=48.7 ms

--- int2.node.dc1.consul ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 48.788/48.788/48.788/0.000 ms
$
{% endhighlight %}

### Int3

`int3` might be a web server behind the loadbalancer (or NAT) `server`.

{% highlight bash %}
$ docker exec -ti ext0 ping -w1 -c1 int3.node.dc1.consul
PING int3.node.dc1.consul (10.0.0.2) 56(84) bytes of data.
64 bytes from server (10.0.0.2): icmp_seq=1 ttl=64 time=0.100 ms

--- int3.node.dc1.consul ping statistics ---
1 packets transmitted, 1 received, 0% packet loss, time 0ms
rtt min/avg/max/mdev = 0.100/0.100/0.100/0.000 ms
$
{% endhighlight %}

## Problems

For now it's a bit brittle, since the agent is only able to bind to one interface. If I would swap the network of `server`, so that it initially connects to int and afterwards to global, the setup does not work.

There is an issue open to smoke that out: [#1620](https://github.com/hashicorp/consul/issues/1620), which references to this PR at nomad [#223](https://github.com/hashicorp/nomad/pull/223).

If this is fixed it should be more stable.

## Conclusion

We are getting there, if this is moved over to consul-template, it would be possible to model all external services as consul agents. 

Furthermore address backend nodes (web-server) behind a load-balancer and resolve to the load-balancer in charge. Which would round-robin according to the amount of back-end services.