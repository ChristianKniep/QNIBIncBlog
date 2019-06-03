---
author: Christian Kniep
layout: post
title: "CI/CD Pipeline to Build ManifestLists"
date: 2019-02-20
published: false
tags: eng blog docker aiml hpc platfeat
---
In [previous posts I motivated](/2019/02/12/optimized-images-for-aiml-hpc/) the problem and [described how ManifestLists](/2019/02/14/manifest-list-to-pick-optimized-images/) are able to help.

## ReCap

Running binaries only compiled for generic x86-64, does not give you all the nice CPU flags:
{% highlight bash %}
$ docker run --rm -ti --device=/dev/nvidia{0,ctl,-uwm} qnib/cv-tf-dev:1.12.0
Using TensorFlow backend.
Your CPU supports instructions that this TensorFlow binary was not compiled to use: SSE4.1 SSE4.2 AVX AVX2 FMA
{% endhighlight %}

Compiled for a Broadwell CPU does, but the image used here includes the CUDA toolkit for CUDA9.0, while the host provides the CUDA driver for CUDA 9.2:

{% highlight bash %}
$ docker run --rm -ti --device=/dev/nvidia{0,ctl,-uwm} qnib/cv-nccl90-tf-dev:broadwell_1.12.0
Using TensorFlow backend.
libcuda reported version is: 390.30.0
kernel reported version is: 396.44.0
kernel version 396.44.0 does not match DSO version 390.30.0 -- cannot find working devices in this configuration
[]
{% endhighlight %}

An image build with CUDA 9.2 gets us one step closer. Unfortunately TensorFlow is compiled with default flags which requires the latest GPUs (>NVIDIA P100).
{% highlight bash %}
$ docker run --rm -ti --device=/dev/nvidia{0,ctl,-uwm} qnib/cv-nccl92-tf-dev:broadwell_1.12.0
Using TensorFlow backend.
Ignoring visible gpu device (device: 0, name: Tesla M60, pci bus id: 0000:00:1e.0, compute capability: 5.2) with Cuda compute capability 5.2.
The minimum required Cuda capability is 7.0.
[]
{% endhighlight %}

What is needed is an image compiled with `CUDA_COMPUTE_CAPABILITIES=5.2`.
{% highlight bash %}
$ docker run --rm -ti --device=/dev/nvidia{0,ctl,-uwm} qnib/cv-nccl92-tf-dev:broadwell_nvcap52_1.12.0
Using TensorFlow backend.
Created TensorFlow device (/job:localhost/replica:0/task:0/device:GPU:0 with 6723 MB memory)
-> physical GPU (device: 0, name: Tesla M60, pci bus id: 0000:00:1e.0, compute capability: 5.2)
['/job:localhost/replica:0/task:0/device:GPU:0']
{% endhighlight %}

## Naming Sucks

That was possible for a long time now and it did not fly because incorporating the target into image names and tags just plain sucks.
It does not really help when submitting a job that get scheduled on a Broadwell with M60 OR a Skylake with two V100s.

For this to work one needs to know in advance where it is going to be scheduled and thus the scheduling needs to be constraint, so that the workload only gets scheduled on a node that matches the image.

## Platform FTW

That is not the first time that problem was solved tho. Official base images designed to run on multiple platforms will work it out through ManifestLists.
A ManifestList is just an index of images identified by a [platform object](https://github.com/opencontainers/image-spec/blob/master/image-index.md#image-index-property-descriptions). The tool [manifest-tool](https://github.com/estesp/manifest-tool)  (and `docker manifest` btw) allows to specify this using a simple yaml file:

{% highlight yaml %}
image: myprivreg:5000/someimage:latest
manifests:
  -
    image: myprivreg:5000/someimage:ppc64le
    platform:
      architecture: ppc64le
      os: linux
  -
    image: myprivreg:5000/someimage:amd64
    platform:
      architecture: amd64
      os: linux
{% endhighlight %}


In order to use it `docker pull` has an experimental feature `--platform`. Downloading the PowerPC version of ubuntu? Just do:

{% highlight bash %}
$ docker pull --platform=linux/ppc64le ubuntu
Using default tag: latest
latest: Pulling from library/ubuntu
2a9179d9b269: Pull complete
8fe609a92e3f: Pull complete
b726957e1026: Pull complete
42ba7c91fb87: Pull complete
Digest: sha256:7a47ccc3bbe8a451b500d2b53104868b46d60ee8f5b35a24b41a86077c650210
Status: Downloaded newer image for ubuntu:latest
{% endhighlight %}

Granted, that does not make much sense in the context of CPU architectures, as you won't be able to run this image on AMD64.

{% highlight bash %}
$ docker run -ti --rm ubuntu echo Huhu
standard_init_linux.go:207: exec user process caused "exec format error"
$ docker pull --platform=linux/amd64 ubuntu
Using default tag: latest
latest: Pulling from library/ubuntu
Digest: sha256:7a47ccc3bbe8a451b500d2b53104868b46d60ee8f5b35a24b41a86077c650210
Status: Downloaded newer image for ubuntu:latest
$ docker run -ti --rm ubuntu echo Huhu
Huhu
{% endhighlight %}

But still... :)

