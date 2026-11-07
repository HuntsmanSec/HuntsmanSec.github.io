---
layout: page
title: Professional Archive
permalink: /professional/
description: Trainings, certifications, speakership, mentorship, recognitions, conferences, and misc archives.
---

This page keeps professional sections grouped away from the homepage so the main landing page stays clean.

## Archives

{% include visible-sections.html %}{% for section in visible_sections %}{% unless section.key == "career" %}- [{{ section.title }}]({{ section.url | relative_url }})
{% endunless %}{% endfor %}
