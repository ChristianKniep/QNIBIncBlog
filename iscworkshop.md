---
layout: page
title: ISC Workshop
permalink: /isc/
---

# ISC 2016 Workshop

This years 'Linux Container' workshop at the ISC 2016 is called: <br>
 **Docker: Linux Containers to Optimise IT Infrastructure for HPC & BigData**.

Unlike last year the focus is to provide actionable knowledge about the world of Linux Containers, discuss problems and possible solutions.
The initial agenda will be pushed out as soon as possible. Please revisit this side in a couple of days.

For an idea of what the workshop is going to touch on the following video recording of the host's talk in Lugano provides some guidance:

<iframe width="560" height="315" src="https://www.youtube.com/embed/3gTJj-HuZuo?list=PLfE3_wJGw9KS3PBvqEcDdpiODeDjAs5v8" frameborder="0" allowfullscreen></iframe>

The issues are talked about from [0:22:30](https://youtu.be/3gTJj-HuZuo?list=PLfE3_wJGw9KS3PBvqEcDdpiODeDjAs5v8&t=1350) on.

## Agenda

The (initial) agenda for the Workshop is as follows. It will evolve (hopefully quickly) in the days to come.

| Slot# |   Title                                  | Speaker   |  Company | State  |
|:-----:|:----------------------------------- |:------------- |:------:|:------:|
| 0 | Introduction                        | Christian Kniep | Gaikai Inc | ![](/pics/confirmed.png) | 
| 1 | Linux Containers in a Nutshell | Holger Gantikow | science+computing ag |  |
| 2 | What drives docker in Non-HPC and how to catch up? | Christian Kniep | Gaikai Inc. | ![](/pics/confirmed.png) |
| 3 | Singularity - best of Containers and clean packaging? | Bernard Li | Berkeley Labs |  |
| 4 | UberCloud - Tackle the ISV | Wolfgang Gentzsch | UberCloud | ![](/pics/confirmed.png) |
| 5 | Docker Volumes w/ BeeGFS | Jasper Lievisse Adriaanse | RedCoolBeans |  ![](/pics/confirmed.png) |
| 6 | RDMA Namespace & CGroups for InfiniBand | | Mellanox | |
| 7? | From System Containers to Shared Namespaces | Christian Kniep | Gaikai Inc. | |
| 7? | Shared GPUs within Containers using rCUDA | | | |
| 8 | Conclusion, Panel Discussion | Christian Kniep | Gaikai Inc. | ![](/pics/confirmed.png) |

### Details

#### Linux Containers in a Nutshell (Holger)
<div id="portrait">
    <img height="75" src="/pics/isc/holger.jpg">
</div>
Holger will kick the workshop of by providing an introduction into what Linux Containers are all about.
 <br>
 <br>
 <br>

#### What drives docker in Non-HPC and how to catch up? (Christian)
<div id="portrait">
    <img height="75" src="/pics/Christian.png">
</div>
Docker benefits the non-HPC environments with its boost to software development by providing fast feedback loops and an easy setup of development environment.<br>
This part will dive into why that is and shed some light on why HPC environments haven't benefited yet.
 <br>

#### Singularity - best of Containers and clean packaging? (Bernard)

#### UberCloud - Tackle the ISV (Wolfgang)
<div id="portrait">
    <img height="75" src="/pics/isc/wolfgang.jpg">
</div>
UberCloud has developed software containers to host ISV codes for on-premise and in the HPC Cloud environments. These production ready containers bundle OS, libraries and software tools as well as ISV software and even whole engineering and scientific workflows. By eliminating the need to install software and configure the high performance computing environment, the time for packaging and accessing ISV software in the cloud has been reduced dramatically.

#### Docker Volumes w/ BeeGFS (Jasper)
<div id="portrait">
    <img height="75" src="/pics/isc/jasper.jpeg">
</div>
RedCoolBeans has developed a plugin for Docker to allow containers to store data on a volume in a BeeGFS cluster. This presentation will discuss Docker volumes in general, and the plugin for BeeGFS in particular.
 <br>
 <br>


#### RDMA Namespace & CGroups for InfiniBand


#### From System Containers to Shared Namespaces (Christian)

At first glance Linux Containers could just be a lightweight substitute for VM. But if the namespaces are embraced it turns into a framework to piece together each part of the runtime environment using different containers and thus, allow different user-lands to provide different services.

#### Shared GPUs within Containers using rCUDA

With [rCUDA](http://www.rcuda.net/) GPU resources can be shard over the network in order to use CUDA remotely. This applied to Linux Containers would make the individual application extremely portable. A developer could run the container locally using CUDA and push the container to a cluster with some GPUs attached and run the application using rCUDA. <br>
**This talk is not settled yet, as we are figuring out who will talk about it - if you like to participate, ping me**

#### Conclusion, Panel Discussion	 (.*)

The workshop is wrapped up by providing some wiggle room to take questions and provide an outlook (wishlist) how Linux Containers evolve in the foreseeable future.