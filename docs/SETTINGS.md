# Settings

[← Documentation home](../README.md)

Settings provides authenticated administration for users, API tokens,
retention, notification providers, appearance, and other installation-level
product controls. Available sections depend on the signed-in role; Owner-only
actions are not exposed to lower-privilege users.

Authentication policy includes server-authoritative inactivity and absolute
session lifetimes. The defaults are 30 minutes of inactivity and seven days
absolute lifetime. Owners can adjust supported values through Settings;
expiring sessions show a warning and require an intentional, CSRF-protected
continuation. Activity that does not represent an intentional authenticated
interaction does not silently extend a session.

Changes are validated before persistence and security-sensitive values remain
write-only. Create a backup before retention reductions or broad access-policy
changes. Host lifecycle configuration, Docker image identity, database memory,
TLS files, and upgrades are intentionally managed with the `veleis` operator
command rather than through Settings.

For host configuration boundaries, see [Configuration and data](CONFIGURATION.md).
