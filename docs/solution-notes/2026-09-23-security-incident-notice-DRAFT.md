# Security Incident Notice — DRAFT (needs your review before sending/publishing)

**Status:** Draft only. Not sent, not published. The "customer data" claim below is
phrased as "no evidence of access," not "data was not accessed" — our forensics were
thorough but not exhaustive (no review of historical outbound traffic logs predating
the response). Get this reviewed (legal, if you have that resource) before it goes
out, given it's a real breach disclosure.

---

## Customer-facing security notice

**Subject: Security update — action taken on a server security incident**

On September 23, 2026, we detected and responded to unauthorized cryptocurrency
mining software running on one of our servers. This document explains what
happened, what we did, and what we found.

**What happened**

Our hosting provider automatically stopped one of our servers after detecting
malicious software (a cryptocurrency miner) running on it. We immediately
investigated and confirmed the finding.

**Root cause**

We identified that a database service on this server was reachable from the
public internet without a password — a misconfiguration that allowed an
automated attack to install the mining software. This was not a targeted
attack on NewRelay specifically; it matches a well-known, automated pattern
that scans the internet for exactly this kind of exposed, unprotected service.

**What we did**

- Removed the malicious software immediately upon detection
- Closed the underlying security gap (required authentication on all
  database/cache services, removed public network access to them)
- Added a firewall to the server restricting all other public access
- Audited the server for any additional unauthorized access, changes, or
  backdoors — **found none**
- Rotated credentials and security keys as a precaution
- Applied the same fix across all related server configurations to prevent
  recurrence

**Impact assessment**

Our investigation found **no evidence** that the attacker accessed, modified,
copied, or exfiltrated any customer data. The malicious software found was
limited to cryptocurrency mining (using server computing power), which does
not access application data by itself. We found no unauthorized logins,
no unfamiliar user accounts, and no unexpected changes to server access
credentials.

[[If your review of historical logs turns up anything further, update this section
before publishing.]]

**What we're doing going forward**

- [ ] Regular automated audits of exposed services across our infrastructure
- [ ] [add any additional planned measures — e.g. dedicated security monitoring,
      scheduled penetration testing, etc.]

If you have any questions or concerns, please contact us at [support email].

---

## Internal notes (delete before publishing externally)

- Server affected: `srv1777969` (hosts both `app.newrelay.com` and
  `dev.newrelay.com`)
- Detected: Hostinger auto-stop due to malware detection
- Malware: XMRig cryptominer (`/var/tmp/.kd/cc_cfg.json`)
- Root cause: Redis + Postgres bound to `0.0.0.0` with no auth
  (`docker-compose.yaml`, plus an old leftover `dakshai` stack with the
  same issue)
- Full technical remediation: see the git commits from 2026-09-23 on
  `feature/ui-changes` (`fix(docker): require Redis auth and bind
  Redis/Postgres to localhost only`, and follow-ups)
- Not independently verified: outbound traffic volume/destination during the
  compromise window (would require reviewing logs predating our response,
  which we did not have preserved before remediation began)
