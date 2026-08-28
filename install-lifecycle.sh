#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT="${VELEIS_INSTALL_ROOT:-/opt/veleis}"
readonly TOOL_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v1.8.10/veleis"
readonly TOOL_SHA256="a107e1acd6f9e8940cf38646fbae52a78554234c6886310c4cee836fcb2bcf43"
readonly RELEASE_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v1.8.10/release.json"
readonly RELEASE_SHA256="9207b91c0298b821503cc6fcb5525c121dea1b43700867d969f3860195256181"
readonly POSTGRES_MEMORY_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v1.8.10/veleis-postgres-memory.sh"
readonly POSTGRES_MEMORY_SHA256="fc7a079a81c217a76457aae48407f9d68f59f7244dd2096c728fdb27d18f676c"
readonly COMPOSE_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/v1.8.10/deploy/compose.yaml"
readonly COMPOSE_SHA256="5c44f566a5bde88ee92e3692323625ce5d5d56701e7bde8075bba9aa250de4b9"

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
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$POSTGRES_MEMORY_URL" -o "$TEMPORARY_DIRECTORY/veleis-postgres-memory.sh"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$COMPOSE_URL" -o "$TEMPORARY_DIRECTORY/compose.yaml"
printf '%s  %s\n' "$TOOL_SHA256" "$TEMPORARY_DIRECTORY/veleis" | sha256sum --check --status || fail "lifecycle tool checksum mismatch"
printf '%s  %s\n' "$RELEASE_SHA256" "$TEMPORARY_DIRECTORY/release.json" | sha256sum --check --status || fail "release metadata checksum mismatch"
printf '%s  %s\n' "$POSTGRES_MEMORY_SHA256" "$TEMPORARY_DIRECTORY/veleis-postgres-memory.sh" | sha256sum --check --status || fail "PostgreSQL memory helper checksum mismatch"
printf '%s  %s\n' "$COMPOSE_SHA256" "$TEMPORARY_DIRECTORY/compose.yaml" | sha256sum --check --status || fail "Compose template checksum mismatch"
bash -n "$TEMPORARY_DIRECTORY/veleis"
bash -n "$TEMPORARY_DIRECTORY/veleis-postgres-memory.sh"
jq -e '.product == "Veleis" and .version == "1.8.10" and .schema == 43 and .backup_format_version == 1' "$TEMPORARY_DIRECTORY/release.json" >/dev/null || fail "release metadata is incompatible"

as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis" /usr/local/bin/veleis
as_root install -d -m 0755 "$INSTALL_ROOT/bin"
as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis-postgres-memory.sh" "$INSTALL_ROOT/bin/veleis-postgres-memory"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/compose.yaml" "$INSTALL_ROOT/bin/veleis-compose.yaml"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/release.json" "$INSTALL_ROOT/release.json"

printf '%s\n' 'Veleis lifecycle tooling installed.' 'Run: sudo veleis status' 'Back up now with: sudo veleis backup'
