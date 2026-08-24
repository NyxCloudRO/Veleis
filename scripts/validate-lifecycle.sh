#!/usr/bin/env bash
set -Eeuo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_directory=$(mktemp -d)
trap 'find "$temporary_directory" -depth -delete 2>/dev/null || true' EXIT
install_root="$temporary_directory/installation"
mkdir -p "$install_root/data/tls"
cat >"$install_root/.env" <<'ENVIRONMENT'
VELEIS_VERSION=1.8.4
VELEIS_IMAGE=docker.io/nyxmael/veleis:1.8.4
VELEIS_HTTPS_PORT=443
VELEIS_PUBLIC_BASE_URL=https://127.0.0.1
POSTGRES_PASSWORD=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
VELEIS_MASTER_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
ENVIRONMENT
printf '%s\n' 'Veleis 1.8.4' >"$install_root/.veleis-installation"
printf '%s\n' 'name: veleis' >"$install_root/compose.yaml"

VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 1.8.4 >"$temporary_directory/no-op.out"
grep -Fq 'No backup, pull, migration, or restart was performed.' "$temporary_directory/no-op.out"

if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 1.7.0 >"$temporary_directory/downgrade.out" 2>&1; then
  echo 'downgrade was accepted' >&2
  exit 1
fi
grep -Fq 'downgrade from 1.8.4 to 1.7.0 is not supported' "$temporary_directory/downgrade.out"

exec 8>"$install_root/.maintenance.lock"
flock -n 8
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 1.8.4 >"$temporary_directory/lock.out" 2>&1; then
  echo 'concurrent lifecycle operation was accepted' >&2
  exit 1
fi
grep -Fq 'another Veleis backup, restore, or upgrade operation is active' "$temporary_directory/lock.out"
flock -u 8

printf '%s\n' 'UNEXPECTED=value' >>"$install_root/.env"
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 1.8.4 >"$temporary_directory/environment.out" 2>&1; then
  echo 'unsupported environment entry was accepted' >&2
  exit 1
fi
grep -Fq 'contains an unsupported or malformed setting' "$temporary_directory/environment.out"
sed -i '/^UNEXPECTED=/d' "$install_root/.env"

archive_root="$temporary_directory/archive"
mkdir -p "$archive_root/files/data"
ln -s /etc/passwd "$archive_root/files/data/escape"
tar -czf "$temporary_directory/unsafe.tar.gz" -C "$archive_root" files
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" restore "$temporary_directory/unsafe.tar.gz" --force >"$temporary_directory/archive.out" 2>&1; then
  echo 'unsafe archive link was accepted' >&2
  exit 1
fi
if ! grep -Fq 'backup archive contains a link or unsupported special file' "$temporary_directory/archive.out"; then
  cat "$temporary_directory/archive.out" >&2
  exit 1
fi

echo 'public lifecycle static validation: PASS'
