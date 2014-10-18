---
layout: post
title:  "Quick Build of QNIBTerminal"
date:   2014-06-09
categories: qnibterminal
tags: blog eng cluster docker isc
description: How to fetch, build and run the docker containers of QNIBTerminal
---

[Last time][last_post] I gave a walkthrough to the docker cluster.
This time around I would like to enable more people to bootstrap it.

So I polished the bashrc functions to fetch and build the neccessary git-repositories.
The next post should use [Python Fabric][py_fab] to spin it up.


Install
=================

First thing to run QNIBTerminal is to setup the docker host. As I use Fedora20 as my
workhorse I just install the packages needed.

{% highlight bash %}
yum install -y lxc docker-io
{% endhighlight %}


Systemd
================

To make the docker server accessible from remote systems (like my MacBook Pro) I offer
the socket 6000 to everyone. This might be considered stupid depending on your environment.

The other options I choose are

- a different location for the docker directory (-g)
- using lxc instead of directly talking to the Kernel (-e)
- choosing googles DNS, due to the poor quality of orangeFRs DNS (--dns)
- not restart containers after the service is restarted (--restart)

{% highlight bash %}
$ cat /usr/lib/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=http://docs.docker.io
After=network.target

[Service]
ExecStart=/usr/bin/docker -d -H tcp://0.0.0.0:6000 -e lxc -g /data/docker/ --dns 8.8.8.8 --restart=false
Restart=on-failure
LimitNOFILE=1048576
LimitNPROC=1048576

[Install]
WantedBy=multi-user.target
{% endhighlight %}

Last but not least the service has to be enabled and started. I disable firewalld, because I want to
connect remotely.

{% highlight bash %}
$ systemctl enable docker
$ systemctl start docker
$ systemctl disable firewalld
$ systemctl stop firewalld
{% endhighlight %}


bashrc
=============

The QNIBTerminal repository hold a bashrc-file that provides a couple of functions for
all the lazy admins out their.

{% highlight bash %}
$ source ~/Daten/QNIBTerminal/bashrc
{% endhighlight %}


Clone Repositories
===================

First lets clone all repositories holding the Dockerfiles.

{% highlight bash %}
$ mkdir docker_dir; cd docker_dir
$ dgit_clone
Where to put the git-directories? [.]
########## docker-fd20
Cloning into 'docker-fd20'...
remote: Reusing existing pack: 13, done.
remote: Total 13 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (13/13), done.
Checking connectivity... done.
########## docker-supervisor
*snip*
########## docker-carbon
Cloning into 'docker-carbon'...
remote: Reusing existing pack: 42, done.
remote: Total 42 (delta 0), reused 0 (delta 0)
Unpacking objects: 100% (42/42), done.
Checking connectivity... done.
$
{% endhighlight %}


Build
------------

The next step is to build all images on the docker-host. For this the DOCKER_HOST variable
has to be setup correct (if on a remote client, otherwise it's not needed).

Let us make sure that I am not cheating by having pre-build images.

{% highlight bash %}
$ docker images -a
REPOSITORY          TAG                 IMAGE ID            CREATED             VIRTUAL SIZE
$ docker ps -a
CONTAINER ID        IMAGE               COMMAND             CREATED             STATUS              NAMES
{% endhighlight %}

And here we go, this takes some time (including downloading the fedora base image);
make sure the coffee is ready.

{% highlight bash %}
$ time dgit_build
Where arethe git-directories? [.]
########## build> docker/fd20
Uploading context 67.58 kB
Uploading context
Step 0 : FROM fedora
Pulling repository fedora
64fd7993bcaf: Download complete
3f2fed40e4b0: Download complete
511136ea3c5a: Download complete
fd241224e9cf: Download complete
 ---> 3f2fed40e4b0
Step 1 : MAINTAINER "Christian Kniep <christian@qnib.org>"
 ---> Running in 7ba085a2c184
 ---> d61a368e84ba
 *snip*
removing intermediate container c5e520fb4296
Successfully built 57c0329e462c

real	48m21.247s
user	0m1.540s
sys	0m6.505s
{% endhighlight %}

Here we go, all images are build. The ordering is not correct, this is the result of
one day debugging. :)

{% highlight bash %}
$ docker images|grep -v none
REPOSITORY          TAG                 IMAGE ID            CREATED              VIRTUAL SIZE
qnib/compute        latest              96f67484c6aa        About an hour ago    1.475 GB
qnib/slurm          latest              9ce757745aa1        About an hour ago    1.398 GB
qnib/terminal       latest              2cc67bc797f4        About an hour ago    1.112 GB
qnib/slurmctld      latest              e3f3c8690ee4        About an hour ago    1.398 GB
qnib/grafana        latest              7563da873e70        4 hours ago          1.143 GB
qnib/haproxy        latest              969b553f15ba        4 hours ago          845.8 MB
qnib/elk            latest              1d02459b67a9        4 hours ago          1.451 GB
qnib/carbon         latest              f223fde0c93d        6 hours ago          1.405 GB
qnib/graphite-api   latest              bc3cf444e7ed        6 hours ago          1.177 GB
qnib/graphite-web   latest              4419b9804c4a        6 hours ago          1.41 GB
qnib/helixdns       latest              364db1472dcf        8 hours ago          983.3 MB
qnib/etcd           latest              bcb0eb9bcb89        8 hours ago          865.3 MB
qnib/supervisor     latest              48e4e77642d2        8 hours ago          831.5 MB
qnib/fd20           latest              ceefcfc92bb5        8 hours ago          620.8 MB
fedora              20                  3f2fed40e4b0        4 days ago           372.7 MB
fedora              heisenbug           3f2fed40e4b0        4 days ago           372.7 MB
fedora              latest              3f2fed40e4b0        4 days ago           372.7 MB
fedora              rawhide             64fd7993bcaf        4 days ago           366.8 MB
{% endhighlight %}

[last_post]: http://blog.qnib.org/qnibterminal/eng/cluster/docker/osdc/isc/2014/05/02/setup-qnibterminal.html
[py_fab]: http://www.fabfile.org/
