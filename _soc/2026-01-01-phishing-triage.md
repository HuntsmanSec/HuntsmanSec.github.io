---
title: Phishing Triage Workflow
date: 2026-01-01
tags: [soc, phishing, email, triage]
status: Draft
excerpt: A reusable public-safe workflow for investigating suspicious email reports.
---

## Use Case

Document the analyst flow for phishing triage without exposing real mailboxes, message IDs, customer names, or internal tooling details.

## Investigation Steps

1. Review sender, recipient, subject, and timestamps.
2. Inspect links and attachments in a safe analysis environment.
3. Check authentication results such as SPF, DKIM, and DMARC.
4. Search for similar messages across the environment using sanitized examples.
5. Record verdict and recommended containment action.

## Safe Example

Use `user01@example.com`, `phish.example.com`, and `REDACTED` placeholders in public notes.
