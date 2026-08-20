# Veleis v1.7.0 — First Public Release

Veleis 1.7.0 is the first public distribution of **Veleis — Unified Monitoring
Platform**, a modern self-hosted monitoring and observability platform.

## Highlights

- HTTP/HTTPS, ICMP/Ping, TCP, DNS, SMTP, IMAP, and TLS certificate monitoring.
- Optional outbound-only Ravyr Linux host agents.
- Observational Docker monitoring and GET-only Proxmox integration.
- Normalized infrastructure Discovery, history, relationships/topology, and
  explicit cross-provider identity trust.
- Unified Overview, custom dashboards, alerts, incidents, dependency-aware
  explanations, durable notifications, and privacy-safe Status Pages.
- Local Owner/Admin/Viewer RBAC, scoped API tokens, account lifecycle, audit
  history, TOTP, encrypted credentials, and retention/capacity controls.

## Install

On Ubuntu 24.04.4 LTS or Debian 13.6 (amd64):

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install.sh | bash
```

The installer creates `/opt/veleis`, installs missing Docker components,
generates unique secrets and an HTTPS certificate, provisions a private
TimescaleDB/PostgreSQL service, pulls the exact Veleis 1.7.0 image, migrates,
waits for readiness, and prints the access URL.

The certificate is self-signed. A browser trust warning is expected, but the
connection remains encrypted. Confirm the host, proceed locally, and create the
first Owner; no default credentials exist.

## Distribution identity

- Docker: `docker.io/nyxmael/veleis:1.7.0`
- Platform: `linux/amd64`
- Manifest:
  `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe`
- Schema: 32
- `1.7` tracks the newest accepted 1.7 patch; `latest` tracks the newest stable
  release. Both point to 1.7.0 at publication.

## Known limitations

- Only amd64 and the two named OS releases are clean-install accepted.
- Default HTTPS uses an installation-specific self-signed certificate.
- Supported upgrade/rollback, backup/restore, automated uninstall, and public
  custom-certificate operations are pending.
- Image signing, public SBOM, and provenance attestations are pending.
- This distribution repository does not publish proprietary application source.

## Documentation and support

- [Documentation](https://github.com/NyxCloudRO/Veleis#documentation)
- [Installation](https://github.com/NyxCloudRO/Veleis/blob/main/docs/INSTALLATION.md)
- [Changelog](https://github.com/NyxCloudRO/Veleis/blob/main/CHANGELOG.md)
- [Docker Hub](https://hub.docker.com/r/nyxmael/veleis)
- [Support](https://github.com/NyxCloudRO/Veleis/blob/main/SUPPORT.md)
- [Security reporting](https://github.com/NyxCloudRO/Veleis/security)
- [Support Nyxmael](https://buymeacoffee.com/nyxmael)
