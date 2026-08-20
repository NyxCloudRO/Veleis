# Upgrading

[← Documentation home](../README.md)

Veleis 1.7.0 provides an accepted clean-install workflow. A supported public
upgrade and rollback workflow is not yet available.

The installer deliberately stops when `/opt/veleis` already exists. Do not:

- rerun the clean installer over an existing instance;
- edit `VELEIS_IMAGE` to a floating tag and run `docker compose up` as an
  improvised upgrade;
- remove the database volume to resolve version or migration errors; or
- assume an image pull alone performs compatibility, backup, migration, and
  rollback validation.

Exact tag `1.7.0` remains immutable. `1.7` and `latest` are documented release
channels, not instructions to auto-update an installation.

Upgrade + backup/restore release engineering is the next planned distribution
milestone. Release notes will publish a tested process before users are asked to
move an existing installation.
