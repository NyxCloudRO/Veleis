# Frequently Asked Questions

[← Documentation home](../README.md)

## Is Veleis open source?

No. Veleis is proprietary software distributed under the
[Veleis Proprietary Distribution License](../LICENSE).

## Is the application source code public?

No. This repository contains public-safe distribution assets, the installer,
documentation, screenshots, and release metadata. It is intentionally not the
application source repository.

## Why is the GitHub repository relatively small?

Application binaries are delivered through the official Docker repository.
GitHub provides the supported installer, deployment definition, operator docs,
release notes, and public project coordination without publishing proprietary
source.

## What does “Unified Monitoring Platform” mean?

Veleis joins service checks, host and Docker observations, Proxmox and Discovery
inventory, topology, dashboards, alerts, incidents, notifications, retention,
governance, and Status Pages in one product and durable data model.

## Does Veleis control Docker or Proxmox?

No. Veleis performs observational Docker calls and fixed GET-only Proxmox calls.
It has no start, stop, reboot, delete, remediation, or remote-shell interface.
Docker socket access is still host-sensitive and should be restricted.

## Why does my browser warn about TLS?

The installer creates a unique self-signed certificate. It encrypts traffic but
is not signed by a public certificate authority, so browsers cannot establish
automatic trust. Verify the host and proceed locally; never disable browser
security globally.

## Where is data stored?

Application data is in the `veleis-database-pg18` Docker volume. Deployment
secrets, TLS identity, and uploaded avatars are under `/opt/veleis`. These
survive routine restart but are not, by themselves, a backup.

## Can I install on ARM?

Not in 1.7.0. The accepted public image is linux/amd64 only.

## Which Linux releases are supported?

Ubuntu 24.04.4 LTS and Debian 13.6 are the exact clean-install-tested releases.

## Does Veleis require a cloud service?

No Veleis cloud service is required. Installation needs public package,
GitHub, and Docker image access. Normal operation uses your local database and
only the external targets/providers/notification services you configure.

## How do I update?

There is no accepted public upgrade workflow yet. The installer rejects an
existing instance, and users should not change image tags ad hoc. See
[Upgrading](UPGRADING.md).

## How do I back up?

An official validated backup/restore procedure is pending. Durable data spans
PostgreSQL plus deployment secrets and TLS/files, so copying one Docker volume
is not presented as a complete backup. See [Backup and restore](BACKUP-RESTORE.md).

## Can I use my own certificate?

The application can consume custom TLS material internally, but public-safe
replacement/reverse-proxy operations have not completed release acceptance.
The supported 1.7.0 installer uses its generated certificate.

## What happens to monitoring history?

Raw probe-result retention defaults to 90 days and is configurable from 7 to
365 days. Current health, incident lifecycle, and audit history are maintained
separately. Storage needs still depend on workload and must be monitored.
