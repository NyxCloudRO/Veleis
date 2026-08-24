#!/bin/sh
set -eu

config_directory="/etc/veleis"
state_directory="/var/lib/veleis-ravyr"
library_directory="/usr/local/lib/veleis-ravyr"
config_path="$config_directory/ravyr.json"

[ "$(id -u)" -eq 0 ] || { echo "Ravyr lifecycle repair requires root." >&2; exit 1; }
command -v systemctl >/dev/null 2>&1 || { echo "systemd is required." >&2; exit 1; }
getent group veleis-ravyr >/dev/null 2>&1 || { echo "The veleis-ravyr group is missing; use the supported installer." >&2; exit 1; }
id veleis-ravyr >/dev/null 2>&1 || { echo "The veleis-ravyr user is missing; use the supported installer." >&2; exit 1; }
[ -s "$config_path" ] || { echo "Existing Ravyr configuration is missing; repair will not re-enroll this host." >&2; exit 1; }
[ -x /usr/local/bin/ravyr ] || { echo "Existing Ravyr binary is missing." >&2; exit 1; }
[ -x /usr/local/bin/ravyr-updater ] || { echo "Existing Ravyr updater is missing." >&2; exit 1; }
[ -s /etc/systemd/system/ravyr.service ] || { echo "Existing Ravyr service unit is missing." >&2; exit 1; }
[ -s /etc/systemd/system/ravyr-updater.service ] || { echo "Existing Ravyr updater unit is missing." >&2; exit 1; }
[ -s /etc/systemd/system/ravyr-updater.timer ] || { echo "Existing Ravyr updater timer is missing." >&2; exit 1; }

# This is deliberately limited to the filesystem contract required by the
# signed Ravyr lifecycle. It does not replace identity, credentials, CA,
# configuration, binaries, or monitoring data.
install -d -m 0750 -o root -g veleis-ravyr "$config_directory"
install -d -m 0700 -o veleis-ravyr -g veleis-ravyr "$state_directory"
install -d -m 0750 -o root -g root "$library_directory"

systemctl daemon-reload
systemctl reset-failed ravyr-updater.service >/dev/null 2>&1 || true
systemctl enable --now ravyr.service ravyr-updater.timer >/dev/null
systemctl start ravyr-updater.service
systemctl is-active --quiet ravyr.service
systemctl is-active --quiet ravyr-updater.timer
test "$(systemctl show ravyr-updater.service -p Result --value)" = "success"

echo "Ravyr lifecycle filesystem repair complete."
echo "Identity, credentials, CA, configuration, and buffered monitoring state were preserved."
