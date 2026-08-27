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

See [Alerts and incidents](ALERTS.md) for acknowledgement and resolution
semantics.
