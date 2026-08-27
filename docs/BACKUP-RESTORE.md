# Backup and Restore

[← Documentation home](../README.md)

Veleis provides a complete, versioned backup rather than treating database
persistence as disaster recovery. Run lifecycle commands with root privileges
or as an ordinary sudo-enabled user.

## Create a backup

```bash
sudo veleis backup
```

The default destination is `/opt/veleis/backups`. An absolute alternative may
be supplied:

```bash
sudo veleis backup /mnt/encrypted-backups/veleis
```

Veleis first verifies the installation, free space, database state, schema, and
HTTPS readiness. It stops only the application container while the database
remains online, creates a PostgreSQL custom-format logical dump, copies the
other required state, restarts the application, and verifies readiness. The
bounded pause prevents application writes during the dump.

The resulting mode-600 `.tar.gz` archive contains:

- the PostgreSQL/TimescaleDB database, including hypertables and policies;
- `.env`, including the database credential and application master key;
- the Compose definition, installation marker, and release metadata;
- the TLS certificate and private key; and
- avatars and other supported persistent files under `/opt/veleis/data`.

Containers, image layers, logs, caches, temporary files, and the raw live
PostgreSQL volume are not included. The archive has an internal manifest and
checksums, plus a same-directory `.sha256` sidecar. Integrity checks detect
damage; they do not authenticate an archive from an untrusted party.

Backups contain secrets. Copy both files to encrypted, access-controlled,
off-host storage and retain them according to your own policy. Veleis never
deletes old backups automatically. Before copying, check capacity with `df -h`.
After copying, verify the sidecar in its destination directory:

```bash
sha256sum --check veleis-backup-1.8.8-YYYYMMDDTHHMMSSZ.tar.gz.sha256
```

## Restore

Restore is deliberately explicit and currently requires a working Veleis
installation at the same application version as the backup:

```bash
sudo veleis restore /secure/path/veleis-backup-1.8.8-YYYYMMDDTHHMMSSZ.tar.gz --force
```

Before changing state, the command rejects unreadable, corrupt, malformed,
unsafe, wrong-architecture, incompatible PostgreSQL/TimescaleDB, wrong-version,
and mismatched-topology archives. It then creates a complete safety backup of
the target installation. Only after that succeeds does it stop Veleis, recreate
the application database, invoke TimescaleDB's pre/post-restore procedures,
restore secrets and files, recreate services, validate schema 40, and wait for
HTTPS readiness.

The source installation's TLS identity and configured public URL are preserved.
On a replacement host, use its current address to connect; a different
hostname/IP may not be covered by the restored self-signed certificate and can
therefore produce a certificate-name warning. Do not regenerate TLS or secrets
merely to make a restore start—doing so changes the recovered identity and can
make encrypted integration credentials unreadable.

The restore command prints the target safety-backup path. Keep it until the
restored system has been independently checked. During failed-upgrade recovery,
that snapshot can be captured while the application is stopped; a snapshot of
a dirty migration state is preserved for forensics but is intentionally not
accepted later as a normal restore source.

## Post-restore validation

```bash
sudo veleis status
sudo veleis version
```

Then sign in as an existing user and verify representative assets, probes,
history, incidents, dashboards, API-token metadata, notification settings,
retention, and avatars. Restart the host or Compose stack once and repeat the
readiness and sign-in checks before declaring recovery complete.

## Tested recovery boundary

The public workflow was accepted with PostgreSQL 18, TimescaleDB 2.28.3,
Veleis 1.8.8/schema 40, and complete same-version restore coverage on
linux/amd64. Supported 1.7.1 and 1.8.0 through 1.8.7 to 1.8.8 upgrades preserve populated state,
backups, and TLS identity. TimescaleDB's documented
full-database `pg_dump`/`pg_restore` flow
and `timescaledb_pre_restore()`/`timescaledb_post_restore()` are used. See the
[official TimescaleDB logical-backup guidance](https://docs.timescale.com/self-hosted/latest/backup-and-restore/logical-backup/).

Not supported: partial restores, merging two installations, cross-architecture
restore, point-in-time recovery, restoring into an older/newer Veleis version,
or treating a raw copy of the live database volume as an official backup.
