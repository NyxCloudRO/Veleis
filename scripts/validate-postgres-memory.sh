#!/usr/bin/env bash
set -Eeuo pipefail

repository_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
helper="$repository_root/veleis-postgres-memory.sh"
temporary_directory=$(mktemp -d)
trap 'find "$temporary_directory" -type f -delete 2>/dev/null || true; find "$temporary_directory" -depth -type d -empty -delete 2>/dev/null || true' EXIT

fail() { printf 'postgres memory test failed: %s\n' "$*" >&2; exit 1; }
assert_equal() { [[ "$1" == "$2" ]] || fail "expected '$2', got '$1' (${3:-assertion})"; }

write_host_memory() {
  local gib=$1
  printf 'MemTotal:       %s kB\n' "$((gib * 1024 * 1024))" >"$temporary_directory/meminfo"
}

detect() {
  VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" \
    VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" \
    VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" \
    "$helper" detect | cut -f1
}

reset_cgroup() {
  find "$temporary_directory/cgroup" -type f -delete 2>/dev/null || true
  find "$temporary_directory/cgroup" -depth -mindepth 1 -type d -empty -delete 2>/dev/null || true
  mkdir -p "$temporary_directory/cgroup"
  printf '0::/\n' >"$temporary_directory/proc-cgroup"
}

# A: a 32 GiB host constrained to 2 GiB.
reset_cgroup; write_host_memory 32
printf '%s\n' 2147483648 >"$temporary_directory/cgroup/memory.max"
assert_equal "$(detect)" 2048 '32 GiB host / 2 GiB cgroup regression'

# B: cgroup v2 max means unlimited and falls back to host memory.
reset_cgroup; write_host_memory 32
printf '%s\n' max >"$temporary_directory/cgroup/memory.max"
assert_equal "$(detect)" 32768 'unlimited cgroup v2'

# C: a cgroup value above host memory cannot increase effective memory.
reset_cgroup; write_host_memory 8
printf '%s\n' 17179869184 >"$temporary_directory/cgroup/memory.max"
assert_equal "$(detect)" 8192 'host remains an upper bound'

# D: only current cgroup ancestors are considered; their minimum wins.
reset_cgroup; write_host_memory 32
mkdir -p "$temporary_directory/cgroup/parent/child" "$temporary_directory/cgroup/sibling"
printf '0::/parent/child\n' >"$temporary_directory/proc-cgroup"
printf '%s\n' 4294967296 >"$temporary_directory/cgroup/memory.max"
printf '%s\n' 3221225472 >"$temporary_directory/cgroup/parent/memory.max"
printf '%s\n' 2147483648 >"$temporary_directory/cgroup/parent/child/memory.max"
printf '%s\n' 1073741824 >"$temporary_directory/cgroup/sibling/memory.max"
assert_equal "$(detect)" 2048 'nested current constraints'

# E/F: invalid/sentinel or missing cgroup data safely falls back to host.
reset_cgroup; write_host_memory 8
printf '%s\n' 9223372036854771712 >"$temporary_directory/cgroup/memory.max"
assert_equal "$(detect)" 8192 'sentinel ignored'
printf '%s\n' invalid >"$temporary_directory/cgroup/memory.max"
assert_equal "$(detect)" 8192 'invalid ignored'
reset_cgroup
assert_equal "$(detect)" 8192 'missing files'

# The advanced override is explicit, bounded, and never silently ignored.
assert_equal "$(VELEIS_POSTGRES_MEMORY_MB=4096 VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" "$helper" detect | cut -f1)" 4096 'safe override'
if VELEIS_POSTGRES_MEMORY_MB=16384 VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" "$helper" detect >/dev/null 2>&1; then
  fail 'unsafe override was accepted'
fi

# G: below-minimum systems are rejected before a dangerous profile is emitted.
if "$helper" profile 512 >/dev/null 2>&1; then fail '512 MiB profile was accepted'; fi

profiles=(1024 2048 4096 8192 16384 32768 65536)
expected=(
  '256 608 2 64 20 4'
  '512 1216 4 96 25 4'
  '1024 2448 5 192 35 6'
  '2048 4912 8 400 50 8'
  '4096 9824 10 816 75 12'
  '8192 19648 16 1632 100 16'
  '16384 39312 21 2048 150 16'
)
for index in "${!profiles[@]}"; do
  # shellcheck disable=SC1090
  source <("$helper" env "${profiles[$index]}")
  actual="$VELEIS_POSTGRES_SHARED_BUFFERS_MB $VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB $VELEIS_POSTGRES_WORK_MEM_MB $VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB $VELEIS_POSTGRES_MAX_CONNECTIONS $VELEIS_POSTGRES_MAX_BG_WORKERS"
  assert_equal "$actual" "${expected[$index]}" "${profiles[$index]} MiB profile snapshot"
  ((VELEIS_POSTGRES_SHARED_BUFFERS_MB < profiles[index])) || fail 'shared_buffers invariant'
  ((VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB * 8 <= profiles[index])) || fail 'maintenance invariant'
  ((VELEIS_POSTGRES_WORK_MEM_MB * VELEIS_POSTGRES_MAX_CONNECTIONS * 2 <= profiles[index] / 8)) || fail 'work_mem concurrency invariant'
done

