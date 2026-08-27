# Changelog

All notable public Veleis releases are recorded here. Versions follow semantic
versioning; the corresponding Git tag uses a `v` prefix.

## [Unreleased]

## [1.8.9] - 2026-08-27

### Improved

- Improved Agents page performance on installations with larger or
  longer-running metric histories.
- Optimized retrieval of recent CPU and memory telemetry.
- Improved request cancellation and timeout handling for Agents operations.
- Reduced redundant background refresh activity during frequent telemetry
  updates.
- Improved Agents search responsiveness and live-update behavior.
- Existing Agent rows remain visible while refreshed data is being retrieved.
- Improved recovery and Retry behavior when an Agents request is temporarily
  unavailable or times out.

### Upgrade and compatibility

- No database migration is required for Veleis 1.8.9. Database schema remains
  version 40.
- Run `sudo veleis backup`, then `sudo veleis upgrade 1.8.9` to use the
  standard upgrade lifecycle and immutable image verification.
- Supported upgrade sources are Veleis 1.7.1 and 1.8.0 through 1.8.8. Backup
  format remains 1. Recommended Ravyr remains signed 1.8.2; minimum Ravyr is
  1.7.0 and lifecycle protocol remains 1.
- The supported platform remains linux/amd64.
- Docker image: `docker.io/nyxmael/veleis:1.8.9`
- Manifest digest: `sha256:6c6e0227c941082d3fa6ef51e67133472e1ce2e16e478fc2e2a2c5120f2ded45`
- Release: <https://github.com/NyxCloudRO/Veleis/releases/tag/v1.8.9>

## [1.8.8] - 2026-08-27

### Highlights

- Added Advanced DNS Monitoring with A, AAAA, CNAME, MX, NS, TXT, SRV, CAA,
  and PTR records; typed expectations; resolver and optional authoritative
  comparison; resolver-dependent DNSSEC state; semantic change history; and
  shared incident/alert integration.
- Added revisioned Notification Escalation Policies with ordered absolute-delay
  steps, multiple channels, immutable incident snapshots, stop-on-acknowledge,
  exactly-once scheduling, cancellation, delivery provenance, active progress,
  and a responsive timeline editor.
- Added in-place notification-channel editing and safe optional credential
  rotation while preserving channel identity, history, type, encryption, and
  write-only secret behavior. Channel management is now a compact responsive
  list.
- Unified Profile, Security, Preferences, Data Retention, and Access below
  canonical `/settings/*` routes with responsive top navigation. The sidebar
  account footer now provides a direct neutral Sign Out action and Settings is
  the sole general configuration entry.

### Database and performance

- Schema advances from 37 to 40. Agent metrics use one-day chunks, drop a
  redundant large index, and enter Timescale columnstore after one day while
  preserving the existing 14-day agent-metric lifecycle.
- Fresh installations size PostgreSQL and TimescaleDB from the minimum of host,
  current cgroup-v2/cgroup-v1 ancestors, and a validated optional override.
  Profiles bound buffers, per-operation memory, connections, and workers. A
  32 GiB host constrained to 2 GiB now receives the 2 GiB profile rather than
  host-sized settings.

### Upgrade notes

- Run `sudo veleis backup` before upgrading, then `sudo veleis upgrade 1.8.8`.
  The lifecycle creates and verifies another mandatory pre-upgrade backup,
  validates the immutable image digest, applies migrations 38–40, and waits for
  schema 40 and HTTPS readiness.
- Fresh 1.8.8 installations use cgroup-aware managed PostgreSQL tuning.
  Historical and administrator-customized settings are never silently
  overwritten during upgrade.
- Existing installations should first refresh the current lifecycle tooling as
  documented in [Upgrading](docs/UPGRADING.md), then run:

  ```bash
  sudo veleis postgres-memory status
  ```

  `HEALTHY`, `WARNING`, or `UNSAFE` is reported with effective memory,
  ownership, and live PostgreSQL settings. An unsafe historical installation
  can explicitly adopt the Veleis-managed profile with:

  ```bash
  sudo veleis postgres-memory adopt-managed
  ```

  Adoption backs up both `.env` and `compose.yaml`, atomically installs the
  managed profile/topology, recreates and health-checks the stack, and restores
  both files if validation fails. It restarts PostgreSQL and the application;
  schedule a maintenance window. No database data is deleted. Operators who
  intentionally maintain custom PostgreSQL configuration remain in control and
  may leave it unchanged after reviewing the warning.
