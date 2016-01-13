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

### VXLAN

InfiniBand as a backend for Docker Networking seems to be not beneficial (yet), since the overlay driver uses VXLAN, which encapsulates the IP traffic once more (as pointed out [here](http://keepingitclassless.net/2014/03/mtu-considerations-vxlan/)). Thus (IMHO) degenerate the performance as the Kernel is involved within VXLAN and IPoIB encapsulation.

It might happen that my kernel is not the greatest and latest in terms of VXLAN (`3.10.0-327` on CentOS7.2).

At the bottom of the post I discuss what I have tackled in terms of VXLAN performance - without much success. :(

### MACLAN

A new docker-plugin for libnetwork, for know it does not cope with the IPoIB interface and it's only single host anyway.

### pipework

Plumbing would allow to attach an additional network bridge per container, but that's cheating. :)

### Conclusion

So far, we have to wait for better days - if a cluster wide networking is the goal.

## Idea

As we saw in the baseline benchmark section of the first post, IP Traffic over InfiniBand (IPoIB) is quite fast.

{% highlight bash %}
$ iperf -c 10.0.0.181 -d -t 120
*snip*
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec  88.9 GBytes  6.37 Gbits/sec
[  4]  0.0-120.0 sec  79.6 GBytes  5.69 Gbits/sec
$
{% endhighlight %}


## Attempts

I tried multiple approaches, all of which do have some caveats.

### Good old `pipework`

I could go back to `pipework` created by Jerome back in the days.

{% highlight bash %}
[root@venus007 binaries]# docker run -ti --net=none --name=container7 192.168.12.11:5000/qnib/ib-bench:cos7 bash
[root@780c2c8af385 /]# ip -o -4 addr
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
[root@780c2c8af385 /]#
{% endhighlight %}

Then I attach a network interface...

{% highlight bash %}
[root@venus007 ~]# /scratch/pipework ib0 container7 10.0.0.207/24
[root@venus007 ~]#
{% endhighlight %}

Et voila...  `iperf` showed reasonable performance in combination with the physical host `venus008`.

{% highlight bash %}
[root@780c2c8af385 /]# ip -o -4 addr
1: lo    inet 127.0.0.1/8 scope host lo\       valid_lft forever preferred_lft forever
148: ib0    inet 10.0.0.207/24 brd 10.0.0.255 scope global ib0\       valid_lft forever preferred_lft forever
[root@780c2c8af385 /]# iperf -c 10.0.0.188 -d -t 120
------------------------------------------------------------
Server listening on TCP port 5001
TCP window size: 85.3 KByte (default)
------------------------------------------------------------
------------------------------------------------------------
Client connecting to 10.0.0.188, TCP port 5001
TCP window size: 1.95 MByte (default)
------------------------------------------------------------
[  5] local 10.0.0.207 port 40961 connected with 10.0.0.188 port 5001
[  4] local 10.0.0.207 port 5001 connected with 10.0.0.188 port 34306
[ ID] Interval       Transfer     Bandwidth
[  5]  0.0-120.0 sec   111 GBytes  7.93 Gbits/sec
[  4]  0.0-120.0 sec  77.4 GBytes  5.54 Gbits/sec
{% endhighlight %}

**But**: This is cheating, since it does not use docker networking. I did this kind of stuff month ago in conjunction with `docker-spotter`. What I want is a transparent networking option throughout the docker cluster.

### macvlan-docker-plugin?

There is a docker-plugin out there, which uses macvlan instead of vxlan. It might get around the additional encapsulation, but for know it seems to be single-host only.

![](/pics/2016-01-09/tweet_macvlan.png)

{% highlight bash %}
[root@venus008 ~]# modprobe macvlan
[root@venus008 ~]# lsmod | grep macvlan
macvlan                19233  0
[root@venus008 ~]# git clone https://github.com/gopher-net/macvlan-docker-plugin.git
Cloning into 'macvlan-docker-plugin'...
remote: Counting objects: 331, done.
remote: Total 331 (delta 0), reused 0 (delta 0), pack-reused 331
Receiving objects: 100% (331/331), 8.86 MiB | 2.52 MiB/s, done.
Resolving deltas: 100% (81/81), done.
[root@venus008 ~]# cd macvlan-docker-plugin/binaries/
[root@venus008 binaries]# ./macvlan-docker-plugin-0.2-Linux-x86_64 -d --host-interface=ib0 --mode=bridge
DEBU[0000] The plugin absolute path and handle is [ /run/docker/plugins/macvlan.sock ]
INFO[0000] Plugin configuration options are:
  container subnet: [192.168.1.0/24],
  container gateway: [192.168.1.1],
  host interface: [ib0],
  mmtu: [1500],
  macvlan mode: [bridge]
INFO[0000] Macvlan network driver initialized successfully
{% endhighlight %}

The MTU is fixed but could easily be adjusted in the code. I can even create a network in the address room of the physical network

{% highlight bash %}
[root@venus007 ~]# docker network create -d macvlan --subnet=10.0.0.0/24 --gateway=10.0.0.254 -o host_iface=ib0 ib
00a7164d9d74c62010d62636f2828e5fc9f58c9e57d52e62c5899f5b72fcd852
[root@venus007 ~]# docker network ls
NETWORK ID          NAME                DRIVER
279aa8f2465c        global              overlay
37abdbb380b2        docker_gwbridge     bridge
4903d1516e18        none                null
6342ca80a88a        host                host
00a7164d9d74        ib                  macvlan
0a0b040f1eab        bridge              bridge
[root@venus007 ~]#
{% endhighlight %}

But unfortunately I get an error when attaching to it... :(

{% highlight bash %}
[root@venus007 ~]# docker run -ti --net=ib 192.168.12.11:5000/qnib/ib-bench:cos7 bash
Error response from daemon: Cannot start container 248ce6ef138dde20ecadde2424cc010433432ff68a728b7fbff3e4ae4376bd02: EOF
[root@venus007 ~]#
{% endhighlight %}

The plugin daemon throws:

{% highlight bash %}
DEBU[0148] The container subnet for this context is [ 10.0.0.1/24 ]
INFO[0148] Allocated container IP: [ 10.0.0.1/24 ]
DEBU[0148] Create endpoint response: &{Interface:{Address: AddressIPv6: MacAddress:7a:42:00:00:00:00}}
DEBU[0148] Create endpoint fe070f3c229f549376c7a3c8eaf3d5347ba811a1a850f686b223fbe41f8ce8c3 &{Interface:{Address: AddressIPv6: MacAddress:7a:42:00:00:00:00}}
DEBU[0148] Join request: NetworkID:00a7164d9d74c62010d62636f2828e5fc9f58c9e57d52e62c5899f5b72fcd852 EndpointID:fe070f3c229f549376c7a3c8eaf3d5347ba811a1a850f686b223fbe41f8ce8c3 SandboxKey:/var/run/docker/netns/604808cb6bb6 Options:map[]
ERRO[0148] failed to create Macvlan: [ 0 0 0 fe070  0 25 0 <nil>} ] with the error: invalid argument
ERRO[0148] Ensure there are no existing [ ipvlan ] type links and remove with 'ip link del <link_name>', also check /var/run/docker/netns/ for orphaned links to unmount and delete, then restart the plugin
DEBU[0148] Delete endpoint request: NetworkID:00a7164d9d74c62010d62636f2828e5fc9f58c9e57d52e62c5899f5b72fcd852 EndpointID:fe070f3c229f549376c7a3c8eaf3d5347ba811a1a850f686b223fbe41f8ce8c3
DEBU[0148] Delete endpoint fe070f3c229f549376c7a3c8eaf3d5347ba811a1a850f686b223fbe41f8ce8c3
DEBU[0148] The requested interface to delete [ fe070 ] was not found on the host: route ip+net: no such network interface
ERRO[0148] The requested interface to delete [ fe070 ] was not found on the host.
{% endhighlight %}


### VXLAN (my first approach actually)

And as we also learned last time around, the advertised interface of Docker Networking has to be specified within the docker config
(DISCLAIMER: That might not be exactly right - not sure about it [yet]).

{% highlight bash %}
[root@venus001 jobs]# cat /etc/sysconfig/docker
OPTIONS="-H tcp://0.0.0.0:2376 --cluster-store=consul://127.0.0.1:8500/network --cluster-advertise=enp4s0f0:2376"
[root@venus001 jobs]#
{% endhighlight %}

#### IPoIB as backend network

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

### Discussion about VXLAN

I reached out via twitter and was asked to check the raw performance of VXLAN ([slides](http://de.slideshare.net/naotomatsumoto/a-first-look-at-xvlan-over-infiniband-network-on-linux-37rc7)).

![](/pics/2016-01-09/tweet_vxlan.png)

#### Kernel Options

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

#### Setup IPoIB plus VXLAN

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

#### Benchmark once more

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

Then I reached out again...

![](/pics/2016-01-09/tweet_vxlan_re.png)

