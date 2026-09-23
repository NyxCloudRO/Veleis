#!/usr/bin/env bash
set -Eeuo pipefail

readonly INSTALL_ROOT="${VELEIS_INSTALL_ROOT:-/opt/veleis}"
readonly TOOL_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v2.0.7/veleis"
readonly TOOL_SHA256="9a8dfc4d561963a4f8a21d065a14b1d5988a650597dc8679a8f0e093783876cd"
readonly RELEASE_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v2.0.7/release.json"
readonly RELEASE_SHA256="018c176adfd97398bccf0a2d045f6899c9ab20827b17d61497fc294476643bc4"
readonly POSTGRES_MEMORY_URL="https://github.com/NyxCloudRO/Veleis/releases/download/v2.0.7/veleis-postgres-memory.sh"
readonly POSTGRES_MEMORY_SHA256="3aeb5a0ece0f77b80d7b7be9718471e76086be7d1cd613ada71fe91e0dfdf961"
readonly COMPOSE_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/v2.0.7/deploy/compose.yaml"
readonly COMPOSE_SHA256="2fbed0a9af027f322e1e402e2a09d7abe1468039938b973e93543fc3af4b7e68"

SUDO=()
TEMPORARY_DIRECTORY=""
INSTALLED_VERSION=""
TARGET_VERSION=""

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
INSTALLED_VERSION=$(as_root sed -n 's/^VELEIS_VERSION=//p' "$INSTALL_ROOT/.env")
[[ "$INSTALLED_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "installed Veleis version is missing or invalid"
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
jq -e '.product == "Veleis" and .version == "2.0.7" and .schema == 54 and .backup_format_version == 1' "$TEMPORARY_DIRECTORY/release.json" >/dev/null || fail "release metadata is incompatible"
TARGET_VERSION=$(jq -r .version "$TEMPORARY_DIRECTORY/release.json")

as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis" /usr/local/bin/veleis
as_root install -d -m 0755 "$INSTALL_ROOT/bin"
as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis-postgres-memory.sh" "$INSTALL_ROOT/bin/veleis-postgres-memory"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/compose.yaml" "$INSTALL_ROOT/bin/veleis-compose.yaml"
if [[ "$INSTALLED_VERSION" == "$TARGET_VERSION" ]]; then
  as_root install -m 0644 "$TEMPORARY_DIRECTORY/release.json" "$INSTALL_ROOT/release.json"
fi

printf '%s\n' 'Veleis lifecycle tooling installed.' 'Run: sudo veleis status' 'Back up now with: sudo veleis backup'
