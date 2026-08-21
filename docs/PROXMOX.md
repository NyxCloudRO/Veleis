# Proxmox VE Setup

[← Documentation home](../README.md) · [Custom dashboards](DASHBOARDS.md) · [Security](SECURITY.md)

Veleis observes Proxmox VE through its HTTPS API. The integration is GET-only:
it discovers nodes, VM/LXC workloads, storage, networks, metadata, and
relationships, but does not start, stop, migrate, snapshot, or otherwise mutate
infrastructure.

Veleis has been validated with Proxmox VE 9.x, including 9.2.x. This is a
conservative tested-version statement, not a claim that every past or future
Proxmox release is supported.

## Prerequisites

- Network reachability from the Veleis container host to Proxmox API port 8006.
- A dedicated Proxmox user and API token used only by Veleis.
- Effective read-only `PVEAuditor` permission at `/` with Propagate.
- A trusted HTTPS certificate/CA, or an explicit operator decision for an
  isolated self-signed endpoint.

## Recommended least-privilege setup

The exact Proxmox UI labels can vary slightly by version.

1. Create a dedicated user, for example `veleis@pam`.
2. Create an API token for that user with token ID `veleis`.
3. Keep **Privilege Separation** enabled.
4. Grant the parent user `PVEAuditor` on ACL path `/` with **Propagate**.
5. Ensure the separated API token also resolves effective `PVEAuditor` access
   on `/` with **Propagate**. With Privilege Separation, a parent-user grant
   alone is not sufficient if the token's separated privileges do not include
   the same read-only scope.
6. Copy the token secret once into Veleis; Proxmox will not show it again.

Do not grant `Administrator` or mutation privileges. Veleis needs audit/read
access, not infrastructure control.

## Add the provider in Veleis

Open **Discovery → Providers → Add Proxmox provider** and enter:

- Hostname/IP: `pve.example.local`
- Port: `8006`
- HTTPS: enabled
- User: `veleis`
- Realm: `pam`
- Token ID: `veleis`
- Token secret: the one-time secret from Proxmox
- Collection interval and optional node filter appropriate to your environment

Use **Test connection**, then add the provider. The first collection populates
Veleis-owned normalized Discovery inventory. Custom Dashboard widgets read that
stored model and never call the Proxmox API from the browser.

## TLS validation

Leave certificate validation enabled when the endpoint has a trusted
certificate or the issuing CA is trusted by the Veleis runtime. **Ignore SSL
validation** weakens endpoint-authenticity verification and should be used only
when you understand and trust the isolated endpoint. It is not the recommended
default.

## Troubleshooting

### 401 Authentication failed

Check the realm, parent user, token ID, and token secret. The API identity is
the combined user/realm and token ID; a copied token name is not a token secret.
Regenerate a token secret if its value is no longer known.

### 403 Permission check failed (/, Sys.Audit)

The effective token permissions are insufficient. Verify `PVEAuditor` on `/`
with Propagate for both the parent user and, when Privilege Separation is
enabled, the separated API token.

### provider configuration is invalid

Check that hostname/IP, port, user, realm, token ID, token secret, HTTPS choice,
and optional node filters are in the expected Veleis fields. Do not paste a
combined Proxmox token identity into the User field.

### Provider is stale or unavailable

Confirm routing, DNS, TCP 8006, certificate trust, token validity, and effective
permissions. Veleis keeps the last normalized observations visible with issue
or stale context; it does not represent them as freshly collected.

## Read-only request surface

Connection testing and collection use observational GET requests, including
Proxmox version, cluster status/resources, node inventory, and node network
inventory. No POST, PUT, PATCH, or DELETE infrastructure request is implemented.