### Platform Applied

In the context of what is discussed here, I incorperate the different aspects of the images into one 'meta' image (a.k.a ManifestList).
I compacted the yaml a bit to not use to much space.

{% highlight yaml %}
image: qnib/cv-tf:1.12.0-rev9
manifests:
    image: qnib/cv-tf-dev:1.12.0-rev11
    platform:
      architecture: amd64
      os: linux
    image: qnib/cv-tf-dev:skylake_1.12.0-rev6
    platform:
      features:
        - skylake
    image: qnib/cv-nccl90-tf-dev:1.12.0-rev1
    platform:
      features:
        - nvidia-390-30
    image: qnib/cv-nccl92-tf-dev:1.12.0-rev11
    platform:
      features:
        - nvidia-396-44
    image: qnib/cv-nccl90-tf-dev:broadwell_1.12.0-rev2
    platform:
      features:
        - broadwell
        - nvidia-390-30
    image: qnib/cv-nccl92-tf-dev:broadwell_1.12.0-rev8
    platform:
      features:
        - broadwell
        - nvidia-396-44
    image: qnib/cv-nccl92-tf-dev:skylake_1.12.0-rev6
    platform:
      features:
        - nvidia-396-44
        - skylake
    image: qnib/cv-nccl92-tf-dev:skylake512_1.12.0-rev8
    platform:
      features:
        - nvidia-396-44
        - skylake512
    image: qnib/cv-nccl92-tf-dev:nvcap52_1.12.0-rev3
    platform:
      features:
        - nv-compute-5-2
        - nvidia-396-44
    image: qnib/cv-nccl92-tf-dev:nvcap37_1.12.0-rev4
    platform:
      features:
        - nv-compute-3-7
        - nvidia-396-44
    image: qnib/cv-nccl92-tf-dev:broadwell_nvcap52_1.12.0-rev2
    platform:
      features:
        - broadwell
        - nv-compute-5-2
        - nvidia-396-44    
{% endhighlight %}

This ManifestList can now be used to download the correct image via `--platform` (with a little change to the engine):

{% highlight bash %}
$ docker pull --platform=linux/amd64:broadwell:nv-compute-5-2:nvidia-396-44 qnib/cv-tf:1.12.0-rev9
1.12.0-rev9: Pulling from qnib/cv-tf
Digest: sha256:bb3ffb86b26892c03667544a7ec296ea0f8bc76842adb4d702bf32baacdc0221
Status: Downloaded newer image for qnib/cv-tf:1.12.0-rev9
{% endhighlight %}

This results in the same image as before.

{% highlight bash %}
$ docker image inspect -f '{{"{{"}}.Id{{}}}}' qnib/cv-nccl92-tf-dev:broadwell_nvcap52_1.12.0-rev2
sha256:21894c739c326d6f3942dfcf36cb9afb73f951f9aafab6b049d273323a0429e8
$ docker image inspect -f '{{"{{"}}.Id{{}}}}' qnib/cv-tf:1.12.0-rev9
sha256:21894c739c326d6f3942dfcf36cb9afb73f951f9aafab6b049d273323a0429e8
{% endhighlight %}

## Engine Configuration

In order to be practical, this needs to be configured on an engine level, so that my Tensorflow job specifies the generic name `qnib/cv-tf:1.12.0-rev9` and the engine will download the correct image for the system it runs on.

One possible idea is to put it in the `daemon.json`, like this:

{% highlight bash %}
$ sudo cat /etc/docker/daemon.json
{
  "debug": true,
  "tls": true,
  "tlscacert": "/etc/docker/ca.pem",
  "tlscert": "/etc/docker/cert.pem",
  "tlskey": "/etc/docker/key.pem",
  "tlsverify": true,
  "experimental": true,
  "platform-features": [
    "broadwell",
    "nv-compute-5-2",
    "nvidia-396-44"
  ]
}
{% endhighlight %}

Doing so, the engine will add the `platform-features` automatically, quite like the manual download using:<br>
`--platform=linux/amd64:broadwell:nv-compute-5-2:nvidia-396-44`.

No need to specify different image names to make sure the correct image is scheduled. The following K8s job will fetch the correct image depending on the engine it is scheduled on.

{% highlight yaml %}
apiVersion: batch/v1
kind: Job
metadata:
  name: TensorFlow
spec:
  backoffLimit: 1
  template:
    spec:
      containers:
      - name: tensorflow
        image: qnib/cv-tf:1.12.0-rev9
        resources:
          limits:
            qnib.org/gpu: 1
{% endhighlight %}

## Ongoing Discussions

IMHO that is going to improve the reproducible, deterministic, reliable execution of images with a dependency on the host. Be it a GPU or a CPU.

If you want to know more, visit the [moby/moby issue](https://github.com/moby/moby/issues/38715) and add a `:thumbsup:` to show your support. :)

## Next

The next blog post will show how I build this using CI/CD and stay sane.
