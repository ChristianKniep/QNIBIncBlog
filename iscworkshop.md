---
layout: page
title: ISC HPCW
permalink: /isc/
---

## ISC 'High Performance Container Workshop'

The workshop series assembles thought leaders to provide the audience with the 'state of containers' and the latest trends.

### Last Workshop 2019

The last workshop was held in June 2019: [5th Annual High Performance Container Workshop](/2019/06/20/isc2019-hpcw/)

### Previous Workshops


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
