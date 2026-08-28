# Alert Rules, Evaluations, and Active Alerts

[← Documentation home](../README.md) · [Features](FEATURES.md) · [Operability hardening](OPERABILITY-HARDENING.md)

An **Alert Rule** is configuration. An **Evaluation** is the rule's current
result for a target. **Active Alerts** is the bounded operational view of
conditions that need attention; it is not the complete healthy evaluation
matrix.

## Active-state semantics

By default Active Alerts includes Pending, Firing, still-active Acknowledged,
still-active Suppressed, Recovering, No Data, and evaluator-error states.
Resolved, disabled, and healthy Normal evaluations do not appear or contribute
to active totals. Select the explicit Normal state filter when troubleshooting
healthy evaluation truth. If no condition needs attention, the view says
**No active alerts**.

Acknowledgement records that an operator has seen an active alert. It does not
change evaluation truth, suppression, maintenance, dependency interpretation,
incident state, or recovery behavior.

The compact list provides state, severity, rule/source, target, suppression,
server search/filter/sort, active-only summary counts, and 25/50/100-page
pagination. Details show the rule, current condition, timestamps, suppression,
notification/incident context, transitions, and bounded diagnostics without
dumping raw internal JSON.

## Availability rule guidance

A common, optional pattern is:

- `degraded` → Warning, named **Probe Degraded**;
- `down` → Critical, named **Probe Down**.

Veleis does not force that policy. Before saving, rule review warns when one
severity covers both degraded and down or another rule overlaps the same
condition, scope, targets, and states. Intentional overlapping rules remain
distinct configuration objects and are identified by their own rule details;
the warning prevents accidental ambiguity rather than silently rewriting them.

## Notifications and deduplication

Each intentionally configured rule keeps its own lifecycle. Within that rule,
the rule/target identity plus condition is deterministic: repeated firing
observations update one active incident generation rather than opening
duplicates. Severity changes remain transitions, recovery is authoritative,
and a later failure starts a new generation. A firing transition and configured
recovery transition may notify independently for each rule. Delivery
deduplication remains keyed by notification channel, incident, and transition
type, so repeated evaluation of the same transition cannot enqueue duplicate
Discord/webhook/email noise. Independently configured routes remain independent
even when they share a destination. Cooldown, retry, recovery, silence,
maintenance-window, and dependency suppression behavior remains authoritative.

An Alert Rule may instead assign one enabled escalation policy. The policy is
snapshotted when the incident opens, so later policy edits cannot rewrite an
active execution. Steps use strictly increasing absolute time from escalation
start—not time relative to the previous step—and may target multiple channels.
Configured acknowledgement, recovery, manual resolution, and retirement stop
future work while preserving delivered history and provenance. See
[Notifications and escalation policies](NOTIFICATIONS.md).

Suppression hides delivery according to its reason; it does not erase the
active condition. Dependency-based notification suppression leaves raw alerts
and incidents visible. Webhook and SMTP credentials remain encrypted/write-only
and are never returned by alert search or details.

## Dependency awareness and correlation

Service Dependency Awareness can explain a bounded likely upstream or
downstream path when active alert incidents map to accepted current dependency
relationships. Timing, direction, cycles, multiple possible roots, and recovery
are represented explicitly; proximity, matching names, a shared asset, or a
shared notification destination are not sufficient evidence.

Cross-signal correlation consumes that accepted evidence to group distinct
incident UUIDs into a stable operational event. Original incidents and their
history remain authoritative. Incidents show bounded related-signal context,
likely-upstream wording, persisted evidence explanations, member/root
navigation, active or previous context, and an explicit Dependency Topology
deep-link. Multiple credible roots remain separate rather than being assigned a
probabilistic score. Veleis does not use AI/ML correlation.

Opening notifications may include a small current correlation count and likely
upstream context. If enrichment is unavailable, the base notification still
delivers. Recovery notifications omit correlation context so they cannot repeat
a stale upstream claim. Correlation never suppresses notifications, merges
routes, changes escalation, or alters retry/idempotency behavior.

### Human-readable channel rendering

Every delivery is built from one bounded canonical event containing only the
operator-facing lifecycle, severity, title/summary, target and rule names,
state, relevant times/duration, safe details, and an optional Veleis link. The
alert engine never hands implementation maps to channel providers.

- Discord receives one semantic embed: critical red, warning amber, recovery
  green, and test/informational neutral. Firing, warning, recovery, and test
  messages have distinct titles and concise fields. Opaque IDs are not shown;
  with a configured public HTTPS base URL, an ID may occur only in an
  investigation link.
- SMTP receives a UTF-8 plaintext message with a lifecycle subject such as
  `[CRITICAL] Service is down` or `[RECOVERED] Service is healthy`.
- Generic webhooks receive stable JSON schema version 1 rather than Discord
  markup. Optional values are omitted intentionally and collections remain
  arrays. A signing secret produces `X-Veleis-Signature` over the exact body.

A representative test notification uses the same renderer as real delivery and
names the configured channel. No production incident is required to verify
formatting. Discord setup requires only a webhook for the chosen channel; treat
its URL as a credential, restrict who can manage it, and rotate it if exposed.

### Retry, rate limits, and troubleshooting

Delivery claims are bounded to five attempts. HTTP 408 and 5xx failures retry
with bounded backoff; ordinary 4xx responses fail permanently. HTTP 429 honors
`Retry-After` up to 15 minutes, preventing an aggressive retry storm. History
shows channel, event, result, attempts, time, and a sanitized error summary
without the destination URL or secret.

If a test fails, verify outbound DNS/HTTPS or SMTP connectivity, the provider's
response, sender/recipient policy, and whether a Discord webhook was revoked.
Repeated evaluations do not create repeated lifecycle deliveries because
deduplication happens before rendering. Silence, alert maintenance, and
dependency suppression remain authoritative.

Generic webhook schema-v1 shape:

```json
{
  "schema_version": 1,
  "event": "incident.opened",
  "severity": "critical",
  "title": "Public API",
  "summary": "Probe availability is down.",
  "target": { "name": "Public API" },
  "rule": { "name": "Probe Down" },
  "state": { "current": "Down", "previous": "Up" },
  "timestamps": { "occurred_at": "2026-08-22T19:42:00Z" },
  "details": []
}
```

For large estates, leave the default active-state selection in place, filter by
severity/source/target when triaging, and request Normal only for deliberate
diagnosis. With 1,000 healthy targets and three firing targets, the default view
represents the three operational problems rather than rendering 1,000 green
rows.
