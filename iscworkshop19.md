---
layout: page
title: ISC Workshop 2019
permalink: /isc/
---

The 'Linux Container' workshop at the ISC 2019 is called: **5th Annual High Performance Container Workshop**

It is going to take place as part of the International Supercomputing Conference in Frankfurt on **June 20nd from 9AM to 6PM** at the Marriott Hotel.

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

### (Draft) Agenda
The first half of the day will be spend with introducing the speakers, provide an overview and discuss
the topics which are not exclusivly HPC specific, but are fundamentals that are also important in non-HPC use cases: Which runtime fits my use-case? How to build my container image? How to distribute the artefacts?
Depending on my use-case, dicipline, vertical - what should I focus on and what is less important?

{% assign ordered_slots = site.slots | sort:"order_number" %}

### Intro (09:00 - 10:00)

| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'intro'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Runtime (10:00 - 11:00)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'runtime'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Build (11:30 - 12:20)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'build'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Distribute (12:20 - 13:00)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'distribute'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Orchestration/Scheduling (14:00 - 15:15)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'orchestration'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Infrastructure (15:15 - 15:30)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'infra'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### HPC Specific / Distributed Workloads (15:30 - 16:00)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'hpc'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

### Use-Cases/Conclusions/Discussion (16:30 - 18:00)
| Start |  Title                                   | Speaker             |    Company     |
|:-----:|:-----------------------------------------|:--------------------|:--------------:|
{% for item in ordered_slots %}{% if item.workshop == 'isc19' and item.segment == 'end'%}| {{ item.start }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} |
{% endif %}{% endfor %}

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

#### General Chair
Christian Kniep, Docker Inc.

#### Program and Publications Chairs:
- Abdulrahman Azab, University of Oslo & PRACE
- Shane Canon, NERSC

## Participation

We encourage everyone to reach out and suggest content.

The **Call For Paper** can be found [here](https://www.uio.no/english/services/it/research/hpc/hpcw-2019.html)
