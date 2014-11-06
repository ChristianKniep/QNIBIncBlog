---
layout: post
title:  "Parse your apache2 logs with qnib/elk"
date:   2014-10-29 22:00
categories: qnibterminal 
tags: qnibterminal cluster docker blog
---

If you are looking for an excuse to use logstash your local webserver is low hanging fruit.

Someone accesses your website and your web server will store some details about the visit:

{% highlight bash %}
10.10.0.1 - - [29/Oct/2014:18:42:18 +0100] "GET / HTTP/1.1" 200 2740 "-" "Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B411 Safari/600.1.4"
10.10.0.1 - - [29/Oct/2014:18:42:19 +0100] "GET /css/main.css HTTP/1.1" 200 2805 "http://qnib.org/" "Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B411 Safari/600.1.4"
10.10.0.1 - - [29/Oct/2014:18:42:19 +0100] "GET /pics/second_strike_trans.png HTTP/1.1" 200 29636 "http://qnib.org/" "Mozilla/5.0 (iPhone; CPU iPhone OS 8_1 like Mac OS X) AppleWebKit/600.1.4 (KHTML, like Gecko) Version/8.0 Mobile/12B411 Safari/600.1.4"
{% endhighlight %}

Within the lines one fetches information about the IP address (hence, location), the browser, device, return codes, bytes send and alike.

I use my [Docker Image][elk_image], which could be fetched from the official repository or you build it yourself.
Lets fetch'em:

{% highlight bash %}
docker pull qnib/elk
{% endhighlight %}

As the [website][elk_image] suggest one has to setup some variables to configure the containers:

{% highlight bash %}
# To get all the /dev/* devices needed for sshd and alike:
export DEV_MOUNTS="-v /dev/null:/dev/null -v /dev/urandom:/dev/urandom -v /dev/random:/dev/random"
export DEV_MOUNTS="${DEV_MOUNTS} -v /dev/full:/dev/full -v /dev/zero:/dev/zero"
### OPTIONAL -> To use a mapped in configuration directory
# if not used, the default will be used within the container
export LS_CONF="-v ${HOME}/logstash.d/:/etc/logstash/conf.d/"
### OPTIONAL -> map apache2 config into container
export AP_LOG="-v /var/log/apache2/:/var/log/apache2"
export HTTP_PORT="-e HTTPPORT=8080 -p 8080:80"
{% endhighlight %}

For the extra amount of fun, export HTUSER (and HTPASSWD) kibana is going to be password protected.

{% highlight bash %}
export HTUSER=kibana
export HTPASSWD=secretpw
{% endhighlight %}

Starting the container looks like this:

{% highlight bash %}
docker run -d -h elk --name kniep_elk --privileged \
    ${DNS_STUFF} ${DEV_MOUNTS} ${LINK} \
    ${HTTP_PORT} ${LS_CONF} ${AP_LOG} \
    -e HTUSER=${HTUSER} -e HTPASSWD=${HTPASSWD} \
    ${ES_PERSIST} qnib/elk:latest
{% endhighlight %}

After a little while kibana should be accessible surfing to the location ```http://YOUR_DOCKER_SERVER:8088/kibana/#/dashboard/file/apache_dash.json```

![](/pics/2014-10-29/screen_kibana_default.png "Graph showing the default kibana dashboard")

The filters are applied to my domain. They should be adjusted as needed.


[elk_image]:  https://registry.hub.docker.com/u/qnib/elk/
