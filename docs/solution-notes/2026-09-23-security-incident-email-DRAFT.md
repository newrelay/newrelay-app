# Security Incident Email — DRAFT (needs your review before sending)

**Status:** Draft only. Not sent. Same caveat as the notice doc — the
"no evidence of data access" line needs your sign-off, not a blanket
"your data is safe" claim, given the limits of our forensics.

---

**To:** [customer list / all users]
**Subject:** Security update: action taken on a server issue

Hi [Name],

We want to let you know about a security issue we identified and resolved
on September 23, 2026.

**What happened:** Our hosting provider flagged and stopped one of our
servers after detecting unauthorized software (a cryptocurrency miner)
running on it. We responded immediately.

**What we found:** A misconfigured database service was reachable from the
public internet without a password, which let an automated attack install
the software. This is a known, common attack pattern — not something
targeted at NewRelay specifically.

**What we did:**
- Removed the unauthorized software right away
- Closed the security gap (added authentication, restricted network access)
- Added a server firewall
- Audited for any further unauthorized access — found none
- Rotated security credentials as a precaution

**Your data:** We found no evidence that customer data was accessed,
modified, or copied. The software found was limited to using server
computing power for mining — it does not access application data on its own.

We take this seriously and are putting additional safeguards in place to
prevent this going forward. If you have any questions, reply to this email
or reach us at [support email].

Thanks,
The NewRelay Team

---

## Internal notes (delete before sending)

Same technical details as the notice doc — see
`2026-09-23-security-incident-notice-DRAFT.md` in this same folder.

Before sending: confirm recipient list/segment (all customers vs. only
those on this specific server/account), and get the "no evidence of data
access" claim reviewed given it's a real disclosure with legal weight.
