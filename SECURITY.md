# Security Policy

## Supported versions

| Version | Public security support |
| ------- | ----------------------- |
| 1.7.x   | Yes                     |
| < 1.7   | No; pre-public builds   |

Support means the current stable 1.7 line is eligible for security corrections.
It is not a contractual support or response-time commitment.

## Reporting a vulnerability

Please use GitHub's **Report a vulnerability** feature on the repository
Security page. This creates a private report for the repository owner.

Do not open a public Issue for a suspected vulnerability. Do not include tokens,
credentials, private keys, personal data, or sensitive infrastructure details in
public discussions.

If private vulnerability reporting is unavailable, open a minimal public Issue
asking for a private reporting channel without disclosing technical details.

## Security model

- Veleis observes infrastructure; it does not expose infrastructure control,
  remediation, remote shell, VM/container start/stop, or reboot operations.
- Proxmox collection uses fixed GET-only requests. Docker collection is
  observational, although access to a Docker socket is itself security-sensitive
  and should be granted only on hosts users intend to monitor.
- Browser sessions use server-side session state, CSRF protection, and local
  Owner/Admin/Viewer authorization. API tokens are hashed, scoped, expiring,
  revocable, and shown only at creation.
- Stored integration credentials are encrypted using the installation-specific
  master key. Generated database and application secrets are not shared between
  installations.
- HTTPS is enabled by default. The installer creates a unique local certificate
  and protects its private key.

See [Security](docs/SECURITY.md) for operator guidance and [LICENSE](LICENSE) for
the proprietary distribution terms.
