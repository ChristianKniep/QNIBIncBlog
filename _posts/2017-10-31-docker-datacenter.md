---
author: Christian Kniep
layout: post
title: "Docker Datacenter in a Box"
date: 2017-10-31
tags: eng blog docker ucp dtr
---

I've been working for Docker for a month now and it is already a fun ride. I joined just before the DockerConEU announcement two weeks back, that the `Docker Enterprise Edition` as well as the `Docker Community Editions for Desktops` (`Docker4Mac`/`Docker4Win`) will support Kubernetes in the future.

## Docker Enterprise Edition, qué?

But not to fast. The `Docker Enterprise Edition` builds on-top of the `Community Edition`, which provides the container runtime (to-be `containerd`), the orchestrator SWARM (will include `Kubernetes` in a couple of month) and developer workflow tools like `docker-compose` the Docker CLI.
Using the `Community Edition` you can get your feet wet with Linux Containers and boost your developing and testing. Furthermore you have all the plumbing in place to run workloads in production.

![](/pics/2017-10-31/docker-enterprise-edition.jpg)

To help you get around implementing all the goodies like `authorisation/authentication`, `security scanning`, `container lifecycle` and so on Docker offers the `Docker Enterprise Edition`, which includes the `Universal Control Plane` (UCP) and `Docker Trusted Registry` (DTR).

It provides an easy to use WebUI, RoleBaseAccessControl (RBAC), LDAP/AD integration and alike.

## Vagrantstack

