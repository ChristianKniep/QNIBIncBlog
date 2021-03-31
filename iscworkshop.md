---
layout: page
title: ISC HPCW
permalink: /isc/
---

The **H**igh **P**erformance **C**ontainer **W**orkshop series assembles thought leaders to provide the 'state of containers' and the latest trends.

# Virtual HPCW 2021

As ISC2021 moved to a virtual event, we went virtual as well pre-recording a stream of information. At the time of the workshop we elease the videos on youtube.

### Communication
To get in touch (even before the workshop) please use the `#hpcw` channel within [hpc-containers.slack.com](https://hpc-containers.slack.com) ([Invitation Link if you are not registered already](https://join.slack.com/t/hpc-containers/shared_invite/zt-ak9q6jw7-UZgpv7IJua5jCtJ_db_yAQ)) for communication.

## Agenda

Last year we dove deep into each aspect (runtime, build, distribute, schedule, HPC specifics, outlook) in three sittings.
We highly recommend going through the youtube recordings. They can be found in last years post: [qnib.org/2020/06/17/isc2020-hpcw](https://qnib.org/2020/06/17/isc2020-hpcw/).

## Previous Workshops

<ul class="posts">
{% for post in site.posts %}
  {% if post.tags contains 'iscworkshop' %}
      <div class="post_info">
        <li>
          <a href="{{ post.url }}">{{ post.title }}</a>
          <span>({{ post.date | date:"%Y-%m-%d" }})</span>
        </li>
      </div>
  {% endif %}
{% endfor %}
</ul>
