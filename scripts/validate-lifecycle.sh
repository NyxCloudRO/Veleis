#!/usr/bin/env bash
# shellcheck disable=SC2016 # Static literals below intentionally inspect lifecycle source.
set -Eeuo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
temporary_directory=$(mktemp -d)
cleanup() {
  local status=$?
  trap - EXIT
  find "$temporary_directory" -depth -delete 2>/dev/null || true
  exit "$status"
}
trap cleanup EXIT
install_root="$temporary_directory/installation"
fake_bin="$temporary_directory/bin"
mkdir -p "$install_root/data/tls" "$fake_bin"

cat >"$install_root/.env" <<'ENVIRONMENT'
VELEIS_VERSION=2.0.0
VELEIS_IMAGE=docker.io/nyxmael/veleis:2.0.0
VELEIS_HTTPS_PORT=443
VELEIS_PUBLIC_BASE_URL=https://127.0.0.1
POSTGRES_PASSWORD=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
VELEIS_MASTER_KEY=AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=
ENVIRONMENT
printf '%s\n' 'Veleis 2.0.0' >"$install_root/.veleis-installation"
git -C "$repository_root" show v2.0.0:deploy/compose.yaml >"$install_root/compose.yaml"
git -C "$repository_root" show v2.0.0:veleis >"$temporary_directory/veleis-2.0.0"
chmod 0755 "$temporary_directory/veleis-2.0.0"

cat >"$temporary_directory/release.json" <<'JSON'
{
  "product": "Veleis",
  "version": "2.0.2",
  "docker_repository": "docker.io/nyxmael/veleis",
  "docker_manifest_digest": "sha256:aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa",
  "platform": "linux/amd64",
  "schema": 51,
  "minimum_upgrade_version": "1.7.1",
  "supported_upgrade_sources": [],
  "lifecycle_gated_upgrade_sources": ["2.0.0"],
  "lifecycle_contract_version": 2,
  "lifecycle_tool_sha256": "bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb",
  "postgres_memory": {"sha256": "cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc"}
}
JSON

