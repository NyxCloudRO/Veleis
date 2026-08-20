# Upgrading

[← Documentation home](../README.md)

The supported lifecycle command is:

```bash
sudo veleis upgrade
```

An exact target may be requested when it is the published stable release:

```bash
sudo veleis upgrade 1.7.1
```

Veleis retrieves public structured release metadata over HTTPS and validates
the exact semantic version, supported source versions, schema direction,
linux/amd64 platform, official Docker repository, and registry digest. It also
checks disk space, creates and verifies a complete pre-upgrade backup, pulls the
immutable image by tag and digest, and applies the release's migration workflow
with a temporary target environment. Persisted version/image metadata changes
only after the target schema and HTTPS readiness pass.

## Current release state

Veleis 1.7.0 is the current stable release. Its metadata names 1.7.0 as a
supported source so a future accepted target can explicitly include it. Until a
newer stable release is published, `sudo veleis upgrade` and
`sudo veleis upgrade 1.7.0` are safe no-ops: they create no backup, pull no
image, run no migration, and restart no service.

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
the target release notes before every accepted upgrade.
