# Docker Image and Tag Policy

[← Documentation home](../README.md)

Official repository:
[docker.io/nyxmael/veleis](https://hub.docker.com/r/nyxmael/veleis)

```bash
docker pull nyxmael/veleis:1.8.12
```

## Tags

| Tag      | Meaning                                                             | Current digest                                                            |
| -------- | ------------------------------------------------------------------- | ------------------------------------------------------------------------- |
| `1.7.0`  | Immutable exact release. It will not move to another build.         | `sha256:5905637213977e8fd5d9f159b65c507a74defe25bac0b0a1b1d66d2602e279fe` |
| `1.7.1`  | Immutable prior release. It will not move to another build.         | `sha256:5fe5948c818a58cda38ded206c594669f6edbbb647703e6cd0055ebf3720c73a` |
| `1.7`    | Floating minor track: newest accepted stable `1.7.x`.               | Same as `1.7.1`                                                           |
| `1.8.0`  | Immutable prior release. It will not move to another build.         | `sha256:b1a3b106599d8b297f48a4573051c3dc646e12bd69c35cfbdae4d49edafff85b` |
| `1.8.1`  | Immutable prior release. It will not move to another build.         | `sha256:5afeb90ec365282990a080c0cc26e84d2fffe69986a87c48612abb9a3260fcfe` |
| `1.8.2`  | Immutable prior release. It will not move to another build.         | `sha256:074c9a6584873e07a793fdb0eaff24f32e292aa387a57314109380f6d1efbda4` |
| `1.8.3`  | Immutable prior release. It will not move to another build.         | `sha256:b8f0f01242371128a3ad8f559d535781f99b7c3ee9bc035781116a8644cf8901` |
| `1.8.4`  | Immutable prior release. It will not move to another build.         | `sha256:40e5927272fc2fc415cea2b50d1d3d5bf63de6876094335b855ab26395415cd3` |
| `1.8.5`  | Immutable prior release. It will not move to another build.         | `sha256:cab41f4a7f63a2ac39295cac1940ff8c524ddf220f6083d2934d977210feb621` |
| `1.8.6`  | Immutable prior release. It will not move to another build.         | `sha256:1c51cd1f41644e72fc734aaa0132a2b6c69d9723c2ea6af9c0c4bf690e4df813` |
| `1.8.7`  | Immutable prior release. It will not move to another build.         | `sha256:894b469f8c1a210f59b2981ea15c473055c56ae77a4c865bbdccecd2d87a8568` |
| `1.8.8`  | Immutable prior release. It will not move to another build.         | `sha256:4f082699b5bec6261f119ea6f620decbf9bcfc72c06523b1e8ae1c8e00a98f8a` |
| `1.8.9`  | Immutable prior release. It will not move to another build.         | `sha256:6c6e0227c941082d3fa6ef51e67133472e1ce2e16e478fc2e2a2c5120f2ded45` |
| `1.8.10` | Immutable prior release. It will not move to another build.         | `sha256:8582265d40de9f531a886f645fd3fd6fbab3e06321c90d0c69344d47a284fcf3` |
| `1.8.11` | Immutable prior release. It will not move to another build.         | `sha256:435d1a3a5b404f8aec2f8fdd3139a8a3f81ba37829eaf44d23bc8f42516876fb` |
| `1.8.12` | Immutable exact current release. It will not move to another build. | `sha256:9ccee823388e437012143eaf622bf8e7d91ffaf6edb0d06cc861cff10fa27e90` |
| `1.8`    | Floating minor track: newest accepted stable `1.8.x`.               | Same as `1.8.12`                                                          |
| `latest` | Floating newest accepted stable release.                            | Same as `1.8.12`                                                          |

The `1.7` tag remains on the newest accepted 1.7 patch. `1.8` tracks accepted
1.8 releases, and `latest` resolves to the accepted 1.8.12 image. Immutable
prior releases remain at their original digests.

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
