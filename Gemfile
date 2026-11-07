source "https://rubygems.org"

# Matches the Jekyll version and plugins GitHub Pages uses to build the site.
gem "github-pages", group: :jekyll_plugins

# Needed for `bundle exec jekyll serve` on Ruby 3.x.
gem "webrick", "~> 1.8"

group :test do
  # Link and image checker used by CI (.github/workflows/site-checks.yml).
  gem "html-proofer", "~> 5.0"
end
