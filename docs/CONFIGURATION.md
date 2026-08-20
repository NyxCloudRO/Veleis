# Configuration and Data

[← Documentation home](../README.md)

## Installer-managed configuration

The clean installer writes:

- `/opt/veleis/compose.yaml` — supported production topology;
- `/opt/veleis/.env` — version, immutable image, HTTPS port/public URL, database
  password, and application master key;
- `/opt/veleis/data/tls/veleis.crt` — public self-signed certificate;
- `/opt/veleis/data/tls/veleis.key` — private key;
- `/opt/veleis/.veleis-installation` — existing-install marker.

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

The release currently has no supported general-purpose configuration-file or
installer reconfiguration workflow. Product settings—assets, probes, users,
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
