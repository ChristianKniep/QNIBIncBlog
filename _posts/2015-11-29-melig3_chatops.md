---
author: Christian Kniep
layout: post
title: "MELIG-3 G: ChatOps mit Rocket.CHat"
date: 2015-11-29
tags: eng docker melig blog chatops
---

In last weeks 3rd M.E.L.I.G. MeetUp I talked about ChatOps, which
consolidates communication channels and helps to provide a more natural
way of communicating in general.

Why we can’t have nice things
-----------------------------

IMHO we are suffering a lot due to the fact that we use a long list of
communication tools, which are mostly not up to the task. Some random
examples I encountered.

-   email madness
    -   Cronjobs send cryptic stderr blobs to a mailing list (ops team),
        which no one cares about, since everyone created a filter after
        the second non-actionable email arrived
    -   Colleagues sent emails stating that they work-from-home, are
        out-of-office or sick to a company wide mailing list.
    -   A PR was created and the team is informed.
    -   The alerting system assumes that ‘web server returned 407’ is
        something that a mailing list can take action upon, even though
        the service is fine now
    -   …
-   Monitoring / Alerting Systems
    -   Yes! I talk to you NAGIOS (and alike)… I was once part of a team
        with thousands of nodes under supervision of NAGIOS. The checks
        were simple in nature like (are all CPUs as we expect them to
        be?, Is the load higher then the core-count?) and such but in
        cases of a major outrage the UI was useless.
    -   Furthermore if a complete rack was to be set in ‘Maintenance
        Mode’ the mouse was set on fire - so we created a little bash
        script that interacted with the FIFO \[sig!\] socket to
        control NAGIOS.
    -   …

I guess you guys get what I want to express. There are way to many
channels open on a day2day bases. Most of them are not actionable, but
only a hind that something has to be researched and you have to know in
advance where to look - otherwise you are screwed.

ChatOps FTW!1!!
---------------

