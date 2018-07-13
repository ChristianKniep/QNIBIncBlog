---
layout: page
title: ISC Workshop 2018
permalink: /isc/
---

# ISC 2018 Workshop


The 'Linux Container' workshop at the ISC 2018 is called: **High Performance Container Workshop**

It is held as part of the International Supercomputing Conference in Frankfurt on **June 28nd from 9AM to 6PM** at the Marriott Hotel.

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

| Slot# |  Title                                   | Material | Speaker             |  Company |
|:-----:|:-----------------------------------------|:---------|:---------------------|:--------:|
| 1 | Container Technology/Engine Architecture 101 | [slides](/data/isc2018/ISC2018_Gantikow_ContainerTechnology-EngineArchitecture101.pdf) | Holger Gantikow | Atos |
| 2 | HPC Problem Statement and current Solutions  | [slides](/data/isc2018/) | Christian Kniep | Docker |
| 3 | HPC in the cloud                             | [slides](/data/isc2018/UberCloud.pdf) | Burak Yenier | UberCloud |
| 4 | Ideas towards High Performance Containers    | [slides](/data/isc2018/high-performance-containers_ideas.pdf)| Christian Kniep | Docker |
| 5 | Using remote GPUs with rCUDA                 | [slides](/data/isc2018/rCUDA_talk_v3.pdf) | Federico Silla  | rCUDA |
| 6 | Strip-down, customized Linux distribution with LinuxKit  | [slides](/data/isc2018/LinuxKit.pdf)| Justin Cormack  | Docker |
| 7 | How BeeGFS secures shared file-systems w/ containers  | | Marco Merkel | ThinkParQ |
| 8 | RoCE and InfiniBand Container Status         | [slides](/data/isc2018/roce-containers.pdf)| Dror Goldenberg | Mellanox |
| 10 | Bioscience computation using containerized workflows  | [slides](https://slides.com/apeltzer/deck?token=DpD3s-CV) | Alexander Peltzer | QBiC |
| 11 | Student Cluster Competition Team Recap      | | Leonhard Reichenbach | DKRZ |

## Targeted Audience
Software developers, users, and managers of data center and cloud infrastructure and applications.

## Estimated attendance
100

## Expected Outcome
By attending the participants will gain an understanding about the drivers behind Linux Containers, the different ecosystems and how they fundamentally work. Furthermore, the workshop will shades light on HPC and enterprise aspects like rCUDA, BigData and how to speed up development cycles. Panel discussions will dive into pitfalls and misconceptions and provides an extensive Q&A.

## Speaker

### Christian Kniep (Chair)
Christian Kniep is a Technical Account Manager at Docker, Inc. With a 10 year journey rooted in the HPC parts of the german automotive industry, Christian Kniep started to support CAE applications and VR installations. When told at a conference that HPC can not learn anything from the emerging Cloud and BigData companies, he became curious and was leading the containerization effort of the cloud-stack at Playstation Now. Christian joined Docker Inc in 2017 to help push the adoption forward and be part of the innovation instead of an external bystander. During the day he helps Docker customers in the EMEA region to fully utilize the power of containers; at night he likes to explore new emerging trends by containerizing them first and seek application in the nebulous world of DevOps.

### Burak Yenier
Burak Yenier CEO and Co-Founder of UberCloud, is an expert in the development and management of large-scale, high availability systems, and in many aspects of the cloud delivery model including information security and capacity planning. He has been working on Software as a Service since early 2000 and held management positions in software development and operations in several companies. In his most recent role as the Vice President of Operations Burak managed the multi-site datacenter and digital payment operations of a financial Software as a Service technology company located in Silicon Valley where he built cloud infrastructure and operations from scratch and for scale.

### Leohard Reichenbach
Leonhard Reichenbach is studying Computing in Science with a focus on
physics at Universität Hamburg. He is interested in scientific
high-performance computing and participates in this years ISC-HPCAC
Student Cluster Competition (SCC).

### Dror Goldenberg
Dror joined Mellanox in 2000 as an architect to work on exciting network innovations. Dror drove silicon and system architecture of multiple generations of Network Interfaces Cards, Switches and SoCs. Dror’s main focus nowadays is on software architecture, enabling network accelerations of cool technologies like artificial intelligence, HPC, cloud, storage, big data, security and more.

### Holger Gantikow
Holger Gantikow studied Computer Science at the University of Furtwangen and is working as a Senior Systems Engineer for Science + Computing AG in Tuebingen since 2009. In his work, he deals with the complexity of heterogenous systems in CAE computation environments and servers customers utilizing technical and scientific applications. Ever since he started his professional career, virtualization and how it changes IT infrastructures gained his interest. This includes especially cloud management systems like OpenNebula and OpenStack, as well as the recently rediscovered container-based virtualization technology based on Docker.

### Federico Silla
Federico Silla received the PhD degree in Computer Engineering from
Universitat Politecnica de Valencia, Spain, where he is currently an
associate professor. He has led the rCUDA project since it began in
2008. He has published more than 150 conference and journal papers.

### Marco Merkel
Marco is since almost 3 years the Vice President worldwide sales & consulting for BeeGFS at ThinkParQ GmbH in Kaiserslautern. Main focus of his position is the international distribution of BeeGFS and sell consulting services into High Performance Computing, AI, Deep Learning, HPC Cloud Services, Bioinformatics, CFD, Finance, Oil & Gas, Media & Entertainment market segments. Key to success is the competent, motivated ThinkParQ team in the background and the development of strategic OEM vendors relations, planning and realizations of business models & solution building blocks for channel partner and lining up flagship end customer projects.

### Alexander Peltzer
Alexander Peltzer studied Bioinformatics at the University of Tuebingen and is working as a Bioinformatics research scientist at the Quantitative Biology Center (QBiC) in Tübingen since 2017. During his Ph.D he worked on complex genomics applications and analysis pipelines and applied container based technologies such as Docker to resolve dependency issues in the field of bioinformatics.

### Justin Cormack
Justin Cormack is an engineer at Docker. He got interested in system software while working on operations, trying to stop it breaking, and became a C programmer by necessity not design. He has recently been working on building unikernels, improving usability of security, and distributed systems. He is a maintainer on the open source Docker project. Justin tweets @justincormack