- Never use `swapoff` or hand-edit PostgreSQL files as the Veleis remediation
  procedure.

### Compatibility and known limitations

- Supported upgrade sources: Veleis 1.7.1 and 1.8.0 through 1.8.7. Backup
  format remains 1. Recommended Ravyr remains signed 1.8.2; minimum Ravyr is
  1.7.0 and lifecycle protocol remains 1.
- The supported image remains linux/amd64. Default HTTPS remains self-signed.
  Image signing, a published SBOM, and provenance attestation are not currently
  part of the Veleis release pipeline.
- PostgreSQL memory profiles bound the primary allocation risks but do not
  guarantee that every third-party workload fits the minimum 1 GiB profile;
  2 GiB is the practical small-install recommendation.
- Docker image: `docker.io/nyxmael/veleis:1.8.8`
- Manifest digest: `sha256:4f082699b5bec6261f119ea6f620decbf9bcfc72c06523b1e8ae1c8e00a98f8a`

## [1.8.7] - 2026-08-26

### Improved

- Added scalable server-side pagination and filtering to Notifications History,
  with channel context, deterministic ordering, bounded error presentation, and
  distinct loading, empty, and failure states.
- Unified notification health across Overview and Notifications: retrying work
  is the canonical active issue, terminal outcomes remain history, and channel
  health follows its latest delivery result.
- Refined Overview Operational Attention and responsive accessibility across
  desktop and mobile layouts.
- Replaced native destructive prompts with consistent accessible Veleis dialogs
  that guard duplicate submission, preserve focus, and keep secrets out of copy.

### Fixed

- Deleting a probe or its asset now retires associated alert instances,
  incidents, dependency interpretations, and undelivered notification work in
  one transaction while preserving delivered and audit history.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1, 1.8.0, 1.8.1, 1.8.2, 1.8.3, 1.8.4,
  1.8.5, and 1.8.6. Schema advances from 36 to 37; backup format remains 1.
- Recommended Ravyr remains the unchanged signed 1.8.2 release; minimum
  supported Ravyr remains 1.7.0 and lifecycle protocol remains 1.
- Docker image: `docker.io/nyxmael/veleis:1.8.7`
- Manifest digest: `sha256:894b469f8c1a210f59b2981ea15c473055c56ae77a4c865bbdccecd2d87a8568`

## [1.8.6] - 2026-08-25

### Added

- Added Certificate Intelligence to TLS Certificate probes: current and
  previous identities, SHA-256 fingerprint, subject/issuer/serial, validity,
  DNS/IP SANs, signature and public-key metadata, chain/verification/hostname
  state, first/last seen timestamps, and observation counts.
- Added bounded certificate identity history and edge-triggered change events.
  An A→B rotation creates one event; repeated observation of B updates its
  counters without duplicating the event.

### Improved

- Added responsive Certificate Intelligence presentation to probe details with
  bounded current, history, and change views across desktop and mobile widths.
- Preserved the accepted compact Status Pages, Asset Details action hierarchy,
  dialog behavior, and application-wide responsive density corrections made
  after 1.8.5.

### Security and safety

- Certificate Intelligence is observational only. It performs the same bounded
  TLS handshake as the existing probe and cannot issue, renew, replace, install,
  or reconfigure certificates or monitored infrastructure.
- Certificate history APIs require normal Veleis authentication and probe-read
  permission. They return a typed 404 for non-TLS probes, cap identities and
  changes at 50 each, and never expose private keys or configured secrets.
- The release image runs as `nonroot:nonroot`; final-image vulnerability and
  secret scanning found no policy-violating HIGH/CRITICAL findings.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1, 1.8.0, 1.8.1, 1.8.2, 1.8.3, 1.8.4,
  and 1.8.5. Schema advances from 35 to 36; backup format remains 1.
- Recommended Ravyr remains the unchanged signed 1.8.2 release; minimum
  supported Ravyr remains 1.7.0 and lifecycle protocol remains 1.
- Docker image: `docker.io/nyxmael/veleis:1.8.6`
- Manifest digest: `sha256:1c51cd1f41644e72fc734aaa0132a2b6c69d9723c2ea6af9c0c4bf690e4df813`

## [1.8.5] - 2026-08-25

### Added

