# Content Guide

How to add things to the portfolio without touching any HTML. Every section is
generated from the Markdown files in the `_collection` folders.

## Where things go

| You want to add…             | Create a file in      | Start from template                  |
| ---------------------------- | --------------------- | ------------------------------------ |
| A job / role                 | `_career/`            | `_templates/career.md`               |
| A certification              | `_certifications/`    | `_templates/certification.md`        |
| A CTF writeup                | `_ctf/`               | `_templates/ctf-writeup.md`          |
| A SOC note                   | `_soc/`               | copy an existing SOC note            |
| A cheatsheet                 | `_cheatsheets/`       | copy an existing cheatsheet          |
| A training                   | `_trainings/`         | `_templates/training.md`             |
| A talk or mentorship session | `_talks/`             | `_templates/talk-or-mentorship.md`   |
| A recognition                | `_recognitions/`      | `_templates/recognition.md`          |
| A conference attended        | `_conferences/`       | `_templates/conference.md`           |
| Anything else                | `_misc/`              | `_templates/misc-note.md`            |

Dated sections (CTF, SOC, trainings, …) use `YYYY-MM-DD-short-title.md` file names.

## What updates automatically

- **Navigation and terminal.** A section only appears in the menu, the
  `Resources` dropdown and the terminal's `ls` once it has at least one
  published entry. Empty sections stay hidden.
- **Certifications.** Adding a file to `_certifications/` adds it to the
  homepage marquee, the certifications page and the terminal's `cert`
  command. `sort_order` controls the position.
- **Career timeline.** The overview chart, durations, year markers and track
  filters are calculated from `start`, `end` and `track`.
- **Technology cards.** Edit `_data/technologies.yml`. Add `alerts: 1234` to
  a platform only once the number is verified and public-safe.
- **Profile links.** Fill in `social:` in `_config.yml`; empty links are hidden.

## Drafts

Add `published: false` to the front matter to keep a file in the repo without
publishing it. The sample entries use this.

## Images

- Certification badges: 256×256 `.webp` in `assets/images/certs/`, kebab-case names.
- Organization logos: `.svg` or `.webp` in `assets/images/organizations/`;
  record the source in `ATTRIBUTION.txt`.
- No spaces in file names. Keep images under ~50 KB where possible.

## Before you push

Run through `SECURITY.md`. The GitHub Action in `.github/workflows/site-checks.yml`
also runs a gitleaks secret scan and checks every internal link and image on
each push.
