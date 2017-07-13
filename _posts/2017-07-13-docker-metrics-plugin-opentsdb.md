---
author: Christian Kniep
layout: post
title: "OpenTSDB Docker Metrics Plugin"
date: 2017-07-13
tags: eng blog docker
---

Recently Docker released it 17.06 version of the Docker Engine ([Announcement](https://blog.docker.com/2017/06/announcing-docker-17-06-community-edition-ce/)) and in there is the new plugin type 'Metrics'.

The example they provide just copies over the internal Prometheus unix socket to an external HTTP endpoint.

```golang
go func() {
			io.Copy(proxyConn, conn)
			conn.(*net.TCPConn).CloseRead()
			proxyConn.(*net.UnixConn).CloseWrite()
		}()
		go func() {
			io.Copy(conn, proxyConn)
			proxyConn.(*net.UnixConn).CloseRead()
			conn.(*net.TCPConn).CloseWrite()
		}()
```

Let's give it a spin...

```bash
$ docker plugin install --grant-all-permissions cpuguy83/docker-metrics-plugin-test:latest
docker run -ti -e SKIP_ENTRYPOINTS=true --network host qnib/plain-elasticsearch bash
[II] qnib/init-plain script v0.4.27
> execute CMD as user 'elasticsearch'
elasticsearch@moby:/$ curl -s http://127.0.0.1:19393/metrics |head
# HELP builder_builds_failed_total Number of failed image builds
# TYPE builder_builds_failed_total counter
builder_builds_failed_total{reason="build_canceled"} 0
builder_builds_failed_total{reason="build_target_not_reachable_error"} 0
builder_builds_failed_total{reason="command_not_supported_error"} 0
builder_builds_failed_total{reason="dockerfile_empty_error"} 0
builder_builds_failed_total{reason="dockerfile_syntax_error"} 0
builder_builds_failed_total{reason="error_processing_commands_error"} 0
builder_builds_failed_total{reason="missing_onbuild_arguments_error"} 0
builder_builds_failed_total{reason="unknown_instruction_error"} 0
```

## OpenTSDB Metrics Plugin

I feel the vibe in Prometheus, but for some things I like the traditional push model more, as the endpoint does not know when a potential collector will scrape the endpoint.
Even though for the internal metrics this is not as important, but maybe some day container metrics will also be available. 

Anyhow, I created an OpenTSDB plugin: [qnib/docker-plugin-metrics-opentsdb](https://github.com/qnib/docker-plugin-metrics-opentsdb)

This plugin connects to the `metrics.sock` provided by the plugin system and transforms the metrics to OpenTSDB(v1) format, pushing it to a given endpoint.

### InfluxDB Stack

To be able to throw the metrics somewhere an InfluxDB stack with enable OpenTSDB endpoint will do.

```bash
$ cat docker-compose.yml
version: '3'
services:
  backend:
    image: qnib/plain-influxdb
    environment:
     - INFLUXDB_META_LOGGING=true
     - INFLUXDB_OPENTSDB_ENABLED=true
    ports:
     - 4242:4242
     - 8083:8083
     - 8086:8086

  frontend:
    image: qnib/plain-grafana4
    ports:
     - 3000:3000
    environment:
     - INFLUXDB_DB=opentsdb
     - INFLUXDB_HOST=tasks.backend
$ docker stack deploy -c docker-compose.yml influxdb
Creating service influxdb_backend
Creating service influxdb_frontend
$
```

### Install, configure and enable plugin

Now we install the plugin.

```bash
$ docker plugin install --disable --grant-all-permissions qnib/docker-plugin-metrics-opentsdb
latest: Pulling from qnib/docker-plugin-metrics-opentsdb
9b5a4c6dd405: Download complete
Digest: sha256:e80586adb32cedfb9e5c2a68ef61d96926f76f212d4659efd7c50eac42ee48c5
Status: Downloaded newer image for qnib/docker-plugin-metrics-opentsdb:latest
Installed plugin qnib/docker-plugin-metrics-opentsdb
$ docker plugin ls
ID                  NAME                                         DESCRIPTION                          ENABLED
4cf98db8588c        cpuguy83/docker-metrics-plugin-test:latest   prometheus collector plugin          true
c9ff581daaba        qnib/docker-plugin-metrics-opentsdb:latest   Plugin to push metrics to OpenTSDB   false
```
The configuration can tweak where the OpenTSDB endpoint is exposed.

```json
{
    "Env": [{
      "Description": "OpenTSDB host address to send metric to",
      "Name": "OPENTSDB_HOST",
      "Settable": ["value"],
      "Value": "127.0.0.1"
      },{
      "Description": "OpenTSDB port address to send metric to",
      "Name": "OPENTSDB_PORT",
      "Settable": ["value"],
      "Value": "4242"
    },{
      "Description": "Prints OpenTSDB strings to logs, instead of sending it off",
      "Name": "DRY_RUN",
      "Settable": ["value"],
      "Value": "false"
    }]
}
```

They are set via `docker plugin set qnib/docker-plugin-metrics-opentsdb:latest OPENTSDB_HOST=127.0.0.1` and the plugin is started using the `enable` subcommand.

```bash
$  docker plugin enable qnib/docker-plugin-metrics-opentsdb:latest
qnib/docker-plugin-metrics-opentsdb:latest
$ docker plugin ls
ID                  NAME                                         DESCRIPTION                          ENABLED
4cf98db8588c        cpuguy83/docker-metrics-plugin-test:latest   prometheus collector plugin          true
c9ff581daaba        qnib/docker-plugin-metrics-opentsdb:latest   Plugin to push metrics to OpenTSDB   true
$
```

## Grafana

Having Grafana in the `docker-compose.yml` stack, you can reach it under [localhost:3000](http://localhost:3000/dashboard/db/docker-engine) (admin/admin).

![](/pics/2017-07-13/grafana.png)

That's it for this post... Enjoy and feel free to suggest other plugins. :)