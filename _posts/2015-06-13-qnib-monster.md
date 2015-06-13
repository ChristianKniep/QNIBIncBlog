---
author: Christian Kniep
layout: post
title: "qnib/monster - all in one box"
date: 2015-06-13
tags: eng logstash blog
---

OK guys, since the [ELK](https://registry.hub.docker.com/u/qnib/elk/) is quite popular on docker-hub, I was wondering if I could push it one notch further. Turns out I could, please welcome qnib/monster...

{% highlight bash %}
git (master) $ git clone https://github.com/ChristianKniep/docker-monster.git
git (master) $ cd docker-monster
docker-monster (master) $ docker-compose up -d
Creating dockermonster_monster_1...
docker-monster (master) $
{% endhighlight %}

This bugger includes a complete stack.<br>
![](/pics/2015-06-13/monster_consul.png)

It includes:

- **Elasticsearch, Logstash, Kibana (ELK)** Workbench to parse, store and visualise logs
- **Carbon + graphite-api + grafana** Framework to store, access and visualise metrics
- **StatsD** Metrics proxy to aggregate and buffer metrics, which do not fit into fire&forget
- **diamond, watchpsutil** tools fetching metrics of the system.

All you have to do is fetch the repository and fire up `docker-compose`, like I did above.
Alternatively you could build the Image locally and tinker around with it, it builds upon my [qnib/logstash(:trunk)](https://registry.hub.docker.com/u/qnib/logstash) image which provides a basic installation of logstash.

I am aware that this is the total opposite of microservices, since I cramp the complete stack in one single container. :)

But - you know - because we can.
