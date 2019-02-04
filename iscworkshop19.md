---
layout: page
title: ISC Workshop 2019
permalink: /isc/
---

# ISC 2019 Workshop


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

#### General Chair
Christian Kniep, Docker Inc.

#### Program and Publications Chairs:
- Abdulrahman Azab, University of Oslo & PRACE
- Shane Canon, NERSC

## Participation

We encourage everyone to reach out and suggest content.

The **Call For Paper** can be found [here](/isc-cfp/)
