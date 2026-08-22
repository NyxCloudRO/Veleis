# Changelog

All notable public Veleis releases are recorded here. Versions follow semantic
versioning; the corresponding Git tag uses a `v` prefix.

## [Unreleased]

## [1.8.0] - 2026-08-22

### Added

- Added signed, same-origin Ravyr artifacts and a separate constrained updater
  service/timer for zero-touch supported agent upgrades.
- Added explicit recommended/minimum agent compatibility, deterministic staged
  cohorts, concurrency and maintenance controls, offline catch-up, fleet UI,
  per-agent policy overrides, rollback events, and failed-release fleet pause.
- Added paginated Status Page component and incident administration with search,
  filters, sorting, scalable ordering, overview counts, and safe bulk actions.
- Added Active Alert acknowledgement, active-only summary counts, explicit Normal
  filtering, compact pagination, and overlapping-rule guidance.

### Changed

- Active Alerts now defaults to operational attention states; healthy Normal
  evaluations remain available only when explicitly requested.
- Public Status Page health still aggregates all enabled components while each
  response and browser render remains bounded.
- Stable Docker channels `1.8` and `latest` now resolve to 1.8.0. The `1.7`
  channel remains on the accepted 1.7.1 image.

### Security and safety

- Ravyr update manifests bind version, protocol, server compatibility, platform,
  exact path, size, SHA-256, Ed25519 signature, and trusted key ID.
- The updater exposes no arbitrary command, service, URL, package, or filesystem
  surface; it changes only Ravyr-owned binaries/state and restarts only
  `ravyr.service`.
- Activation is disk-preflighted and atomic, requires a resumed heartbeat plus
  telemetry, and restores the previous binary on failure.

### Compatibility

- Supported upgrade: `1.7.1` to `1.8.0` through the mandatory backup workflow.
- Schema advances from 32 to 33; backup format remains 1.
- Accepted upgrade testing preserved users, assets, probes, dashboards,
  incidents, provider configuration/inventory, and TLS identity.
- DEV Ubuntu and Debian Ravyr hosts upgraded from 1.7.0 to 1.8.0 without
  re-enrollment; a signed faulty canary proved rollback, local release blocking,
  and server fleet pause.
- Docker image: `docker.io/nyxmael/veleis:1.8.0`
- Manifest digest: `sha256:b1a3b106599d8b297f48a4573051c3dc646e12bd69c35cfbdae4d49edafff85b`

## [1.7.1] - 2026-08-21

### Added

- Added first-class Proxmox overview, workloads, and storage widgets to Custom
  Dashboards.
- Added Discovery summary and recent activity widgets with bounded,
  newest-first normalized data.
- Added deterministic per-provider or explicit all-provider widget scope,
  including safe empty, disabled, deleted, issue, and stale states.
- Added public Custom Dashboard and Proxmox setup guides.

### Changed

- Expanded Infrastructure summary to represent configured providers,
  discovered infrastructure, and Proxmox workloads alongside incidents, agents,
  and Docker runtime state.
- Clarified least-privilege Proxmox setup with a dedicated user/token,
  `PVEAuditor` on `/` with Propagate, and Privilege Separation behavior.
- Stable Docker channels `1.7` and `latest` now resolve to 1.7.1.

### Fixed

- Prevented Viewer sessions from rendering the asset-creation action.
- Preserved provider freshness and issue context in dashboards instead of
  presenting stale normalized observations as current.

### Compatibility

- Supported upgrade: `1.7.0` to `1.7.1`.
- Schema remains 32; backup format remains 1.
- Accepted upgrade testing preserved dashboards and widget layouts, assets,
  probes, users, incidents, Discovery provider configuration and inventory,
  and the installation TLS identity through the mandatory backup workflow.
- Docker image: `docker.io/nyxmael/veleis:1.7.1`
- Manifest digest:
  `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a`

### Distribution operations

- Added a focused `veleis` operator command for status, version, logs, complete
  logical backups, validated same-version restores, and compatibility-gated
  future upgrades.
- Added versioned backup manifests and checksums covering PostgreSQL/TimescaleDB,
  deployment secrets, TLS identity, avatars, Compose, and release metadata.
- Added mandatory target safety backups, TimescaleDB-aware restore, exclusive
  maintenance locking, strict archive validation, disk checks, and readiness
  verification.
- Added a verified lifecycle bootstrap for existing 1.7.0 installations and
  lifecycle installation in the clean installer.
- Documented rollback boundaries and cross-OS restore acceptance while keeping
  the prior 1.7.0 release assets and Docker image immutable.

## [1.7.0] - 2026-08-20

First public Veleis distribution.

### Highlights

- Unified availability monitoring with HTTP/HTTPS, ICMP/Ping, TCP, DNS,
  SMTP, IMAP, and TLS certificate probes.
- Optional Ravyr Linux agents for host, service, process, runtime, network,
  and storage observations.
- Observational Docker and GET-only Proxmox monitoring.
- Normalized infrastructure Discovery, relationships/topology, inventory
  history, changes, search, and explicitly trusted cross-provider identities.
- Custom dashboards, alert rules, incident lifecycle, dependency-aware
  explanations, durable notifications, and privacy-safe public Status Pages.
- Local Owner/Admin/Viewer roles, scoped personal API tokens, account lifecycle,
  immutable audit history, and monitoring retention/capacity controls.
- Public amd64 image and one-command clean installer for Ubuntu 24.04.4 LTS and
  Debian 13.6, with generated secrets and HTTPS enabled by default.

### Distribution

- Docker image: `docker.io/nyxmael/veleis:1.7.0`
- Manifest digest:
  `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe`
- Installer: immutable `1.7.0` target; no source checkout is required.

### Known limitations

- linux/amd64 only; Ubuntu 24.04.4 LTS and Debian 13.6 are the tested hosts.
- The generated default certificate is self-signed.
- Automated uninstall and custom-certificate operations are not yet published.
- Image signing, a public SBOM, and provenance attestations are pending.

[1.8.0]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.8.0
[1.7.1]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.7.1
[1.7.0]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.7.0
