# Releases and Supported Versions

[← Documentation home](../README.md) · [Changelog](../CHANGELOG.md)

## Current stable release

Veleis **2.0.3** is the current stable release.

| Component                  | Release identity                 |
| -------------------------- | -------------------------------- |
| Application                | `2.0.3`                          |
| Git tag and GitHub Release | `v2.0.3`                         |
| Installer target           | `docker.io/nyxmael/veleis:2.0.3` |
| Docker manifest            | Recorded in `release.json`       |
| Schema                     | 53                               |
| Backup format              | 1                                |

All prior releases remain immutable at their original Docker digests and
GitHub releases. Upgrades from 1.7.1, 1.8.0 through 1.8.12, 2.0.0, 2.0.1, or
2.0.2 to 2.0.3 use a mandatory pre-upgrade backup. Schema 53 is current; upgrades apply
every required migration through schema 53. Sources on 2.0.0, 2.0.1, or 2.0.2 must
refresh the lifecycle tool before upgrading.

## Supported versions

| Version | Status                                          |
| ------- | ----------------------------------------------- |
| 2.0.3   | Current public stable release                   |
| 2.0.2   | Lifecycle-gated upgrade source for 2.0.3        |
| 2.0.1   | Lifecycle-gated upgrade source for 2.0.3        |
| 2.0.0   | Lifecycle-gated upgrade source for 2.0.3        |
| 1.8.x   | Supported upgrade source line for 2.0.3         |
| 1.7.1   | Supported upgrade source for 2.0.3              |
| 1.7.0   | Prior immutable release; upgrade to 1.7.1 first |
| <1.7    | Pre-public development; no public support       |

This policy is a conservative community release policy, not a contractual SLA.
Only releases and platforms explicitly listed in current documentation are
supported.

## Version and channel policy

- Exact version tags such as `2.0.0`, `2.0.1`, `2.0.2`, and `2.0.3` are immutable.
- Minor tags such as `1.8` move only to the newest accepted stable patch in that
  minor line.
- `latest` moves only to the newest accepted stable public release.
- Git tags use `v` (`v2.0.3`); application and Docker versions do not.

See [Docker image and tag policy](DOCKER.md).

## Lifecycle compatibility metadata

`release.json` is the machine-readable source for the current schema, backup
format, minimum upgrade source, explicit supported-source list, image digest,
platform, and lifecycle-tool checksum. Upgrade support is opt-in per target
release; a floating Docker tag alone never establishes compatibility.

## Persistent release-history policy

`CHANGELOG.md` is the canonical persistent release history for Veleis. Every
release—including patch, minor, and major releases—must update its corresponding
changelog entry before publication. GitHub Release notes must be written or
generated from that entry.

Do not create per-version `RELEASE-NOTES-<version>.md` files. Release preparation
must instead update the README and existing documentation whenever a release
changes features, installation, operation, compatibility, security,
requirements, or other user-facing behavior.

The public validation workflow enforces the durable parts of this policy: it
rejects per-version release-note files and requires the version declared in
`release.json` to have a matching `CHANGELOG.md` entry. These checks apply to
all future releases, including 1.7.2, 1.8.0, 2.0.0, and later versions.
