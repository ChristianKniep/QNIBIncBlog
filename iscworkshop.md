---
layout: page
title: ISC HPCW
permalink: /isc/
---

## ISC 'High Performance Container Workshop'

The workshop series assembles thought leaders to provide the audience with the 'state of containers' and the latest trends.

### Virtual Workshop 2020

As ISC moved to a virtual event, we will go virtual as well. At the time of the workshop we are going to release videos on youtube.

Instead of having one long sitting, we are going to break the workshop into three sessions that will all have similar structure:

* **Firstly**, a hand full experts and thought leaders will provide their insights and expertise in a short and crisp 10min lightning talk. This will fill the first half (~45min) and will be back to back, without time to do Q&A.
* **Second** - and this is really the important and insightful part - all speakers will be available for a panel and virtual Q&A.

As tools we are going to **stream the video** (not 100% settled yet but most likely twich.tv or Youtube) and use [hpc-containers.slack.com](https://hpc-containers.slack.com/#/) as the communication channel to live-chat, do polls and collect questions for the panelist and Q&A. **Plese do make sure that you add yourself to the slack channel.**

## Agenda

{% assign ordered_slots = site.slots | sort:"order_number" %}

**We are currently building out the agenda and refining the format!** 
Please do come back often to check for new updates.

#### Runtime 
**Scheduled for:** (6/16 - 5PM CEST)

The first segment will start building from the ground up by introducing container runtimes and why HPC did not adopt standard runtimes. Afterwards the leading project are going to present the current state of the art and conclude by discussing the area with the community.

| # | Duration |  Title                                   | Speaker             |    Company     | Links |
|:-:|:-----:|:-----------------------------------------|:--------------------|:--------------:|:-----:|
{% for item in ordered_slots %}{% if item.workshop == 'isc20' and item.segment == 'runtime' and item.hidden != 'true' %}| {% if item.duration != '' and item.break != 'true'%}{{ item.order_number }}{% endif %} | {{ item.duration }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} | {% if item.yt %}[Video]({{item.yt}}){% endif %}{% if item.slides and item.yt %}/{% endif %}{% if item.slides %}[Slides](/data/hpcw19/{{item.slides}}){% endif %} |
{% endif %}{% endfor %}

#### Build 
**Scheduled for:** (6/16 - 7PM CEST)

This segment will focus on the building of images as an artifact, how recepies look like and what the end-user might worry about when defining the artifact.


| # | Duration |  Title                                   | Speaker             |    Company     | Links |
|:-:|:-----:|:-----------------------------------------|:--------------------|:--------------:|:-----:|
{% for item in ordered_slots %}{% if item.workshop == 'isc20' and item.segment == 'build' and item.hidden != 'true' %}| {% if item.duration != '' and item.break != 'true'%}{{ item.order_number }}{% endif %} | {{ item.duration }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} | {% if item.yt %}[Video]({{item.yt}}){% endif %}{% if item.slides and item.yt %}/{% endif %}{% if item.slides %}[Slides](/data/hpcw19/{{item.slides}}){% endif %} |
{% endif %}{% endfor %}

#### Distribute 

**Scheduled for:** (6/17 - 5PM CEST)

Once an image is build it needs to be distributed - this segment will focus on how that can be done in a scalable and secure manner.

| # | Duration |  Title                                   | Speaker             |    Company     | Links |
|:-:|:-----:|:-----------------------------------------|:--------------------|:--------------:|:-----:|
{% for item in ordered_slots %}{% if item.workshop == 'isc20' and item.segment == 'dist' and item.hidden != 'true' %}| {% if item.duration != '' and item.break != 'true'%}{{ item.order_number }}{% endif %} | {{ item.duration }} | {% if item.description %}<details><summary>{% endif %}{{ item.title }}{% if item.description %}</summary><div class="slot-tiny">{{ item.description }}</div></details>{% endif %} | {{ item.speakers }}  | {{ item.affiliation }} | {% if item.yt %}[Video]({{item.yt}}){% endif %}{% if item.slides and item.yt %}/{% endif %}{% if item.slides %}[Slides](/data/hpcw19/{{item.slides}}){% endif %} |
{% endif %}{% endfor %}

#### Orchestration/Scheduling 

**Scheduled for:** (6/17 - 7PM CEST)

Starting with a simple scheduler like SLURM this segment will build up to more complex schedulers (K8s) and workflow managers (Nextflow, Argo, Airflow).

#### HPC Specific 

**Scheduled for:** (6/18 - 5PM CEST)

Approaching the meet on the bone we are going to discuss the particularities of HPC. Device integration, POSIX file-systems, MPI(/PMI) and scale in general.

#### Use-cases and Outlook

**Scheduled for:** (6/18 - 7PM CEST)

We'll look back on 6 years of this workshop, get a glimps into how big centers run containers successfully and how HPC use-cases evolved.


## Previous Workshops


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
