# Ravyr Fleet Lifecycle

[← Documentation home](../README.md) · [Security](SECURITY.md) · [Troubleshooting](TROUBLESHOOTING.md)

Ravyr is Veleis's optional outbound-only Linux observer. It reports host,
service, process, runtime, inventory, and optional Docker observations to its
enrolled Veleis server. Ravyr has no listener, remote shell, arbitrary command
handler, infrastructure-control API, or package-management facility.

## Install and enroll

Open **Agents → Install Ravyr**, name the intended host, and generate the
one-time command. The command first retrieves the presented server certificate,
verifies its authenticated SHA-256 fingerprint, and uses that verified
certificate as a temporary CA to download the checksum and small installer
through normal TLS validation. The installer then establishes persistent
CA-validated HTTPS; no stage relies on `curl -k`. The token
is exchanged once for that host's durable identity and is not its continuing
credential. Protect the command while it is valid and never reuse it on another
host. The UI reports a successful clipboard copy and provides manual selection
if browser clipboard access is unavailable.

The installer supports direct root execution and ordinary `sudo` on the tested
Ubuntu and Debian hosts. It creates `/etc/veleis` for configuration,
`/var/lib/veleis-ravyr` for private state, and
`/usr/local/lib/veleis-ravyr` for updater-owned lifecycle files before enabling
the hardened units.

Installation creates three narrowly scoped systemd units:

- `ravyr.service` observes the host and sends telemetry;
- `ravyr-updater.service` performs one bounded lifecycle check; and
- `ravyr-updater.timer` schedules checks with stable jitter.

The updater runs as root because replacing a root-owned executable and
restarting `ravyr.service` require privilege. It may modify only Ravyr-owned
binary and state locations. It cannot execute server-provided shell, select a
service name, install packages, or download from an arbitrary origin.

## Automatic updates

New installations follow the global **Stable / Progressive** policy with
automatic updates enabled. The server publishes a recommended version, minimum
supported version, protocol range, concurrency limit, and optional maintenance
window. Compatible older agents continue monitoring while waiting for their
cohort; offline agents catch up after their next authenticated connection.

Progressive rollout uses deterministic 1%, 5%, 25%, 50%, and 100% cohorts based
on agent identity and release identity. Healthy stages advance automatically.
Operators may set an agent to Follow Global, Canary, Stable, or exceptional
Manual/Pinned policy. Update timing is explicit:

- **Any time** means an eligible cohort may update whenever its concurrency slot
  is available. Window fields are inactive and cleared.
- **Maintenance window** means a recurring daily local-time range, not a
  calendar appointment. Start, end, and an IANA timezone are required. An
  overnight range such as 23:00–03:00 is valid.

The timezone selector is searchable (`Bucharest` finds
`Europe/Bucharest`). On first use only, the browser's valid IANA timezone is
suggested; a saved policy is never overwritten. IANA rules automatically apply
daylight-saving changes, so operators do not manually convert EET/EEST or other
seasonal offsets. Existing `UTC` policies remain valid.

Per-agent policies mean:

- **Follow Global** uses the fleet-wide rollout and timing policy.
- **Canary** receives compatible releases first for safety validation.
- **Stable** receives stable releases automatically without canary priority.
- **Manual / pinned** disables automatic updates for that agent.

Without a maintenance window, stable cohort and concurrency limits still
prevent restart storms.

The Agents workspace shows fleet totals, recommended/minimum versions, and each
agent's installed version, compatibility, connectivity, channel, and update
state as separate facts. An older manual agent is **Pinned**, never misleadingly
**Current**. A rollback names the restored and failed target versions plus a
human reason. A failed canary produces a clear paused-rollout banner; remaining
agents stay put. Saving timing or concurrency cannot resume a pause—**Resume
rollout** is a separate confirmed action. Normal compatible updates require no
per-host SSH action.

## Verification and rollback

Ravyr downloads the strict same-origin release manifest and candidate into
private staging. Before activation it validates server/protocol compatibility,
Linux/amd64, exact path, bounded size, SHA-256, Ed25519 signature, and trusted
key ID. Veleis 1.8.3 trusts the signed Ravyr 1.8.2 key
`226fc31b6ee01ca3`; unsigned metadata cannot
replace the trusted key.

Activation preflights disk and permissions, retains one previous binary, stages
on the target filesystem, switches atomically, and restarts only
`ravyr.service`. Success requires a resumed heartbeat and post-start telemetry.
On failure the updater restores the known-good binary, verifies recovery,
records the rollback, blocks that release for the host, and pauses wider fleet
rollout. A newer release or explicit policy revision is required before another
attempt, preventing an update/rollback loop. Identity, credentials,
configuration, and the bounded telemetry spool are not replaced.

## Troubleshooting

Start with the Agents workspace lifecycle state and bounded event history, then
inspect the local units without exposing the enrollment configuration:

```bash
sudo systemctl status ravyr.service ravyr-updater.timer
sudo journalctl -u ravyr.service -u ravyr-updater.service --since '1 hour ago'
```

Check outbound HTTPS/DNS, clock synchronization, free space, ownership of
Ravyr-owned paths, the configured maintenance window, fleet pause reason, and
whether the installed version is still compatible. Do not bypass signature or
same-origin validation. A failed candidate should remain blocked while the
previous agent continues monitoring.

## Disable or uninstall

Revoke or disable the agent in Veleis first when retiring a host. To stop local
collection and future lifecycle checks:

```bash
sudo systemctl disable --now ravyr-updater.timer ravyr-updater.service ravyr.service
```

An automated destructive uninstall is not published. Retain the Ravyr identity,
configuration, spool, and previous binary until the retirement is confirmed;
remove Ravyr-owned files only under the host operator's normal change process.
