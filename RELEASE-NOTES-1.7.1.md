# Veleis v1.7.1

Veleis 1.7.1 makes Discovery and Proxmox first-class Custom Dashboard data
sources while preserving Veleis's observational, read-only infrastructure
boundary.

## Highlights

- New Proxmox overview, workloads, and storage widgets.
- New Discovery summary and recent activity widgets.
- Deterministic all-provider or selected-provider configuration, with bounded
  rows and explicit disabled, deleted, issue, and stale states.
- Infrastructure summary now includes providers, discovered infrastructure,
  and Proxmox workloads alongside incidents, agents, and Docker state.
- A new public Proxmox guide documents privilege-separated tokens,
  `PVEAuditor` on `/` with Propagate, TLS choices, and common 401/403/config
  failures.
- Viewer asset-creation controls are now correctly hidden.

## Upgrade

Veleis 1.7.0 to 1.7.1 is supported. The lifecycle tool creates a mandatory
pre-upgrade backup, verifies the immutable image digest, applies migrations,
and waits for HTTPS readiness.

```bash
sudo veleis upgrade
```

Exact-version alternative:

```bash
sudo veleis upgrade 1.7.1
```

Schema remains **32** and backup format remains **1**. Existing dashboards,
assets, probes, users, incidents, Discovery provider configuration/inventory,
TLS identity, and login state are preserved.

## Distribution

- Image: `docker.io/nyxmael/veleis:1.7.1`
- linux/amd64 manifest:
  `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a`
- Floating tags `1.7` and `latest` resolve to the same accepted digest.
- Immutable `1.7.0` remains unchanged at
  `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe`.

## Known limitations

- linux/amd64 only; tested public installer hosts remain Ubuntu 24.04.4 LTS and
  Debian 13.6.
- Proxmox widgets use normalized inventory/state. Historical Proxmox CPU and
  memory timeseries are not persisted in this release.
- Default HTTPS uses an installation-specific self-signed certificate.
- Automated uninstall, image signing, a public SBOM, and provenance
  attestations are not yet published.