- Added read-only SNMP scalar-OID monitoring with SNMPv2c and SNMPv3
  `noAuthNoPriv`, `authNoPriv`, and `authPriv`, secure write-only credentials,
  typed condition evaluation, scheduled/manual execution, history, incidents,
  and alert integration.

### Improved

- Corrected Asset Details action hierarchy around Add Probe, Edit asset, and
  Delete asset, with an accessible Veleis-native exact-once delete dialog.
- Unified application density and responsive layout behavior across primary
  workspaces while preserving the compact Agents reference.

### Security and safety

- SNMP performs one bounded scalar `GET` per attempt. It never issues `SET` and
  does not implement WALK, GETBULK, traps, discovery, or MIB-name resolution.
- SNMP communities and v3 authentication/privacy secrets are encrypted at rest,
  write-only through the API, redacted from responses, and discarded from logs.
  SNMPv3 `authPriv` is recommended where security matters. MD5 and DES are
  rejected; the supported SHA authentication and AES privacy families are
  documented in the [SNMP guide](docs/SNMP.md).

### Compatibility

- Preserved and synchronized the Veleis 1.8.5 validated amd64 installation
  matrix: Ubuntu 24.04 LTS, Ubuntu 25.04, Ubuntu 26.04 LTS, Debian 12
  (Bookworm), and Debian 13 (Trixie). The maintained installer now enforces
  these exact releases and continues rejecting unknown or unvalidated hosts.
- Supported upgrade sources: Veleis 1.7.1, 1.8.0, 1.8.1, 1.8.2, 1.8.3, and
  1.8.4. Schema advances from 34 to 35; backup format remains 1.
- Recommended Ravyr remains the unchanged signed 1.8.2 release; minimum
  supported Ravyr remains 1.7.0 and lifecycle protocol remains 1.
- Docker image: `docker.io/nyxmael/veleis:1.8.5`
- Manifest digest: `sha256:cab41f4a7f63a2ac39295cac1940ff8c524ddf220f6083d2934d977210feb621`

## [1.8.4] - 2026-08-23

### Fixed

- Replaced time-percentage Ravyr rollout admission with serialized, bounded
  five-minute leases, canary-first admission, stale-lease reconciliation, and
  a strict maximum-concurrent limit so small fleets continue making progress.
- Made installed version authoritative for agent lifecycle presentation: an
  older follow-global agent cannot appear Current, pinned agents remain
  explicit, malformed/newer versions fail safely, and summary counters agree
  with effective row state without double-counting offline agents.
- Added concise safe reasons for waiting, paused, pinned, failed, updating, and
  current states, plus live lifecycle events so rows advance without a manual
  browser refresh.
- Published an idempotent, narrowly scoped legacy Ravyr repair script for the
  historical missing `/usr/local/lib/veleis-ravyr` systemd namespace path. It
  preserves identity, credentials, CA, configuration, and buffered telemetry.
- Refined the Automatic Update Policy editor into one aligned responsive form
  with coherent timing controls and attached Cancel/Save actions.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1, 1.8.0, 1.8.1, 1.8.2, and 1.8.3.
- Schema advances from 33 to 34; backup format remains 1.
- Recommended Ravyr remains the unchanged signed 1.8.2 release; minimum
  supported Ravyr remains 1.7.0 and lifecycle protocol remains 1.
- Docker image: `docker.io/nyxmael/veleis:1.8.4`
- Manifest digest: `sha256:40e5927272fc2fc415cea2b50d1d3d5bf63de6876094335b855ab26395415cd3`

## [1.8.3] - 2026-08-23

### Fixed

- Rebuilt the expanded Automatic Update Policy editor around one responsive
  form grid with aligned fields, compact timing controls, coherent lower-right
  actions, meaningful dirty-state saving, non-mutating cancellation, and
  visible validation/API failures across desktop, tablet, and mobile layouts.
- Hardened the shortened Ravyr HTTPS bootstrap so it retrieves the server
  certificate first, verifies its authenticated fingerprint, installs it as a
  temporary CA, and downloads the checksum and installer with normal TLS
  verification—without `curl -k` or another insecure transport bypass.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1, 1.8.0, 1.8.1, and 1.8.2.
- Schema remains 33; backup format remains 1; no database migration is added.
- Recommended Ravyr remains the signed 1.8.2 release; minimum supported Ravyr
  remains 1.7.0 and lifecycle protocol remains 1. No re-enrollment is required.
- Docker image: `docker.io/nyxmael/veleis:1.8.3`
- Manifest digest: `sha256:b8f0f01242371128a3ad8f559d535781f99b7c3ee9bc035781116a8644cf8901`

