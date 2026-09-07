# Upgrading

[← Documentation home](../README.md)

The supported lifecycle command is:

```bash
sudo veleis upgrade
```

An exact target may be requested when it is the published stable release:

```bash
sudo veleis upgrade 2.0.1
```

Veleis retrieves public structured release metadata over HTTPS and validates
the exact semantic version, supported source versions, schema direction,
linux/amd64 platform, official Docker repository, and registry digest. It also
checks disk space, creates and verifies a complete pre-upgrade backup, pulls the
immutable image by tag and digest, and applies the release's migration workflow
with a temporary target environment. Persisted version/image metadata changes
only after the target schema and HTTPS readiness pass.

Refreshing lifecycle tooling for a newer target preserves the installed
release metadata until that upgrade completes, so the mandatory source backup
remains internally version-consistent and directly restorable.

## Current release state

Veleis 2.0.1 is the current stable release. Veleis 1.7.1, 1.8.0 through
1.8.12, and 2.0.0 are explicit upgrade sources. Refresh the lifecycle tooling
before the upgrade so the schema-50 compatibility contract and current
PostgreSQL memory helper are installed:

```bash
curl -fsSL https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/install-lifecycle.sh | bash
sudo veleis status
sudo veleis postgres-memory status
sudo veleis upgrade 2.0.1
```

The exact target form is `sudo veleis upgrade 2.0.1`. Schema 50 is current.
The 2.0.0 → 2.0.1 path requires no schema migration. Older supported sources
advance through every required migration through schema 50 in order.
Users and sessions, tokens, assets, probes/history, alerts/incidents,
notifications and encrypted credentials, Status Pages, dashboards, Discovery,
Ravyr enrollment/policy, retention, and TLS identity are preserved. Existing
TLS probes begin Certificate Intelligence history on their next completed
handshake; pre-upgrade observations cannot be reconstructed.

On 2.0.1, `sudo veleis upgrade` and `sudo veleis upgrade 2.0.1` are safe
no-ops: they create no backup, pull no image, run no migration, and restart no
service. A downgrade from 2.0.1 remains rejected.

## PostgreSQL memory profile

New 2.0.1 installations select a managed database profile from the effective
cgroup or host memory limit. One GiB is the hard minimum and two GiB or more is
recommended. Upgrades automatically converge fingerprinted Veleis-managed
profiles and exact historical Veleis Compose definitions. Unknown or
operator-customized configurations remain unchanged and require explicit
review before adoption:

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
