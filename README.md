# HuntsmanSec.github.io

Jekyll-based cybersecurity portfolio published at <https://huntsmansec.github.io>.

## Run it locally

Requires Ruby 3.x and Bundler.

```bash
bundle install
bundle exec jekyll serve --livereload
# open http://127.0.0.1:4000
```

The `Gemfile` uses the `github-pages` gem, so the local build matches what
GitHub Pages produces.

## Structure

```
_career/ _certifications/ _ctf/ _soc/ …   content, one Markdown file per entry
_data/sections.yml                        navigation + terminal sections
_data/technologies.yml                    homepage technology cards
_data/career_tracks.yml                   career timeline tracks and colours
_layouts/                                 page templates
_includes/                                terminal, career timeline, shared data
_templates/                               copy-ready templates for new entries
assets/css/style.css                      all styles
assets/js/filters.js                      terminal, filters, modals, timeline
```

See [CONTENT_GUIDE.md](CONTENT_GUIDE.md) for adding content and
[SECURITY.md](SECURITY.md) for the publishing checklist.

## Checks

Every push runs `.github/workflows/site-checks.yml`:

- **gitleaks** scans the full history for secrets.
- **Jekyll build + html-proofer** fails on broken internal links or missing images.
