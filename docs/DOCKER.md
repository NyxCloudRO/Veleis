# Docker Image and Tag Policy

[← Documentation home](../README.md)

Official repository:
[docker.io/nyxmael/veleis](https://hub.docker.com/r/nyxmael/veleis)

```bash
docker pull nyxmael/veleis:1.7.1
```

## Tags

| Tag | Meaning | Current digest |
| --- | ------- | -------------- |
| `1.7.0` | Immutable exact release. It will not move to another build. | `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe` |
| `1.7.1` | Immutable exact current release. It will not move to another build. | `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a` |
| `1.7` | Floating minor track: newest accepted stable `1.7.x`. | Same as `1.7.1` |
| `latest` | Floating newest accepted stable release. | Same as `1.7.1` |

The `1.7` tag exists so operators who deliberately follow compatible 1.7 patch
releases have a minor channel. Veleis `1.7.0` remains unchanged while `1.7` and
`latest` now resolve to the accepted `1.7.1` image.
When `1.8.0` becomes stable, `1.7` remains on the newest accepted 1.7 patch,
`1.8` tracks 1.8, and `latest` advances to the newest stable line.

Each release installer deliberately uses its immutable exact tag, not a floating
channel. Old release installers therefore cannot silently install a future
image.

## Use the installer

The application image alone is not a complete deployment. Normal users should
use [the installer](INSTALLATION.md), which provides the pinned database,
migrations, secrets, TLS, internal networking, persistence, and readiness
checks. PostgreSQL is not exposed publicly by the supported Compose topology.

The public image is currently linux/amd64 only. It runs as a non-root user from
a minimal distroless runtime.
