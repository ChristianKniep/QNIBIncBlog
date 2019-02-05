---
layout: page
title: ISC Workshop 2019
permalink: /isc/
---

The 'Linux Container' workshop at the ISC 2019 is called: **5th Annual High Performance Container Workshop**

It is going to take place as part of the International Supercomputing Conference in Frankfurt on **June 20nd from 9AM to 6PM** at the Marriott Hotel.

## Previous ISC Workshops

<ul class="posts">
{% for post in site.posts %}
  {% if post.tags contains 'iscworkshop' %}
      <div class="post_info">
        <li>
          <a href="{{ post.url }}">{{ post.title }}</a>
          <span>({{ post.date | date:"%Y-%m-%d" }})</span>
        </li>
      </div>
  {% endif %}
{% endfor %}
</ul>

### Abstract

Linux Containers continue to gain momentum within data centers all over the world.
They are able to benefit legacy infrastructures by leveraging the lower overhead compared
to traditional, hypervisor-based virtualization. But there is more to Linux Containers,
which this workshop will explore. Their portability, reproducibility and distribution
capabilities outclass all prior technologies and disrupt former monolithic architectures,
due to sub-second life cycles and self-service provisioning.

This workshop will outline the current state of Linux Containers in HPC/AI, what challenges
are hindering the adoption in HPC/BigData and how containers can foster
improvements when applied to the field of HPC, Big Data and AI in the mid- and long-term.
By dissecting the different layers within the container ecosystem (runtime, supervision, engine, orchestration, distribution, security, scalability) this workshop will provide a holistic and a state-of-the-container overview, so that participants can make informed discussions on how to start, improve or continue their container adoption.

#### Format

The workshop will follow the concepts of the last 4 successful workshops at ISC by inviting leading members within the container industry (Mellanox, UberCloud, rCUDA, NVIDIA, Docker, Singularity/Sylabs), end-users from Bioinformatics labs, Enterprise Performance Computing and participants of the Student cluster competition.
In addition, the workshop will solicit research papers from the broader research community, reviewed by renowned container experts within HPC/AI.

##### Agenda

The agenda will be structured to shed light on different aspects of containerized environment.
Discussions are ongoing, current proposal is to structure each section as follows:

* Introduction to motivate section
* Series of lightning talks (5-10min)
* Panel discussion including a Q&A

##### Topics of Interest

* Build
   * Provisioning and building containers for HPC systems.
   * Building portable, hardware optimized containers
   * Pre-build images in contrast to runtime decisions on what specific system to run
   * Security of provenance and the build process; building from “untrusted” sources
   * rootless builds
* Distribute
   * How to efficiently manage images that are run across a large number of nodes, without the need of downloading the image content and creating a container file system snapshot
   * Managing access so that users can only see their images
   * Distribution and transport security
* Runtime
   * Security and isolation of containers
   * Performance benchmarking of containerized workloads
   * Scheduling and orchestration of containers
   * Container runtime environments
   * Providing a secure, easy to use RDMA networking to accelerate MPI applications
* Platform/Orchestration
   * Comparison of different container platforms in terms of security and performance
   * Integration with existing HPC schedulers
   * What does the broader container orchestration platforms  (e.g. Kubernetes and Swarm) provide for HPC?
* Use-cases
   * Containers in Big Data, Modeling and Simulation, Life Sciences and AI/ML applications
   * Containerized RDMA, GPU, and MPI applications
   * High availability systems for containerized distributed workloads
   * Auxiliary Services tied to HPC/AI workflows
   * IoT/Edge computing if related to HPC/AI workloads
* Related
   * Other topics relevant to containers in HPC
   * The impact of containers on software development in HPC and technical computing.
   * Monitoring (logs, events, metrics) and auditing in the area of containers


#### General Chair
Christian Kniep, Docker Inc.

#### Program and Publications Chairs:
- Abdulrahman Azab, University of Oslo & PRACE
- Shane Canon, NERSC

## Participation

We encourage everyone to reach out and suggest content.

The **Call For Paper** can be found [here](/isc-cfp/)
