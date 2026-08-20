# Operations

[← Documentation home](../README.md)

The focused lifecycle command is the supported routine interface:

```bash
sudo veleis status
sudo veleis version
sudo veleis logs --tail=200 veleis
sudo veleis backup
```

## Status and readiness

```bash
sudo veleis status
curl --cacert /opt/veleis/data/tls/veleis.crt https://127.0.0.1/health/ready
```

Healthy operation shows `database` and `veleis` as healthy. The one-shot
`migrate` container may appear as successfully exited.

## Logs

```bash
sudo docker compose logs --tail=200 veleis
sudo docker compose logs --tail=200 database
sudo docker compose logs -f veleis
```

Review logs before sharing them and remove sensitive targets, addresses, or
personal information. Veleis does not intentionally log generated deployment
secrets.

Backup, restore, and upgrade operations share an exclusive maintenance lock.
A second lifecycle operation is rejected rather than run concurrently. See
[Backup and restore](BACKUP-RESTORE.md) and [Upgrading](UPGRADING.md).

## Start, stop, and restart

```bash
sudo docker compose up -d
sudo docker compose stop
sudo docker compose restart
```

`restart: unless-stopped` starts the database and application again when Docker
starts after a host reboot. Do not use `docker compose down --volumes` for
routine operation; deleting the database volume destroys persistent data.

## Locations

| Item | Location |
| ---- | -------- |
| Compose | `/opt/veleis/compose.yaml` |
| Generated environment/secrets | `/opt/veleis/.env` |
| Certificate | `/opt/veleis/data/tls/veleis.crt` |
| Private key | `/opt/veleis/data/tls/veleis.key` |
| Uploaded avatars | `/opt/veleis/data/avatars/` |
| Release metadata | `/opt/veleis/release.json` |
| Local backups | `/opt/veleis/backups/` |
| Database | Docker volume `veleis-database-pg18` |

## Firewall

The installer makes no firewall changes. If remote browsers or agents cannot
connect, ensure TCP 443 is permitted along the intended network path. Do not
expose the database port.

## Removal boundary

No automated uninstall is published. To stop Veleis, use `docker compose stop`.
Container removal and permanent data deletion are different operations. Never
delete `/opt/veleis` or `veleis-database-pg18` unless you intentionally accept
irreversible loss and have an independently validated backup.
