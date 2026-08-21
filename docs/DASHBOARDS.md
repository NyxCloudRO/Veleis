# Custom Dashboards

[← Documentation home](../README.md) · [Features](FEATURES.md) · [Proxmox setup](PROXMOX.md)

Custom Dashboards are user-owned, read-only operational views. Widgets can be
moved and resized, and their layout, configuration, and revision are persisted.
They do not add infrastructure control actions.

## Discovery & Proxmox widgets

Veleis 1.7.1 adds a dedicated **Discovery & Proxmox** catalog category:

| Widget | Displays |
| --- | --- |
| Proxmox overview | Provider state and freshness; nodes online/offline; VM, LXC, running/stopped workload, and storage counts |
| Proxmox workloads | A bounded VM/LXC list with name, type, VMID, node, state, and provider |
| Proxmox storage | Bounded normalized storage inventory with type, node, state, shared status, and capacity only when the provider reported a trustworthy total |
| Discovery summary | Configured/current/issue providers, active infrastructure objects and relationships, recent changes, and latest collection |
| Discovery activity | A bounded newest-first list of added, changed, removed, renamed, or moved normalized objects |

Each widget can use **All providers** or an explicitly selected Proxmox
provider. The selection is stored with the dashboard. Veleis never silently
chooses an arbitrary provider. A deleted selection is shown as unavailable;
disabled, unhealthy, and stale providers retain their visible context.

## Infrastructure summary

The Infrastructure summary widget presents six compact signals: configured
providers, discovered infrastructure, Proxmox workloads, active incidents,
online agents, and running Docker containers. These values keep their distinct
product meanings and do not imply that discovered objects are active monitors.

## Bounds and access

Workload, storage, and activity rows are limited to 25 per widget. Dashboard
requests use Veleis-owned normalized data and do not contact Proxmox. API tokens
must satisfy both `dashboards:read` and `discovery:read` where the requested data
requires both permissions; user role permissions remain authoritative.

Existing 1.7.0 dashboards continue to load unchanged after upgrading. New
widget configuration is optional and has backward-compatible defaults.

## Current limitations

Veleis does not persist historical Proxmox CPU or memory timeseries in 1.7.1,
so this release does not provide Proxmox resource charts. A separate node-health
widget was not added because its reliable current node state is already included
in Proxmox overview; no additional polling subsystem was introduced.
