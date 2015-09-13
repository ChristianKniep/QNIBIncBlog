---
author: Christian Kniep
layout: post
title: "Kafka mini Jepsen via heka"
date: 2015-09-14
tags: eng heka kafka blog
---

Guys, it's been a while.... Sorry for the delay, but I am quite busy these days.

But nonetheless I got a nice one today. Stressing [Kafka](http://kafka.apache.org/) using [Heka](https://hekad.readthedocs.org/en/latest/).

## Kafka? Heka? What are you talking about?!

### Kafka

Kafka is a distributed logfile. That's it. You can send messages to a topic (the equivalent of a file) and get the messages back in order. 

The inner workings are along the line, that multiple kaka-instances (called `brokers`) form a cluster.

Each topic elects a `leader` broker, which is in charge of appending the messages to the 
``topic``. It one broker is not enough to handle the load, the topic can be split into multiple ``partitions`, which share the burden.
To allow a fast response to `leader` failure, each partition has one or more `replicas`, which are provided with the latest updates by the `leader` and if he fails they are able to take over.
All of this is backed by zookeeper and seems to work quite nice. 

### Heka

Heka is kind of Logstash on speed (plus X). It is written in GO and developed under the roof of Mozilla .
Heka provides plugins like Logstash (Input, Filter, Output) plus the ability to hack stuff in lua.
I just tipped my toe into it, but I like it! No JVM running inside my supposedly small docker containers. The rich set of functions provided by Logstash is not match by far, but we might get there some day.

### Jepsen

But what is this blog post all about? Anyone not familiar with [Jepsen](https://github.com/aphyr/jepsen)?
It's a project of Kyle Kingsbury, which explores the limitations of databases when it comes to network partitions. Do they fall apart, loose data and so on. He is loved and feared for that, I assume. So far he looked at: MongoDB, Zookeeper, Elasticsearch, etcd/consul, ...
His [Blog](https://aphyr.com/tags/jepsen) provides articles about all of them.

## My little ride

I wanted to toy around with Kafka to get a better understanding.

![](/pics/2015-09-14/monster_consul.png)

