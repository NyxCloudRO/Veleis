#!/usr/bin/env bash
# Canonical PostgreSQL/Timescale memory detection and profile generation.
# This file is sourced by the installer and may also be run directly for
# read-only diagnostics and deterministic tests.

veleis_memory_fail() {
  printf 'Veleis PostgreSQL memory tuning failed: %s\n' "$*" >&2
  return 1
}

veleis_read_finite_bytes() {
  local file=$1 value
  [[ -r "$file" ]] || return 1
  IFS= read -r value <"$file" || return 1
  [[ "$value" =~ ^[0-9]+$ ]] || return 1
  # zero and values at/above 2^60 are unlimited/sentinel values, not RAM.
  ((value > 0 && value < 1152921504606846976)) || return 1
  printf '%s\n' "$value"
}

veleis_consider_memory_file() {
  local file=$1 bytes mib
  bytes=$(veleis_read_finite_bytes "$file") || return 0
  mib=$((bytes / 1024 / 1024))
  ((mib > 0)) || return 0
  if ((VELEIS_DETECTED_MEMORY_MB == 0 || mib < VELEIS_DETECTED_MEMORY_MB)); then
    VELEIS_DETECTED_MEMORY_MB=$mib
    VELEIS_DETECTED_MEMORY_SOURCE=$file
  fi
}

