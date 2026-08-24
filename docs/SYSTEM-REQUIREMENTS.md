# System Requirements

[← Documentation home](../README.md)

## Supported platform

| Requirement | Supported |
| ----------- | --------- |
| Operating systems | Ubuntu 24.04.4 LTS; Debian 13.6 |
| CPU architecture | linux/amd64 |
| Container runtime | Docker Engine with Docker Compose v2; installer can install distribution packages |
| Quick Start tool | `curl` must be present to retrieve the piped installer |
| External application port | TCP 443 (HTTPS) |
| Database port | Not host-published; internal Compose network only |

Other Debian/Ubuntu releases, derivatives, and arm64 have not completed public
clean-install acceptance and are not claimed as supported for 1.8.4.

## Host sizing

| Resource | Minimum starting point | Recommended starting point |
| -------- | ---------------------- | -------------------------- |
| CPU | 2 vCPU | 4 vCPU |
| Memory | 4 GiB | 8 GiB |
| Free storage | 20 GiB | 50 GiB or more on SSD |
| Network | Stable installation access | Stable access to every monitored/notification endpoint |

These are deployment starting points, not unlimited-capacity guarantees.
Increase resources for short probe intervals, many agents/containers, large
Discovery inventories, or long retention. Monitor the capacity view and the
Docker host's storage.

## Network access

During installation, the host needs DNS and outbound HTTP/HTTPS access to its
Debian/Ubuntu package repositories, Docker Hub, and GitHub's raw-content host.
Normal operation may require outbound access to:

- configured HTTP, TCP, DNS, SMTP, IMAP, and TLS targets;
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
