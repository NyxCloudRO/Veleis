# Releases and Supported Versions

[← Documentation home](../README.md) · [Changelog](../CHANGELOG.md)

## Current stable release

Veleis **1.7.0** is the first public distribution.

| Component | Release identity |
| --------- | ---------------- |
| Application | `1.7.0` |
| Git tag and GitHub Release | `v1.7.0` |
| Installer target | `docker.io/nyxmael/veleis:1.7.0` |
| Docker manifest | `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe` |
| Schema | 32 |

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
- Git tags use `v` (`v1.7.0`); application and Docker versions do not.

See [Docker image and tag policy](DOCKER.md).
