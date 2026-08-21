# Releases and Supported Versions

[← Documentation home](../README.md) · [Changelog](../CHANGELOG.md)

## Current stable release

Veleis **1.7.1** is the current stable release.

| Component | Release identity |
| --------- | ---------------- |
| Application | `1.7.1` |
| Git tag and GitHub Release | `v1.7.1` |
| Installer target | `docker.io/nyxmael/veleis:1.7.1` |
| Docker manifest | `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a` |
| Schema | 32 |
| Backup format | 1 |

Veleis 1.7.0 remains immutable at its original Docker digest and GitHub release.
The supported transition from 1.7.0 to 1.7.1 uses a mandatory pre-upgrade backup
and keeps schema 32.

## Supported versions

| Version | Status |
| ------- | ------ |
| 1.7.x | Current public stable line; eligible for security and correctness fixes |
| <1.7 | Pre-public development; no public support |

This policy is a conservative community release policy, not a contractual SLA.
Only releases and platforms explicitly listed in current documentation are
supported.

## Version and channel policy

- Exact version tags such as `1.7.0` are immutable.
- Minor tags such as `1.7` move only to the newest accepted stable patch in that
  minor line.
- `latest` moves only to the newest accepted stable public release.
- Git tags use `v` (`v1.7.1`); application and Docker versions do not.

See [Docker image and tag policy](DOCKER.md).

## Lifecycle compatibility metadata

`release.json` is the machine-readable source for the current schema, backup
format, minimum upgrade source, explicit supported-source list, image digest,
platform, and lifecycle-tool checksum. Upgrade support is opt-in per target
release; a floating Docker tag alone never establishes compatibility.
