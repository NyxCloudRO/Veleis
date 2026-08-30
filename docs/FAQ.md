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

## Can Veleis change an SNMP device?

No. Veleis 1.8.11 performs one bounded scalar numeric-OID `GET` per probe
attempt. It has no SNMP `SET`, WALK, GETBULK, trap, discovery, or MIB-name
resolution capability. See [SNMP monitoring](SNMP.md).

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

Not in 1.8.11. The accepted public image is linux/amd64 only.

## Which Linux releases are supported?

Veleis 1.8.11 installation is supported and validated on Ubuntu 24.04 LTS,
Ubuntu 25.04, Ubuntu 26.04 LTS, Debian 12 (Bookworm), and Debian 13 (Trixie),
on amd64/x86_64. Other releases, derivatives, and architectures are not part
of the supported installation matrix.

## Does Veleis require a cloud service?

No Veleis cloud service is required. Installation needs public package,
GitHub, and Docker image access. Normal operation uses your local database and
only the external targets/providers/notification services you configure.

## How do I update?

Use `sudo veleis upgrade`. Veleis 1.7.1, 1.8.0, 1.8.1, 1.8.2, 1.8.3, 1.8.4,
1.8.5, 1.8.6, 1.8.7, 1.8.8, 1.8.9, and 1.8.10 upgrade to the current 1.8.11
stable release after a mandatory backup and immutable-digest verification. On
1.8.11, the same command is a no-op. Targets must explicitly
accept the installed source version and pass metadata, schema, digest, backup,
migration, and readiness checks. See [Upgrading](UPGRADING.md).

## How do I back up?

Run `sudo veleis backup`. It creates a complete, checksummed archive containing
the logical database plus secrets, TLS identity, avatars, Compose, and release
metadata. Copy it to protected off-host storage. See
[Backup and restore](BACKUP-RESTORE.md).

## Can I restore onto another supported operating system?

Yes, within the documented compatibility boundary. The accepted test restored
a complete Ubuntu 24.04.4 backup onto Debian 13.6 on amd64. The target must have
the same Veleis version and accepted topology; the restored certificate may not
cover the new host address.

## Can I use my own certificate?

The application can consume custom TLS material internally, but public-safe
replacement/reverse-proxy operations have not completed release acceptance.
The supported 1.8.11 installer uses its generated certificate.

## What happens to monitoring history?

Raw probe-result retention defaults to 90 days and is configurable from 7 to
365 days. Current health, incident lifecycle, and audit history are maintained
separately. Storage needs still depend on workload and must be monitored.
