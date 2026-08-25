# Releases and Supported Versions

[← Documentation home](../README.md) · [Changelog](../CHANGELOG.md)

## Current stable release

Veleis **1.8.6** is the current stable release.

| Component | Release identity |
| --------- | ---------------- |
| Application | `1.8.6` |
| Git tag and GitHub Release | `v1.8.6` |
| Installer target | `docker.io/nyxmael/veleis:1.8.6` |
| Docker manifest | `sha256:1c51cd1f41644e72fc734aaa0132a2b6c69d9723c2ea6af9c0c4bf690e4df813` |
| Schema | 36 |
| Backup format | 1 |

All prior releases remain immutable at their original Docker digests and
GitHub releases. Upgrades from 1.7.1, 1.8.0, 1.8.1, 1.8.2, 1.8.3, 1.8.4, or
1.8.5 to 1.8.6 use a mandatory pre-upgrade backup; schema 32–35 advances to 36.

## Supported versions

| Version | Status |
| ------- | ------ |
| 1.8.x | Current public stable line; eligible for security and correctness fixes |
| 1.8.5 | Supported upgrade source for 1.8.6 |
| 1.8.4 | Supported upgrade source for 1.8.6 |
| 1.8.3 | Supported upgrade source for 1.8.6 |
| 1.8.2 | Supported upgrade source for 1.8.6 |
| 1.8.1 | Supported upgrade source for 1.8.6 |
| 1.8.0 | Supported upgrade source for 1.8.6 |
| 1.7.1 | Supported upgrade source for 1.8.6 |
| 1.7.0 | Prior immutable release; upgrade to 1.7.1 first |
| <1.7 | Pre-public development; no public support |

This policy is a conservative community release policy, not a contractual SLA.
Only releases and platforms explicitly listed in current documentation are
supported.

## Version and channel policy

- Exact version tags such as `1.8.5` and `1.8.6` are immutable.
- Minor tags such as `1.8` move only to the newest accepted stable patch in that
  minor line.
- `latest` moves only to the newest accepted stable public release.
- Git tags use `v` (`v1.8.6`); application and Docker versions do not.

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
