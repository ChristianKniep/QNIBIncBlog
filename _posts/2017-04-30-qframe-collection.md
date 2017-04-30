---
author: Christian Kniep
layout: post
title: "M.E.L.I.G.: Log/Event/Metric Collection within Containers"
date: 2017-04-30
tags: eng melig blog docker metrics
---

[Yesterdays (ok, late post - at the last) MeetUp](https://www.meetup.com/M-E-L-I-G-Berlin-Metrics-Events-Logs-Inventory-Glue/events/238948734/) was first and foremost about the Container Manifesto, which aims to foster understanding about how to build and run a Container.

Afterwards we figured that I missed 'Containers should start fast (thx Lukasz)' as an additional point - next time. :)

For today I will just put the video in here, a separat blog post might follow - even though I feel it is not that necessary, as no code was executed.

<iframe width="560" height="315" src="https://www.youtube.com/embed/DPI1eAgts0w?ecver=1" frameborder="0" allowfullscreen></iframe>


## Log/Event/Metric Collection with qframe

I was working the last couple of days/weeks on a my [qframe](https://github.com/qnib/qframe) ETL framework (inspired by Logstash) but written in go and focusing on containerised environments.

The video gives a 20min (rough) introduction.

<iframe width="560" height="315" src="https://www.youtube.com/embed/bkRvhu6m1Jc?ecver=1" frameborder="0" allowfullscreen></iframe>

The goal is to provide a framework that allows to model generic ETLs inspired by Logstash.

![](/pics/2017-04-30/architecture.png)

### Channels
The framework provides a tick-channel, ticking along every once so often (5s by default).

The `Data` channel moves messages from collectors to handlers and allows any number of filters in between.


### Plugins

Each plugin is its own golang project. Thus, it is easily written and interchangeable.
Furthermore the plan is to allow the use of GOLANG plugins, so that each plugin can be build as shared object and dynamically loaded, without the need to compile it into the resulting daemon.

* **collector**: Input plugin producing messages
* **filter**: plugin to refine/alter messages from collectors or other filters
* **handler**: output plugin to send/output the data

#### Plugins List

The following plugins are available.

##### Collectors

- [docker-events](https://github.com/qnib/qframe-collector-docker-events) Hooks into moby's `/events` API endpoint and parses incoming events like `contianer.create` or `network.attach. 
 For now SWARM events are not provided, but there is already a PR against moby (former called docker) on github.
- [docker-stats](https://github.com/qnib/qframe-collector-docker-stats) For each incoming `docker-event` about a started container, 
 this collector will spawn a goroutine to stream the /container/<id>/stats` API call. Thus, the collector gets (as close as possible) real-time metrics for a container.
- [GELF](https://github.com/qnib/qframe-collector-gelf) Collector for the GELF log-driver of the docker-engine. Should be replaced by a `docker-logs` collector, which spawns a listener for 
 each container like the `docker-stas` collector does. Supposed to be much nicer, because the logs can still be viewed via `docker logs <container>`.
- [tcp](https://github.com/qnib/qframe-collector-tcp) Opens a TCP port which should be used by a container to send messages like AppMetrics.
 By using the `inventory` filter the metadata will be added according to the remote-IP used by the container.
- [file](https://github.com/qnib/qframe-collector-file) Simple collector to tail a file.

##### Filters

- [id](https://github.com/qnib/qframe-filter-id) Relays the message - might be droped as it was used for reversing events.
- [inventory](https://github.com/qnib/qframe-filter-inventory) Listens to `docker-events` and keeps an inventory of all containers. 
 Can be queried by other plugins sending `ContainerRequests down the `Data` channel.
- [grok](https://github.com/qnib/qframe-filter-grok) Allows for matching `QMsg` with GROK patterns (typed RegEx, much nicer to use then RegExp).
- [docker-stats](https://github.com/qnib/qframe-filter-docker-stats) Potential filter to aggregate or transform metrics comming from the `docker-stats` collector.

##### Handlers

- [log](https://github.com/qnib/qframe-handler-log) Outputs to stdout of the daemon.
- [influxdb](https://github.com/qnib/qframe-handler-influxdb) Forwards metrics to an InfluxDB server. 
- [elasticsearch](https://github.com/qnib/qframe-handler-elasticsearch) FOrwards `QMsg` to Elasticsearch.


### Example Run
The following is a run of the `docker-filter-inventory` filter, which listens to `docker-events` and keeps track of containers.

{% highlight bash %}
$ docker run -ti --name qframe-filter-inventory --rm \                                                                                                                                                                                        git:(master|)
             -v /var/run/docker.sock:/var/run/docker.sock qnib/qframe-filter-inventory
> execute CMD 'qframe-filter-inventory'
2017/04/30 20:07:10 [II] Dispatch broadcast for Back, Data and Tick
2017/04/30 20:07:10 [  INFO] inventory >> Start inventory v0.1.0
2017/04/30 20:07:10 [  INFO] docker-events >> Connected to 'moby' / v'17.05.0-ce-rc1'
2017/04/30 20:07:10 [ DEBUG] docker-events >> Already running container /qframe-filter-inventory: SetItem(bc935ed885dd875cc79be7d5d2c7c43614f63c3e463c2722bf558dd507ee5634)
2017/04/30 20:07:11 [ DEBUG] inventory >> SearcRequest for name TestCnt11493582830
2017/04/30 20:07:11 [ DEBUG] inventory >> SearcRequest for name TestCnt21493582830
2017/04/30 20:07:11 [ DEBUG] docker-events >> Just started container /TestCnt11493582830: SetItem(a62863726cb225699b9a20024fd5c817f3094c9b0715087bd73223b2b651b94a)
2017/04/30 20:07:11 [ DEBUG] inventory >> #### Received message on Data-channel: TestCnt11493582830: container.start
2017/04/30 20:07:11 [  INFO] inventory >> Received Event: container.start
2017/04/30 20:07:12 [ DEBUG] inventory >> Ticker came along: p.Inventory.CheckRequests()
2017/04/30 20:07:12 [  INFO] inventory >>  SUCCESS > Request: /TestCnt11493582830 (length of PendingPendingRequests: 1)
2017/04/30 20:07:14 [ DEBUG] docker-events >> Just started container /TestCnt21493582830: SetItem(3c581fd5f484f65d2a25d50083c35d54b1275c8312a4b56de7265bd11176ed72)
2017/04/30 20:07:14 [ DEBUG] inventory >> #### Received message on Data-channel: TestCnt21493582830: container.start
2017/04/30 20:07:14 [  INFO] inventory >> Received Event: container.start
2017/04/30 20:07:15 [ DEBUG] inventory >> Ticker came along: p.Inventory.CheckRequests()
2017/04/30 20:07:15 [  INFO] inventory >>  SUCCESS > Request: /TestCnt21493582830 (length of PendingPendingRequests: 0)
2017/04/30 20:07:15 [ DEBUG] inventory >> PendingRequests has length: 0                                                                                                                                                                                   
{% endhighlight %}

What is going on here:

- `2017/04/30 20:16:38.*inventory >> SearcRequest for name TestCnt.*` The `main.go` creates two search requests which are submitted to the inventory queue.
  As the containers are not yet started, they are added to the `Inventory.PendingRequests` array.
- When the first container is started at `2017/04/30 20:16:39`, it triggers a message to the `docker-events` collector, which subsequently ends up in the Inventory of `filter-inventory`
- The ticker generates a tick-event at `2017/04/30 20:16:40`, which results in a run of [CheckRequests](https://github.com/qnib/qframe-inventory/blob/master/lib/inventory.go#L81) and results in a response of the requests Back channel.
- As at `2017/04/30 20:16:42` the second container is started the search can be fulfilled and results in the second `SUCCESS > Request: /TestCnt21493583397 (length of PendingPendingRequests: 0)`

After that the PendingRequest list is empty and the command will exit.
