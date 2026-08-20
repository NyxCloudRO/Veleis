#!/usr/bin/env bash
set -Eeuo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer="$repository_root/install.sh"
temporary_directory=$(mktemp -d)
trap 'find "$temporary_directory" -type f -delete 2>/dev/null || true; rmdir "$temporary_directory" 2>/dev/null || true' EXIT

"$installer" --print-compose >"$temporary_directory/compose.yaml"
diff -u "$repository_root/deploy/compose.yaml" "$temporary_directory/compose.yaml"

printf '%s\n' 'ID=alpine' 'PRETTY_NAME="Alpine Linux"' >"$temporary_directory/unsupported-os"
if VELEIS_OS_RELEASE_FILE="$temporary_directory/unsupported-os" "$installer" >"$temporary_directory/os.out" 2>&1; then
  echo "unsupported OS was accepted" >&2
  exit 1
fi
grep -q "unsupported operating system 'alpine'" "$temporary_directory/os.out"

printf '%s\n' 'ID=debian' 'VERSION_ID="13"' 'PRETTY_NAME="Debian GNU/Linux 13 (trixie)"' >"$temporary_directory/debian-os"
if VELEIS_OS_RELEASE_FILE="$temporary_directory/debian-os" VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/arch.out" 2>&1; then
  echo "unsupported architecture was accepted" >&2
  exit 1
fi
grep -q "unsupported architecture 'arm64'" "$temporary_directory/arch.out"

if VELEIS_INSTALL_ROOT=/ "$installer" >"$temporary_directory/root.out" 2>&1; then
  echo "unsafe installation root was accepted" >&2
  exit 1
fi
grep -q "installation root must be a non-root absolute path" "$temporary_directory/root.out"

if VELEIS_HTTPS_PORT=70000 "$installer" >"$temporary_directory/port.out" 2>&1; then
  echo "invalid HTTPS port was accepted" >&2
  exit 1
fi
grep -q "HTTPS port must be between 1 and 65535" "$temporary_directory/port.out"

echo "public installer static validation: PASS"
