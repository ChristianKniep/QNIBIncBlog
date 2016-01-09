---
author: Christian Kniep
layout: post
title: "FOSDEM #2 - IPoIB"
date: 2016-01-09 15:20
tags: eng docker blog fosdem
---

## Related Post

This post is one out of a series of blog post in the advent of [FOSDEM 2016](https://fosdem.org/2016/schedule/event/hpc_bigdata_hpc_cluster/) and the [HPC Advisory Council Workshop](http://www.hpcadvisorycouncil.com/events/2016/stanford-workshop/agenda.php) in Stanford, were I am going to talk about Docker Networking on HPC (BigData) systems. 

<ul class="posts">
{% for post in site.posts %}
  {% if post.tags contains 'fosdem' %}
      <div class="post_info">
        <li>
          <a href="{{ post.url }}">{{ post.title }}</a>
          <span>({{ post.date | date:"%Y-%m-%d" }})</span>
        </li>
      </div>
  {% endif %}
{% endfor %}
</ul>

## DISCLAIMER: Understanding-In-Progress

As I wrote at the end, the network should be much faster...
If I figure out what's wrong, I will add a 'Second Strike'. :)

## IPoIB - First strike!

As we saw in the baseline benchmark section of the first post, IP Traffic over InfiniBand (IPoIB) is quite fast.

{% highlight bash %}
$ iperf -c 10.0.0.181 -d -t 120
*snip*
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  88.9 GBytes  6.37 Gbits/sec
[  4]  0.0-120.0 sec  79.6 GBytes  5.69 Gbits/sec
$
{% endhighlight %}

And as we also learned last time around, the advertised interface of Docker Networking has to be specified within the docker config
(DISCLAIMER: That might not be exactly right - not sure about it [yet]).

{% highlight bash %}
[root@venus001 jobs]# cat /etc/sysconfig/docker
OPTIONS="-H tcp://0.0.0.0:2376 --cluster-store=consul://127.0.0.1:8500/network --cluster-advertise=enp4s0f0:2376"
[root@venus001 jobs]#
{% endhighlight %}

### IPoIB as backend network

So how about we use the `ib0` device?

{% highlight bash %}
[root@venus001 ~]# cat /etc/sysconfig/docker
OPTIONS="-H tcp://0.0.0.0:2376 --cluster-store=consul://127.0.0.1:8500/network --cluster-advertise=ib0:2376"
[root@venus001 ~]#
[root@venus001 ~]# docker network create -d overlay global
28cee319f57a91c95df243e8db62a5fac4dca1a19018084d1779bdff06c2a8c0
[root@venus001 ~]# docker network ls
NETWORK ID          NAME                DRIVER
28cee319f57a        global              overlay
e336375aefc4        bridge              bridge
eebd62fe7775        none                null
dfafdf923699        host                host
07342005436a        docker_gwbridge     bridge
[root@venus001 ~]#
{% endhighlight %}

Let's run a quick iperf.

{% highlight bash %}
[root@hpcg1 /]# iperf -c hpcg3 -d -t 120
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
------------------------------------------------------------
Client connecting to hpcg3, TCP port 5001
TCP window size:  423 KByte (default)
------------------------------------------------------------
[  5] local 10.0.0.2 port 35176 connected with 10.0.0.3 port 5001
[  4] local 10.0.0.2 port 5001 connected with 10.0.0.3 port 58516
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  13.5 GBytes   969 Mbits/sec
[  4]  0.0-120.0 sec  13.7 GBytes   983 Mbits/sec
{% endhighlight %}

Hmm, I would have expected we do better, even though the InfiniBand interface was used indeed (Remember, the IB traffic on top is not scaled correctly, I have to correct the measurement).

![](/pics/2016-01-09/ipoib_iperf.png)

#### Back to ETH

OK, it's a bit faster though... 

{% highlight bash %}
[root@hpcg1 /]# iperf -c hpcg3 -d -t 120
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
------------------------------------------------------------
Client connecting to hpcg3, TCP port 5001
TCP window size: 99.0 KByte (default)
------------------------------------------------------------
[  5] local 10.0.0.2 port 44864 connected with 10.0.0.4 port 5001
[  4] local 10.0.0.2 port 5001 connected with 10.0.0.4 port 51545
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  8.73 GBytes   625 Mbits/sec
[  4]  0.0-120.0 sec  10.4 GBytes   747 Mbits/sec
[root@hpcg1 /]#
{% endhighlight %}

### Latency

The latency with IPoIB:

{% highlight bash %}
[root@hpcg1 /]# ping -c5 hpcg3
PING hpcg3 (10.0.0.3) 56(84) bytes of data.
64 bytes from hpcg3 (10.0.0.3): icmp_seq=1 ttl=64 time=0.190 ms
64 bytes from hpcg3 (10.0.0.3): icmp_seq=2 ttl=64 time=0.250 ms
64 bytes from hpcg3 (10.0.0.3): icmp_seq=3 ttl=64 time=0.083 ms
64 bytes from hpcg3 (10.0.0.3): icmp_seq=4 ttl=64 time=0.088 ms
64 bytes from hpcg3 (10.0.0.3): icmp_seq=5 ttl=64 time=0.122 ms

--- hpcg3 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 3999ms
rtt min/avg/max/mdev = 0.083/0.146/0.250/0.065 ms
[root@hpcg1 /]#
{% endhighlight %}

When I go back to the ethernet device:

{% highlight bash %}
[root@hpcg1 /]#  ping -c5 hpcg3
PING hpcg3 (10.0.0.4) 56(84) bytes of data.
64 bytes from hpcg3 (10.0.0.4): icmp_seq=1 ttl=64 time=0.348 ms
64 bytes from hpcg3 (10.0.0.4): icmp_seq=2 ttl=64 time=0.240 ms
64 bytes from hpcg3 (10.0.0.4): icmp_seq=3 ttl=64 time=0.204 ms
64 bytes from hpcg3 (10.0.0.4): icmp_seq=4 ttl=64 time=0.311 ms
64 bytes from hpcg3 (10.0.0.4): icmp_seq=5 ttl=64 time=0.224 ms

--- hpcg3 ping statistics ---
5 packets transmitted, 5 received, 0% packet loss, time 3999ms
rtt min/avg/max/mdev = 0.204/0.265/0.348/0.056 ms
[root@hpcg1 /]#
{% endhighlight %}

Lower ping, but as said... I would have expected more. :(

## Conclusion

Even though the traffic uses the IPoIB interface it should be much faster. I'll sleep over it and ask around, why it's only at ethernet speed. Maybe there is a hand break that limits the traffic... To be continued...