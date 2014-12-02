---
layout: post
title:  "insideHPC Interview about 'Containerized MPI Workloads'"
subtitle: "Video interview with insideHPC"
date:   2014-12-02
categories: qnibterminal
tags: qnibterminal eng cluster docker blog talk
---

As an aftermath of the ['HPC Advisory Council China Workshop']({% post_url 2014-11-06-Containerized-MPI-workloads %})
Rich invited me to have an interview via Skype about the very same topic.

Apart from the fact that it's always a pleasure to talk to HPC enthusasts like Rich, it was a perfect oportunity to record the slides,
since I failed to operate the GoPro and my MacBook Pro propperly. IMHO the recording was even better then the original.
For starters I added a MPI Microbenchmark, which provides a nice bare MPI flavor.

<iframe width="420" height="315" src="//www.youtube.com/embed/f_663isRkXQ" frameborder="0" allowfullscreen></iframe>

A little remark I would like to point out regarding the slide about using an InfiniBand network adapter.
![](/pics/2014-12-02/tradi_docker_virt.png "Traditinal vs. Containerized Virtualization")

Let's say that this view might be a little bit outdated. This sure was they way to do it to provide performance in the old days.
Within the dark ages there was no way to squeeze performance out. DMA was done by the first virtual machine and everyone had to pick up the
memory bits. I saw a nice visualization within a youtube video about SR-IOV:

XXXXX Insert YT-Link here

Today we got paravirtualization up to SR-IOV and that is why I am looking forward to play around with this technique in the days to come.