cat >"$fake_bin/curl" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
output=
while (($#)); do
  if [[ "$1" == -o ]]; then output=$2; shift 2; continue; fi
  shift
done
[[ -n "$output" ]]
cp "$VELEIS_TEST_RELEASE_METADATA" "$output"
SCRIPT
cat >"$fake_bin/docker" <<'SCRIPT'
#!/usr/bin/env bash
set -eu
if [[ "${1:-} ${2:-}" == "compose version" ]]; then exit 0; fi
printf '%s\n' "$*" >>"$VELEIS_TEST_DOCKER_MUTATIONS"
exit 99
SCRIPT
chmod 0755 "$fake_bin/curl" "$fake_bin/docker"
mutation_log="$temporary_directory/docker-mutations"

# Execute the actual released 2.0.0 CLI. Because 2.0.0 appears only in the new
# lifecycle-gated list, that unaware binary must fail before any mutation.
if PATH="$fake_bin:$PATH" VELEIS_INSTALL_ROOT="$install_root" \
  VELEIS_RELEASE_METADATA_URL=https://release.invalid/release.json \
  VELEIS_TEST_RELEASE_METADATA="$temporary_directory/release.json" \
  VELEIS_TEST_DOCKER_MUTATIONS="$mutation_log" \
  "$temporary_directory/veleis-2.0.0" upgrade 2.0.2 >"$temporary_directory/old-cli.out" 2>&1; then
  echo 'released 2.0.0 CLI falsely accepted a lifecycle-gated upgrade' >&2
  exit 1
fi
grep -Fq 'not in the published supported-source list' "$temporary_directory/old-cli.out"
[[ ! -s "$mutation_log" ]]
[[ ! -e "$install_root/backups" ]]
[[ "$(sed -n 's/^VELEIS_VERSION=//p' "$install_root/.env")" == 2.0.0 ]]

# The candidate CLI must likewise reject mismatched target lifecycle artifacts
# before backup, image pull, Compose, or environment mutation.
cp "$repository_root/veleis-postgres-memory.sh" "$install_root/veleis-postgres-memory.sh"
chmod 0755 "$install_root/veleis-postgres-memory.sh"
if PATH="$fake_bin:$PATH" VELEIS_INSTALL_ROOT="$install_root" \
  VELEIS_RELEASE_METADATA_URL=https://release.invalid/release.json \
  VELEIS_TEST_RELEASE_METADATA="$temporary_directory/release.json" \
  VELEIS_TEST_DOCKER_MUTATIONS="$mutation_log" \
  "$repository_root/veleis" upgrade 2.0.2 >"$temporary_directory/identity.out" 2>&1; then
  echo 'candidate CLI accepted mismatched lifecycle artifacts' >&2
  exit 1
fi
grep -Fq 'installed lifecycle CLI does not match the target release' "$temporary_directory/identity.out"
[[ ! -s "$mutation_log" ]]
[[ "$(sed -n 's/^VELEIS_VERSION=//p' "$install_root/.env")" == 2.0.0 ]]

# Retain the established lifecycle safety matrix while adding the old-CLI
# compatibility gate above.
VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 2.0.0 >"$temporary_directory/no-op.out"
grep -Fq 'No backup, pull, migration, or restart was performed.' "$temporary_directory/no-op.out"

if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 1.7.0 >"$temporary_directory/downgrade.out" 2>&1; then
  echo 'downgrade was accepted' >&2
  exit 1
fi
grep -Fq 'downgrade from 2.0.0 to 1.7.0 is not supported' "$temporary_directory/downgrade.out"

exec 8>"$install_root/.maintenance.lock"
flock -n 8
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 2.0.0 >"$temporary_directory/lock.out" 2>&1; then
  echo 'concurrent lifecycle operation was accepted' >&2
  exit 1
fi
grep -Fq 'another Veleis backup, restore, or upgrade operation is active' "$temporary_directory/lock.out"
flock -u 8

printf '%s\n' 'UNEXPECTED=value' >>"$install_root/.env"
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 2.0.0 >"$temporary_directory/environment.out" 2>&1; then
  echo 'unsupported environment entry was accepted' >&2
  exit 1
fi
grep -Fq 'contains an unsupported or malformed setting' "$temporary_directory/environment.out"
sed -i '/^UNEXPECTED=/d' "$install_root/.env"

printf '%s\n' 'VELEIS_POSTGRES_WORK_MEM_MB=4' >>"$install_root/.env"
if VELEIS_INSTALL_ROOT="$install_root" "$repository_root/veleis" upgrade 2.0.0 >"$temporary_directory/partial-profile.out" 2>&1; then
  echo 'partial PostgreSQL memory profile was accepted' >&2
  exit 1
fi
grep -Fq 'either zero or all eleven PostgreSQL profile settings' "$temporary_directory/partial-profile.out"
sed -i '/^VELEIS_POSTGRES_WORK_MEM_MB=/d' "$install_root/.env"

grep -Fq 'memory_ownership=$("$memory_helper" classify-installation "$INSTALL_ROOT")' "$repository_root/veleis"
grep -Fq '"$memory_helper" converge-managed "$INSTALL_ROOT"' "$repository_root/veleis"
grep -Fq '"$memory_helper" verify-effective "$INSTALL_ROOT"' "$repository_root/veleis"
grep -Fq 'INSTALLED_VERSION=$(as_root sed -n '\''s/^VELEIS_VERSION=//p'\'' "$INSTALL_ROOT/.env")' "$repository_root/install-lifecycle.sh"
grep -Fq 'if [[ "$INSTALLED_VERSION" == "$TARGET_VERSION" ]]; then' "$repository_root/install-lifecycle.sh"
metadata_install_line=$(grep -n 'install -m 0644 "$TEMPORARY_DIRECTORY/release.json" "$INSTALL_ROOT/release.json"' "$repository_root/install-lifecycle.sh" | cut -d: -f1)
metadata_guard_line=$(grep -n 'if \[\[ "$INSTALLED_VERSION" == "$TARGET_VERSION" \]\]; then' "$repository_root/install-lifecycle.sh" | cut -d: -f1)
((metadata_guard_line < metadata_install_line)) || { echo 'lifecycle installer does not preserve cross-version source metadata' >&2; exit 1; }
backup_line=$(grep -n 'create_backup "$INSTALL_ROOT/backups"' "$repository_root/veleis" | tail -n 1 | cut -d: -f1)
converge_line=$(grep -n '"$memory_helper" converge-managed "$INSTALL_ROOT"' "$repository_root/veleis" | cut -d: -f1)
((backup_line < converge_line)) || { echo 'PostgreSQL convergence is not protected by the mandatory upgrade backup' >&2; exit 1; }
grep -Fq 'name: veleis-database-pg18' "$repository_root/deploy/compose.yaml"

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

echo 'public lifecycle execution and safety validation: PASS'
