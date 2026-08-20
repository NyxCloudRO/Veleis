# Architecture Overview

[← Documentation home](../README.md)

Veleis is distributed as a self-contained application container backed by
PostgreSQL and TimescaleDB.

```text
Browser / API client
        │ HTTPS :443
        ▼
  Veleis application ───── internal Compose network ───── PostgreSQL/TimescaleDB
        ▲                                                    persistent volume
        │ authenticated observations
        ├── Ravyr Linux agents ── optional Docker observations
        ├── GET-only Proxmox APIs
        └── configured service probes and notification endpoints
```

## Production containers

- `veleis`: serves the web application and JSON API, schedules monitoring work,
  evaluates alerts, manages incidents/notifications, and accepts authenticated
  agent observations. It runs non-root with a read-only container filesystem.
- `migrate`: a one-shot use of the same immutable image that applies the bundled
  schema before the application starts.
- `database`: pinned TimescaleDB 2.28.3/PostgreSQL 18. It has no host-published
  port and persists in `veleis-database-pg18`.

## Persistence

PostgreSQL is authoritative for accounts, configuration, current monitoring
state, history, inventory, incidents, alerts, dashboards, notifications, and
audit records. The database volume survives container and host-service restart.
`/opt/veleis/data` persists the TLS identity and uploaded avatars; `/opt/veleis/.env`
persists generated deployment secrets.

Persistence is not a backup. See [Backup and restore](BACKUP-RESTORE.md).

## Read-only boundary

Veleis separates monitoring from infrastructure control. Ravyr initiates
outbound authenticated communication. Docker collection performs observational
queries. Proxmox uses fixed GET-only endpoints. Discovery providers submit
observations and relationships; Veleis does not remediate the systems it
describes.
