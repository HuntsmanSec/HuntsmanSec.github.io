# HuntsmanSec.github.io

Jekyll-based cybersecurity portfolio for `https://HuntsmanSec.github.io`.

## Design

- Dark terminal-inspired layout.
- Clean homepage with only high-level content hubs.
- Content archives live on their own pages.
- Each archive supports `All` plus tag-specific filtering.
- Public-safe publishing checklist included in `SECURITY.md`.

## Add A New CTF Writeup

Create a file in `_ctf/`:

```text
_ctf/2026-01-01-challenge-name.md
```

Use this front matter:

```yaml
---
title: Challenge Name
date: 2026-01-01
tags: [ctf, forensics, beginner]
status: Published
excerpt: Short public-safe summary.
---
```

## Add A New SOC Note

Create a file in `_soc/`:

```text
_soc/2026-01-01-note-title.md
```

Use tags such as:

```yaml
tags: [soc, phishing, email, triage]
```

## Add A New Cheatsheet

Create a file in `_cheatsheets/`:

```text
_cheatsheets/2026-01-01-topic.md
```

Use tags such as:

```yaml
tags: [linux, cli, incident-response]
```

## Other Archives

Use the matching collection folder:

- `_career/`
- `_trainings/`
- `_certifications/`
- `_talks/`
- `_recognitions/`
- `_conferences/`
- `_misc/`

Every entry should include `title`, `date`, `tags`, `status`, and `excerpt`.

## Publish Safely

Before pushing:

```bash
git status
git diff
git diff --cached
gitleaks detect --source .
```

Never commit `.env`, private keys, tokens, customer data, internal screenshots, tenant IDs, or real internal infrastructure details.
