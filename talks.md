---
layout: page
title: Talks
permalink: /talks/
---
<ul class="posts">
    {% for post in site.posts %}
        {% if post.tags contains 'talk' %}
            <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ post.url }}">{{ post.title }}</a><br>
            {% if post.description %}
                <span style="padding-left:68px;"></span>{{ post.description }}
            {% endif %}
            </li>
        {% endif %}
    {% endfor %}
</ul>

<p class="rss-subscribe">subscribe to talks <a href="{{ "/talks.xml" | prepend: site.baseurl }}">via RSS</a></p>

