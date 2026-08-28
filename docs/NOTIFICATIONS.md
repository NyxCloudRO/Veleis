# Notifications and Escalation Policies

[← Documentation home](../README.md)

Notification channels are managed under Notifications. Existing channels can
be edited in place, including their display name and destination settings;
secret fields remain write-only.

Escalation policies define an ordered sequence of notification steps. Each
step selects a channel and delay, and can be reordered before saving. Assign a
policy to the relevant monitored asset or alerting workflow, then use the
channel test action before relying on it for incidents.

Veleis records notification attempts and escalation progress, but successful
delivery still depends on the external provider. Keep provider credentials
current and retain an independent path for critical operational alerts.

An opening notification may include bounded current correlation context when
accepted dependency evidence is available. This enrichment is supplementary:
the base notification remains deliverable if the lookup is unavailable,
recovery omits potentially stale correlation claims, and correlation never
merges routes, suppresses delivery generically, or changes escalation and retry
semantics.

See [Alerts and incidents](ALERTS.md) for acknowledgement and resolution
semantics.
