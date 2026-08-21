#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT="${VELEIS_INSTALL_ROOT:-/opt/veleis}"
readonly TOOL_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/veleis"
readonly TOOL_SHA256="efc4a7a8e991a3ef179cd87d9413bc94c1bf36e31a80d63dca899b6f9c5e2e18"
readonly RELEASE_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/release.json"
readonly RELEASE_SHA256="8f95f0c30ad6d10dea6cb70ed62060622ac80d5cb921ef28740101d502ddfa04"

SUDO=()
TEMPORARY_DIRECTORY=""

fail() { printf 'Veleis lifecycle installation failed: %s\n' "$*" >&2; exit 1; }
as_root() { if ((${#SUDO[@]})); then "${SUDO[@]}" "$@"; else "$@"; fi; }
cleanup() {
  if [[ -n "$TEMPORARY_DIRECTORY" && -d "$TEMPORARY_DIRECTORY" ]]; then
    find "$TEMPORARY_DIRECTORY" -depth -delete 2>/dev/null || true
  fi
}
trap cleanup EXIT

if ((EUID != 0)); then
  command -v sudo >/dev/null 2>&1 || fail "root privileges are required and sudo is not installed"
  sudo -v || fail "sudo authorization failed"
  SUDO=(sudo)
fi

[[ "$INSTALL_ROOT" == /* && "$INSTALL_ROOT" != / ]] || fail "installation root must be a non-root absolute path"
as_root test -d "$INSTALL_ROOT" || fail "Veleis is not installed at $INSTALL_ROOT"
as_root test -f "$INSTALL_ROOT/.env" || fail "Veleis environment is missing"
as_root test -f "$INSTALL_ROOT/.veleis-installation" || fail "Veleis installation marker is missing"
if as_root test -L /usr/local/bin/veleis; then
  fail "/usr/local/bin/veleis is a symbolic link and was not replaced"
fi

missing_packages=()
command -v curl >/dev/null 2>&1 || missing_packages+=(curl ca-certificates)
command -v jq >/dev/null 2>&1 || missing_packages+=(jq)
command -v flock >/dev/null 2>&1 || missing_packages+=(util-linux)
if ((${#missing_packages[@]})); then
  as_root apt-get update
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${missing_packages[@]}"
fi

TEMPORARY_DIRECTORY=$(mktemp -d)
chmod 0700 "$TEMPORARY_DIRECTORY"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$TOOL_URL" -o "$TEMPORARY_DIRECTORY/veleis"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$RELEASE_URL" -o "$TEMPORARY_DIRECTORY/release.json"
printf '%s  %s\n' "$TOOL_SHA256" "$TEMPORARY_DIRECTORY/veleis" | sha256sum --check --status || fail "lifecycle tool checksum mismatch"
printf '%s  %s\n' "$RELEASE_SHA256" "$TEMPORARY_DIRECTORY/release.json" | sha256sum --check --status || fail "release metadata checksum mismatch"
bash -n "$TEMPORARY_DIRECTORY/veleis"
jq -e '.product == "Veleis" and .version == "1.7.1" and .schema == 32 and .backup_format_version == 1' "$TEMPORARY_DIRECTORY/release.json" >/dev/null || fail "release metadata is incompatible"

as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis" /usr/local/bin/veleis
as_root install -m 0644 "$TEMPORARY_DIRECTORY/release.json" "$INSTALL_ROOT/release.json"

printf '%s\n' 'Veleis lifecycle tooling installed.' 'Run: sudo veleis status' 'Back up now with: sudo veleis backup'
