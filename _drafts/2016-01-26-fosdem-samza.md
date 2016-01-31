---
author: Christian Kniep
layout: post
title: "FOSDEM #3: Samza for the masses"
date: 2016-01-30
tags: eng docker blog consul samza
---

Samza is a distributed streaming processor that uses Kafka as a communication channel.

As I am fond of the idea to squeeze all logs through the big Kafka pipe, it's worth a shot to look at Saamza. Why Kafka for that purpose? It's a big distributed log which can be replayed and trusted.
So if I want to replay a particular hour of logs over and over again to optimise a particular part of my log-pipeline I can do so easily with Kafka. But that's a complete post on its own. :)

## The Stack

This Samza stack comprises of Consul as foundation (as always), a Zookeeper cluster, a Kafka cluster on top, WebUI for Zookeeper and Kafka and at least one Samza container.

![](/pics/2016-01-30/nat.png)


{% highlight bash %}
$ docker-compose pull consul1 zk1 zkui kafka1 kafka-manager kafka-monitor samza1
Pulling kafka-monitor (qnib/kafka-monitor:latest)...
venus008: Pulling qnib/kafka-monitor:latest...
*snip*
venus005: Pulling 192.168.12.11:5000/qnib/kafka:latest... : downloaded
$
{% endhighlight %}

{% highlight bash %}
$ docker-compose up -d consul{1,2,8}
Creating consul2
Creating consul1
Creating consul8
$
{% endhighlight %}

{% highlight bash %}
$ docker-compose up -d zk{1..4} zkui
Creating zkui
Creating zk1
Creating zk4
Creating zk2
Creating zk3
$
{% endhighlight %}

{% highlight bash %}
$ docker-compose up -d kafka{1,2,4} kafka-manager
Creating kafka4
Creating kafka-manager
Creating kafka1
Creating kafka2
$ docker-compose ps
    Name                   Command               State               Ports
---------------------------------------------------------------------------------------
consul1         /opt/qnib/bin/start_superv ...   Up      192.168.12.181:28501->8500/tcp
consul2         /opt/qnib/bin/start_superv ...   Up      192.168.12.182:28502->8500/tcp
consul8         /opt/qnib/bin/start_superv ...   Up      192.168.12.188:28508->8500/tcp
kafka-manager   /opt/qnib/supervisor/bin/s ...   Up      192.168.12.188:9000->9000/tcp
kafka1          /opt/qnib/bin/start_superv ...   Up
kafka2          /opt/qnib/bin/start_superv ...   Up
kafka4          /opt/qnib/bin/start_superv ...   Up
zk1             /opt/qnib/bin/start_superv ...   Up
zk2             /opt/qnib/bin/start_superv ...   Up
zk3             /opt/qnib/bin/start_superv ...   Up
zk4             /opt/qnib/bin/start_superv ...   Up
zkui            /opt/qnib/bin/start_superv ...   Up      192.168.12.188:9090->9090/tcp
{% endhighlight %}


{% highlight bash %}
$ docker-compose up -d samza1
Creating samza1
$ docker exec -ti samza1 ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file:///opt/hello-samza/deploy/samza/config/wikipedia-feed.properties
*snip*
2016-01-30 21:56:12 YarnClientImpl [INFO] Submitted application application_1454190943122_0001
2016-01-30 21:56:12 JobRunner [INFO] waiting for job to start
2016-01-30 21:56:12 JobRunner [INFO] job started successfully - Running
2016-01-30 21:56:12 JobRunner [INFO] exiting
$
{% endhighlight %}

{% highlight bash %}
$ docker-compose up -d samza3
Creating samza3
$ docker exec -ti samza3 ./deploy/samza/bin/run-job.sh --config-factory=org.apache.samza.config.factories.PropertiesConfigFactory --config-path=file:///opt/hello-samza/deploy/samza/config/wikipedia-parser.properties
java version "1.7.0_91"
*snip*
2016-01-30 21:58:06 YarnClientImpl [INFO] Submitted application application_1454191067681_0001
2016-01-30 21:58:06 JobRunner [INFO] waiting for job to start
2016-01-30 21:58:06 JobRunner [INFO] job started successfully - Running
2016-01-30 21:58:06 JobRunner [INFO] exiting
$ 
{% endhighlight %}


{% highlight bash %}
$ docker ps
NAMES                    IMAGE                                   COMMAND                  PORTS
venus003/samza3          192.168.12.11:5000/qnib/u-samza         "/opt/qnib/supervisor"   192.168.12.183:32769->8042/tcp, 192.168.12.183:32768->8088/tcp
venus001/samza1          192.168.12.11:5000/qnib/u-samza         "/opt/qnib/supervisor"   192.168.12.181:8042->8042/tcp, 192.168.12.181:8088->8088/tcp
venus001/kafka1          192.168.12.11:5000/qnib/kafka           "/opt/qnib/bin/start_"
venus002/kafka2          192.168.12.11:5000/qnib/kafka           "/opt/qnib/bin/start_"
venus008/kafka-manager   192.168.12.11:5000/qnib/kafka-manager   "/opt/qnib/supervisor"   192.168.12.188:9000->9000/tcp
venus004/kafka4          192.168.12.11:5000/qnib/kafka           "/opt/qnib/bin/start_"
venus003/zk3             192.168.12.11:5000/qnib/zookeeper       "/opt/qnib/bin/start_"
venus001/zk1             192.168.12.11:5000/qnib/zookeeper       "/opt/qnib/bin/start_"
venus002/zk2             192.168.12.11:5000/qnib/zookeeper       "/opt/qnib/bin/start_"
venus004/zk4             192.168.12.11:5000/qnib/zookeeper       "/opt/qnib/bin/start_"
venus008/zkui            192.168.12.11:5000/qnib/zkui            "/opt/qnib/bin/start_"   192.168.12.188:9090->9090/tcp
venus001/consul1         192.168.12.11:5000/qnib/consul          "/opt/qnib/bin/start_"   192.168.12.181:28501->8500/tcp
venus008/consul8         192.168.12.11:5000/qnib/consul          "/opt/qnib/bin/start_"   192.168.12.188:28508->8500/tcp
venus002/consul2         192.168.12.11:5000/qnib/consul          "/opt/qnib/bin/start_"   192.168.12.182:28502->8500/tcp
venus002/u2              ubuntu                                  "bash"
venus001/hpcg1           192.168.12.11:5000/qnib/ib-bench:cos7   "/opt/qnib/bin/start_"
venus001/consul          qnib/consul                             "/opt/qnib/bin/start_"   192.168.12.181:18500->8500/tcp
docker1/registry         registry:2                              "/bin/registry /etc/d"   192.168.12.11:5000->5000/tcp
$ 
{% endhighlight %}