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

Each intentionally configured rule keeps its own lifecycle. A firing transition
and configured recovery transition may notify independently for each rule.
Delivery deduplication is keyed by notification channel, incident, and
transition type, so repeated evaluation of the same transition cannot enqueue
duplicate Discord/webhook/email noise. Cooldown, retry, recovery, silence,
maintenance-window, and dependency suppression behavior remains authoritative.

Suppression hides delivery according to its reason; it does not erase the
active condition. Dependency-based notification suppression leaves raw alerts
and incidents visible. Webhook and SMTP credentials remain encrypted/write-only
and are never returned by alert search or details.

For large estates, leave the default active-state selection in place, filter by
severity/source/target when triaging, and request Normal only for deliberate
diagnosis. With 1,000 healthy targets and three firing targets, the default view
represents the three operational problems rather than rendering 1,000 green
rows.

