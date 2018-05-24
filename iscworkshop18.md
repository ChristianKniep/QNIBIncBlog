---
layout: page
title: ISC Workshop 2018
permalink: /isc/
---

# ISC 2018 Workshop


The 'Linux Container' workshop at the ISC 2018 was called: <br>
 **High Performance Container Workshop**.

It was held after the International Supercomputing Conference in Frankfurt on **June 28nd from 9AM to 6PM** at the Marriott Hotel.

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

## Abstract
Docker as the dominant flavor of Linux Container continues to gain momentum within datacenter all over the world. It is able to benefit legacy infrastructure by leveraging the lower overhead compared to traditional, hypervisor-based virtualization. But there is more to Linux Containers - and Docker in particular, which this workshop will explore. It's portability, reproducibility and distribution capabilities outclass all prior technologies and disrupt former monolithic architectures, due to sub-second life cycles and self- service provisioning.
This workshop will outline the current state of Containers, what challenges is hindering the adoption in HPC/BigData and how containers can foster improvements when applied to the field of HPC and Big Data in the mid- and long-term.

## Keywords
HPC, cloud, Docker, virtualization, container, software stack, mpi, monitoring, orchestration

## Agenda

-  9:00 - 9:05  Introduction
-  9:05 - 9:30  Container Technology/Engine Architecture 101, Holger
-  9:30 - 10:00 HPC Use-Cases and Current Solutions, Christian
- 10:00 - 10:30 break
- 10:30 - 11:15 HPC in the cloud, Burak
- 11:15 - 12:00 Challenges in HPC and Big Data environments, Christian
- 12:00 - 13:00 lunch
- 13:00 - 13:45 Using remote GPUs with rCUDA, Federico
- 13:45 - 14:30 Strip-down, customized Linux distribution with LinuxKit, Justin
- 14:30 - 15:15 How BeeGFS secures shared file-systems w/ containers, Marco
- 15:15 - 16:00 User-land optimization, Christian
- 16:00 - 16:30 break
- 16:30 - 17:15 Bioscience computation using containerized workflows, Alexander
- 17:15 - 18:00 Student Cluster Competition Team Recap, Michael

## Targeted Audience
Software developers, users, and managers of data center and cloud infrastructure and applications.

## Estimated attendance
100

## Expected Outcome
By attending the participants will gain an understanding about the drivers behind Linux Containers, the different ecosystems and how they fundamentally work. Furthermore, the workshop will shades light on HPC and enterprise aspects like rCUDA, BigData, how to speed up development cycles. Panel discussions will dive into pitfalls and misconceptions and provides an extensive Q&A.

## Speaker

### Christian Kniep (Chair)
Christian Kniep is a Technical Account Manager at Docker, Inc. With a 10 year journey rooted in the HPC parts of the german automotive industry, Christian Kniep started to support CAE applications and VR installations. When told at a conference that HPC can not learn anything from the emerging Cloud and BigData companies, he became curious and was leading the containerization effort of the cloud-stack at Playstation Now. Christian joined Docker Inc in 2017 to help push the adoption forward and be part of the innovation instead of an external bystander. During the day he helps Docker customers in the EMEA region to fully utilize the power of containers; at night he likes to explore new emerging trends by containerizing them first and seek application in the nebulous world of DevOps.

### Burak Yenier
Burak Yenier CEO and Co-Founder of UberCloud, is an expert in the development and management of large-scale, high availability systems, and in many aspects of the cloud delivery model including information security and capacity planning. He has been working on Software as a Service since early 2000 and held management positions in software development and operations in several companies. In his most recent role as the Vice President of Operations Burak managed the multi-site datacenter and digital payment operations of a financial Software as a Service technology company located in Silicon Valley where he built cloud infrastructure and operations from scratch and for scale.

### Michael Kuhn
Michael Kuhn is a postdoctoral researcher in the Scientific Computing group at Universität Hamburg, where he also received his doctoral degree in computer science in 2015. He conducts research in the area of high performance I/O with a special focus on I/O interfaces and data reduction techniques. Other interests of his include file systems and high performance computing in general.

### Holger Gantikow
Holger Gantikow studied Computer Science at the University of Furtwangen and is working as a Senior Systems Engineer for Science + Computing AG in Tuebingen since 2009. In his work, he deals with the complexity of heterogenous systems in CAE computation environments and servers customers utilizing technical and scientific applications. Ever since he started his professional career, virtualization and how it changes IT infrastructures gained his interest. This includes especially cloud management systems like OpenNebula and OpenStack, as well as the recently rediscovered container-based virtualization technology based on Docker.

### Federico Silla
Federicos research addresses high performance on-chip and off-chip interconnection networks as well as distributed memory systems and remote GPU virtualization mechanisms. The different papers he has published so far provide an H-index impact factor equal to 26 according to Google Scholar. Additionally, he is leading and coordinating the development and advancement of the rCUDA remote GPU virtualization middleware since it began in 2008. The rCUDA technology, which enables remote virtualized access to CUDA GPUs, is exclusively and entirely developed by Technical University of Valencia. Moreover, he is leading and coordinating the development of other virtualization technologies. He was also co-founder of the "Remote Libraries" company, which was aimed at provide technical support for the rCUDA technology.

### Marco Merkel

### Alexander Peltzer

### Justin Cormack
Justin Cormack is an engineer at Docker. He got interested in system software while working on operations, trying to stop it breaking, and became a C programmer by necessity not design. He has recently been working on building unikernels, improving usability of security, and distributed systems. He is a maintainer on the open source Docker project. Justin tweets @justincormack
