# Configuration and Data

[← Documentation home](../README.md)

SNMP communities and v3 authentication/privacy secrets follow the same
installation master-key encryption boundary as other integration credentials.
They are write-only and are not returned in configuration reads. See
[SNMP monitoring](SNMP.md) for protocol-specific options and limitations.

## Installer-managed configuration

The clean installer writes:

- `/opt/veleis/compose.yaml` — supported production topology;
- `/opt/veleis/.env` — version, immutable image, HTTPS port/public URL, database
  password, and application master key;
- `/opt/veleis/data/tls/veleis.crt` — public self-signed certificate;
- `/opt/veleis/data/tls/veleis.key` — private key;
- `/opt/veleis/.veleis-installation` — existing-install marker.
- `/opt/veleis/release.json` — accepted release, schema, compatibility, and
  immutable Docker identity metadata.
- `/usr/local/bin/veleis` — focused public lifecycle command.

The environment file and marker are root-owned mode 600. The private key is
mode 600 and readable by the non-root application UID. Generated secrets are
unique per installation and are not printed.

## Safe handling

- Keep `/opt/veleis/.env` and the private key secret.
- Preserve the master key; encrypted integration credentials cannot be read
  without it.
- Do not paste the environment file into Issues or logs.
- Do not change the image tag to perform an unvalidated upgrade.
- Do not replace the generated Compose file with a single `docker run`; Veleis
  depends on the database, migrations, secrets, TLS, networks, health checks,
  and persistence defined there.

Do not hand-edit installer-managed files. The release has no supported
general-purpose reconfiguration workflow. Product settings—assets, probes, users,
tokens, providers, notifications, dashboards, status pages, and retention—are
managed through authenticated Veleis screens/APIs.

## HTTPS identity

The installer creates a unique RSA-3072 certificate valid for 825 days. SANs
include the detected hostname, `localhost`, the primary IPv4 address selected
from the default route (or a filtered global-address fallback), and `127.0.0.1`.
It persists across container restart.

Public custom-certificate/reverse-proxy replacement operations are not yet
documented as a supported v1 workflow. Do not disable HTTPS merely to suppress
a browser warning.

## Data and retention

The default clean-install raw probe-result retention is 90 days. Owners can set
the supported 7–365 day range with explicit confirmation for reductions.
Capacity information is visible in application settings. Retention applies to
raw probe results; current probe health, incident lifecycle, and audit history
remain separate durable truth.

## Authoritative state model

| Classification | Components |
| --- | --- |
| Required for restore | PostgreSQL/TimescaleDB logical data; `.env` secrets and release settings; TLS certificate/private key; avatars and supported persistent files; installation marker; matching Compose and release metadata |
| Optional or regenerable | `/usr/local/bin/veleis`; verified Docker images and layers; checksum sidecars copied from trusted storage |
| Ephemeral | Running/stopped containers, one-shot migration container, runtime logs, caches, temporary lifecycle work directories |
| Must not be backed up as the official method | Live PostgreSQL volume files, container writable layers, Docker socket/state, package caches, unrelated host data |

Routine persistence is not a backup. Use `sudo veleis backup`, store its archive
off-host, and test restore independently. See [Backup and restore](BACKUP-RESTORE.md).
