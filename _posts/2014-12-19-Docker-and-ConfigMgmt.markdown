---
layout: post
title:  "Containerization eats Configuration Management?"
subtitle: "Thought about Docker and Ansible"
date:   2014-12-19
tags: eng ansible docker blog talk
---

Last week I was invited to introduce Docker at the [Hamburg Ansible-Meetup](http://www.meetup.com/Ansible-Hamburg/) and kick of some thoughts about the intersection with Configuration Management.

The presentation could be found below, the introduction part should be known by now. I would like to dive a little bit deeper into how this might change Configuration Management.

<iframe src="//www.slideshare.net/slideshow/embed_code/42731103" width="425" height="355" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/QnibSolutions/ansible-docker" title="Ansible docker" target="_blank">Ansible docker</a> </strong> from <strong><a href="//www.slideshare.net/QnibSolutions" target="_blank">QNIB Solutions</a></strong> </div>

## Disclaimer

This topic is not settled stuff as far as I am concerned. So please take this article with a grain (or a pound) of salt.
I might add a comment section underneath, as to provide a way to rant about my assumptions.

If you can't help yourself, feel free to throw feedback at my twitter handle: [@cqnib](http://twitter.com/cqnib)... :)

## Configuration Management 

Let us first talk about what Configuration Management's 'Jobs-to-be-done' ([JTBD-Theory](http://jobstobedone.org/)) actually are.
Besides making the complete process of tempering with infrastructure more robust by providing a systems which does the
heavy lifting and only consumes a higher level configuration, one might break it down like this:

#### Provisioning (optional)

This might be out of scope for some ConfigMgmt systems but I worked for quite some time with one that took
care of bootstrap systems by pressing a button, which was pretty cool stuff to do. It was even bundled with a
given switch-port. Thus, if a node dies in a rack, it was thrown in the trash and a new node - connected via the same cable -
was automatically treated to become the successor.
    
But let me not get to far away, this point might simply be a usb-key, bootstrapping a box.

#### Customize Individually (fundamental)

First thing that I am not going to chicken out from is that a host has to be configured. Set up ssh-keys, install certain packages, create users, groups, shares, <you name it>
Within a small installation this might be even the only thing someone hires Configuration Management to do. And rightfully so.

Ansible for instance is perfectly fitting this role, since it is easy as a pie...

#### Orchestrate Globally (for advanced cases)

If one has to set up more then one system it begins to become more interlocked. The &lt;XYZ>-Server has to be configured within all clients and
one hesitates to hard-code this information. Thus, one needs some kind of inventory to keep track.
One might use some fancy tool like [consul](https://consul.io/) or etcd-bound DNS services ([skydns](https://github.com/skynetservices/skydns), [consul vs.skydns](http://www.consul.io/intro/vs/skydns.html)) to be able to discover this dynamically, but still.

That is the kind of situations in which ConfigMgmt comes to the rescue, because it just sets up the server, so the information is available.
Moreover the ConfigMgmt should be aware of the big picture.

#### Descriptiveness and Idempotency

Working on behalf of customers that want to build cars and not deal with all the IT stuff by them self, it came down to
deterministic trouble shooting. First and foremost to reduce friendly fire in which someone's bash script went ballistic.

The nice feature of ConfigMgmt (in most cases) is that it is descriptive and idempotent.

- descriptive

    One *describes* the state in which the system should be and not all the steps to go there.
    Thus, if a new user has to be added, the end-state is changed and the methods(,functions,modules) are fired up to go
    out there and do what the master wants them to do. No matter if it is Windows,Linux or MacOSX.
    
- idempotent

    More over a system should not be broken by a method running a second time. In this case the state should not be changed.
    Ideally the state should be checked non-inversively. To provide a simple case:
    Adding a user should not work like this ```useradd myuser```, but along this lines ```id user >/dev/null 2>&1 && useradd user```.
    Thus, if the user already existed the useradd command is not executed. Granted, that in this case far more could go wrong, but you got the idea.

## That said, what am I talking about? 

Now that I described what Configuration Management means to me, what is the big deal now?

Back in the old days, I was a big fan of assembling building blocks. A bootstrapped server got a series of configuration methods
thrown in his direction until he reaches the state he was expected to have. In cases in which the cat hits the fan, we would bootstrap the server
and start again.

#### Image creation is the new bootstrap configuration

In the new, shiny world of containers the server is hardly an Linux distribution but more or less a firmware to run containers on top.
CoreOS, RedHat Atomic, the AMI you spin up to host Containers within EC2, all of that sort is left mostly untouched.

And Docker just launched **Docker Machine** which aims to provide a provisioning tool. Just point in the right direction and it will jump-start a target.

This means that the core competency everyone was looking for is now gone, ain't it? Customizing services and stuff on a given docker target comes
down to start the desired service images and that's it.

#### Orchestration is the big thing left

It's more an orchestration now and this is where the big meat is going to be. And the systems throwing their hat into the
ring to take over this task are queuing up already. 
IMHO it's because Docker has gained so much momentum and speed; everyone is afraid to miss the party, which disrupts his buisness model.

We got (as it pops into my head, not complete nor ordered):

- **Mesos** Claims to be the kernel of your data-center. Abstracts the complete thing, you just schedule your task. To me it sounds like a resource scheduler like SLURM that expands his territory.
- **Kubernetes** Google's way of orchestration. You define a scenario and it will take care of the ugly rest.
- Amazon **EC2 Container Service**. AWS broken down to containers instead of VM instances.
- **Google Container Engine** sounds quite familiar to the one above, it might even uses Kubernetes to provide it.
- **Docker Swarm**, which accumulates up multiple docker hosts to one and **Docker Composer**, which provides the accumulation of containers to an application stack.

And I am not even talking about all the Configuration Management tools. It is going to be hard to find one, which not provides some
kind of orchestration for containers.


#### Keep ConfigMgmt to build Images?

OK, it might be tempting to keep your ConfigMgmt tool to create the Docker Image, but I do not see myself providing an image for ```ComplexService``` using a Dockerfile like this:

{% highlight bash %}
FROM ubuntu:14.04

MAINTAINER Christian Kniep

RUN apt-get install -y python-ansible
WORKDIR /data/
ADD . /data/
RUN ansible-playbook <xyz> complex-service.yml
CMD complex_service --foreground
{% endhighlight %}

This would screw the concept of having multiple steps to inherit from and provide multiple family trees of Images with multiple tags.

#### Immutable Infrastructure

I rather would like to work with immutable infrastructure. Meaning, that if you feel the need to change something inside of 
the container, you rather change the image used, spin up a new one, move the traffic and kick the old. Thus your workflow
is most likely quite robust. You do not fiddle around and create technical debt, because the next SysAdmin did not know about a change
you did within the service container. Sure, this does not suite every scenario; one needs uncoupled micro-services for this; but we might get there.


#### Verification of Configuration

Some ConfigMgmt tools are providing compliance reports, a history of changes and a way to verify the configuration. Early this year I got to know a founder of [Rudder](http://www.rudder-project.org/), which does this pretty good.
I suppose that the management type of person likes this feature, because you can create charts for the upper-management out of it. :)

Question is, how fain grained this is going to be needed in the future...

#### Verdict

Since my train ride comes to an end... What's the gist of this article?

IMHO Configuration Management might become a niche. As hard as it sounds.

- Bootstrap systems to become a container host is a fairly simple task, someone has to provide this.

- Services are composed within Dockerfiles, no need for a configuration management there.

- What's left in customization seems to be done by providing environment variables that controlling the internal behavior of a container.

- Verification of current states might sounds like an additional Nagios check of some sort. If the check implies bad configuration, why bother with fixing it? Just spin up a twin and kill the old.

To me this is the most thrilling shift I experienced so far. Not only is it promising to abstract most of the boring stuff and create a robust environment to
build cool stuff; there is also going to be a big open fight as of what is the best case for different use cases.
Heck, even Docker containers are not without recent competition: [rocket](https://coreos.com/blog/rocket/)

And whether the old buddies within the container sphere, like OpenVZ, BSD Jails and alike are answering the rise of the newcomers with something fancy for some use cases has to be seen as well.

In the meantime I will look into as much cool tools as possible, but I won't attach myself to much. Maybe the love will be disrupted and we all know that dumping someone or being dumped hurts.
Let them fight in 2015 and everyone can decide which tool fits best for the individual use-case.