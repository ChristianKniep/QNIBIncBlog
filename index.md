---
layout: page
title: QNIBlog
permalink: /index.html
---
<ul class="posts">
    {% for post in site.posts %}
        {% if post.tags contains 'blog' %}
            <li><span>{{ post.date | date_to_string }}</span> &raquo; <a href="{{ post.url }}">{{ post.title }}</a><br>
            {% if post.description %}
                <span style="padding-left:68px;"></span>{{ post.description }}
            {% endif %}
            </li>
        {% endif %}
    {% endfor %}
</ul>