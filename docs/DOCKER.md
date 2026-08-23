# Docker Image and Tag Policy

[← Documentation home](../README.md)

Official repository:
[docker.io/nyxmael/veleis](https://hub.docker.com/r/nyxmael/veleis)

```bash
docker pull nyxmael/veleis:1.8.3
```

## Tags

| Tag | Meaning | Current digest |
| --- | ------- | -------------- |
| `1.7.0` | Immutable exact release. It will not move to another build. | `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe` |
| `1.7.1` | Immutable prior release. It will not move to another build. | `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a` |
| `1.7` | Floating minor track: newest accepted stable `1.7.x`. | Same as `1.7.1` |
| `1.8.0` | Immutable prior release. It will not move to another build. | `sha256:b1a3b106599d8b297f48a4573051c3dc646e12bd69c35cfbdae4d49edafff85b` |
| `1.8.1` | Immutable prior release. It will not move to another build. | `sha256:5afeb90ec365282990a080c0cc26e84d2fffe69986a87c48612abb9a3260fcfe` |
| `1.8.2` | Immutable prior release. It will not move to another build. | `sha256:074c9a6584873e07a793fdb0eaff24f32e292aa387a57314109380f6d1efbda4` |
| `1.8.3` | Immutable exact current release. It will not move to another build. | `sha256:b8f0f01242371128a3ad8f559d535781f99b7c3ee9bc035781116a8644cf8901` |
| `1.8` | Floating minor track: newest accepted stable `1.8.x`. | Same as `1.8.3` |
| `latest` | Floating newest accepted stable release. | Same as `1.8.3` |

The `1.7` tag remains on the newest accepted 1.7 patch. `1.8` tracks accepted
1.8 releases, and `latest` resolves to the accepted 1.8.3 image.

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
