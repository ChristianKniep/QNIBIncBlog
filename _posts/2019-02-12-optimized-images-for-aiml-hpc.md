---
author: Christian Kniep
layout: post
title: "Optimized Container Images for AI/ML and HPC"
date: 2019-02-12
tags: eng blog docker aiml hpc platfeat
---

Containers gain more and more foothold as a lightweight mode of isolating different application relying on kernel features to not spin up emulated hardware - create (rather) heavy virtual machines.
That worked great so far, as the resource isolation was only focusing on what the kernel can provide:

- CPU cycles
- Memory
- Input/output to resources controlled by the kernel (e.g. network and filesystems)

### Kernel Bypassing Devices

Due to the advent of acceleration cards - most prominently GPUs; two or three years ago- containers are more and more willing to break out of the host kernel context, accessing those cards. Since the kernel is only involved for some control work, it is a challenge.

In order to use these devices three additional pieces need to work in concert:

 - **devices** provide the means of accessing resources. Either devices to control the kernel driver (like `/dev/nvidiactl`) or representation of the resource (1st GPU: `/dev/nvidia0`, 2nd GPU: `/dev/nvidia1`).
 - the **kernel driver** needs to be installed on the host itself in order to interact with the card.
 -  a **user-land driver** within the user-land (a.k.a. container file system) provides a library to leverage the functionality of the device from within the container.

The following schema shows the representation for the most common use-case these days: a GPU, more specific a NVIDIA GPU.

![](/pics/2019-02-12/device-driver-schema.png)

### Device Passthrough

A rather easy piece in this trinity is the passing the device from the host to the container. Docker is able to pass-in devices using the flag `—device=/dev/nvidia0` almost from day one.
Since the above is located in the Docker-API and workloads are scheduled using some kind of orchestrator - because you ask for trouble if you do it with `docker run`) it comes down to support from your favorite orchestrator. Kubernetes introduced [Kubernetes Device Plugins](link to explenation) a while back in [v1.9](link-to-release-notes) it is commonly used as of today.

Device Plugins have some limitation as of today, but they provide as a first shot of what is possible. The two things I am banging my head against the most is

  1. a device only allows exclusive access to a GPU by a container within a pod and not the complete pod. Say you have a workload that comprises of ETL and compute and you leverage the concept of pods, you can not share the GPU between different containers within the pod. Ok, there is a good argument to support this decision, as processes share the same compute and GPU memory and thus, could run out of either of them - but if users know what they are doing... we are fine, right?
  2. a variation of the above is that Device Plugin use integers to grant access, so you are not able to provide half a GPU to containerA and the other half to containerB. For this we have to wait for sound cgroups guarding the GPU memory I guess. Some day...
  3. Another drawback of the initial design is that the resource will be made available by one resource name and one only. I foresee use-cases in which the device should be exposed under a generic name (`org.qnib.gpu`) and also more specific names (`org.qnib.gpu.nv`, `org.qnib.gpu.nv.k80`), so that you can  

