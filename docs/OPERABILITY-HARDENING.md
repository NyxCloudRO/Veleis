# Production Operability Hardening

[← Documentation home](../README.md)

Veleis 1.8.0 combines three production-scale changes in schema 33.

## Ravyr fleet lifecycle

Ravyr remains an outbound-only observer. A separate root-owned updater checks
authenticated policy on a jittered timer and may maintain only Ravyr-owned
software. It accepts no command, shell, package, arbitrary URL, or arbitrary
service instruction.

Stable policy declares the recommended and minimum supported Ravyr versions and
protocol range. Deterministic cohorts advance through 1%, 5%, 25%, 50%, and
100%, with a fleet concurrency bound and optional maintenance window. Offline
agents catch up at their next authenticated check.

Artifacts are immutable and same-origin. The strict manifest binds semantic
version, server/protocol compatibility, OS/architecture, exact path, byte size,
SHA-256, Ed25519 signature, and key ID. Activation preflights disk space, stages
on the target filesystem, retains one previous version, atomically replaces the
binary, and restarts only `ravyr.service`. Success requires Veleis to observe a
new heartbeat and telemetry. Failure restores the previous binary, blocks the
release for that agent, and pauses the fleet.

## Status Pages at scale

The authenticated workspace separates Overview, Components, Incidents, and
Settings. Components use compact rows, server-side search/filter/sort and
25/50/100 pagination, explicit ordering, on-demand editing, and bounded bulk
enable/disable/remove actions. Overview counts cover the complete page. Public
health also aggregates all enabled components while each response renders a
bounded page and never exposes private probe or asset context.

## Active Alerts semantics

Active Alerts represents conditions needing operational attention. Normal and
disabled evaluations do not appear by default; Normal remains available as an
explicit filter. Pending, Firing, Acknowledged, suppressed, Recovering, No Data,
and evaluator errors remain visible with bounded filters and pagination.

Acknowledgement records operator attention without changing evaluation or
incident truth. Rule editing warns about overlapping condition/scope/state and
about using one severity for both degraded and down states. Explicitly distinct
rules remain distinct. Delivery deduplication remains keyed by channel,
incident, and transition type, preventing repeated evaluation noise.

## Compatibility

- Veleis: 1.8.0
- Database schema: 33
- Recommended Ravyr: 1.8.0
- Minimum supported Ravyr: 1.7.0
- Ravyr protocol: 1
- Supported Veleis upgrade source: 1.7.1

The accepted upgrade preserves existing monitoring, dashboard, identity,
incident, Discovery, provider, and TLS data through the mandatory backup
workflow. Exact 1.7.x Docker tags remain immutable.
