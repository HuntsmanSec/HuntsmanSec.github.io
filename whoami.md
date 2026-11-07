---
layout: page
title: Whoami
permalink: /whoami/
description: Public profile, focus areas, and links.
---

Hi, I am **HuntsmanSec**.

I document cybersecurity learning, SOC workflows, CTF writeups, detection notes, and professional growth. This site is written as a public-safe knowledge base: no private credentials, internal screenshots, customer artifacts, or sensitive environment details.

## Focus Areas

- Security Operations Center
- Threat detection
- Incident response
- SIEM investigation
- Blue team labs
- CTF writeups
- Security cheatsheets
- Mentorship and community learning

## Public Links

{% for link in site.social %}{% if link[1] != "" %}- [{{ link[0] | replace: "hackthebox", "Hack The Box" | replace: "tryhackme", "TryHackMe" | replace: "linkedin", "LinkedIn" | replace: "github", "GitHub" | replace: "blog", "Blog" }}]({{ link[1] }})
{% endif %}{% endfor %}
