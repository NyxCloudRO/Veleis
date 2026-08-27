# System Requirements

[← Documentation home](../README.md)

## Tested and supported platforms

Veleis 1.8.8 installation is validated on the following host platforms:

| Distribution | Version | Status |
| ------------ | ------- | ------ |
| Ubuntu | 24.04 LTS | Supported / validated |
| Ubuntu | 25.04 | Supported / validated |
| Ubuntu | 26.04 LTS | Supported / validated |
| Debian | 12 (Bookworm) | Supported / validated |
| Debian | 13 (Trixie) | Supported / validated |

Architecture: `amd64 / x86_64`

Other Linux distributions or releases may work, but are not currently part of
the validated Veleis installation matrix. Derivative distributions and arm64
are not implied or supported by this matrix.

## Host requirements

| Requirement | Supported |
| ----------- | --------- |
| Operating systems | One of the exact validated releases listed above |
| CPU architecture | linux/amd64 (`amd64 / x86_64`) |
| Container runtime | Docker Engine with Docker Compose v2; installer can install distribution packages |
| Quick Start tool | `curl` must be present to retrieve the piped installer |
| External application port | TCP 443 (HTTPS) |
| Database port | Not host-published; internal Compose network only |

## Host sizing

| Resource | Minimum starting point | Recommended starting point |
| -------- | ---------------------- | -------------------------- |
| CPU | 2 vCPU | 4 vCPU |
| Memory | 1 GiB for a minimal low-load installation | 2 GiB practical small-install starting point |
| Free storage | 20 GiB | 50 GiB or more on SSD |
| Network | Stable installation access | Stable access to every monitored/notification endpoint |

These are deployment starting points, not unlimited-capacity guarantees. The
installer detects the minimum finite host/current-cgroup memory boundary and
generates a bounded PostgreSQL/TimescaleDB profile. Increase resources for
short probe intervals, many agents/containers, large Discovery inventories, or
long retention. Monitor the capacity view and the Docker host's storage.

## Network access

During installation, the host needs DNS and outbound HTTP/HTTPS access to its
Debian/Ubuntu package repositories, Docker Hub, and GitHub's raw-content host.
Normal operation may require outbound access to:

- configured HTTP, TCP, DNS, SMTP, IMAP, TLS, and SNMP targets (UDP 161 by
  default, or the explicitly configured SNMP port);
- webhook/Discord notification endpoints and SMTP notification servers;
- enrolled Ravyr agents' outbound connection path to Veleis;
- configured Proxmox API endpoints.

The installer does not edit UFW or nftables. Allow inbound TCP 443 through host
and network firewalls for the clients and agents that should reach Veleis.

## Browser

Use a current desktop release of Chrome/Chromium, Firefox, Safari, or Edge with
JavaScript, cookies, and modern TLS enabled. The responsive interface also
supports current mobile browsers. Default installations require acknowledging
or locally trusting the generated self-signed certificate.
