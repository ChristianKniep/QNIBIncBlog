---
author: Christian Kniep
layout: post
title: "Hello World of qcollect"
date: 2016-09-13
tags: eng docker blog
---

A while back I stumbled upon [Fullerite](https://github.com/Yelp/fullerite), a GOLANG metrics collector, which can reuses the collectors of the python Diamond collector.

One of the [issues](https://github.com/Yelp/fullerite/issues/205) I had was, that it is not using the event time, but the process time of collected metrics.
Thus, if you want to bulk update collected metrics, they will all have the same timestamp of the time they are push to the metrics backend.

So I forked the project and in the recent weeks renamed my fork to [qcollector](https://github.com/qnib/qcollect).

Furthermore I created a docker-stats collector that uses the latest docker libraries to collect metrics from docker 1.12.

A hello-world you ask? Off we go...

## Hello World from [docker-qcollect](https://github.com/qnib/docker-qcollect)

I am using DockerForMac, which exposes the docker socket on `/var/run/docker.sock`. 
Currently `qcollect` uses the Docker environment variables; in the next iteration this should be configured in a more convenient way.

{% highlight bash %}
➜  temp git clone https://github.com/qnib/docker-qcollect.git
Cloning into 'docker-qcollect'...
remote: Counting objects: 108, done.
remote: Compressing objects: 100% (26/26), done.
remote: Total 108 (delta 7), reused 0 (delta 0), pack-reused 78
Receiving objects: 100% (108/108), 163.91 KiB | 0 bytes/s, done.
Resolving deltas: 100% (25/25), done.
Checking connectivity... done.
➜  temp cd docker-qcollect
➜  docker-qcollect git:(master) docker-compose up -d
Creating consul
Creating influxdb
Creating qcollect
Creating grafana3
➜  docker-qcollect git:(master) 
{% endhighlight %}

After a couple of seconds you can get the metrics by pointing to [localhost:3000](http://localhost:3000/dashboard/db/dockerstats-dash)

![](/pics/2016-09-13/grafana3.png)

The influxdb backend shows the measurements taken.

![](/pics/2016-09-13/influxdb.png)

Just as a sneak peak - looking forward to refine this project and add more and more collectors/handlers and other features. 