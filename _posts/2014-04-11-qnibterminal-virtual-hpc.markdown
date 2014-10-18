---
layout: post
title:  "OSDC2014 my way to QNIBTerminal - Virtual HPC"
date:   2014-04-11 10:27:36
categories: qnibterminal 
tags: qnibterminal eng cluster docker osdc blog
---

On my way home (at least to an intermediate stop at my mothers) from the
[OSDC2014][osdc] I guess it's time to recap the last couple of weeks.

I gave a talk which title reads ['Understand your data-center by overlaying multiple information layers'][my_talk].
The pain-point I had in mind when I submitted the talk was my SysOps days debugging an InfiniBand problem that was connected to
other layers of the stack we were dealing with. After being frustrated about it I choose to use my BSc-thesis to tackle this problem.
The outcome was a not-scaling OpenSM plug-in to monitor InfiniBand. :)
But the basics were not as bad, so I revisited the topic with some state-of-the-art log management (logstash) and
performance measurement (graphite) experience I gained over the last couple of month.
Et voila, it scales better... 

I can spin up a simulated fabric (last time I checked I could not find a real cluster in my basement) with a reasonable amount of hosts and let the metrics flow into graphite.
Unplugging a node and replugging it shows nicely up in the WebUI.

![IB metrics and events](/pics/graphite_chart_node4.png "Graph showing IB metrics and overlayed events")

# Now you got 1/1000 of the stack...

After the first satisfaction flushed out of my bloodstream I realized that I now have possible solution for one part of the puzzle.
And the puzzle is not a small one. Apart from the interconnect there are a bunch of other layers that I do not cover.

![Cluster layers](/pics/cluster_layers.png "Cluster layers ([picture part of my talk at OSDC2014][my_talk])")

If one looks carefully the 'IB counters' could be found at the bottom on the right hand side.
And this layer description is not even complete. It's a brain dump summarization I came up with. If
you ask three SysOps you will get four answers, if you include DevOps and management personnel you will get forty.

Not to mention that everyone who is working on/with the system has it's own methodologies and points of view.
And that is totally fine with me, I strongly believe that you need as many different mindsets to handle complex systems.

![Cluster layers and points of view](/pics/cluster_layers_views.png "Cluster layers and points of view([picture part of my talk at OSDC2014][my_talk])")

OK, good to know, but how to mock-up the rest of the stack if you only have an InfiniBand mock-up so far?

# Virtualization

I thought that spinning up a virtual machine providing basic functions like some kind of inventory (+DNS) and a Job Scheduler might worth a shot.
If I could then add a couple of virtual compute nodes mocking up scenarios where they behave like real-job-running nodes, I would be not that far away from
introducing other layers.

Problem is that with the classical approach of virtualization one is doomed, because you allocate all the resources even if they the compute
nodes are idling most of the time. If some of them are busy it is hard for them to distribute the load in a fair manner.
Granted, that one could write a small daemon that would monitor the load of the machines and change the resource allocations reactively;
but my watch (iPad, Macbook and the others) is telling me it's 2014.

# Hello Docker!
And then it strucked me. I was searching for a reason to give docker a spin quite some time and this has to be the project to do so.
Turns out it is...

Docker leverages the LXC capabilities within Linux to spawn processes and encapsulate them. If you think of BSD zones you are not far away.
To jump-start your understanding: the process spawned is imprisoned in his own 'Process Namespace'. You tell the container to start up with '''/bin/bash'''
and a '''ps -ef''' will show you the following:

![simple bash spawned within container](/pics/simple_bash_ps.png "Simple bash spawned within container")

'''/bin/bash''' got the PID 1 and ps is the only child. Seems very sad for them, right? No friends to talk to and everyone can blame them if
something goes wrong. But wait, that's pretty cool. Isn't 'Spliting of concerns' one of the top bullshit-bingo words you hear (even if they could be used in the right context, not only in bullshit-bingo meetings).

So one could spin up a 'compute-node as a process'. And since he has it's own '/proc' file-system and network device it feels and behaves pretty much like a real node.
One can send metrics that are leveraging the /proc file-system (which are... most of the system metrics tools... kind of [read hopefully]).

Not to mention that one could use cgroups to strangle the nodes performance on a lot of nob's. The node should only be able to write 1KB/s through the network interface?
No problem, cgroups is your friend.

As I see it after three weeks, docker provides 'chroot on steroids'. One spawns a process that could use a completely different user-land than the system it is hosted on
and this process could be strangled and massaged in a truckload of ways.
I will postpone the idea to check out if the low overhead won't allow a HPC-cluster to encapsulate job-runs in containers which could be optimized for the use-case at hand.

# QNIBTerminal

And this are basically the building blocks of QNIBTerminal. I create different images for every entity in the cluster stack and instantiate them if I like.  So far I created images for...

- [Fedora20][fd20]: Base Fedora20 image; child of the official fedora tree
- [Helixdns][helixdns]: Image to serve helixdns (highly flexible DNS server)
- [Graphite][graphite]: Image serving the graphite stack (+statsd) using nginx and gunicorn
- [Elasticsearch/Logstash/Kibana][elk]: First strike of log management, leveraging the ELK stack
- [Graylog2][graylog2]: Image serving graylog2-server and graylog2-web-interface (logstash + ACL + configure w/o restart)
- [MPI Compute][compute]: Image of an compute node, serving as a slurm-client, metric and log pusher and stuff

In the pipe:

- Alarming: Icinga to present the states and hierarchy of the cluster
- Convert: Image to convert video recording (VDR at my mothers :) to h.265 

I guess QNIBTerminal should be a separat post...

Merci Netways and the OSDC staff as well as all contributors and attendees. It was a interesting and smooth event.

[osdc]:  http://www.netways.de/osdc/osdc2014/overview/
[my_talk]:  http://www.netways.de/index.php?id=4321
[fd20]:  https://index.docker.io/u/qnib/fd20/
[graphite]:  https://index.docker.io/u/qnib/graphite/
[elk]:  https://index.docker.io/u/qnib/elk/
[helixdns]:  https://index.docker.io/u/qnib/helixdns/
[graylog2]:  https://index.docker.io/u/qnib/graylog/
[compute]:  https://index.docker.io/u/qnib/compute/