veleis_consider_cgroup_ancestors() {
  local root=$1 relative=$2 filename=$3 candidate
  relative=${relative#/}
  candidate="$root/$relative"
  while [[ "$candidate" == "$root" || "$candidate" == "$root/"* ]]; do
    veleis_consider_memory_file "$candidate/$filename"
    [[ "$candidate" != "$root" ]] || break
    candidate=${candidate%/*}
  done
}

veleis_detect_effective_memory() {
  local meminfo=${VELEIS_MEMINFO_FILE:-/proc/meminfo}
  local proc_cgroup=${VELEIS_PROC_CGROUP_FILE:-/proc/self/cgroup}
  local cgroup_root=${VELEIS_CGROUP_ROOT:-/sys/fs/cgroup}
  local host_kib controllers relative override

  host_kib=$(awk '$1 == "MemTotal:" && $2 ~ /^[0-9]+$/ { print $2; exit }' "$meminfo" 2>/dev/null) || true
  [[ "$host_kib" =~ ^[0-9]+$ ]] && ((host_kib > 0)) ||
    veleis_memory_fail "cannot determine physical/VM memory from $meminfo" || return

  VELEIS_HOST_MEMORY_MB=$((host_kib / 1024))
  VELEIS_DETECTED_MEMORY_MB=$VELEIS_HOST_MEMORY_MB
  VELEIS_DETECTED_MEMORY_SOURCE=$meminfo

  # A namespaced cgroup mount commonly exposes the current cgroup as its root.
  veleis_consider_memory_file "$cgroup_root/memory.max"
  veleis_consider_memory_file "$cgroup_root/memory.limit_in_bytes"
  veleis_consider_memory_file "$cgroup_root/memory/memory.limit_in_bytes"

  # Also walk only the current process's ancestors. Never scan sibling cgroups.
  if [[ -r "$proc_cgroup" ]]; then
    while IFS=: read -r _ controllers relative; do
      if [[ -z "$controllers" ]]; then
        veleis_consider_cgroup_ancestors "$cgroup_root" "$relative" memory.max
      elif [[ ",$controllers," == *,memory,* ]]; then
        veleis_consider_cgroup_ancestors "$cgroup_root" "$relative" memory.limit_in_bytes
        veleis_consider_cgroup_ancestors "$cgroup_root/memory" "$relative" memory.limit_in_bytes
      fi
    done <"$proc_cgroup"
  fi

  override=${VELEIS_POSTGRES_MEMORY_MB:-}
  if [[ -n "$override" ]]; then
    [[ "$override" =~ ^[1-9][0-9]*$ ]] ||
      veleis_memory_fail "VELEIS_POSTGRES_MEMORY_MB must be an integer number of MiB" || return
    ((override >= 1024)) ||
      veleis_memory_fail "VELEIS_POSTGRES_MEMORY_MB must be at least 1024 MiB" || return
    ((override <= VELEIS_DETECTED_MEMORY_MB)) ||
      veleis_memory_fail "VELEIS_POSTGRES_MEMORY_MB ($override MiB) exceeds detected effective memory ($VELEIS_DETECTED_MEMORY_MB MiB)" || return
    VELEIS_DETECTED_MEMORY_MB=$override
    VELEIS_DETECTED_MEMORY_SOURCE=VELEIS_POSTGRES_MEMORY_MB
  fi

  ((VELEIS_DETECTED_MEMORY_MB >= 1024)) ||
    veleis_memory_fail "effective memory is ${VELEIS_DETECTED_MEMORY_MB} MiB; Veleis requires at least 1024 MiB" || return
}

veleis_round_down_16() {
  local value=$1
  printf '%s\n' "$((value / 16 * 16))"
}

veleis_generate_postgres_profile() {
  local memory_mb=$1 shared cache maintenance connections work bg_workers worker_processes
  [[ "$memory_mb" =~ ^[1-9][0-9]*$ ]] && ((memory_mb >= 1024)) ||
    veleis_memory_fail "profile memory must be an integer of at least 1024 MiB" || return

  shared=$((memory_mb / 4)); ((shared > 16384)) && shared=16384
  shared=$(veleis_round_down_16 "$shared")
  cache=$((memory_mb * 3 / 5)); cache=$(veleis_round_down_16 "$cache")
  maintenance=$((memory_mb / 20)); ((maintenance < 64)) && maintenance=64
  ((maintenance > 2048)) && maintenance=2048
  maintenance=$(veleis_round_down_16 "$maintenance")

  if ((memory_mb < 2048)); then
    VELEIS_POSTGRES_PROFILE=tiny; connections=20; bg_workers=4
  elif ((memory_mb < 4096)); then
    VELEIS_POSTGRES_PROFILE=small; connections=25; bg_workers=4
  elif ((memory_mb < 8192)); then
    VELEIS_POSTGRES_PROFILE=medium; connections=35; bg_workers=6
  elif ((memory_mb < 16384)); then
    VELEIS_POSTGRES_PROFILE=large; connections=50; bg_workers=8
  elif ((memory_mb < 32768)); then
    VELEIS_POSTGRES_PROFILE=xlarge; connections=75; bg_workers=12
  elif ((memory_mb < 65536)); then
    VELEIS_POSTGRES_PROFILE=xxlarge; connections=100; bg_workers=16
  else
    VELEIS_POSTGRES_PROFILE=huge; connections=150; bg_workers=16
  fi
  work=$((memory_mb / 10 / connections / 2))
  ((work < 1)) && work=1
  ((work > 64)) && work=64
  worker_processes=$((bg_workers + 8))

  VELEIS_POSTGRES_MEMORY_MB=$memory_mb
  VELEIS_POSTGRES_SHARED_BUFFERS_MB=$shared
  VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB=$cache
  VELEIS_POSTGRES_WORK_MEM_MB=$work
  VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB=$maintenance
  VELEIS_POSTGRES_MAX_CONNECTIONS=$connections
  VELEIS_POSTGRES_MAX_BG_WORKERS=$bg_workers
  VELEIS_POSTGRES_MAX_WORKER_PROCESSES=$worker_processes

  veleis_validate_postgres_profile
}

veleis_validate_postgres_profile() {
  local memory=$VELEIS_POSTGRES_MEMORY_MB
  ((VELEIS_POSTGRES_SHARED_BUFFERS_MB < memory)) || veleis_memory_fail "shared_buffers invariant failed" || return
  ((VELEIS_POSTGRES_SHARED_BUFFERS_MB * 10 <= memory * 3)) || veleis_memory_fail "shared_buffers exceeds 30% safety cap" || return
  ((VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB * 8 <= memory)) || veleis_memory_fail "maintenance_work_mem exceeds 12.5% safety cap" || return
  ((VELEIS_POSTGRES_WORK_MEM_MB * VELEIS_POSTGRES_MAX_CONNECTIONS * 2 <= memory / 8)) ||
    veleis_memory_fail "work_mem concurrency budget exceeds 12.5% safety cap" || return
  ((VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB >= VELEIS_POSTGRES_SHARED_BUFFERS_MB && VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB < memory)) ||
    veleis_memory_fail "effective_cache_size invariant failed" || return
  ((VELEIS_POSTGRES_MAX_CONNECTIONS >= 20 && VELEIS_POSTGRES_MAX_CONNECTIONS <= 150)) ||
    veleis_memory_fail "max_connections invariant failed" || return
}

veleis_print_postgres_env() {
  local fingerprint
  fingerprint=$(veleis_postgres_profile_fingerprint)
  cat <<EOF
VELEIS_POSTGRES_TUNING_MODE=managed
VELEIS_POSTGRES_TUNING_FINGERPRINT=${fingerprint}
VELEIS_POSTGRES_EFFECTIVE_MEMORY_MB=${VELEIS_POSTGRES_MEMORY_MB}
VELEIS_POSTGRES_PROFILE=${VELEIS_POSTGRES_PROFILE}
VELEIS_POSTGRES_SHARED_BUFFERS_MB=${VELEIS_POSTGRES_SHARED_BUFFERS_MB}
VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB=${VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB}
VELEIS_POSTGRES_WORK_MEM_MB=${VELEIS_POSTGRES_WORK_MEM_MB}
VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB=${VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB}
VELEIS_POSTGRES_MAX_CONNECTIONS=${VELEIS_POSTGRES_MAX_CONNECTIONS}
VELEIS_POSTGRES_MAX_BG_WORKERS=${VELEIS_POSTGRES_MAX_BG_WORKERS}
VELEIS_POSTGRES_MAX_WORKER_PROCESSES=${VELEIS_POSTGRES_MAX_WORKER_PROCESSES}
EOF
}

veleis_postgres_profile_fingerprint() {
  printf '%s\n' \
    "$VELEIS_POSTGRES_MEMORY_MB" \
    "$VELEIS_POSTGRES_SHARED_BUFFERS_MB" \
    "$VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB" \
    "$VELEIS_POSTGRES_WORK_MEM_MB" \
    "$VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB" \
    "$VELEIS_POSTGRES_MAX_CONNECTIONS" \
    "$VELEIS_POSTGRES_MAX_BG_WORKERS" \
    "$VELEIS_POSTGRES_MAX_WORKER_PROCESSES" | sha256sum | awk '{print $1}'
}

veleis_env_value() {
  local file=$1 key=$2
  sed -n "s/^${key}=//p" "$file" | tail -n 1
}

veleis_classify_postgres_env() {
  local file=$1 mode recorded calculated
  [[ -r "$file" ]] || veleis_memory_fail "cannot read environment file $file" || return
  mode=$(veleis_env_value "$file" VELEIS_POSTGRES_TUNING_MODE)
  [[ "$mode" == managed ]] || { printf 'custom\n'; return; }

  VELEIS_POSTGRES_MEMORY_MB=$(veleis_env_value "$file" VELEIS_POSTGRES_EFFECTIVE_MEMORY_MB)
  VELEIS_POSTGRES_SHARED_BUFFERS_MB=$(veleis_env_value "$file" VELEIS_POSTGRES_SHARED_BUFFERS_MB)
  VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB=$(veleis_env_value "$file" VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB)
  VELEIS_POSTGRES_WORK_MEM_MB=$(veleis_env_value "$file" VELEIS_POSTGRES_WORK_MEM_MB)
  VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB=$(veleis_env_value "$file" VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB)
  VELEIS_POSTGRES_MAX_CONNECTIONS=$(veleis_env_value "$file" VELEIS_POSTGRES_MAX_CONNECTIONS)
  VELEIS_POSTGRES_MAX_BG_WORKERS=$(veleis_env_value "$file" VELEIS_POSTGRES_MAX_BG_WORKERS)
  VELEIS_POSTGRES_MAX_WORKER_PROCESSES=$(veleis_env_value "$file" VELEIS_POSTGRES_MAX_WORKER_PROCESSES)
  recorded=$(veleis_env_value "$file" VELEIS_POSTGRES_TUNING_FINGERPRINT)
  calculated=$(veleis_postgres_profile_fingerprint)
  if [[ -n "$recorded" && "$recorded" == "$calculated" ]]; then
    printf 'managed\n'
  else
    printf 'custom\n'
  fi
}

veleis_assess_postgres_profile() {
  local memory=$1 shared=$2 cache=$3 work=$4 maintenance=$5 connections=$6
  local status=HEALTHY
  if ((shared >= memory || maintenance >= memory || work * connections * 2 >= memory)); then
    status=UNSAFE
  elif ((shared * 10 > memory * 3 || maintenance * 8 > memory || work * connections * 2 > memory / 8 || cache >= memory)); then
    status=WARNING
  fi
  printf '%s\n' "$status"
}

veleis_recalculate_postgres_env() {
  local source_file=$1 memory_mb=$2 output_file=$3 classification
  classification=$(veleis_classify_postgres_env "$source_file") || return
  [[ "$classification" == managed ]] || {
    printf 'WARNING: PostgreSQL tuning is administrator-customized; preserving it unchanged.\n' >&2
    return 3
  }
  veleis_write_postgres_env "$source_file" "$memory_mb" "$output_file"
}

veleis_write_postgres_env() {
  local source_file=$1 memory_mb=$2 output_file=$3 temporary_profile
  veleis_generate_postgres_profile "$memory_mb" || return
  temporary_profile=$(mktemp)
  veleis_print_postgres_env >"$temporary_profile"
  awk '!/^VELEIS_POSTGRES_/' "$source_file" >"$output_file"
  cat "$temporary_profile" >>"$output_file"
  find "$(dirname "$temporary_profile")" -maxdepth 1 -type f -name "$(basename "$temporary_profile")" -delete
}

veleis_postgres_status() {
  local install_root=${1:-/opt/veleis} environment_file compose_file classification status runtime_values
  local -a runtime_settings=()
  environment_file="$install_root/.env"
  compose_file="$install_root/compose.yaml"
  veleis_detect_effective_memory || return
  classification=$(veleis_classify_postgres_env "$environment_file") || return
  VELEIS_POSTGRES_MEMORY_MB=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_EFFECTIVE_MEMORY_MB)
  VELEIS_POSTGRES_SHARED_BUFFERS_MB=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_SHARED_BUFFERS_MB)
  VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB)
  VELEIS_POSTGRES_WORK_MEM_MB=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_WORK_MEM_MB)
  VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB)
  VELEIS_POSTGRES_MAX_CONNECTIONS=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_MAX_CONNECTIONS)
  if [[ -r "$compose_file" ]]; then
    runtime_values=$(docker compose --project-directory "$install_root" --env-file "$environment_file" \
      --file "$compose_file" exec --no-TTY database psql --username=veleis --dbname=veleis \
      --tuples-only --no-align --command="
        SELECT pg_size_bytes(current_setting('shared_buffers')) / 1048576;
        SELECT pg_size_bytes(current_setting('effective_cache_size')) / 1048576;
        SELECT pg_size_bytes(current_setting('work_mem')) / 1048576;
        SELECT pg_size_bytes(current_setting('maintenance_work_mem')) / 1048576;
        SELECT current_setting('max_connections');" 2>/dev/null) || true
    mapfile -t runtime_settings <<<"$runtime_values"
    if ((${#runtime_settings[@]} == 5)) && [[ "${runtime_settings[*]}" =~ ^[0-9]+\ [0-9]+\ [0-9]+\ [0-9]+\ [0-9]+$ ]]; then
      VELEIS_POSTGRES_SHARED_BUFFERS_MB=${runtime_settings[0]}
      VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB=${runtime_settings[1]}
      VELEIS_POSTGRES_WORK_MEM_MB=${runtime_settings[2]}
      VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB=${runtime_settings[3]}
      VELEIS_POSTGRES_MAX_CONNECTIONS=${runtime_settings[4]}
    fi
  fi
  if [[ "$VELEIS_POSTGRES_SHARED_BUFFERS_MB" =~ ^[0-9]+$ &&
        "$VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB" =~ ^[0-9]+$ &&
        "$VELEIS_POSTGRES_WORK_MEM_MB" =~ ^[0-9]+$ &&
        "$VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB" =~ ^[0-9]+$ &&
        "$VELEIS_POSTGRES_MAX_CONNECTIONS" =~ ^[0-9]+$ ]]; then
    status=$(veleis_assess_postgres_profile "$VELEIS_DETECTED_MEMORY_MB" \
      "$VELEIS_POSTGRES_SHARED_BUFFERS_MB" "$VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB" \
      "$VELEIS_POSTGRES_WORK_MEM_MB" "$VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB" \
      "$VELEIS_POSTGRES_MAX_CONNECTIONS")
  else
    status=WARNING
  fi
  printf 'Effective memory: %s MiB (%s)\n' "$VELEIS_DETECTED_MEMORY_MB" "$VELEIS_DETECTED_MEMORY_SOURCE"
  printf 'PostgreSQL tuning ownership: %s\n' "$classification"
  printf 'PostgreSQL memory safety: %s\n' "$status"
  if [[ "$VELEIS_POSTGRES_SHARED_BUFFERS_MB" =~ ^[0-9]+$ ]]; then
    printf 'shared_buffers: %s MiB; effective_cache_size: %s MiB; work_mem: %s MiB; maintenance_work_mem: %s MiB; max_connections: %s\n' \
      "$VELEIS_POSTGRES_SHARED_BUFFERS_MB" "$VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB" \
      "$VELEIS_POSTGRES_WORK_MEM_MB" "$VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB" \
      "$VELEIS_POSTGRES_MAX_CONNECTIONS"
  fi
  case "$status" in
    UNSAFE) printf 'UNSAFE: PostgreSQL memory configuration can exceed the effective memory available to this Veleis installation.\n' ;;
    WARNING) printf 'WARNING: PostgreSQL memory configuration is outside the Veleis safety envelope or could not be fully verified.\n' ;;
  esac
}

veleis_install_postgres_profile() {
  local operation=$1 install_root=${2:-/opt/veleis} environment_file compose_file classification
  local timestamp backup_file compose_backup_file next_file old_fingerprint new_fingerprint template_file
  environment_file="$install_root/.env"
  compose_file="$install_root/compose.yaml"
  [[ -r "$environment_file" && -r "$compose_file" ]] ||
    veleis_memory_fail "Veleis installation files are missing below $install_root" || return
  classification=$(veleis_classify_postgres_env "$environment_file") || return
  if [[ "$operation" == apply && "$classification" != managed ]]; then
    printf 'WARNING: PostgreSQL tuning is administrator-customized; no configuration was changed.\n' >&2
    return 3
  fi
  if [[ "$operation" == adopt ]]; then
    template_file=${VELEIS_POSTGRES_COMPOSE_TEMPLATE:-$install_root/bin/veleis-compose.yaml}
    [[ -r "$template_file" && ! -L "$template_file" ]] ||
      veleis_memory_fail "managed Compose template is missing or unsafe: $template_file" || return
  fi
  old_fingerprint=$(veleis_env_value "$environment_file" VELEIS_POSTGRES_TUNING_FINGERPRINT)
  veleis_detect_effective_memory || return
  veleis_generate_postgres_profile "$VELEIS_DETECTED_MEMORY_MB" || return
  new_fingerprint=$(veleis_postgres_profile_fingerprint)
  if [[ "$operation" == apply && "$old_fingerprint" == "$new_fingerprint" ]]; then
    printf 'PostgreSQL managed memory profile is already current; no configuration was changed.\n'
    return 0
  fi

  timestamp=$(date -u +%Y%m%dT%H%M%SZ)
  backup_file="$environment_file.postgres-memory-$timestamp.backup"
  next_file=$(mktemp "$install_root/.env.postgres-memory.XXXXXX")
  install -m 0600 "$environment_file" "$backup_file"
  if [[ "$operation" == adopt ]]; then
    compose_backup_file="$compose_file.postgres-memory-$timestamp.backup"
    install -m 0644 "$compose_file" "$compose_backup_file"
  fi
  if ! veleis_write_postgres_env "$environment_file" "$VELEIS_DETECTED_MEMORY_MB" "$next_file"; then
    find "$install_root" -maxdepth 1 -type f -name "$(basename "$next_file")" -delete
    return 1
  fi
  chmod 0600 "$next_file"
  mv "$next_file" "$environment_file"
  if [[ "$operation" == adopt ]]; then
    install -m 0644 "$template_file" "$compose_file"
  fi

  if ! docker compose --project-directory "$install_root" --env-file "$environment_file" --file "$compose_file" config --quiet ||
     ! docker compose --project-directory "$install_root" --env-file "$environment_file" --file "$compose_file" up --detach --wait; then
    next_file=$(mktemp "$install_root/.env.postgres-memory.rollback.XXXXXX")
    install -m 0600 "$backup_file" "$next_file"
    mv "$next_file" "$environment_file"
    if [[ "$operation" == adopt ]]; then
      install -m 0644 "$compose_backup_file" "$compose_file"
    fi
    docker compose --project-directory "$install_root" --env-file "$environment_file" --file "$compose_file" up --detach --wait >/dev/null 2>&1 || true
    veleis_memory_fail "stack validation failed; restored $backup_file${compose_backup_file:+ and $compose_backup_file}" || return
  fi
  if [[ "$operation" == adopt ]]; then
    printf 'Adopted managed PostgreSQL profile %s; backups: %s and %s\n' \
      "$VELEIS_POSTGRES_PROFILE" "$backup_file" "$compose_backup_file"
  else
    printf 'Applied managed PostgreSQL profile %s; backup: %s\n' "$VELEIS_POSTGRES_PROFILE" "$backup_file"
  fi
}

veleis_apply_managed_postgres_profile() {
  veleis_install_postgres_profile apply "${1:-/opt/veleis}"
}

veleis_adopt_managed_postgres_profile() {
  veleis_install_postgres_profile adopt "${1:-/opt/veleis}"
}

veleis_print_postgres_summary() {
  cat <<EOF
Detected effective memory: ${VELEIS_POSTGRES_MEMORY_MB} MiB
PostgreSQL tuning profile: ${VELEIS_POSTGRES_PROFILE}
shared_buffers: ${VELEIS_POSTGRES_SHARED_BUFFERS_MB} MiB
effective_cache_size: ${VELEIS_POSTGRES_EFFECTIVE_CACHE_SIZE_MB} MiB
work_mem: ${VELEIS_POSTGRES_WORK_MEM_MB} MiB
maintenance_work_mem: ${VELEIS_POSTGRES_MAINTENANCE_WORK_MEM_MB} MiB
max_connections: ${VELEIS_POSTGRES_MAX_CONNECTIONS}
TimescaleDB background workers: ${VELEIS_POSTGRES_MAX_BG_WORKERS}
EOF
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  case "${1:-}" in
    detect)
      veleis_detect_effective_memory || exit 1
      printf '%s\t%s\n' "$VELEIS_DETECTED_MEMORY_MB" "$VELEIS_DETECTED_MEMORY_SOURCE"
      ;;
    profile)
      veleis_generate_postgres_profile "${2:-}" || exit 1
      veleis_print_postgres_summary
      ;;
    env)
      veleis_generate_postgres_profile "${2:-}" || exit 1
      veleis_print_postgres_env
      ;;
    classify-env)
      veleis_classify_postgres_env "${2:-}" || exit 1
      ;;
    assess)
      [[ $# == 7 ]] || { printf 'assess requires MEMORY SHARED CACHE WORK MAINTENANCE CONNECTIONS (MiB)\n' >&2; exit 2; }
      veleis_assess_postgres_profile "$2" "$3" "$4" "$5" "$6" "$7"
      ;;
    recalculate-env)
      [[ $# == 4 ]] || { printf 'recalculate-env requires INPUT MEMORY_MB OUTPUT\n' >&2; exit 2; }
      veleis_recalculate_postgres_env "$2" "$3" "$4"
      ;;
    status)
      veleis_postgres_status "${2:-/opt/veleis}"
      ;;
    apply-managed)
      veleis_apply_managed_postgres_profile "${2:-/opt/veleis}"
      ;;
    adopt-managed)
      veleis_adopt_managed_postgres_profile "${2:-/opt/veleis}"
      ;;
    *)
      printf 'usage: %s {detect|profile MEMORY_MB|env MEMORY_MB|classify-env FILE|assess MEMORY SHARED CACHE WORK MAINTENANCE CONNECTIONS|recalculate-env INPUT MEMORY_MB OUTPUT|status [INSTALL_ROOT]|apply-managed [INSTALL_ROOT]|adopt-managed [INSTALL_ROOT]}\n' "$0" >&2
      exit 2
      ;;
  esac
fi
