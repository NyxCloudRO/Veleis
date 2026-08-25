# Certificate Intelligence

[← Documentation home](../README.md)

Veleis 1.8.6 extends the existing TLS Certificate probe with bounded,
observational certificate identity and rotation history. It uses the same
configured host, port, SNI/server name, verification choice, timeout, and
scheduler lifecycle as the ordinary TLS probe.

## What is recorded

After each completed TLS handshake, Veleis records the active certificate's
SHA-256 fingerprint, subject, common name, issuer, serial number, validity
window, DNS and IP SANs, signature algorithm, public-key algorithm and size or
curve, certificate version, CA/self-signed classification, chain length,
verification/chain/hostname state, and first/last seen timestamps. Repeated
observations increment a counter instead of creating duplicate identities.

When the fingerprint changes from A to B, Veleis marks A as previous, B as
current, and records one change event with the changed fields and
classification. Repeated B observations do not create another event. The API
and UI return at most 50 identities and 50 changes per probe.

## Security and operating boundary

Certificate Intelligence is read-only monitoring. It cannot issue, renew,
replace, install, deploy, revoke, or reconfigure certificates. It never reads
or returns a target private key. The authenticated API requires probe-read
permission and returns not found when used with a non-TLS probe.

Verification enabled means normal chain and hostname validation applies.
Verification disabled is reported explicitly and should be used only for
deliberate monitoring of private or self-signed endpoints. Expired,
not-yet-valid, hostname-mismatched, untrusted, and self-signed observations are
classified rather than silently treated as trusted.

## Upgrade behavior and limitations

Schema 36 creates the certificate identity and change tables. Existing TLS
probes need no reconfiguration and begin populating Certificate Intelligence on
their next completed handshake. Historical handshakes from before schema 36
cannot be reconstructed. The feature observes the leaf certificate and bounded
presented-chain metadata; it is not a certificate authority, renewal service,
certificate-transparency client, or active internet-wide scanner.