But I am patient, as the Kubernetes community is fast paced - [discussion is already](https://github.com/kubernetes/community/pull/2265) on the way for the next version of resource plugins.

For now it comes down to attach devices according to some resource request and scheduling.

![](/pics/2019-02-12/kubernetes-device-plugin.png)

I create one ([qnib/k8s-device-gpu](https://github.com/qnib/k8s-device-plugin-gpu)) back in the days.<br>
*note-to-myself*: needs an update to only limit it to pass through devices.

### The Juicy Stuff: Driver Matching

Ok, now that we have the boring stuff out of the way - let's talk about the drivers.

To make a particular GPU run, the user-land driver (CUDA toolkit) needs to match the kernel driver (CUDA driver). If not, you will get a complaint. Say I am on a g3.xlarge box from AWS with Ubuntu 18.04 and the package `nvidia-396-44` installed - the CUDA driver tied to CUDA 9.2.

#### How it is done today

A common way of overcoming the issue, runtime (or wrapper of runtimes) evolved, which just bind-mount the driver from the host. [nvidia-docker](https://github.com/NVIDIA/nvidia-docker) does it that way, even though after three years and with NVIDIA being the company that controls the complete stack; I am pretty sure they are good in what they are doing and it is just the most practical way.

![](/pics/2019-02-12/nvidia-docker-bindmount.png)

Problem I have here is that the container file-system and the runtime configuration is changed at runtime, depending on what host the workloads is scheduled on.

Let me repeat:

 - The container file-system is changed - even if I start my container in `--read-only` mode, because a directory is mapped into the container at runtime.
 - Even worse: depending on what node the container will be scheduled on the bind-mount and the content might be different.
 - and in case *Host3* is added the image `training:v1` has to make sure that it is able to run with whatever user-land driver is mapped in from underneath as well.

Oh my goodness... With that in mind - how to improve the situation?

#### Immutable container

IMHO we should - as a community - focus on keeping the runtime dependency as small as possible and - for moby's sake - leave the container file-system out of runtime dependencies.

A container per hardware configuration would be nice...

![](/pics/2019-02-12/platform-feature-image.png)

No matter what hardware is added, the mapping between the image for *host1* and *host1* stays the same.

#### Show me!

Running an image that incorperates CUDA90 (encoded into the image name via `nccl90`) and thus expects the kernel driver `nvidia-390-30` will not work:

{% highlight bash %}
$ docker run --rm -ti --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
             qnib/cv-nccl90-tf-dev:1.12.0
Using TensorFlow backend.
Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1 SSE4.2 AVX AVX2 FMA
libcuda reported version is: 390.30.0
kernel reported version is: 396.44.0
kernel version 396.44.0 does not match DSO version 390.30.0 -- cannot find working devices in this configuration
[]
{% endhighlight %}

One has to pic the correct one carrying CUDA 9.2 (`nccl92`).

{% highlight bash %}
$ docker run --rm -ti --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
             qnib/cv-nccl92-tf-dev:1.12.0-rev10
Using TensorFlow backend.
Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1 SSE4.2 AVX AVX2 FMA
successful NUMA node read from SysFS had negative value (-1), but there must be at least one NUMA node, so returning NUMA node zero
Found device 0 with properties:
name: Tesla K80 major: 3 minor: 7 memoryClockRate(GHz): 0.8235
pciBusID: 0000:00:1e.0
totalMemory: 11.17GiB freeMemory: 11.10GiB
Ignoring visible gpu device (device: 0, name: Tesla K80, pci bus id: 0000:00:1e.0, compute capability: 3.7) with Cuda compute capability 3.7. The minimum required Cuda capability is 7.0.
{% endhighlight %}

Let's ignore that Tensorflow expects the latest and greatest GPU (with [Cuda capability](https://developer.nvidia.com/cuda-gpus) > 7.0). The container matches the CUDA driver and we are good to go.<br>
Even though one thing anyones the performance loving container junkie:
> Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1 SSE4.2 AVX AVX2 FMA

TensorFlow just does not recognize the Broadwell CPU provided by the box. All nice instructions are unused. :/

So let us use yet another image, compiled to utilize the Broadwell architecture (`CFLAGS=-march=broadwell`).

{% highlight bash %}
$ docker run --rm -ti --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
             qnib/cv-nccl92-tf-dev:broadwell_1.12.0
Using TensorFlow backend.
successful NUMA node read from SysFS had negative value (-1), but there must be at least one NUMA node, so returning NUMA node zero
Found device 0 with properties:
name: Tesla K80 major: 3 minor: 7 memoryClockRate(GHz): 0.8235
pciBusID: 0000:00:1e.0
totalMemory: 11.17GiB freeMemory: 11.10GiB
[]
{% endhighlight %}

But do not get overexcited - even though I build an image for the latest Skylake with AVX52 (`skylake-avx512`), the CPU does not support the latest, so TensorFlow fails.

{% highlight bash %}
$ docker run --rm -ti --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
             qnib/cv-nccl92-tf-dev:skylake512_1.12.0
Using TensorFlow backend.
19 Illegal instruction     (core dumped)
{% endhighlight %}

AVX512 create a core dump.

At the end of the day I need to compile NCCL and Tensorflow with `CUDA_COMPUTE_CAPABILITIES=5.2` to support the M60.

{% highlight bash %}
$ docker run --rm -ti --device /dev/nvidia0 --device /dev/nvidiactl --device /dev/nvidia-uvm \
             qnib/cv-nccl92-tf-dev:broadwell_nvcap52_1.12.0
Using TensorFlow backend.
name: Tesla M60 major: 5 minor: 2 memoryClockRate(GHz): 1.1775
pciBusID: 0000:00:1e.0
totalMemory: 7.44GiB freeMemory: 7.36GiB
2019-02-12 16:00:23.636790: I tensorflow/core/common_runtime/gpu/gpu_device.cc:1511] Adding visible gpu devices: 0
2019-02-12 16:00:23.973380: I tensorflow/core/common_runtime/gpu/gpu_device.cc:982] Device interconnect StreamExecutor with strength 1 edge matrix:
     0
0:   N
Created TensorFlow device (/job:localhost/replica:0/task:0/device:GPU:0 with 6723 MB memory) -> physical GPU (device: 0, name: Tesla M60, pci bus id: 0000:00:1e.0, compute capability: 5.2)
['/job:localhost/replica:0/task:0/device:GPU:0']
{% endhighlight %}

### Does not help - yet?

Building these images is only fun when you do not have to do it manually. So I use GoCD to compose the images.<br>
**Even less fun**: Picking the correct image for the underlying node - if that would be easy people would have already done it two years ago...

I will address both issues in the next slides later this week - so stay tuned. :)
