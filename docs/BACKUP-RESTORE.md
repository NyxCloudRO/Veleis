# Backup and Restore

[← Documentation home](../README.md)

An official, tested public backup/restore workflow is not yet available for
Veleis 1.7.0. This document defines the data boundary so operators do not mistake
persistence for a complete backup.

A complete Veleis recovery set must account for:

- PostgreSQL/TimescaleDB data in `veleis-database-pg18`;
- `/opt/veleis/.env`, especially the application master key and database
  credential;
- `/opt/veleis/data/tls/`, including the installation's private key;
- `/opt/veleis/data/avatars/` where used; and
- the matching Veleis release and supported Compose definition.

Losing the master key can make encrypted integration credentials unrecoverable.
A database dump without secrets/files is therefore incomplete, while a raw
volume copy taken without database consistency controls is not automatically a
valid backup.

Until the supported workflow is published, do not rely on undocumented
copy/paste backup commands for disaster recovery. Never test restore by
overwriting the only production copy. Preserve persistent data and follow future
release documentation for a validated backup, verification, and isolated
restore procedure.
