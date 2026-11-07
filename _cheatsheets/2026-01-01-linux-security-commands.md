---
title: Linux Security Commands
date: 2026-01-01
tags: [linux, cli, incident-response]
status: Draft
excerpt: Quick command references for Linux investigation and response practice.
---

Run these on systems you are authorised to investigate. Prefer collecting output to a file (`cmd | tee out.txt`) so evidence is preserved.

## System Context

```bash
hostnamectl                 # hostname, OS, kernel
uptime                      # how long since last reboot
date; timedatectl           # time and timezone (needed for log correlation)
```

## Users and Logins

```bash
who; w                      # currently logged-in users
last -a | head -n 30        # recent logins
lastb | head -n 30          # failed logins (root)
cat /etc/passwd | awk -F: '$3 == 0'   # accounts with UID 0
sudo -l                     # what the current user can run as root
```

## Processes

```bash
ps auxf                     # process tree
top -c                      # live view with full command lines
ls -l /proc/<PID>/exe       # binary behind a PID (deleted binaries show "(deleted)")
cat /proc/<PID>/cmdline | tr '\0' ' '
```

## Network

```bash
ss -tulpen                  # listening sockets with owning process
ss -tanp state established  # active TCP connections
ip addr; ip route           # interfaces and routes
```

## Persistence

```bash
crontab -l; ls -la /etc/cron.*        # scheduled jobs
systemctl list-unit-files --state=enabled
ls -la ~/.ssh/; cat ~/.ssh/authorized_keys
```

## Files

```bash
find / -xdev -mtime -2 -type f 2>/dev/null | head    # modified in last 2 days
find / -xdev -perm -4000 -type f 2>/dev/null         # SUID binaries
sha256sum <file>                                     # hash for reputation checks
```

## Logs

```bash
journalctl -xe                        # recent journal entries with context
journalctl -u ssh --since "1 hour ago"
grep -i "failed password" /var/log/auth.log | tail   # Debian/Ubuntu
grep -i "failed password" /var/log/secure | tail     # RHEL/CentOS
```
