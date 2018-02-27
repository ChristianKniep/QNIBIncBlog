---
layout: page
title: ISC Workshop 2018
permalink: /isc/
---

# ISC 2018 Workshop


The 'Linux Container' workshop at the ISC 2018 was called: <br>
 **Linux Container to optimise IT Infrastructure and High-Performance Workloads**.

It was proposed to be part of the International Supercomputing Conference in Frankfurt at the Marriott Hotel.

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


## Agenda

The initial agenda will be published once the workshop is accepted.

## Speakers

**Burak Yenier** is the CEO of UberCloud. He is a thought-leader and speaks about High Performance Computing, Cloud and Software Containers. <br>
Burak is an expert in large-scale, high availability systems and cloud. As an early SaaS proponent, Burak's management experience spans software development and operations. His most recent role was as the Vice President of Operations of a Silicon Valley SaaS company in banking. Burak built the company's cloud infrastructure and operations from scratch and for scale. He also managed all the data centers and the digital payment operations.<br>
Burak co-founded UberCloud in 2012.  UberCloud has developed  over 150 case-studies in every conceivable area of engineering simulation. The company publishes award-winning blueprints and best practices in cloud and technical computing. Burak simplifies the lives of engineers with powerful, easy to use compute environments in the Cloud. @BurakYenier https://www.linkedin.com/in/buraky/

**Christian Kniep** With a 10y journey rooted in the HPC parts of the german automotive industry, Christian started to support CAE applications and VR installations.<br>
After getting bored with the small pieces, he became the InfiniBand go-to-guy while operating a 4000 node crash-test cluster and pivoted to the R&D department of Bulls BXI interconnect. When told at a conference that HPC can not learn anything from the emerging Cloud and BigData companies, he became curious and is now leading the containerization effort at Gaikai Inc. (part of Sony Interactive Entertainment).<br>
Christian likes to explore new emerging trends by containerizing them first and seek application in the nebulous world of DevOps.

**Holger Gantikow** studied Computer Science at the University of Furtwangen and is working as a Senior Systems Engineer for Science + Computing AG in Tübingen since 2009. In his work, he deals with the complexity of heterogenous systems in CAE computation environments and servers customers utilizing technical and scientific applications. Ever since he started his professional career, virtualization and how it changes IT infrastructures gained his interest. This includes especially cloud management systems like OpenNebula and OpenStack, as well as the recently rediscovered container-based virtualization technology based on Docker.

**Michael Bauer** is an undergraduate student at the University of Michigan, where he is studying Computer Science & Engineering with a focus on computer architecture. He has spent the last 9 months working at the GSI national laboratory in Darmstadt, Germany, as an experimental systems researcher. For the last several months, he has been a developer of Singularity, an open source container solution designed for HPC.