To make myself familiar I derived a [vagrant]() setup from a `docker-machine` setup Sacha (a fellow Dockerian) came up with: [DDC-Cluster](https://github.com/foodebeer/DDC-Cluster)

To make everything as tightly packaged as possible (an upcoming version should use `LinuxKit` to make it even tighter), I created `packer` templates, to create Alpine boxes, which are already include the Docker Images needed, so that they will just start, without downloading GB worth of images first.

- [alpine-docker](https://github.com/qnib/packer-files/tree/master/alpine-docker) (`257M`) includes Docker 17.10 
- [alpine-docker-ucp](https://github.com/qnib/packer-files/tree/master/alpine-docker-ucp) (`567M`) holds the engine and preloaded UCP images
- [alpine-docker-dtr](https://github.com/qnib/packer-files/tree/master/alpine-docker-dtr) (`645M`) also holds the engine and the images needed to spin up DTR.

To download the images before hand, just fire up the following commands. It will download roughly 1.5GB, so make sure you stay hydrated, but once that is done you can disconnect from the internet.

```bash
$ vagrant box add qnib/alpine-docker http://qnib.org/down/virtualbox-alpine-docker-1710.box
$ vagrant box add qnib/alpine-docker-ucp http://qnib.org/down/virtualbox-alpine-docker-1710-ucp-2.2.3.box
$ vagrant box add qnib/alpine-docker-dtr http://qnib.org/down/virtualbox-alpine-docker-1710-dtr-2.3.3.box
```

As the images are based on `Alpine Linux` one needs to install the vagrant plugin to control those.

```bash
$ vagrant plugin install vagrant-alpine
```

## Spin 'em up

Ok, now let us spin up the images. The setup will start...

- a `UCP` VM called `ucp0`, which will provide the SWARM master and will hold all the UCP images
- a `DTR` VM caled `dtr0` (suprise!) running the image registry 
- and one worker node `node0`, which will just join the SWARM and start the `ucp_agent` to accept services.

First, download the repository and change directory.

```bash
$ git clone https://github.com/qnib/vagrant-orchestration.git
$ cd vagrant-orchestration/alpine-docker-datacenter
```

Next up, start the UCP node.

```bash
$ vagrant up ucp0
Bringing machine 'ucp0' up with 'virtualbox' provider...
==> ucp0: Importing base box 'qnib/alpine-docker-ucp'...
==> ucp0: Matching MAC address for NAT networking...
==> ucp0: Setting the name of the VM: alpine-docker-datacenter_ucp0_1509437047250_40404
*snip*
==> ucp0: Running provisioner: shell...
    ucp0: Running: inline script
==> ucp0: >>> ucp 192.168.100.20 false
==> ucp0: >> docker swarm init --advertise-addr=192.168.100.20
==> ucp0: Swarm initialized: current node (ffpwrj7zkl0t7y3gcv6ne6h34) is now a manager.
==> ucp0: To add a worker to this swarm, run the following command:
==> ucp0:
==> ucp0:     docker swarm join --token SWMTKN-1-5xz3xzza40m8wfieeivu8bo1fnek3msg2qb9m9q8q7fuqb91os-eqahw4cxhiq5zgsm7egw7503d 192.168.100.20:2377
==> ucp0:
==> ucp0: To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
==> ucp0: >> Dump tokens
==> ucp0: >> Install UCP
==> ucp0: docker run --rm --tty --name ucp -v /var/run/docker.sock:/var/run/docker.sock docker/ucp:2.2.3
==> ucp0:            install --host-address 192.168.100.20 --admin-username moby --admin-password moby1234
==> ucp0:            --force-insecure-tcp --swarm-port 2378 --controller-port 9443
==> ucp0: INFO[0000] Verifying your system is compatible with UCP 2.2.3 (b3f6755b6)
==> ucp0: INFO[0000] Your engine version 17.10.0-ce, build unsupported (4.9.32-0-hardened) is compatible
==> ucp0: INFO[0000] All required images are present
==> ucp0: WARN[0000] None of the hostnames we'll be using in the UCP certificates [ucp0 127.0.0.1 172.17.0.1 192.168.100.20] contain a domain component.  Your generated certs may fail TLS validation unless you only use one of these shortnames or IPs to connect.  You can use the --san flag to add more aliases
==> ucp0: INFO[0002] Establishing mutual Cluster Root CA with Swarm
==> ucp0: INFO[0005] Installing UCP with host address 192.168.100.20 - If this is incorrect, please specify an alternative address with the '--host-address' flag
==> ucp0: INFO[0005] Generating UCP Client Root CA
==> ucp0: INFO[0005] Deploying UCP Service
==> ucp0: INFO[0045] Installation completed on ucp0 (node ffpwrj7zkl0t7y3gcv6ne6h34)
==> ucp0: INFO[0045] UCP Instance ID: 6dgxm4io0cxv0q3k08wdeeutx
==> ucp0: INFO[0045] UCP Server SSL: SHA-256 Fingerprint=56:0C:C9:29:A8:A9:08:3C:7F:0C:06:E3:79:D2:92:65:89:F8:75:FC:63:1F:F6:DF:EC:8B:7F:8C:B8:86:85:88
==> ucp0: INFO[0045] Login to UCP at https://192.168.100.20:9443
==> ucp0: INFO[0045] Username: moby
==> ucp0: INFO[0045] Password: (your admin password)
$
```

That's it for UCP, you can go to [https://192.168.100.20:9443](https://192.168.100.20:9443) and login to UCP (moby/moby1234).

![](/pics/2017-10-31/ucp-init.gif)

In order to interact with the cluster, head to the user profile, create, download, extract and source a client-bundle. This will setup your environment with certs and such, so that you can use the cluster.

![](/pics/2017-10-31/ucp-cbundle.gif)

To explore all the features, go to [https://store.docker.com/editions/enterprise/docker-ee](https://store.docker.com/editions/enterprise/docker-ee) and get yourself a trial license. Otherwise you won't be able to push images to DTR, which is a little dull.

```bash
$ docker pull alpine:3.2
*snip*
$ docker tag alpine:3.2 192.168.100.30/moby/alpine:3.2
$ docker push !$
docker push 192.168.100.30/moby/alpine:3.2
The push refers to a repository [192.168.100.30/moby/alpine]
6bdcec7e93ad: Preparing
error parsing HTTP 402 response body: invalid character 'D' looking for beginning of value: "DTR doesn't have a license\n"
$
```

## Security Scanning

When the license is uploaded to UCP and DTR, the image can be pushed...

```bash
$ docker push 192.168.100.30/moby/alpine:3.2
The push refers to a repository [192.168.100.30/moby/alpine]
6bdcec7e93ad: Pushed
3.2: digest: sha256:3c9debbe7ed35ece3eb8bd62649aaf572377da71de94e7cd1ee0b51e93d26528 size: 528
```
... and scanned for vulnerabilities. Turns out the `alpine:3.2` version has some issues.

![](/pics/2017-10-31/ucp-dtr.gif)

## Explore

This setup should get you started with the `Docker Enterprise Edition`. Enjoy!

