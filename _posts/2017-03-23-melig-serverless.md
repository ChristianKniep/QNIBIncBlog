---
author: Christian Kniep
layout: post
title: "M.E.L.I.G.: From VM to Unikernel and SOA to Serverless"
date: 2017-03-23
tags: eng melig blog
---

During the [latest MeetUp](https://www.meetup.com/M-E-L-I-G-Berlin-Metrics-Events-Logs-Inventory-Glue/events/238294391/) we talked about the rise of virtualization techniques and how software changed from clunky big services to state-less functions.

## Slides & Videos

<iframe src="//www.slideshare.net/slideshow/embed_code/key/vGuHkdLSzirLBb" width="595" height="485" frameborder="0" marginwidth="0" marginheight="0" scrolling="no" style="border:1px solid #CCC; border-width:1px; margin-bottom:5px; max-width: 100%;" allowfullscreen> </iframe> <div style="margin-bottom:5px"> <strong> <a href="//www.slideshare.net/QnibSolutions/melig-unikernel-and-serverless" title="M.E.L.I.G. Unikernel and Serverless" target="_blank">M.E.L.I.G. Unikernel and Serverless</a> </strong> from <strong><a target="_blank" href="//www.slideshare.net/QnibSolutions">QNIB Solutions</a></strong> </div>

The videos are split in three, as my Windows capturing box was rebooting twice. Furthermore I somewhat screwed up the ratio a bit, it's been a while.<br>
<b>The second one lacks the audio...</b> :( <br>

<iframe width="560" height="315" src="https://www.youtube.com/embed/Nnt0L8rN-iE" frameborder="0" allowfullscreen></iframe>
<iframe width="560" height="315" src="https://www.youtube.com/embed/jekqAIztHvg" frameborder="0" allowfullscreen></iframe>
<iframe width="560" height="315" src="https://www.youtube.com/embed/CfHVk7x8o_w" frameborder="0" allowfullscreen></iframe>

## Virtualization

While VMs and containers are all over the place I wanted to give an introduction to Unikernels. Which merges application code, libraries and the bits&pieces of the kernel needed into an 'application kernel'.
One project to make use of it is [Unik](https://github.com/emc-advanced-dev/unik). 

### Setup UniK

To install it on macOS, the following steps have to be done, as described here: [github.com/emc-advanced-dev/unik/blob/master/docs/install.md](https://github.com/emc-advanced-dev/unik/blob/master/docs/install.md)

{% highlight bash %}
$ git clone git@github.com:emc-advanced-dev/unik.git ~/src/github.com/emc-advanced-dev/unik
$ cd ~/src/github.com/emc-advanced-dev/unik
$ make
$ cp _build/unik /usr/local/bin                                                                                                                                                                                   
{% endhighlight %}

Afterwards open up VirtualBox and check on the `vboxnet0` adapter (under Preferences).

<table border="0">
	<tr>
		<th><img src="/pics/2017-03-23/vboxnet0_overview.png"/></th>
		<th><img src="/pics/2017-03-23/vboxnet0_adapter.png"/></th>
		<th><img src="/pics/2017-03-23/vboxnet0_dhcpd.png"/></th>
	</tr>
</table>

The unikernel will get IP addresses from the range of the DHCP server, the address of the adapter has to be in the same network as the range. 
Next up, configuration of the unik daemon:

{% highlight bash %}
$ mkdir $HOME/.unik
$ cat << \EOF > $HOME/.unik/daemon-config.yaml
providers:
  virtualbox:
    - name: my-vbox
      adapter_type: host_only
      adapter_name: vboxnet0
EOF
$
{% endhighlight %}

And start the daemon in one terminal window...

{% highlight bash %}
$ unik daemon
INFO[0000] daemon started                                config={Providers:{Aws:[] Gcloud:[] Vsphere:[] Virtualbox:[{Name:my-vbox AdapterName:vboxnet0 VirtualboxAdapterType:host_only}] Qemu:[] Photon:[] Xen:[] Openstack:[] Ukvm:[]} Version:}
*snip*
{% endhighlight %}

This compiles a little unikernel itself and starts it. After a little while we can open another tab and connect to the daemon.

{% highlight bash %}
$ unik target --host localhost
$ unik instances
INFO[0000] listing instances                             host=localhost:3000
NAME            ID                   INFRASTRUCTURE CREATED                        IMAGE                IPADDRESS       STATE
VboxUnikInstanc 265604ea-40a6-4183-9 VIRTUALBOX     2017-03-23 15:45:04.317971783  VboxUnikInstanceList 192.168.100.101 running
{% endhighlight %}

### Create First Unikernel
So far, so good, but let's create our own little unikernel following the little example: [emc-advanced-dev/unik/blob/master/docs/getting_started.md](https://github.com/emc-advanced-dev/unik/blob/master/docs/getting_started.md#write-a-go-http-server)

{% highlight bash %}
$ git clone git@github.com:qnib/unik-http.git ~/src/github.com/qnib/unik-http/
$ cd ~/src/github.com/qnib/unik-http/
$ unik build --name httpImage --path ./ --base rump --language go --provider virtualbox
INFO[0000] running unik build                            args= base=rump force=false host=localhost:3000 language=go mountPoints=[] name=httpImage path=./ provider=virtualbox
INFO[0000] App packaged as tarball: /var/folders/4x/s7z45gq93y5cq1cyccjbzw3h0000gn/T/sources.tar.gz.892223842

NAME                 ID                   INFRASTRUCTURE  CREATED                        SIZE(MB) MOUNTPOINTS
httpImage            httpImage            VIRTUALBOX      2017-03-23 15:50:12.887106166  39
$
{% endhighlight %}

Now we start the unikernel...

{% highlight bash %}
$ unik run --instanceName httpInstance --imageName httpImage
INFO[0000] running unik run                              env=map[] host=localhost:3000 imageName=httpImage instanceName=httpInstance mounts=map[]
NAME            ID                   INFRASTRUCTURE CREATED                        IMAGE                IPADDRESS       STATE
httpInstance    919ffb07-3788-4159-9 VIRTUALBOX     2017-03-23 15:59:57.960772954  httpImage                            pending
$ sleep 30 ; curl -s http://192.168.100.102:8080
my first unikernel!
{% endhighlight %}

Et voila...

## Function-as-a-Service (FaaS)

The second outcome is somehow related, but not necessarily. Lately serverless, function-as-a-service caught my interest...

This new paradigm breaks down microservices into single functions, without the need of an actual service anymore - it's just the function which is scheduled and load-balanced by some framework.
In the case of FaaS ([github.com/alexellis/faas](https://github.com/alexellis/faas/)) Docker Services are used to scale up and a golang watchdog just schedules a binary over and over again.

Since it runs on SWARM, it's pretty hassle-free to set up:

{% highlight bash %}
$ git clone git@github.com:alexellis/faas.git ~/src/github.com/alexellis/faas/
Cloning into '/Users/kniepbert/src/github.com/alexellis/faas'...
remote: Counting objects: 997, done.
remote: Compressing objects: 100% (139/139), done.
remote: Total 997 (delta 66), reused 0 (delta 0), pack-reused 853
Receiving objects: 100% (997/997), 1.55 MiB | 1.24 MiB/s, done.
Resolving deltas: 100% (515/515), done.
Checking connectivity... done.
$ ./deploy_stack.sh
Deploying stack
Creating service func_hubstats
Creating service func_alertmanager
Creating service func_wordcount
Creating service func_gateway
Creating service func_alexacolorchange
Creating service func_nodeinfo
Creating service func_echoit
Creating service func_base64
Creating service func_markdown
Creating service func_prometheus
Creating service func_decodebase64
Creating service func_webhookstash
$
{% endhighlight %}

This creates a bunch of exemplary functions (as docker services). Once every docker image is downloaded and started...

{% highlight bash %}
$ docker service ls
ID            NAME                   MODE        REPLICAS  IMAGE
25m7f8sz72fl  func_prometheus        replicated  1/1       quay.io/prometheus/prometheus:latest
2wev4d40mfxp  func_nodeinfo          replicated  1/1       alexellis2/faas-nodeinfo:latest
749jiszgx2t2  func_gateway           replicated  1/1       alexellis2/faas-gateway:latest
7subbjju3oc2  func_alexacolorchange  replicated  1/1       alexellis2/faas-alexachangecolorintent:latest
atqkvvfm6ek5  func_hubstats          replicated  1/1       alexellis2/faas-dockerhubstats:latest
lwp6xe4s8z76  func_echoit            replicated  1/1       alexellis2/faas-alpinefunction:latest
m9dxiljg51mf  func_decodebase64      replicated  1/1       alexellis2/faas-alpinefunction:latest
n5bnq69ffxdf  func_markdown          replicated  1/1       alexellis2/faas-markdownrender:latest
ptm6wfn2roov  func_base64            replicated  1/1       alexellis2/faas-alpinefunction:latest
qtsom1nqqpl8  func_webhookstash      replicated  1/1       alexellis2/faas-webhookstash:latest
tyeeksxdyxpq  func_alertmanager      replicated  1/1       quay.io/prometheus/alertmanager:latest
xgv1gpso6fot  func_wordcount         replicated  1/1       alexellis2/faas-alpinefunction:latest
$
{% endhighlight %}

... it is time to check it out. Open the dashboard ([localhost:8080](http://localhost:8080/)).

![](/pics/2017-03-23/faas_dash.png)

A function can be invoked via the WebUI.

![](/pics/2017-03-23/faas_hubstats.png)

Or using the bash...

{% highlight bash %}
$ curl --data qnib http://localhost:8080/function/func_hubstats
The organisation or user qnib has 228 repositories on the Docker hub.
$
{% endhighlight %}

What I dislike here is that the containers are not trashed and rescheduled after use.

## Fission (FaaS for Kubernetes)

I am not that much of a Kubernetes guy, but I have to admit that the fission project might convince me otherwise.

### Install Minikube
Not unlike OpenStack, when I first encountered kubernetes it was hard to set it up locally. And on a normal host there were a lot of moving parts to consider.
This times are gone, welcome minikube...

{% highlight bash %}
$ curl -sLO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/darwin/amd64/kubectl
$ chmod +x kubectl
$ mv kubectl /usr/local/bin
$ curl -Lo minikube https://storage.googleapis.com/minikube/releases/v0.17.1/minikube-darwin-amd64 
$ chmod +x minikube
$ mv minikube /usr/local/bin/
{% endhighlight %}

### Deploy Fission

{% highlight bash %}
$ minikube start
Starting local Kubernetes cluster...
Starting VM...
Downloading Minikube ISO
 89.24 MB / 89.24 MB [==============================================] 100.00% 0s
SSH-ing files into VM...
Setting up certs...
Starting cluster components...
Connecting to cluster...
Setting up kubeconfig...
Kubectl is now configured to use the cluster.
$ kubectl create -f http://fission.io/fission.yaml
namespace "fission" created
namespace "fission-function" created
deployment "controller" created
deployment "router" created
service "poolmgr" created
deployment "poolmgr" created
deployment "kubewatcher" created
service "etcd" created
deployment "etcd" created
$ kubectl create -f http://fission.io/fission-nodeport.yaml
service "router" created
service "controller" created
$ export FISSION_URL=http://$(minikube ip):31313
$ export FISSION_ROUTER=$(minikube ip):31314
$ curl -s http://fission.io/mac/fission > fission
$ chmod +x fission
$ mv fission /usr/local/bin/
{% endhighlight %}

### Create example

Let us go through the little example...

{% highlight bash %}
$ fission env create --name nodejs --image fission/node-env
$ cat << \EOF > hello.js
module.exports = async function(context) {
    return {
        status: 200,
        body: 'Your body here\n'
    };
}
EOF
$ fission function create --name hellojs --env nodejs --code hello.js
$ fission route create --method GET --url /hellojs --function hellojs
$ curl http://$FISSION_ROUTER/hellojs
Your body here
$ 
{% endhighlight %}

### Spin up Kubernetes

{% highlight bash %}
$ git clone https://github.com/marselester/prometheus-on-kubernetes.git ~/src/github.com/marselester/prometheus-on-kubernetes
Cloning into '/Users/kniepbert/src/github.com/marselester/prometheus-on-kubernetes'...
remote: Counting objects: 56, done.
remote: Total 56 (delta 0), reused 0 (delta 0), pack-reused 56
Unpacking objects: 100% (56/56), done.
Checking connectivity... done.
$ cd ~/src/github.com/marselester/prometheus-on-kubernetes
$ kubectl create -f kube/prometheus/deployment-v1.yml
deployment "prometheus-deployment" created
$ kubectl expose deployment prometheus-deployment --type=NodePort --name=prometheus-service
service "prometheus-service" exposed
$ kubectl describe service prometheus-service
Name:			prometheus-service
Namespace:		default
Labels:			app=prometheus-server
Selector:		app=prometheus-server
Type:			NodePort
IP:			10.0.0.102
Port:			<unset>	9090/TCP
NodePort:		<unset>	32241/TCP
Endpoints:		172.17.0.12:9090
Session Affinity:	None
No events.
$ open http://$(minikube ip):32241
{% endhighlight %}

# Conclusion

This new approaches starting to boggle my mind. 

We had a nice discussion about what one might gain and my argument was:

**Optimize Mixed Workloads**

When a heterogenous workload is what your users are putting upon your shoulders (like AWS experiences), functions can help fill the unused gaps and provide more utilization.

**Iteration Speed and Reproducibility**

As the function is stateless, it can be updated on the spot, without the need for an actual update-path. And each execution is completely the same - without any side-effects.

So far... thanks everyone for attending - always a pleasure...