# DNS Monitoring

[← Documentation home](../README.md)

Veleis supports direct DNS probes and Advanced DNS records in an asset's
Monitor tab. Advanced records cover MX, NS, SOA, SRV, CAA, TXT, and custom
record types while preserving the existing simple A/AAAA workflow.

For each record, choose the expected response and interval, save the asset,
then use the probe history and incident timeline to verify the result. DNS
answers are evaluated as monitoring evidence; Veleis does not modify zones or
act as an authoritative resolver. Avoid putting secrets in TXT expectations or
incident notes.

DNS changes can involve TTL and resolver-cache delay. Confirm an alert against
an independent resolver before changing production DNS solely in response to a
new incident.
