# SNMP Monitoring

[← Documentation home](../README.md)

Veleis 1.8.5 adds read-only SNMP probes for monitoring one scalar numeric OID
at a time. SNMP uses the same scheduler, current state, history, incidents,
alerts, and manual-run workflow as other Veleis probes.

## Supported protocols

- SNMPv2c with a write-only community value.
- SNMPv3 `noAuthNoPriv`, `authNoPriv`, and `authPriv`.
- Authentication: SHA-1 for compatibility, plus SHA-224, SHA-256, SHA-384,
  and SHA-512. MD5 is rejected.
- Privacy: AES-128, AES-192, and AES-256. DES is rejected.

Use SNMPv3 `authPriv` wherever device support and security requirements allow.
Apply least-privilege, read-only device credentials and restrict UDP access to
the Veleis host.

## Target and OID

Set a hostname or IP address and a UDP port; the default is 161. The shared
probe destination policy resolves the target according to the selected IP mode
and rejects protected cloud-metadata destinations. Enter a numeric scalar OID,
for example `1.3.6.1.2.1.1.3.0`. Symbolic MIB names are not resolved.

Each attempt performs one bounded scalar `GET`. Veleis records the canonical
OID, returned SNMP type, exact bounded value, resolved address, condition
outcome, and latency. Supported values include integer/counter/gauge/timetick,
octet string, object identifier, IP address, and opaque floating-point types.
Large counters retain an exact decimal representation.

## Conditions

Choose OID responds, equals, not equals, greater than, greater than or equal,
less than, less than or equal, contains, or does not contain. Ordered operators
require numeric values; text operators require text values. Type mismatches are
safe failed observations rather than implicit conversions.

## Credential behavior

Communities and SNMPv3 authentication/privacy secrets are encrypted with the
installation master key. They are accepted only through authenticated writes,
never returned to the browser, and never written to normal logs. Probe reads
show only whether each required secret is configured. Leaving a replacement
field blank during an edit preserves the existing credential; changing version
or security level removes credential components that are no longer applicable.

Back up `/opt/veleis/.env` with the database through `sudo veleis backup`.
Losing the application master key can make encrypted probe credentials
unrecoverable.

## Read-only boundary and limitations

Veleis never issues SNMP `SET` and exposes no SNMP write path. Version 1.8.5
does not implement GETNEXT, GETBULK, WALK, device/interface discovery, traps,
trap reception, or symbolic MIB-name resolution. Configure monitoring inside
Veleis only; the probe cannot reconfigure the target device.

AES-192/AES-256 interoperability depends on the device's SNMPv3 USM extension
variant. AES-128 is usually the broadest interoperable privacy choice. SHA-1 is
available only for compatibility and appears after the preferred SHA-2 family.

## Troubleshooting

If a probe times out, verify routing, firewall rules, UDP port, SNMP version,
security level, username, algorithms, and the exact numeric OID from the Veleis
host. A response with an unexpected type may require a different condition.
Replace credentials through the edit form; do not paste secrets into Issues or
logs.
