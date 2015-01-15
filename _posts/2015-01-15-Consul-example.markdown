---
layout: post
title:  "Consul, the corner stone service to rule them all"
d/ate:   2015-01-15
tags: eng blog qnibterminal
---

I started to write [an article about enhancements within my analytics stack](/2015/01/15/Grafana-analytic-stack/) (elk/graphite) and got a little bit verbose about consul.
Therefore I decided to put it into a seperate article...
 
## Consul

I had ```consul``` on my list for some time, but it was just recently that I gave it a spin. And I must admit I am
hooked. It provides a nice set of functionalities that I need to bootstrap...

Let's give a quick ride by starting two containers: server and client

{% highlight bash %}
$ docker run -ti --rm -e PS1="\h$ " -h server --name server -p 8500:8500 qnib/consul bash
server$
{% endhighlight %}
Within a second terminal a spin up the client.
{% highlight bash %}
$ docker run -ti --rm -e PS1="\h$ " -h client --name client qnib/consul bash
client$
{% endhighlight %}

The server starts a consul agent in server mode.
{% highlight bash %}
server$ mkdir -p /tmp/consul.d/
server$ consul agent -server -data-dir /var/consul/ -config-dir=/tmp/consul.d/ \
                     -ui-dir /opt/consul-web-ui/ -bootstrap-expect=1 -client=0.0.0.0
==> WARNING: It is highly recommended to set GOMAXPROCS higher than 1
==> Starting Consul agent...
==> Starting Consul agent RPC...
==> Consul agent running!
{% endhighlight %}

By doing so, it present a nice UI worth checking out  (Port 8500 [boot2docker](http://192.168.59.103:8500), [localhost](http://127.0.0.1:8500)).

![](/pics/2015-01-15/consul_init_services.png)

List of nodes:

![](/pics/2015-01-15/consul_init_nodes.png)

And that's what is shown by default. Each consul agent reports it's own health status. But there is more...
Consul provides a DNS server by default:
{% highlight bash %}
server$ dig @127.0.0.1 -p 8600 server.node.consul. ANY +short
172.17.0.14
{% endhighlight %}

Furthermore customized service checks are in close proximity. A service check is as easy as a little JSON blob.

{% highlight bash %}
server$ cat << \EOF > /tmp/consul.d/check_srv01.json
{
  "service": {
    "name": "srv01",
    "port": 5000,
    "check": {
      "script": "test -f /var/log/lastlog",
      "interval": "10s"
    }
  }
}
EOF
server$ rm -rf /var/consul/*
server$ consul agent -server -data-dir /var/consul/ -config-dir=/tmp/consul.d/ \
                     -ui-dir /opt/consul-web-ui/ -bootstrap-expect=1 -client=0.0.0.0
{% endhighlight %}

Now a new service is available:

![](/pics/2015-01-15/consul_srv01.png)

The service is even available as a SRV entry within DNS. Based on the health check it is only exposed, if healthy.

{% highlight bash %}
server$ dig @127.0.0.1 -p 8600 srv01.service.consul. ANY +short
172.17.0.14
{% endhighlight %}

### Consul Client

By throwing in an additional consul agent a client join the server.

{% highlight bash %}
client$ consul agent -config-dir=/tmp/consul.d/ -join=${SERVER_PORT_8500_TCP_ADDR}
{% endhighlight %}

Now the UI has a new member...

![](/pics/2015-01-15/consul_client.png)

### The Untouched

And I haven't touched the Key/Value store, which should behave like etcd. Put something in and everyone else can fetch it, wait for changes and such.
Even better, consul is able to put restrictions on all of the endpoints. Security FTW!

This Key/Value store is compatible with confd, so no problem on that side either.

Since I have not used it, this part has to wait to be explored and put into an article. To be continued...