Let me introduce ChatOps, in particular the OpenSource variant of it [RocketChat](http://rocket.chat)

![](/pics/2015-11-29/rocket.chat.png)

If Slack or HipChat comes to mind, you are on the right path, even
though Rocket.Chat is open-source and on-premise (hosting is also
available, I suppose).

It’s not yet v1.0, but it is a functional and it will thrive (I hope
so).

What it provides is (from my point of view):

-   **Channels** No need for endless email threads that might even span
    above multiple threads. With ChatOps you have a channel that you can
    parse and you know what it’s all about.
-   **Formatting** Simple markdown allows to paste code snippets without
    bleeding coming out of you eyes. Each time I have to include code
    into my email I wonder how I should do it. I am tempted to make a
    screenshot of the editors terminal, but I got a blind colleagues -
    this will be rendered useless, so it has to be text.
-   **Bot providing Context** With ChatOps the context is provided by
    interactive bots, which might add performance charts, log entries,
    alerts and alike into the channel (or a subsequent
    channel alongside) and links to drill deeper into the gist which was
    introduce into the channel.
-   **Bot providing Fun** Since we all love cats a bot could also
    provide some fun by uploading a cat into the channel every time
    someone uses bullshit buzzwords. Or just to announce that a new
    deploy was being made.

Hands On
--------

But enough words spends, let’s have a look…

{% highlight bash %}
$ git clone https://github.com/ChristianKniep/orchestra.git
$ cd orchestra/rocketchat/
$ ./up.sh
++ echo tcp://192.168.99.101:2376
++ egrep -o '\d+\.\d+\.\d+\.\d+'
+ RKTHOST=192.168.99.101
+ docker-compose up -d consul mongodb
Creating consul
Creating mongodb
+ sleep 5
++ echo tcp://192.168.99.101:2376
++ egrep -o '\d+\.\d+\.\d+\.\d+'
+ RKTHOST=192.168.99.101
+ docker-compose up -d rocketchat carbon gapi grafana
consul is up-to-date
mongodb is up-to-date
Creating rocketchat
Creating carbon
Creating graphite-api
Creating grafana
+ sleep 30
++ echo tcp://192.168.99.101:2376
++ egrep -o '\d+\.\d+\.\d+\.\d+'
+ RKTHOST=192.168.99.101
+ docker-compose up -d
consul is up-to-date
Creating hubot
mongodb is up-to-date
rocketchat is up-to-date
carbon is up-to-date
graphite-api is up-to-date
grafana is up-to-date
$
{% endhighlight %}

This spins up the complete stack with some delay in between to wait for
other services.

**TODO**: I might change this in the future to now have to wait for it.
If you can not find the `up.sh` script just run `docker-compose up -d`.

After a while the Consul WebUI should be all green.

![](/pics/2015-11-29/consul_green.png)

The bot should log into rocket chat, which could be checked accessing
his logs:

{% highlight bash %}
$ docker logs  hubot
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO Starting Rocketchat adapter...
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO Once connected to rooms I will respond to the name: bot
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO Connecting To: 192.168.99.101:3000
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO Successfully Connected!
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO GENERAL
[Sun Nov 29 2015 11:24:59 GMT+0000 (UTC)] INFO Logging In
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Successfully Logged In
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Joining Room: GENERAL
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Joining Room: GENERAL
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO rid:  [ 'GENERAL' ]
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO all rooms joined
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Successfully joined room: GENERAL
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Preparing Meteor Subscriptions..
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Subscribing to Room: GENERAL
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO all subscriptions ready
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Successfully subscribed to room: GENERAL
[Sun Nov 29 2015 11:25:00 GMT+0000 (UTC)] INFO Setting up reactive message list...
$
{% endhighlight %}

If he is not willing, just kick his tires again…

{% highlight bash %}
$ docker restart hubot
$
{% endhighlight %}

Otherwise please [open a ticket at the
github-repo](https://github.com/ChristianKniep/orchestra/issues/new)

Using Rocket.Chat {#using-rocketchat}
-----------------

Next, please log into Rocket.Chat (`<docker_host>:3000`), the login is
`admin`/`admin`.

![](/pics/2015-11-29/rocket_init.png)

The formatting is close to markdown, it’s shown underneath the text-area
at the bottom.

![](/pics/2015-11-29/rocket_format.png)

#### The bot

The fun part is [Hubot](https://hubot.github.com/), which (or who?)
brings interactivity to the chat.

![](/pics/2015-11-29/bot_help.png)

Fun stuff like reacting on buzzwords…

![](/pics/2015-11-29/bot_shipit.png)

Or translations…

![](/pics/2015-11-29/bot_trans.png)

Show a map…

![](/pics/2015-11-29/bot_map.png)

#### Metrics

The stack silently includes a simple metrics component (`<docker_host>:8080`).

![](/pics/2015-11-29/grafana.png)

This can be used to push metrics charts into the chat window…

![](/pics/2015-11-29/bot_graph.png)

Imaging, I have a dream
-----------------------

The hubot scripts used are only a limited subset of the available once.

-   <https://github.com/github/hubot-scripts>
-   <http://hubot-script-catalog.herokuapp.com/>

And hey are easy `coffee-scripts` anyway…

Furthermore RocketChat has an API to code against.

-   <https://github.com/RocketChat/Rocket.Chat/wiki/REST-APIs>

I see a lot of potential to consolidate most of the communication into
chat-channels and archive them in the legacy places. E.g.

#### Future of Incident Handling?

-   open a ticket in what ever ticketing system on earth
-   open a channel in Rocket.Chat for the open ticket and discuss,
    comment, deal with the ticket. **Provide the evolving context** for
    the ticket in a live discussion, which can be read after the fact
    and understood. :)
-   Once the ticket is closed, archive the channel into the ticketing
    system and delete the channel in Rocket.Chat

What a nice time we are living in… :)

