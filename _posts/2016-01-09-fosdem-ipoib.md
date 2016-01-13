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

## TL;DR

InfiniBand as a backend for Docker Networking seems to be not beneficial (yet), since the overlay driver uses VXLAN, which encapsulates the IP traffic once more (as pointed out [here](http://keepingitclassless.net/2014/03/mtu-considerations-vxlan/)). Thus (IMHO) degenerate the performance as the Kernel is involved within VXLAN and IPoIB encapsulation.

It might happen that my kernel is not the greatest and latest in terms of VXLAN (`3.10.0-327` on CentOS7.2).

At the bottom of the post I discuss what I have tackled in terms of VXLAN performance - without much success. :(

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

## Discussion about VXLAN

I reached out via twitter and was asked to check the raw performance of VXLAN ([slides](http://de.slideshare.net/naotomatsumoto/a-first-look-at-xvlan-over-infiniband-network-on-linux-37rc7)).

![](/pics/2016-01-09/tweet_vxlan.png)

### Kernel Options

The kernel config should be alright:

{% highlight bash %}
[root@venus007 ~]# grep VXLAN /boot/config-3.10.0-327.3.1.el7.x86_64
CONFIG_OPENVSWITCH_VXLAN=m
CONFIG_VXLAN=m
CONFIG_BE2NET_VXLAN=y
CONFIG_I40E_VXLAN=y
CONFIG_FM10K_VXLAN=y
CONFIG_MLX4_EN_VXLAN=y
# CONFIG_QLCNIC_VXLAN is not set
{% endhighlight %}

### Setup IPoIB plus VXLAN

Setup a route for ib0.

{% highlight bash %}
[root@venus007 ~]# ip route add 224.0.0.0/4 dev ib0
[root@venus007 ~]# route -n
Kernel IP routing table
Destination     Gateway         Genmask         Flags Metric Ref    Use Iface
0.0.0.0         192.168.12.101  0.0.0.0         UG    100    0        0 enp4s0f0
10.0.0.0        0.0.0.0         255.255.255.0   U     150    0        0 ib0
172.17.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker0
172.18.0.0      0.0.0.0         255.255.0.0     U     0      0        0 docker_gwbridge
192.168.12.0    0.0.0.0         255.255.255.0   U     100    0        0 enp4s0f0
224.0.0.0       0.0.0.0         240.0.0.0       U     0      0        0 ib0
[root@venus007 ~]#

{% endhighlight %}

Now I mimic what was done in the slides - may the force be with me... :)

{% highlight bash %}
[root@venus007 ~]# ip link add vxlan99 type vxlan id 5001 group 239.0.0.99 ttl 10 dev ib0
vxlan: destination port not specified
Will use Linux kernel default (non-standard value)
Use 'dstport 4789' to get the IANA assigned value
Use 'dstport 0' to get default and quiet this message
[root@venus007 ~]# ip link set up dev ib1
[root@venus007 ~]# ip link add vxlan99 type vxlan id 5001 group 239.0.0.99 ttl 10 dev ib0
vxlan: destination port not specified
Will use Linux kernel default (non-standard value)
Use 'dstport 4789' to get the IANA assigned value
Use 'dstport 0' to get default and quiet this message
RTNETLINK answers: File exists
[root@venus007 ~]# ip addr add 192.168.99.1/24 dev vxlan99
[root@venus007 ~]# ip link set up dev vxlan99
[root@venus007 ~]# iperf -u -s -B 239.0.0.99 &
[1] 25654
[root@venus007 ~]#
{% endhighlight %}

The second node...

{% highlight bash %}
[root@venus008 ~]# ip route add 224.0.0.0/4 dev ib0
[root@venus008 ~]# ip link add vxlan99 type vxlan id 5001 group 239.0.0.99 ttl 10 dev ib0
vxlan: destination port not specified
Will use Linux kernel default (non-standard value)
Use 'dstport 4789' to get the IANA assigned value
Use 'dstport 0' to get default and quiet this message
[root@venus008 ~]# ip addr add 192.168.99.2/24 dev vxlan99
[root@venus008 ~]# ip link set up dev vxlan99
[root@venus008 ~]# ip link show dev vxlan99
172: vxlan99: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1994 qdisc noqueue state UNKNOWN mode DEFAULT
    link/ether c2:0f:ce:de:90:f5 brd ff:ff:ff:ff:ff:ff
[root@venus008 ~]# iperf -u -s -B 239.0.0.99 &
[1] 15476
[root@venus008 ~]# iperf -s
{% endhighlight %}

### Benchmark once more

And benchmark the vxlan.

{% highlight bash %}
[root@venus007 ~]# iperf -c 192.168.99.2 -d
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
------------------------------------------------------------
Client connecting to 192.168.99.2, TCP port 5001
TCP window size: 1.02 MByte (default)
------------------------------------------------------------
[  5] local 192.168.99.1 port 46364 connected with 192.168.99.2 port 5001
[  4] local 192.168.99.1 port 5001 connected with 192.168.99.2 port 33802
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-10.0 sec  2.66 GBytes  2.28 Gbits/sec
[  4]  0.0-10.0 sec  2.13 GBytes  1.83 Gbits/sec
[root@venus007 ~]#
{% endhighlight %}

And the other way around...

{% highlight bash %}
[root@venus008 ~]# iperf -c 192.168.99.1 -d
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
------------------------------------------------------------
Client connecting to 192.168.99.1, TCP port 5001
TCP window size:  790 KByte (default)
------------------------------------------------------------
[  5] local 192.168.99.2 port 33815 connected with 192.168.99.1 port 5001
[  4] local 192.168.99.2 port 5001 connected with 192.168.99.1 port 46377
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-10.0 sec  2.15 GBytes  1.85 Gbits/sec
[  4]  0.0-10.0 sec  2.64 GBytes  2.27 Gbits/sec
[root@venus008 ~]#
{% endhighlight %}

Now I'll wait... 

![](/pics/2016-01-09/tweet_vxlan_re.png)

