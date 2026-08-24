#!/usr/bin/env bash
set -Eeuo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
installer="$repository_root/install.sh"
temporary_directory=$(mktemp -d)
trap 'find "$temporary_directory" -type f -delete 2>/dev/null || true; rmdir "$temporary_directory" 2>/dev/null || true' EXIT

"$installer" --print-compose >"$temporary_directory/compose.yaml"
diff -u "$repository_root/deploy/compose.yaml" "$temporary_directory/compose.yaml"

assert_os_accepted() {
  local distribution=$1 version=$2 label=$3
  printf 'ID=%q\nVERSION_ID=%q\nPRETTY_NAME=%q\n' "$distribution" "$version" "$label" >"$temporary_directory/os-release"
  if VELEIS_OS_RELEASE_FILE="$temporary_directory/os-release" VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/os.out" 2>&1; then
    echo "accepted OS reached an unexpected successful installation: $distribution $version" >&2
    exit 1
  fi
  grep -q "unsupported architecture 'arm64'" "$temporary_directory/os.out" || {
    echo "supported OS was rejected before architecture validation: $distribution $version" >&2
    cat "$temporary_directory/os.out" >&2
    exit 1
  }
}

assert_os_rejected() {
  local distribution=$1 version=$2
  printf 'ID=%q\nVERSION_ID=%q\n' "$distribution" "$version" >"$temporary_directory/os-release"
  if VELEIS_OS_RELEASE_FILE="$temporary_directory/os-release" VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/os.out" 2>&1; then
    echo "unsupported OS was accepted: $distribution $version" >&2
    exit 1
  fi
  grep -q "unsupported operating system '$distribution $version'" "$temporary_directory/os.out"
  grep -q "Ubuntu 24.04 LTS, Ubuntu 25.04, Ubuntu 26.04 LTS, Debian 12 (Bookworm), and Debian 13 (Trixie), on amd64/x86_64" "$temporary_directory/os.out"
}

assert_os_accepted ubuntu 24.04 "Ubuntu 24.04 LTS"
assert_os_accepted ubuntu 25.04 "Ubuntu 25.04"
assert_os_accepted ubuntu 26.04 "Ubuntu 26.04 LTS"
assert_os_accepted debian 12 "Debian GNU/Linux 12 (bookworm)"
assert_os_accepted debian 13 "Debian GNU/Linux 13 (trixie)"

assert_os_rejected ubuntu 22.04
assert_os_rejected ubuntu 25.10
assert_os_rejected debian 11
assert_os_rejected debian 14
assert_os_rejected alpine 3.22

printf '%s\n' 'ID=ubuntu' >"$temporary_directory/missing-version-os"
if VELEIS_OS_RELEASE_FILE="$temporary_directory/missing-version-os" VERSION_ID=24.04 VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/missing.out" 2>&1; then
  echo "os-release missing VERSION_ID was accepted" >&2
  exit 1
fi
grep -q "unsupported operating system 'ubuntu unknown'" "$temporary_directory/missing.out"

printf '%s\n' 'VERSION_ID=24.04' >"$temporary_directory/missing-id-os"
if VELEIS_OS_RELEASE_FILE="$temporary_directory/missing-id-os" ID=ubuntu VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/missing.out" 2>&1; then
  echo "os-release missing ID was accepted" >&2
  exit 1
fi
grep -q "unsupported operating system 'unknown 24.04'" "$temporary_directory/missing.out"

if VELEIS_OS_RELEASE_FILE="$temporary_directory/does-not-exist" VELEIS_ARCHITECTURE=arm64 "$installer" >"$temporary_directory/missing.out" 2>&1; then
  echo "missing os-release file was accepted" >&2
  exit 1
fi
grep -q "cannot read $temporary_directory/does-not-exist" "$temporary_directory/missing.out"

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
