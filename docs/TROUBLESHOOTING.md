# Troubleshooting

[← Documentation home](../README.md)

The installer exits non-zero and does not print the success banner unless
Veleis is actually ready over HTTPS. If state was already created, it is
preserved at `/opt/veleis` for diagnosis.

## Unsupported operating system

Error contains `unsupported operating system`. Veleis 1.7.0 is accepted only on
Ubuntu 24.04.4 LTS and Debian 13.6. Do not bypass OS detection on a production
host.

## Unsupported architecture

Error contains `unsupported architecture`. The public image is amd64 only.
arm64 and other architectures are not currently supported.

## Root or sudo unavailable

The installer requires root or an ordinary user with functional sudo. It will
report that sudo is absent or authorization failed. Configure host privileges
through normal operating-system policy; never send a sudo password to Veleis.

## Docker daemon unavailable

The installer enables/starts Docker and waits 30 seconds. Check:

```bash
sudo systemctl status docker --no-pager
sudo journalctl -u docker --no-pager --lines=200
sudo docker version
sudo docker compose version
```

Resolve the host's Docker/package/storage problem, then note that an existing
`/opt/veleis` path intentionally blocks blind reinstallation.

## TCP port 443 is occupied

Veleis will not stop or replace another service. Identify the listener:

```bash
sudo ss -ltnp 'sport = :443'
```

Decide which service owns the port. Do not kill it blindly. Alternative-port
installation is available only for deliberate operator testing through
`VELEIS_HTTPS_PORT`; the standard public URL and supported default use 443.

## Image pull fails

Check DNS, outbound HTTPS, Docker Hub reachability, proxy policy, and available
disk space:

```bash
sudo docker pull nyxmael/veleis:1.7.0
sudo docker system df
```

Do not disable TLS verification or substitute an unofficial image.

## Database does not become healthy

```bash
cd /opt/veleis
sudo docker compose ps
sudo docker compose logs --tail=200 database
```

Common host causes are insufficient disk/memory, Docker storage errors, or an
interrupted database initialization. Preserve the volume and logs; do not delete
the database as a first troubleshooting step.

## Veleis does not become ready

```bash
cd /opt/veleis
sudo docker compose ps
sudo docker compose logs --tail=200 migrate veleis
curl --cacert data/tls/veleis.crt https://127.0.0.1/health/ready
```

Readiness covers database connectivity, schema compatibility, and backend
startup. Share only sanitized logs in an Issue.

## Browser certificate warning

This is expected for the default self-signed certificate. Confirm the URL is the
host printed by the installer. The connection remains encrypted. Do not turn
off browser certificate validation globally.

## Existing installation detected

The clean installer found an existing path and preserved it. Do not delete it to
force installation. If this is an existing Veleis instance, see
[Upgrading](UPGRADING.md). If it is an unrelated directory, inspect it and make
a deliberate operator decision before changing anything.

## Getting help

Read [Support](../SUPPORT.md), then open an Issue with version, exact OS,
architecture, installation method, the failing step, and sanitized diagnostics.