# Managed values are fingerprinted. Editing one value automatically classifies
# the configuration as custom so future lifecycle code preserves it.
"$helper" env 2048 >"$temporary_directory/managed.env"
assert_equal "$("$helper" classify-env "$temporary_directory/managed.env")" managed 'managed fingerprint'
"$helper" recalculate-env "$temporary_directory/managed.env" 4096 "$temporary_directory/recalculated.env"
assert_equal "$("$helper" classify-env "$temporary_directory/recalculated.env")" managed 'recalculated managed fingerprint'
assert_equal "$(sed -n 's/^VELEIS_POSTGRES_EFFECTIVE_MEMORY_MB=//p' "$temporary_directory/recalculated.env")" 4096 'managed deterministic recalculation'
sed -i 's/VELEIS_POSTGRES_WORK_MEM_MB=4/VELEIS_POSTGRES_WORK_MEM_MB=8/' "$temporary_directory/managed.env"
assert_equal "$("$helper" classify-env "$temporary_directory/managed.env")" custom 'custom preservation classification'
if "$helper" recalculate-env "$temporary_directory/managed.env" 4096 "$temporary_directory/custom-output.env" >/dev/null 2>&1; then
  fail 'custom environment was recalculated'
fi
[[ ! -e "$temporary_directory/custom-output.env" ]] || fail 'custom environment produced replacement output'

# Permanent reproduction of the production-like failure and its replacement.
assert_equal "$("$helper" assess 2048 8192 24576 61 2048 100)" UNSAFE 'old host-sized profile'
assert_equal "$("$helper" assess 2048 512 1216 4 96 25)" HEALTHY 'new 2 GiB profile'

# A legacy/custom installation is never changed by apply-managed. The explicit
# adopt operation backs up both lifecycle files, installs the canonical Compose
# template, and writes a fingerprinted managed profile.
mkdir -p "$temporary_directory/fake-bin" "$temporary_directory/legacy/bin"
cat >"$temporary_directory/fake-bin/docker" <<'DOCKER'
#!/usr/bin/env bash
if [[ "${FAKE_DOCKER_FAIL_CONFIG:-false}" == true && " $* " == *" config "* ]]; then
  exit 1
fi
exit 0
DOCKER
chmod +x "$temporary_directory/fake-bin/docker"
cat >"$temporary_directory/legacy/.env" <<'ENVIRONMENT'
VELEIS_VERSION=1.8.7
VELEIS_IMAGE=docker.io/nyxmael/veleis:1.8.7
VELEIS_HTTPS_PORT=443
VELEIS_PUBLIC_BASE_URL=https://127.0.0.1
POSTGRES_PASSWORD=legacy-memory-acceptance
VELEIS_MASTER_KEY=legacy-memory-acceptance
ENVIRONMENT
printf '%s\n' 'name: legacy' >"$temporary_directory/legacy/compose.yaml"
printf '%s\n' 'name: managed' >"$temporary_directory/managed-compose.yaml"
write_host_memory 2
reset_cgroup
if PATH="$temporary_directory/fake-bin:$PATH" \
  VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" \
  VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" \
  VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" \
  "$helper" apply-managed "$temporary_directory/legacy" >/dev/null 2>&1; then
  fail 'apply-managed rewrote a legacy custom installation'
fi
PATH="$temporary_directory/fake-bin:$PATH" \
  VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" \
  VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" \
  VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" \
  VELEIS_POSTGRES_COMPOSE_TEMPLATE="$temporary_directory/managed-compose.yaml" \
  "$helper" adopt-managed "$temporary_directory/legacy" >/dev/null
assert_equal "$("$helper" classify-env "$temporary_directory/legacy/.env")" managed 'explicit managed adoption'
assert_equal "$(sed -n 's/^VELEIS_POSTGRES_EFFECTIVE_MEMORY_MB=//p' "$temporary_directory/legacy/.env")" 2048 'adopted effective memory'
assert_equal "$(cat "$temporary_directory/legacy/compose.yaml")" 'name: managed' 'adopted Compose template'
assert_equal "$(find "$temporary_directory/legacy" -maxdepth 1 -name '.env.postgres-memory-*.backup' | wc -l)" 1 'environment adoption backup'
assert_equal "$(find "$temporary_directory/legacy" -maxdepth 1 -name 'compose.yaml.postgres-memory-*.backup' | wc -l)" 1 'Compose adoption backup'

# Failed stack validation atomically restores both legacy files.
mkdir -p "$temporary_directory/rollback/bin"
cp "$temporary_directory/legacy/.env.postgres-memory-"*.backup "$temporary_directory/rollback/.env"
printf '%s\n' 'name: legacy-rollback' >"$temporary_directory/rollback/compose.yaml"
if PATH="$temporary_directory/fake-bin:$PATH" \
  FAKE_DOCKER_FAIL_CONFIG=true \
  VELEIS_MEMINFO_FILE="$temporary_directory/meminfo" \
  VELEIS_PROC_CGROUP_FILE="$temporary_directory/proc-cgroup" \
  VELEIS_CGROUP_ROOT="$temporary_directory/cgroup" \
  VELEIS_POSTGRES_COMPOSE_TEMPLATE="$temporary_directory/managed-compose.yaml" \
  "$helper" adopt-managed "$temporary_directory/rollback" >/dev/null 2>&1; then
  fail 'failed adoption reported success'
fi
assert_equal "$(sed -n 's/^VELEIS_VERSION=//p' "$temporary_directory/rollback/.env")" 1.8.7 'environment rollback'
assert_equal "$(cat "$temporary_directory/rollback/compose.yaml")" 'name: legacy-rollback' 'Compose rollback'

echo 'PostgreSQL effective-memory detection and tuning acceptance: PASS'
