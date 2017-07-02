---
author: Christian Kniep
layout: post
title: "Byfahrer: Terminate SSL for Docker SWARM"
date: 2017-06-02
tags: eng blog docker
---

I like the idea and prospect of having only the plain Docker stack running, as it provides a nice experience from development to operations (I am talking about you: DevOps!). I can start with a single container, create a set of (unreplicated) services and try to make it work in a distributed setup - all on my little laptop and stay confident that it will work on a cluster as well.

But, what I am envy in the Kubernetes ecosystem is that they still have shared namespaces for services. It was there once, back in the days of good-old swarm-mode, which was 'just' a API proxy in front of multiple engines.

It is not impossible to implement the notion of PODs within SwarmKit though. For now a SWARM service is broken down into tasks, which are containers running on a SWARM worker. If this tasks would comprise of multiple containers, they could share namespaces. But I reckon, that if Docker goes down the route - it is never going to put this genie back into the bottle.  I opened an issue ([docker/swarmkit/issues/2291](https://github.com/docker/swarmkit/issues/2291)), but I do not have high hopes for it to be fixed soon:

![](/pics/2017-07-02/github_issue.png)

## Sidecar Proxy `gosslterm`

The pain stems from the fact, that a container should be limited in scope and do one thing efficiently. That excludes (most of the times) to provide authentication and authorisation, which might be done via SSL certificates.
Sharing namespaces allows for simple services to bind to `127.0.0.1`, not caring about anything else then delivering value. A separat container jumps into the same namespace and proxies the service using SSL. Maybe even logging, tracing and all of that.

As I like to tinker, I created a little proxy container, which I called [gosslterm](https://github.com/qnib/gosslterm).

To show a little example, I start a container providing a webservice:

```bash
$ docker run --rm --name www -ti -p 8081:8081 -e SKIP_ENTRYPOINTS=true  qnib/plain-httpcheck
[II] qnib/init-plain script v0.4.28
> execute CMD 'go-httpcheck'
2017/07/02 14:04:22 Start serving on 0.0.0.0:8080
```

Please note, that the service provides it service on `:8080`, even though the container only exposes `:8081`. Therefore, nothing can be done.

```bash
$ curl "http://127.0.0.1:8080/pi"
curl: (7) Failed to connect to 127.0.0.1 port 8080: Connection refused
```
By starting a little proxy entering the network namespace of the previously started container...

```bash
$ docker run -ti --rm --network=container:www \
             -e GOSSLTERM_BACKEND_ADDR=127.0.0.1:8080 \
             -e GOSSLTERM_FRONTEND_ADDR=:8081 \
             qnib/gosslterm
2017/07/02 14:09:08 Load cert '/opt/qnib/ssl/cert.pem' and key '/opt/qnib/ssl/key.pem'
2017/07/02 14:09:08 Create http.Server on ':8081'
```

...the service becomes available.

```bash
$ curl --insecure "https://127.0.0.1:8081/pi"
Welcome: pi(9999)=3.141493
```

The proxy logs the forwarded request.

```bash
[negroni] 2017-07-02T14:09:18Z | 200 | 	 25.191458ms | 127.0.0.1:8081 | GET /pi
```

As well as the service itself.

```bash
request:+1|c app=go-httpcheck,endpoint=/pi,version=1.1.4
duration:23|ms app=go-httpcheck,endpoint=/pi,version=1.1.4
```

## Proxy as a service

To automate this bit, I created (yet another) tool ([qnib/go-byfahrer](https://github.com/qnib/go-byfahrer)) based on my [qframe ETL framework](https://github.com/qnib/qframe). I employ the [docker-events collector](https://github.com/qnib/qframe-collector-docker-events), which provides a stream of engine (and lately SWARM events) and use these events to spawn a proxy if needed.

```bash
$ docker run -ti --rm -v /var/run/docker.sock:/var/run/docker.sock qnib/byfahrer
2017/07/02 14:14:10 [II] Start Version: 0.0.0
2017/07/02 14:14:10 [II] Dispatch broadcast for Back, Data and Tick
2017/07/02 14:14:10.503568 [NOTICE]     go-byfahrer Name:go-byfahrer >> Start plugin v0.0.0
2017/07/02 14:14:10.504095 [NOTICE]   docker-events Name:docker-events >> Start docker-events collector v0.2.4
2017/07/02 14:14:10.652408 [  INFO]     go-byfahrer Name:go-byfahrer >> Connected to 'moby' / v'17.06.0-ce-rc5'
2017/07/02 14:14:10.777493 [  INFO]   docker-events Name:docker-events >> Connected to 'moby' / v'17.06.0-ce-rc5'
```
The agent looks for container declaring that they want to have a sidecar-proxy started using the container label `org.qnib.byfahrer.proxy-image`. 

```bash
$ docker run --rm --name www -ti -p 8081:8081 \
                  --label org.qnib.byfahrer.proxy-image=qnib/gosslterm qnib/plain-httpcheck
[II] qnib/init-plain script v0.4.28
> execute entrypoint '/opt/entry/00-logging.sh'
> execute entrypoint '/opt/entry/10-docker-secrets.env'
[II] No /run/secrets directory, skip step
> execute entrypoint '/opt/entry/99-remove-healthcheck-force.sh'
> execute CMD 'go-httpcheck'
2017/07/02 14:15:40 Start serving on 0.0.0.0:8080
```
If present, `byfahrer` will spawn a container into the network namespace using the image described.

```bash
*snip*[  INFO]     go-byfahrer Name:go-byfahrer >> Use org.qnib.byfahrer.proxy-image=qnib/gosslterm to start proxy
*snip*[  INFO]     go-byfahrer Name:go-byfahrer >> Create proxy container 'www-proxy' for 'www'
```

Hence, the service is now available via SSL.

```bash
$ curl --insecure "https://127.0.0.1:8081/pi"
Welcome: pi(9999)=3.141493
```

## Conclusion

Even though I would like to have this specifically defined within the `docker-compose` file, so that I do not rely on a hidden service, which provides a sidecar - it might help carry the problem along.
The projects is not yet finished, as it does not handle all errors and (more importantly) it does not kill the proxy once the service to proxy had died. :)

A start...