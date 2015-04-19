---
author: Christian Kniep
layout: post
title: "Logstash zeromq plugin bugfix"
date: 2015-04-19
tags: eng logstash blog
---

The `zeromq` filter within logstash 1.4 is not working out as expected for me. I opened an [issue on github](https://github.com/logstash-plugins/logstash-filter-zeromq/issues/2) to cope with that. For now I work around this issue by starting `logstash 1.3` as a separate instance and let this version deal with zeromq.

## Come again?!

For those of you asking *WTF?*... :)
ZeroMQ is a message library that provides multiple patterns like PUB/SUB, PUSH/PULL and others. I got a use-case in which I want specific log events to be handled outside of logstash. And more outside then firing up the [ruby](http://logstash.net/docs/1.4.2/filters/ruby) filter. I want to process the event within a external daemon to check some things, update the JSON with additional information (lookup names, routes or alike) and after I am done I push it back into the logstash pipeline.

## Bugfixed proposed

There is a bugfix provided by [barravi](https://github.com/barravi/logstash-filter-zeromq) which I am going to try out. Since I do not have a ruby or java strong suit in my closet, I figured I should blog about my experience first hand. :)

## Set up the development environment

Since I like docker I created a branch which provides a docker file to spin up a fresh dev environment. To use it; just build and run it.

{% highlight bash %}
$ git clone -b docker_dev https://github.com/qnib/logstash.git
$ cd logstash
$ fig build
$ fig up -d
{% endhighlight %}


## Show error scenario

To verify that the problem still exists, I will reproduce the error. I connect to the host, and setup a small `zmq` test server.

{% highlight bash %}
$ docker exec -ti logstash_logstash_1 bash
container $ cat << \EOF > /tmp/server.py
import zmq
context = zmq.Context()
consumer_receiver = context.socket(zmq.REP)
consumer_receiver.bind("tcp://0.0.0.0:5557")
while True:
    work = consumer_receiver.recv_json()
    print work
    consumer_receiver.send_json(work)
EOF
container $ python /tmp/server.py &
{% endhighlight %}

The logstash config used is pretty basic. `Stdin` piped through `zeromq` and pushed out via `stdout`.

{% highlight bash %}
container $ cat << \EOF > /tmp/all.config
input {
    stdin {}
}

filter {
   zeromq {
        address => "tcp://localhost:5557"
   }
}

output {
    stdout {}
}
EOF
{% endhighlight %}

If this is fired up with the installed logstash version it comes down to this:

{% highlight bash %}
container $ /opt/logstash/bin/logstash -f /tmp/all.config
Using milestone 1 filter plugin 'zeromq'. This plugin should work, but would benefit from use by folks like you. Please let us know if you find bugs or have suggestions on how to improve this plugin.  For more information on plugin milestones, see http://logstash.net/docs/1.4.2-modified/plugin-milestones {:level=>:warn}
Test
{u'host': u'0e6a6256aae8', u'message': u'Test', u'@version': u'1', u'@timestamp': u'2015-04-19T09:41:46.474Z'}
0mq filter exception {:address=>"tcp://localhost:5557", :exception=>#<NoMethodError: undefined method `[]' for nil:NilClass>, :backtrace=>["/opt/logstash/lib/logstash/event.rb:163:in `overwrite'", "/opt/logstash/lib/logstash/filters/zeromq.rb:197:in `filter'", "(eval):23:in `initialize'", "org/jruby/RubyProc.java:271:in `call'", "/opt/logstash/lib/logstash/pipeline.rb:262:in `filter'", "/opt/logstash/lib/logstash/pipeline.rb:203:in `filterworker'", "/opt/logstash/lib/logstash/pipeline.rb:143:in `start_filters'"], :level=>:warn}
NoMethodError: undefined method `[]' for nil:NilClass
        sprintf at /opt/logstash/lib/logstash/event.rb:224
           gsub at org/jruby/RubyString.java:3041
        sprintf at /opt/logstash/lib/logstash/event.rb:216
           to_s at /opt/logstash/lib/logstash/event.rb:99
         encode at /opt/logstash/lib/logstash/codecs/line.rb:54
        receive at /opt/logstash/lib/logstash/outputs/stdout.rb:57
         handle at /opt/logstash/lib/logstash/outputs/base.rb:86
     initialize at (eval):35
           call at org/jruby/RubyProc.java:271
         output at /opt/logstash/lib/logstash/pipeline.rb:266
   outputworker at /opt/logstash/lib/logstash/pipeline.rb:225
  start_outputs at /opt/logstash/lib/logstash/pipeline.rb:152
{% endhighlight %}

## Test bugfix

Now I am going to fetch the bug fixed version of the filter, bootstrap my logstash branch and 
install the plugin.

{% highlight bash %}
container $ cd /opt
container $ git clone https://github.com/barravi/logstash-filter-zeromq.git
container $ cd /logstash/
container $ echo 'gem "logstash-filter-zeromq", :path => "/opt/logstash-filter-zeromq/"' >> Gemfile
container $ rake bootstrap
container $ bin/plugin install --no-verify
{% endhighlight %}

### Workaround (?)
Somehow I need to add some standard input/outputs and codecs to get it going...
I guess the libs are not in the right ruby path or something like that. Maybe it's even nicer this way, because I made sure not to use the default plugins.

{% highlight bash %}
container $ cp /opt/logstash/lib/logstash/inputs/stdin.rb lib/logstash/inputs/ 
container $ cp /opt/logstash/lib/logstash/outputs/stdout.rb lib/logstash/outputs/
container $ cp /opt/logstash/lib/logstash/codecs/{json.rb,line.rb,plain.rb,json_lines.rb} lib/logstash/codecs/
{% endhighlight %}

Run the thing:

{% highlight bash %}
container $ ./bin/logstash -f /tmp/all.config
*snip*
Logstash startup completed
Test
{u'host': u'0e6a6256aae8', u'message': u'Test', u'@version': u'1', u'@timestamp': u'2015-04-19T09:49:25.928Z'}
2015-04-19T09:49:25.928Z 0e6a6256aae8 Test
It works! Yeah!!
{u'host': u'0e6a6256aae8', u'message': u'It works! Yeah!!', u'@version': u'1', u'@timestamp': u'2015-04-19T09:49:33.925Z'}
2015-04-19T09:49:33.925Z 0e6a6256aae8 It works! Yeah!!
{% endhighlight %}

Nice, the error is gone. 
