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

## Safe Alternatives

- Use `.env.example` with placeholders.
- Replace real domains with `example.com`.
- Replace internal IPs with documentation ranges such as `192.0.2.0/24`, `198.51.100.0/24`, and `203.0.113.0/24`.
- Replace private hostnames with `host01.example.local`.
- Replace real users with `user01`.
- Replace tokens with `REDACTED`.
- Blur or crop screenshots before publishing.
