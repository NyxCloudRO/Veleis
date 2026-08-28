# Installation

[← Documentation home](../README.md)

## Supported installation

Veleis 1.8.10 supports clean installation on:

- Ubuntu 24.04 LTS, amd64 / x86_64
- Ubuntu 25.04, amd64 / x86_64
- Ubuntu 26.04 LTS, amd64 / x86_64
- Debian 12 (Bookworm), amd64 / x86_64
- Debian 13 (Trixie), amd64 / x86_64

Other distributions or releases may work, but are not currently part of the
validated Veleis installation matrix. The installer rejects them rather than
assuming generic Ubuntu, Debian, derivative, or ARM compatibility.

The installer works when run as root or as a normal user with functional
`sudo`. It does not request, read, or store a sudo password itself; the normal
sudo mechanism may prompt through the terminal.

The one-command form requires `curl` to already be available so it can retrieve
the installer. If `curl` is absent, install it with the operating-system package
manager or download `install.sh` from the GitHub release on another machine.

## Quick start

Run the same primary command shown in the README:

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install.sh | bash
```

For review-before-execution, the equivalent supported flow is:

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install.sh -o install-veleis.sh
less install-veleis.sh
chmod +x install-veleis.sh
./install-veleis.sh
```

The maintained main-branch installer targets the exact immutable image
`docker.io/nyxmael/veleis:1.8.10`. Earlier releases retain their original
publication-time `install.sh` and `SHA256SUMS` assets; use the maintained
main-branch installer above for the current validated host policy.

## What the installer does

1. Reads structured OS information from `/etc/os-release`.
2. Detects amd64 and rejects unsupported architectures.
3. Selects direct-root or ordinary sudo operation.
4. Installs missing system tools, Docker Engine/CLI, and Compose v2 from the OS
   package repositories.
5. Verifies the Docker daemon and checks that TCP 443 is free.
6. Detects the effective cgroup/host memory limit, requires at least 1 GiB, and
   selects a managed PostgreSQL profile (2 GiB or more is recommended).
7. Creates the persistent installation at `/opt/veleis`.
8. Generates independent database and application secrets.
9. Generates an installation-specific self-signed TLS certificate.
10. Pulls the immutable Veleis image and pinned TimescaleDB image.
11. Starts the database, applies migrations, and starts Veleis.
12. Waits for database, schema, application, and HTTPS readiness.
13. Installs the verified `/usr/local/bin/veleis` lifecycle and PostgreSQL
    memory commands plus release
    metadata.
14. Prints the detected HTTPS address and routine operator commands.

The installer never prints generated secrets, changes firewall rules, exposes
PostgreSQL on the host, or creates default application credentials.

## First Owner

After the success banner:

1. Open the printed `https://<detected-ip>/` URL.
2. Confirm it is your host. A trust warning is expected for the generated
   certificate; do not disable browser security globally.
3. Create the first Owner with your own login and password.
4. Sign in. The first-owner endpoint closes after the account is created.

## Verify installation

```bash
cd /opt/veleis
sudo docker compose ps
curl --cacert data/tls/veleis.crt https://127.0.0.1/health/ready
```

Both `database` and `veleis` should be healthy, and readiness returns
`{"status":"ready"}`.

## Existing installations

The v1 installer is intentionally a clean-install tool. If `/opt/veleis`
already exists, it stops without overwriting configuration, secrets,
certificate, or database state. Do not rerun it to add lifecycle tooling.

Install the lifecycle command on an accepted Veleis 1.7.0 installation created
before this tooling was published with:

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install-lifecycle.sh | bash
sudo veleis status
```

The bootstrap requires the existing environment and installation marker,
downloads only the public lifecycle script and release metadata over HTTPS,
verifies pinned SHA-256 values, and does not restart Veleis. See
[Upgrading](UPGRADING.md).

## Installation location

```text
/opt/veleis/
├── .env                 # generated secrets and release settings; mode 600
├── .veleis-installation # install marker; mode 600
├── compose.yaml         # supported production topology
├── release.json         # compatibility and immutable release identity
├── backups/             # root-only lifecycle backup archives
└── data/
    ├── avatars/
    └── tls/
        ├── veleis.crt
        └── veleis.key   # mode 600
```

Database files live in the Docker volume `veleis-database-pg18`.
The operator command is installed at `/usr/local/bin/veleis`.

Next: [Operations](OPERATIONS.md) · [Troubleshooting](TROUBLESHOOTING.md)
