---
layout: page
title: ISC Workshop 2017
permalink: /isc/
---

# ISC 2017 Workshop 


This years 'Linux Container' workshop at the ISC 2017 is called: <br>
 **Linux Container to optimise IT Infrastructure and High-Performance Workloads**.
 
It is held after the International Supercomputing Conference in Frankfurt on **June 22rd from 2PM to 6PM** at the Marriott Hotel.

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

The initial agenda reads as follows, the agenda is subject to refinements.

| Slot# |  Time |  Title                                          | Speaker                         |
|:-----:|:-----:|:------------------------------------------------|:--------------------------------|
| 14:00 | 5min  | Introduction                                    | Christian Kniep                 |
| 14:05 | 25min | Linux Containers Technology & Runtimes          | Holger Gantikow                 |
| 14:30 | 30min | Docker Ecosystem: Engine, Swarm, Compose        | Christian Kniep                 |
| 15:00 | 30min | Non-Docker Ecosystem: Kubernetes et al          | Sebastian Scheele               |
| 15:30 | 15min | Workflow Orchestration with Nextflow            | Paolo Di Tommaso                |
| 15:45 | 15min | Workload Reproducibility using Containers       | Christian Kniep                 |
| 16:00 | 30min | Coffee Break                                                                     ||
| 16:30 | 40min | Current state of HPC-workloads in the cloud     | Burak Yenier, Wolfgang Gentzsch |
| 17:00 | 10min | Reproducible Orchestration with Nextflow        | Paolo Di Tommaso                |
| 17:20 | 10min | User-land performance and customisation         | Christian Kniep                 |
| 17:30 | 30min | Q&A, Panel Discussion                           | All                             |

## Speakers

**Burak Yenier**, CEO and Co-Founder of UberCloud, is an expert in the development and management of large-scale, high availability systems, and in many aspects of the cloud delivery model including information security and capacity planning. He has been working on Software as a Service since early 2000 and held management positions in software development and operations in several companies. In his most recent role as the Vice President of Operations Burak managed the multi-site datacenter and digital payment operations of a financial Software as a Service technology company located in Silicon Valley where he built cloud infrastructure and operations from scratch and for scale. @BurakYenier and http://www.linkedin.com/in/buraky.

**Christian Kniep** With a 10y journey rooted in the HPC parts of the german automotive industry, Christian started to support CAE applications and VR installations.<br>
After getting bored with the small pieces, he became the InfiniBand go-to-guy while operating a 4000 node crash-test cluster and pivoted to the R&D department of Bulls BXI interconnect. When told at a conference that HPC can not learn anything from the emerging Cloud and BigData companies, he became curious and is now leading the containerization effort at Gaikai Inc. (part of Sony Interactive Entertainment).<br>
Christian likes to explore new emerging trends by containerizing them first and seek application in the nebulous world of DevOps. 

**Holger Gantikow** studied Computer Science at the University of Furtwangen and is working as a Senior Systems Engineer for Science + Computing AG in Tübingen since 2009. In his work, he deals with the complexity of heterogenous systems in CAE computation environments and servers customers utilizing technical and scientific applications. Ever since he started his professional career, virtualization and how it changes IT infrastructures gained his interest. This includes especially cloud management systems like OpenNebula and OpenStack, as well as the recently rediscovered container-based virtualization technology based on Docker.

<!--**Michael Bauer** is an undergraduate student at the University of Michigan, where he is studying Computer Science & Engineering with a focus on computer architecture. He has spent the last 9 months working at the GSI national laboratory in Darmstadt, Germany, as an experimental systems researcher. For the last several months, he has been a developer of Singularity, an open source container solution designed for HPC.
-->

**Paolo Di Tommaso** is research software engineer at Center for Genomic Regulation, Spain. He is a 20 years experienced software developer, software architecture designer and advocate of open source software. His main interests are parallel programming, HPC and cloud computing. Paolo is B.Sc. in Computer Science and M.Sc. in Bioinformatics. He is the creator and project leader of the Nextflow workflow framework

**Sebastian Scheele** is a co-founder of Loodse, a software company that has developed Kubermatic - a managed Master as a Service for the orchestration of multiple Kubernetes clusters. Moreover, Loodse provides consulting and training services in the area of cloud native strategies. Sebastian has been qualified an official Google Cloud trainings partner. Before, Sebastian worked as a software developer for SAP. He holds a degree in Computer Science from the University of Applied Science and Arts of Dortmund.

**Wolfgang Gentzsch** is co-founder & president of the UberCloud Community and Marketplace for engineers and scientists to discover, try, and buy computing power on demand in the cloud. He is also Co-Chairman of the ISC Cloud & Big Data conference series. Wolfgang was Director At-Large of the Board of Directors of the Open Grid Forum, and an advisor to the EU projects DEISA and EUDAT. Before he directed the German D-Grid Initiative, was a professor of computer science at Duke in Durham, NC State in Raleigh, and the University of Applied Sciences in Regensburg, and a visiting scientist at RENCI, the Renaissance Computing Institute at UNC Chapel Hill. Wolfgang was a member of the US President's Council of Advisors for Science and Technology, PCAST, and held leading positions at Sun, MCNC, Gridware, and Genias Software.