# Security Guide

[← Documentation home](../README.md) · [Vulnerability reporting](../SECURITY.md)

## Infrastructure observation

Veleis intentionally has no infrastructure remediation or control surface.
Proxmox integration is GET-only. Docker and Linux agent collection is
observational. Ravyr has no inbound remote shell. Use least-privilege accounts
and network access even with this application-level boundary.

## Authentication and authorization

- A fresh installation requires creation of the first Owner; no default
  username or password exists.
- Owner manages users, roles, account lifecycle, and security settings.
- Admin can operate monitoring but cannot assume Owner-only identity powers.
- Viewer is enforced read-only by the server.
- Personal API tokens have explicit scopes, optional expiry, revocation, and
  role intersection. Their plaintext value is shown only once; stored values
  are hashes.
- Browser mutations require authenticated server-side sessions and CSRF
  validation. TOTP and recovery codes are available.

## Secrets

The installer generates unique high-entropy database and master secrets. Veleis
uses the master key to encrypt stored integration credentials. Protect
`/opt/veleis/.env`; losing it can make encrypted configuration unrecoverable.
Do not share environment files, cookies, API tokens, enrollment tokens, private
keys, or provider credentials in Issues.

## HTTPS

HTTPS is enabled by default. The generated certificate is unique and its private
key remains under `/opt/veleis/data/tls/`. Browser trust warnings are expected
because no public certificate authority signs it. The warning does not mean
traffic is plain HTTP. Verify the hostname/IP before proceeding; do not disable
browser certificate checking globally.

## Host hardening

- Expose only TCP 443 as needed; keep PostgreSQL private.
- Apply Debian/Ubuntu and Docker security updates through normal OS operations.
- Restrict shell and sudo access to the Veleis host.
- Limit Docker socket access on monitored hosts. The socket can confer broad
  host privileges even though Veleis performs only observational calls.
- Review role assignments and revoke unused tokens/agents.
- Monitor disk capacity and retention.

The current image is not yet signed and has no public SBOM/provenance
attestation. Verify immutable release references against [Docker policy](DOCKER.md).
