# Operations

[← Documentation home](../README.md)

Run production commands from the installation directory:

```bash
cd /opt/veleis
```

## Status and readiness

```bash
sudo docker compose ps
curl --cacert data/tls/veleis.crt https://127.0.0.1/health/ready
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
