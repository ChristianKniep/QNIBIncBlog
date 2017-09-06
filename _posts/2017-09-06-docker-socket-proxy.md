---
author: Christian Kniep
layout: post
title: "Doxy: A Docker Socket Proxy"
date: 2017-09-06
tags: eng blog docker
---

Talking to security engineers I was asked how to secure a docker-socket, so that applications like metrics collector, are only able to access a subset of API endpoints.

When looking into it I was looking into the authorisation plugins already out there, but it as far as I understood them, they are only working on TCP sockets and rely on an SSL certificate providing informations about who is accessing them. Recently I tried to create a plugin using the newest plugin system, but that failed to some extend. The plugin system is currently in a transition to be used within the plugin framework and not be directly started at startup.

To circumvent this and get something to work with, I created a little golang tool, that creates a `httputil.ReverseProxy`, providing a proxy-socket, checking the request against some regular expressions and forwards granted requests to the docker socket on the behalf of the user.

Meet [doxy](https://github.com/qnib/doxy):

```bash
bash-3.2$ go run main.go -h
NAME:
   Proxy Docker unix socket to filter out insecure, harmful requests. - doxy [options]

USAGE:
   main [global options] command [command options] [arguments...]

VERSION:
   0.1.2

COMMANDS:
     help, h  Shows a list of commands or help for one command

GLOBAL OPTIONS:
   --docker-socket value  Docker host to connect to. (default: "/var/run/docker.sock") [$DOXY_DOCKER_SOCKET]
   --proxy-socket value   Proxy socket to be created (default: "/tmp/doxy.sock") [$DOXY_PROXY_SOCKET]
   --debug                Print proxy requests [$DOXY_DEBUG]
   --pattern-file value   File holding line-separated regex-patterns to be allowed (comments allowed, use #) (default: "/etc/doxy.pattern") [$DOXY_PATTERN_FILE]
   --help, -h             show help
   --version, -v          print the version
```
It will grant access if the request uses the `GET` method and matches the following regular expressions:

```
$ cat doxy.pattern
# List, inspect, metrics and processes of containers
^/(v\d\.\d+/)?containers(/\w+)?/(json|stats|top)$
# List and inspect services
^/(v\d\.\d+/)?services(/[0-9a-f]+)?$
# List and inspect tasks
^/(v\d\.\d+/)?tasks(/\w+)?$
# List and inspect networks
^/(v\d\.\d+/)?networks(/\w+)?$
# List and inspect volumes
^/(v\d\.\d+/)?volumes(/\w+)?$
# List and inspect nodes
^/(v\d\.\d+/)?nodes(/\w+)?$
# Show engine info
^/(v\d\.\d+/)?info$
# Show engine version
^/(v\d\.\d+/)?version$
# Healthcheck
^/_ping$
# List and inspect images
^/(v\d\.\d+/)?images(/\w+)?$
```

Pretty straight forward, I recon:

```bash
$ go run main.go --pattern-file doxy.pattern
2017/09/06 20:07:53 [II] Start Version: 0.1.2
2017/09/06 20:07:53 [gk-soxy] Listening on /tmp/doxy.sock
2017/09/06 20:07:53 Serving proxy on '/tmp/doxy.sock'
```

Querying looks like this:

```bash
$ docker -H unix:///tmp/doxy.sock images |head -n5
REPOSITORY                                       TAG                                        IMAGE ID            CREATED             SIZE
qnib/alplain-gocd-agent                          17.9.0-1                                   992e1dfea220        24 hours ago        655MB
qnib/alplain-gocd-agent                          17.9.0                                     adc8c2d1e655        24 hours ago        655MB
qnib/alplain-openjre8                            3.6                                        a677b96cc6fa        24 hours ago        92.3MB
qnib/alplain-openjre8                            latest                                     a677b96cc6fa        24 hours ago        92.3MB
$ docker -H unix:///tmp/doxy.sock network ls
NETWORK ID          NAME                DRIVER              SCOPE
639821d71abc        bridge              bridge              local
```

While 'dangerous' queries are not allowed anymore:

```bash
$ docker -H unix:///tmp/doxy.sock network create --driver overlay test
Error response from daemon: Only GET requests are allowed, req.Method: POST
$
```

If one want to get more information on the request I use negroni to allow for middleware to be plugged in:

```bash
$ go run main.go --pattern-file doxy.pattern -debug
2017/09/06 20:11:54 [II] Start Version: 0.1.2
2017/09/06 20:11:54 [gk-soxy] Listening on /tmp/doxy.sock
2017/09/06 20:11:54 Serving proxy on '/tmp/doxy.sock'
[negroni] 2017-09-06T20:11:58+02:00 | 200 |  2.726445ms | docker | GET /_ping
[negroni] 2017-09-06T20:11:58+02:00 | 200 |  3.61883ms | docker | GET /v1.31/networks
[negroni] 2017-09-06T20:12:01+02:00 | 200 |  2.572848ms | docker | GET /_ping
[negroni] 2017-09-06T20:12:01+02:00 | 400 |  17.906µs | docker | POST /v1.31/networks/create
[negroni] 2017-09-06T20:12:05+02:00 | 200 |  7.21227ms | docker | GET /_ping
[negroni] 2017-09-06T20:12:05+02:00 | 200 |  142.321713ms | docker | GET /v1.31/images/json
```

That is basically it, I expect this to be retired some day in the future by more flexible auth-plugins, but for the time being...
