---
author: Christian Kniep
layout: post
title: "Hello Sensu"
date: 2015-12-31
tags: eng docker blog sensu
---

Even though I like [Consul](http://consul.io) a lot (it is the foundation of my stacks in terms of service/node discovery) it's most likely not a replacement for a monitoring framework with notification handlers, distributed checks and a nice dashboard.

I assume that most of the readers have used NAGIOS at some point and decide to hate-love it. It works, but only kinda... :)

One customer I worked for had a NAGIOS installation making sanity checks on a couple of thousand servers. Worked quite nicely, but only if the checks were issued once a day and were mostly OK.

What I want for my stacks is something that is simple and self-service. One nice thing of Consul + Docker to me is that I can drop a JSON file into `/etc/consul.d/`, which describes a new service and after `consul reload` the service is discoverable. That simple!

I would love this for the monitoring solution as well...

## Hello Sensu

It seems to me that [Sensu](https://sensuapp.org/) could be such a tool. 

### Simple

The architecture is quite easy. We got:

- **Clients**: They push (check) results (JSON blobs) in a RabbitMQ queue. The checks can be triggered via pub/sub out of RabbitMQ or - the dead-simple version - the checks are triggered by an interval on the client itself (standalone-checks).
- **Server**: The server fetches the results from RabbitMQ, evaluates what is going on and keeps a state in Redis. If checks are scheduled as pub/sub checks, the server sends out the trigger (as shown on the animated gif).
- **API**: The last part is an API daemon that fetches the state and provides a RESTful interface to serve the information. 

![](/pics/2015-12-31/sensu-diagram.gif)

As an WebUI I used the default [Uchiwa](https://uchiwa.io/#/).


![](/pics/2015-12-31/uchiwa.png)

### Spin 'em up!

Enough of the talking, let's spin it up. As usual I created a stack...

{% highlight bash %}
$ git clone https://github.com/ChristianKniep/orchestra.git
Cloning into 'orchestra'...
remote: Counting objects: 1249, done.
remote: Compressing objects: 100% (27/27), done.
remote: Total 1249 (delta 6), reused 0 (delta 0), pack-reused 1220
Receiving objects: 100% (1249/1249), 10.34 MiB | 660.00 KiB/s, done.
Resolving deltas: 100% (506/506), done.
Checking connectivity... done.
$ cd orchestra/hello-sensu/
$ docker-compose up -d
Creating consul
Creating uchiwa
Creating sensu
Creating redis
Creating rabbitmq
Creating redis-commander
$
{% endhighlight %}

This stack provides everything we need. After a bit, consul (`<docker_host>:8500`) should glow in pastel green.

![](/pics/2015-12-31/sensu_consul.png)

### What to expect...?

I kept the config pretty simple. All JSON blobs underneath `/etc/sensu/` are merged into one big blob by Sensu. To keep them separated helps organising it.

#### Global Config

The global configuration provides information about the different pieces (RabbitMQ, Redis, and the API).
Furthermore I put a check in there, which is triggered via RabbitMQ to clients subscribed to `test`.

{% highlight bash %}
[root@sensu /]# cat /etc/sensu/config.json
{
  "rabbitmq": {
    "host": "rabbitmq.service.consul",
    "vhost": "/sensu",
    "user": "sensu",
    "password": "pass"
  },
  "redis": {
    "host": "redis.service.consul"
  },
  "api": {
    "host": "sensu-api.service.consul",
    "port": 4567
  },
  "checks": {
    "test": {
      "command": "echo -n OK - subscribed by all hosts within 'test'",
      "subscribers": [
        "test"
      ],
      "interval": 60
    }
  }
}
[root@sensu /]#
{% endhighlight %}

#### Client Config

The client is called `sensu`, the address should be written by `consul-tempalte` in an interaction to come (to get the actual IP). 
This client subscribes to `test`, therefore he will react on the trigger above.

{% highlight bash %}
[root@sensu /]# cat /etc/sensu/conf.d/client.json
{
  "client": {
    "name": "sensu",
    "address": "127.0.0.1",
    "subscriptions": [
      "test"
    ]
  }
}
[root@sensu /]#
{% endhighlight %}

#### Standalone Check

To me it seems that the standalone checks are a diamond in terms of Containers, since dropping a check file into a directory creates a check for the container.

{% highlight bash %}
[root@sensu /]# cat /etc/sensu/conf.d/standalone_check.json
{
  "checks": {
    "standalone-check": {
      "command": "echo -n OK - is triggered on the client and pushes to RabbitMQ",
      "standalone": true,
      "interval": 60
    }
  }
}
[root@sensu /]#
{% endhighlight %}

This check triggers every 60 seconds.

### WebUI

By visiting the WebUI (`<docker_host>:3000/#/client/Default/sensu`) all checks are visible.

![](/pics/2015-12-31/uchiwa_client.png)

### Consul Checks vs. Sensu

What I haven't settled on is how to balance Consul and Sensu when both are used. I rather would like to have only one source of truth for checks.
It should bot happen, that Sensu states a service is *OK*, while Consul determines the service is  *WARN*.

As a starting point I might configure Consul to query Sensu. On the other hand if the API is not available I am screwed... Hmm... Or maybe use the same check-scripts for the same service. That way they will conclude on a state. We'll see... :)

### Register/Deregister

New clients are popping up automatically, since they push test through RabbitMQ. 

The deregistration might be done by hooking into the Docker event stream (like registrator is doing it) and act on the event `Container XYZ stopped`.
Maybe with a small wrapper that checks if the container was meant to be stopped or just crashed. For starters I might just deregister it. The clients of a service should report, when a service they rely on are not present. But again - we'll see...

### First Verdict: Promising

And that's just the beginning... I will incorporate that into QNIBTerminal and figure out how good of a fit it is.

At first glance it looks very promising. 

Guten Rutsch! (nice slide into the next year, German phrase)<br>
Christian
