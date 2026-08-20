# Features in Veleis 1.7.0

[← Documentation home](../README.md)

This inventory describes implemented release functionality, not planned ideas.

## Service monitoring

- HTTP/HTTPS status, redirects, bounded response checks, timing, and history.
- ICMP/Ping reachability and latency.
- TCP connection checks.
- DNS response and expected-answer checks.
- SMTP and IMAP protocol checks with explicit TLS and optional encrypted
  credentials.
- Dedicated TLS certificate trust, identity, validity, chain metadata, and
  warning/critical expiry thresholds.
- Scheduled and manual execution, current health, result history, analytics,
  incidents, and alert integration.

## Ravyr host monitoring

Ravyr is the optional outbound-only Linux agent. It reports host identity,
CPU, memory, storage, network, kernel/runtime details, service and process
inventory, lifecycle events, and optional Docker observations. Enrollment uses
a one-time token that becomes a host credential. Ravyr exposes no inbound remote
shell or remediation interface.

Agent enrollment instructions are generated inside the authenticated Veleis
Agents screen. A separate public standalone agent packaging workflow is not yet
published.

## Docker monitoring

Veleis observes Docker engines, containers, images, volumes, networks, runtime
state, metrics, and events through Ravyr. It records engine availability and
container health without exposing Docker control actions.

Docker socket access is security-sensitive because the socket itself is broadly
powerful. Grant it only on hosts you intend to monitor, restrict access to the
agent service, and understand that Veleis code uses it only for observational
API calls.

## Proxmox monitoring

The Proxmox provider uses a read-only API token and fixed GET requests to
observe clusters, nodes, VMs, LXCs, storage, networks, metadata, and
relationships. Create a least-privilege read-only token in Proxmox and enter it
through the authenticated provider configuration screen. Veleis provides no VM
or LXC start, stop, reboot, delete, or configuration actions.

## Discovery and topology

- Normalized inventory from typed providers while preserving provider source.
- Stable identities, fingerprints, current/historical records, and change
  history.
- Search, filtering, hierarchy, relationships, and bounded topology views.
- Partial/failure-aware provider lifecycle that does not convert incomplete
  observations into false removals.
- Explicit, audited cross-provider trust decisions; equal names or addresses do
  not merge resources automatically.

## Operations

- Unified Overview, asset details, and current attention summaries.
- User-owned custom dashboards and configurable monitoring widgets.
- Alert rules, silences, maintenance windows, and no-data handling.
- Open/acknowledged/resolved incident lifecycle and recovery history.
- Dependency-aware incident explanations with optional notification-only
  suppression; raw alerts and incidents remain visible.
- Durable generic webhook, Discord webhook, and SMTP email delivery with retry.
- Private-by-default Status Pages with selected probe components and bounded,
  privacy-safe public incident communication.
- Configurable raw probe-result retention (7–365 days, 90-day clean-install
  default) and capacity visibility. Incident and audit truth is separate from
  raw probe-result retention.

## Identity and security

- First-owner bootstrap without default credentials.
- Owner, Admin, and read-only Viewer roles with server-side enforcement.
- Server-side sessions, CSRF protection, Argon2id passwords, throttling, TOTP,
  and recovery codes.
- Scoped, expiring, revocable personal API tokens stored as hashes and displayed
  only once.
- Account disable/re-enable, administrative reset, forced password replacement,
  credential/session revocation, and immutable audit history.
- Encrypted integration secrets and HTTPS by default.
