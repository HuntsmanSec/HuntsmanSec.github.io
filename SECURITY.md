# Publishing Security Checklist

Before publishing content to this GitHub Pages site, verify that no sensitive data is included.

## Never Commit

- `.env` files
- API keys
- Passwords
- Private keys
- Access tokens
- Session cookies
- Internal IP addresses
- Internal domains
- Customer names
- Company-confidential screenshots
- SIEM screenshots with real alerts
- EDR screenshots with hostnames or usernames
- Cloud account IDs
- Tenant IDs
- Private flags from active CTF competitions

## Before Push

Run:

```bash
git status
git diff
git diff --cached
gitleaks detect --source .
```

The same gitleaks scan runs automatically on every push via
`.github/workflows/site-checks.yml`, but run it locally too so secrets never
reach GitHub in the first place.

## Also Check

- Commit author: use the GitHub username and the GitHub-provided noreply
  address (Settings → Emails → "Keep my email addresses private"), never a
  personal name or email.
- Numbers and metrics: only publish figures you can verify and that do not
  reveal client volumes or tooling.
- Image metadata: strip EXIF/GPS data from photos before adding them.

## Safe Alternatives

- Use `.env.example` with placeholders.
- Replace real domains with `example.com`.
- Replace internal IPs with documentation ranges such as `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.
- Replace private hostnames with `host01.example.local`.
- Replace real users with `user01`.
- Replace tokens with `REDACTED`.
- Blur or crop screenshots before publishing.
