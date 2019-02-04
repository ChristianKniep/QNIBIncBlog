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

#### Technical Program committee
- Abdulrahman Azab, University of Oslo, Norway & PRACE
- Björn Grüning, University of Freiburg, Germany
- Bob Killen, Lawrence Livermore National Laboratory (LLNL), USA
- Burak Yenier, UberCloud, USA
- CJ Newburn, NVIDIA, USA
- Carlos E. Arango, Sylabs, USA
- Carlos Fernandez, CESGA, Spain
- Diakhate Francois, CEA, France
- Gilles Wiber, CEA, France
- Giuseppa Muscianisi, CINECA, Italy
- Hisham Kholidy, SUNY Polytechnic Institute, USA
- Martial Michel, Data Machines Corp, USA
- Michael Jennings, Los Alamos National Lab (LANL), USA
- Michael W. Bauer, Sylabs, USA
- Paolo Di Tommaso, Centre for Genomic Regulation (CRG), Spain & Seqera Labs
- Parav Pandit, Mellanox, USA
- Rosa M Badia, Barcelona Supercomputing Center, Spain
- Shane Canon, National Energy Research Scientific Computing Center (NERSC), USA
- Thomas Röblitz, University of Oslo, Norway
- Wolfgang Gentzsch, UberCloud, USA

### Call for Proposal (going to be refined)

The workshop will comprise of invited speakers and research paper slots, with the general goal to provide a holistic view of the containerized ecosystem and compare different parts within this ecosystem with regards to what the provide and spark panel discussions about highly debated topics.

### Submission

#### Full papers

Full paper submissions should be structured as technical papers (up to 7 pages + 2 pages for references). Submitted papers must represent original unpublished research that is not currently under review for any other conference or journal. The submission is open to academic as well as industrial authors.

#### Short Industrial papers / Extended Abstract

We encourage submissions on innovative solutions and applications related to commercial or industrial-strength software. At least one of the authors needs to have a non-academic affiliation. Industrial papers should be structured as extended abstracts (2-4 pages + 2 pages for references).

#### Important Dates

Tentative dates are as follows:

 * Abstract submission deadline: April 20
 * Paper submission deadline: April 25
 * Author notification: May 15
 * Workshop Day: June 20
 * Camera-ready deadline: July 15

#### Topics of Interest

Topics of interest include but are not limited to

* Build
   * Provisioning and building containers for HPC systems.
   * Building portable, hardware optimized containers
   * Pre-build images in contrast to runtime decisions on what specific system to run
   * Security of provenance and the build process; building from “untrusted” sources
* Distribute
   * How to efficiently manage images that are run across a large number of nodes, without the need of downloading the image content and creating a container file system snapshot.
   * Managing access so that users can only see their images
   * Distribution and transport security
* Runtime
   * Security and isolation of containers
   * Performance benchmarking of containerised workloads
   * Scheduling and orchestration of containers
   * Container runtime environments
   * Providing a secure, easy to use RDMA networking to accelerate MPI applications
* Platform/Orchestration
   * Comparison of different container platforms in terms of security and performance
   * Integration with existing HPC schedulers
   * What does the broader container orchestration platforms  (e.g. Kubernetes and Swarm) provide for HPC?
* Use-cases
   * Containers in Big Data, Modeling and Simulation, Life Sciences and AI/ML applications
   * Containerised RDMA, GPU, and MPI applications
   * High availability systems for containerized distributed workloads
   * Auxiliary Services tied to HPC/AI workflows
   * IoT/Edge computing if related to HPC/AI workloads
* Related
   * Other topics relevant to containers in HPC
   * The impact of containers on software development in HPC and technical computing.
   * Monitoring (logs, events, metrics) and auditing in the area of containers
