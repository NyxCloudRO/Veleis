# Releases and Supported Versions

[← Documentation home](../README.md) · [Changelog](../CHANGELOG.md)

## Current stable release

Veleis **1.8.0** is the current stable release.

| Component | Release identity |
| --------- | ---------------- |
| Application | `1.8.0` |
| Git tag and GitHub Release | `v1.8.0` |
| Installer target | `docker.io/nyxmael/veleis:1.8.0` |
| Docker manifest | `sha256:b1a3b106599d8b297f48a4573051c3dc646e12bd69c35cfbdae4d49edafff85b` |
| Schema | 33 |
| Backup format | 1 |

Veleis 1.7.0 and 1.7.1 remain immutable at their original Docker digests and
GitHub releases. The supported transition from 1.7.1 to 1.8.0 uses a mandatory
pre-upgrade backup and advances schema 32 to 33.

## Supported versions

| Version | Status |
| ------- | ------ |
| 1.8.x | Current public stable line; eligible for security and correctness fixes |
| 1.7.1 | Supported upgrade source for 1.8.0 |
| 1.7.0 | Prior immutable release; upgrade to 1.7.1 first |
| <1.7 | Pre-public development; no public support |

This policy is a conservative community release policy, not a contractual SLA.
Only releases and platforms explicitly listed in current documentation are
supported.

## Version and channel policy

- Exact version tags such as `1.8.0` are immutable.
- Minor tags such as `1.8` move only to the newest accepted stable patch in that
  minor line.
- `latest` moves only to the newest accepted stable public release.
- Git tags use `v` (`v1.8.0`); application and Docker versions do not.

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
