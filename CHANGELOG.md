# Changelog

All notable public Veleis releases are recorded here. Versions follow semantic
versioning; the corresponding Git tag uses a `v` prefix.

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
- Supported upgrade, backup/restore, automated uninstall, and custom-certificate
  operations are not yet published.
- Image signing, a public SBOM, and provenance attestations are pending.

[1.7.0]: https://github.com/NyxCloudRO/Veleis/releases/tag/v1.7.0