## [1.8.2] - 2026-08-23

### Added

- Added server-side name, heartbeat, CPU, memory, storage, version, OS, and
  search controls for bounded Managed Hosts pages, with deterministic identity
  tie-breaking across a 1,001-agent fleet.
- Added a short Ravyr enrollment command that downloads one installer, verifies
  its authenticated SHA-256, pins the server certificate fingerprint during
  bootstrap, and persists CA-validated HTTPS for all continuing traffic.
- Added explicit clipboard success feedback and a manual-selection fallback,
  plus direct Community access at `https://community.nyxcloud.ro/`.

### Changed

- Agents now opens with a compact fleet summary, collapsed update-policy
  configuration, dense 25/50/100-row management, and clearly separate
  connectivity, compatibility, installed/recommended version, update state,
  and policy facts.
- Live Host, Probe, Docker, Proxmox workload, and Proxmox storage widgets retain
  deterministic identity order and scroll position while telemetry refreshes.
- Status Page management now uses a compact page selector and header with
  explicit Published/Unpublished state, copyable public path, conditional public
  link, direct Publish/Unpublish actions, stable tabs, and deemphasized revision.
- Ravyr's recommended signed release advances to 1.8.2 while the minimum
  supported version remains 1.7.0 and lifecycle protocol remains 1.

### Fixed

- Deduplicated semantically identical Linux socket observations before
  Discovery ingestion and added a defensive server normalization layer, fixing
  qBittorrent-style repeated wildcard UDP descriptors without merging distinct
  owners, address families, ports, or protocols.
- Ensured fresh and repair Ravyr installation creates
  `/usr/local/lib/veleis-ravyr` and its config/state parents with the ownership
  and modes required by the hardened updater systemd namespace.
- Clarified disabled stable-channel controls, zero-agent policy setup, copy
  failures, and Status Page publication actions without weakening token,
  signature, TLS, RBAC, or monitoring-only boundaries.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1, 1.8.0, and 1.8.1.
- Schema remains 33; backup format remains 1; no database migration is added.
- Existing Ravyr identities, credentials, policy overrides, configuration, CA
  trust, and buffered telemetry are preserved; re-enrollment is not required.
- Docker image: `docker.io/nyxmael/veleis:1.8.2`
- Manifest digest: `sha256:074c9a6584873e07a793fdb0eaff24f32e292aa387a57314109380f6d1efbda4`

## [1.8.1] - 2026-08-22

### Added

- Added one bounded canonical notification event model with channel-specific
  Discord embed, UTF-8 email, and versioned generic-webhook renderers.
- Added explicit **Any time** and recurring **Maintenance window** Ravyr update
  timing, searchable IANA timezones, first-use browser timezone suggestion, and
  clear Follow Global, Canary, Stable, and Manual/Pinned explanations.

### Changed

- Discord firing, warning, recovery, and test delivery now uses concise semantic
  embeds; SMTP uses operator-readable subjects and plaintext bodies.
- Fleet policy saves no longer resume a paused rollout. Resume is a separate,
  confirmed action, and installed/recommended/compatibility/update state remain
  visibly distinct.
- Generic webhooks now receive documented schema-v1 JSON. Discord 429 handling
  honors bounded `Retry-After`; other provider failures retain bounded retry.

### Fixed

- Prevented raw Go map syntax, `<nil>`, internal fields, and credential material
  from appearing in normal operator notifications.
- Corrected Status Page incident-update grouping so empty collections encode as
  `[]`, eliminating the intermittent administration crash during empty, rapid
  mutation, refresh, and upgraded-page flows.
- Clarified rollback, paused rollout, pinned-agent, overnight-window, and DST
  behavior without changing signed Ravyr 1.8.0 compatibility metadata.

### Compatibility

- Supported upgrade sources: Veleis 1.7.1 and 1.8.0.
- Schema remains 33; backup format remains 1.
- Recommended Ravyr remains signed 1.8.0; no agent re-enrollment or credential
  rotation is required.
- Docker image: `docker.io/nyxmael/veleis:1.8.1`
- Manifest digest: `sha256:5afeb90ec365282990a080c0cc26e84d2fffe69986a87c48612abb9a3260fcfe`

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
[1.8.1]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.8.1
[1.8.2]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.8.2
[1.7.1]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.7.1
[1.7.0]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.7.0
