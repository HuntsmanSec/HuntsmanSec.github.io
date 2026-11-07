---
title: Phishing Triage Workflow
date: 2026-01-01
tags: [soc, phishing, email, triage]
status: Draft
excerpt: A reusable public-safe workflow for investigating suspicious email reports, from first look to verdict and containment.
---

## Use Case

A user reports a suspicious email, or an email security control raises an alert. The goal is a confident verdict (malicious, suspicious, spam, or benign) and the right containment, fast. Examples use placeholders only: no real mailboxes, message IDs, customer names, or internal tooling details.

## 1. Scope the Report

- Who reported it, when it arrived, and whether anyone interacted (clicked, replied, opened an attachment, entered credentials).
- Is it a single message or part of a wider campaign? Same sender, subject, or URL across many recipients raises priority.

## 2. Review the Headers

| Check | What to look for |
| --- | --- |
| `From` vs `Reply-To` vs `Return-Path` | Mismatched domains, free-mail reply addresses |
| `Authentication-Results` | `spf`, `dkim`, and `dmarc` results; a `fail` on a domain that normally passes is a strong signal |
| `Received` chain | Unexpected sending infrastructure or geography for the claimed sender |
| Display name | Executive or vendor names paired with an external address |

## 3. Analyse Links and Attachments Safely

- Never open links or attachments on an analyst workstation. Use a sandbox or detonation service.
- Defang indicators in notes: `hxxps://phish[.]example[.]com/login`.
- Record file hashes (SHA-256) rather than sharing the file itself.
- Check reputation of URLs, domains, and hashes, and note how recently the domain was registered.

## 4. Hunt for Spread

- Search mail logs for the same sender, subject, URL, or attachment hash.
- Check web proxy or DNS logs for any user who visited the URL.
- Check endpoint telemetry for execution of the attachment hash.

## 5. Verdict and Containment

| Verdict | Typical actions |
| --- | --- |
| Malicious, no interaction | Purge from mailboxes, block sender/domain/URL, notify reporter |
| Malicious, clicked or credentials entered | Above, plus reset credentials, revoke sessions, review sign-in logs, escalate |
| Malicious, attachment executed | Isolate the endpoint, escalate to incident response |
| Spam / benign | Close with a short rationale, thank the reporter |

## 6. Document

Write the case so another analyst can follow it: timeline, indicators (defanged), verdict, actions taken, and any escalation.

## Safe Example

Use `user01@example.com`, `phish.example.com`, `192.0.2.10`, and `REDACTED` placeholders in public notes.
