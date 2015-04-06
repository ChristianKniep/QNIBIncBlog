---
author: Christian Kniep
layout: post
title: "QNIBTerminal - pure SLURM"
date: 2015-04-04 17:30:00
tags: eng docker blog qnibtermial
---

The foundation of QNIBTerminal is an image that holds consul and glues everything together. I used the Easter break to refine my `qnib/slurm` images - this blog post give a quick intro.

<!-- more -->

[SLURM](https://computing.llnl.gov/linux/slurm/) is a resource scheduler that helps out by freeing your mind from how to use resources in a cluster. 
Hence the name **S**imple **L**inux **U**tility for **R**esource **M**anagement.

To spin up a cluster three daemons are necessary:

**Munge** ([MUNGE Uid 'N' Gid Emporium](https://code.google.com/p/munge/)) creates and validates credentials for authentication.

**SLURM Controller** The SLURM controller (`slurmctld`) is in charge of the actual scheduling. It gathers all information and dispatches the jobs.

**SLURM Daemon** The `slurmd` daemon runs on all nodes within the cluster and connects to the `slurmctld`, reports the node ready for duty.

# Docker Images

For this simple version of a SLURM cluster, three docker containers are needed.

- **qnib/consul** bundles everything together by providing service discovery and a key/value store
- **qnib/slurmctld** provides the SLURM Controller
- **qnib/slurmd** acts as the compute node

# SLURM config file

The two slum daemons use a common configuration file `slurm.conf`. 
This bugger has to be equal among all daemons, otherwise they will complain. Within my first iteration of QNIBTerminal I used etcd and some bash scripts to keep everyone in sync - this time around I use the power of consul. :)

## consul services

The containers are reporting all services back to consul. Among them `slurmctld` and `slurmd`.  Within consul, these nodes can be queried using the consul HTTP API:

{% highlight bash %}
$ export CHOST="http://consul.service.consul:8500"
$ curl -s ${CHOST}/v1/catalog/service/slurmd|python -m json.tool
[
    {
        "Address": "172.17.0.217",
        "Node": "001a982e8af1",
        "ServiceAddress": "",
        "ServiceID": "slurmd",
        "ServiceName": "slurmd",
        "ServicePort": 6818,
        "ServiceTags": null
    }
]
{% endhighlight %}

And if that would be not enough the guys behind consul provide `consul-template` to use the information painlessly simple.

## consul-template

As the name suggests, `consul-tempate` uses consul and creates config files out of it. 
Since our SLURM cluster is going to be fairly dynamic (the cluster should grow and shrink if we feel like it) it has to be configured dynamically as well. 
The hard part within the slum config file is to get the nodes dynamically created. 

{% highlight bash %}
$ tail -n5 /usr/local/etc/slurm.conf
NodeName=001a982e8af1 NodeAddr=172.17.0.217
PartitionName=qnib Nodes=001a982e8af1 Default=YES MaxTime=INFINITE State=UP
{% endhighlight %}

This information derives out of this template:

{% highlight bash %}
{% raw %}
$ tail -n6 /etc/consul-template/templates/slurm.conf.tmpl
{{range service "slurmd" "any"}}
NodeName={{.Node}} NodeAddr={{.Address}}{{end}}

PartitionName=qnib Nodes={{range $i, $e := service "slurmd" "any"}}{{if ne $i 0}},{{end}}{{$e.Node}}{{end}} Default=YES MaxTime=INFINITE State=UP
{% endraw %}{% endhighlight %}

`consul-template` gets a list of all nodes providing `slurmd` (by default it only takes services into account that are up'n'running, "any" gets them all).

Supervisors holds the serves that listens for changes, recreates the configuration and restarts the service, that's it. :)

{% highlight bash %}
$ cat /etc/supervisord.d/slurmd_update.ini
[program:slurmd_update]
command=consul-template -consul consul.service.consul:8500 -template "/etc/consul-template/templates/slurm.conf.tmpl:/usr/local/etc/slurm.conf:supervisorctl restart slurmd"
redirect_stderr=true
stdout_logfile=syslog
{% endhighlight %}


## fig

I must admit I am stuck at fig, I should update to docker-compose - but still...

The following fig file spins up the stack:

{% highlight yaml %}
consul:
    image: qnib/consul
    ports:
     - "8500:8500"
    environment:
    - DC_NAME=dc1
    - ENABLE_SYSLOG=true
    dns: 127.0.0.1
    hostname: consul
    privileged: true

slurmctld:
    image: qnib/slurmctld
    ports:
    - "6817:6817"
    links:
    - consul:consul
    environment:
    - DC_NAME=dc1
    - SERVICE_6817_NAME=slurmctld
    - ENABLE_SYSLOG=true
    dns: 127.0.0.1
    hostname: slurmctld
    privileged: true

slurmd:
    image: qnib/slurmd
    links:
    - consul:consul
    - slurmctld:slurmctld
    environment:
    - DC_NAME=dc1
    - ENABLE_SYSLOG=true
    dns: 127.0.0.1
    #hostname: slurmd
    privileged: true
{% endhighlight %}

I do not use a hostname to have a dynamic hostname for each slurmd container. 

Logging into the first node I can use the slum commands:

{% highlight bash %}
$ docker exec -ti dockerslurmd_slurmd_1 bash
bash-4.2# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
qnib*        up   infinite      1   idle 001a982e8af1
bash-4.2# srun hostname
001a982e8af1
{% endhighlight %}

By using `fig scale` the cluster can be expanded...

{% highlight bash %}
$ fig scale slurmd=5
Starting dockerslurmd_slurmd_2...
Starting dockerslurmd_slurmd_3...
Starting dockerslurmd_slurmd_4...
Starting dockerslurmd_slurmd_5...
$ docker exec -ti dockerslurmd_slurmd_1 bash
bash-4.2# sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
qnib*        up   infinite      5   idle 001a982e8af1,9d8960b0d3ae,46e07712f89e,988187e8255a,e10c39a5ea12
bash-4.2# srun -N 5 hostname
001a982e8af1
e10c39a5ea12
46e07712f89e
988187e8255a
9d8960b0d3ae
{% endhighlight %}

And that's it...
