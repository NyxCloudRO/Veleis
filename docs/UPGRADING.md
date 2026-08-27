# Upgrading

[← Documentation home](../README.md)

The supported lifecycle command is:

```bash
sudo veleis upgrade
```

An exact target may be requested when it is the published stable release:

```bash
sudo veleis upgrade 1.8.9
```

Veleis retrieves public structured release metadata over HTTPS and validates
the exact semantic version, supported source versions, schema direction,
linux/amd64 platform, official Docker repository, and registry digest. It also
checks disk space, creates and verifies a complete pre-upgrade backup, pulls the
immutable image by tag and digest, and applies the release's migration workflow
with a temporary target environment. Persisted version/image metadata changes
only after the target schema and HTTPS readiness pass.

## Current release state

Veleis 1.8.9 is the current stable release. Veleis 1.7.1 and 1.8.0 through
1.8.8 are explicit upgrade sources. Refresh the lifecycle tooling before the
upgrade so the schema-40 compatibility contract and PostgreSQL memory helper
are installed:

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install-lifecycle.sh | bash
sudo veleis status
sudo veleis postgres-memory status
sudo veleis upgrade 1.8.9
```

The exact target form is `sudo veleis upgrade 1.8.9`. Schema 40 is current;
the 1.8.8 → 1.8.9 path performs no migration. Older supported sources advance
to schema 40 as required.
Users and sessions, tokens, assets, probes/history, alerts/incidents,
notifications and encrypted credentials, Status Pages, dashboards, Discovery,
Ravyr enrollment/policy, retention, and TLS identity are preserved. Existing
TLS probes begin Certificate Intelligence history on their next completed
handshake; pre-upgrade observations cannot be reconstructed.

On 1.8.9, `sudo veleis upgrade` and `sudo veleis upgrade 1.8.9` are safe
no-ops: they create no backup, pull no image, run no migration, and restart no
service. A 1.8.9 downgrade remains rejected.

## PostgreSQL memory profile

New 1.8.9 installations select a managed database profile from the effective
cgroup or host memory limit. One GiB is the hard minimum and two GiB or more is
recommended. Existing installations retain their current database topology
until an operator explicitly adopts the managed profile:

```bash
sudo veleis postgres-memory status
sudo veleis postgres-memory adopt-managed
```

Adoption backs up `.env` and `compose.yaml`, installs the accepted template,
validates it, and restarts the stack. If validation or readiness fails, both
files are restored. Do not run `swapoff`, hand-edit PostgreSQL memory settings,
or copy only part of the managed profile.

Downgrades, non-exact versions, unpublished versions, unsupported source
versions, floating tags, a digest mismatch, an older target schema, and
unavailable/invalid metadata are rejected before installation state changes.

## Failure and recovery boundary

Failures before the mandatory backup or before state mutation leave the running
installation unchanged. If image pull, migration, or target readiness fails,
the pre-upgrade backup is retained and persisted source-version metadata has not
been switched.

Once a migration has begun, Veleis does not claim that swapping the old image
back is safe and does not automatically downgrade the database. The command
prints the preserved pre-upgrade backup on failure. Restore can create its
required target safety snapshot even if the application is stopped. Diagnose
first; recovery is a deliberate restore while the persisted source version
still matches the backup:

```bash
sudo veleis restore /opt/veleis/backups/<pre-upgrade-backup>.tar.gz --force
```

Never remove the database volume, edit `.env` to a floating image tag, or rerun
the clean installer as an improvised upgrade. Keep backups off-host and review
the target version's entry in [the canonical changelog](../CHANGELOG.md) before
every accepted upgrade.
