#!/usr/bin/env bash
set -Eeuo pipefail

readonly VELEIS_VERSION="1.8.2"
readonly VELEIS_IMAGE="docker.io/nyxmael/veleis:${VELEIS_VERSION}"
readonly LIFECYCLE_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/veleis"
readonly LIFECYCLE_SHA256="efc4a7a8e991a3ef179cd87d9413bc94c1bf36e31a80d63dca899b6f9c5e2e18"
readonly RELEASE_METADATA_URL="https://raw.githubusercontent.com/NyxCloudRO/Veleis/main/release.json"
readonly RELEASE_METADATA_SHA256="fd601aacc512580ec070f04aca3a27182b8ee1f18b051913d40b0d29d43692d9"
readonly INSTALL_ROOT="${VELEIS_INSTALL_ROOT:-/opt/veleis}"
readonly HTTPS_PORT="${VELEIS_HTTPS_PORT:-443}"
readonly CONTAINER_UID=65532
readonly CONTAINER_GID=65532

SUDO=()
TEMPORARY_DIRECTORY=""
INSTALL_STARTED=false
DIAGNOSTICS_SHOWN=false

log() { printf 'Veleis: %s\n' "$*"; }
fail() { printf 'Veleis installation failed: %s\n' "$*" >&2; exit 1; }

as_root() {
  if ((${#SUDO[@]})); then
    "${SUDO[@]}" "$@"
  else
    "$@"
  fi
}

docker_command() { as_root docker "$@"; }

cleanup() {
  if [[ -n "$TEMPORARY_DIRECTORY" && -d "$TEMPORARY_DIRECTORY" ]]; then
    find "$TEMPORARY_DIRECTORY" -type f -delete 2>/dev/null || true
    rmdir "$TEMPORARY_DIRECTORY" 2>/dev/null || true
  fi
}

failure_diagnostics() {
  local status=$?
  if [[ "$DIAGNOSTICS_SHOWN" == true ]]; then
    exit "$status"
  fi
  DIAGNOSTICS_SHOWN=true
  if [[ "$INSTALL_STARTED" == true && -f "$INSTALL_ROOT/compose.yaml" ]]; then
    printf '\nVeleis containers did not become ready. Recent diagnostics follow:\n' >&2
    (cd "$INSTALL_ROOT" && docker_command compose ps) >&2 || true
    (cd "$INSTALL_ROOT" && docker_command compose logs --no-color --tail=80) >&2 || true
    printf 'Installation state was preserved at %s for troubleshooting.\n' "$INSTALL_ROOT" >&2
  fi
  exit "$status"
}

trap cleanup EXIT
trap failure_diagnostics ERR

write_compose() {
  cat <<'COMPOSE'
name: veleis

services:
  database:
    image: timescale/timescaledb:2.28.3-pg18@sha256:2c718e700b1c75b93488085596f2254c991c3aa29584fc282ebbe62fd8335791
    environment:
      POSTGRES_USER: veleis
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:?POSTGRES_PASSWORD must be set}
      POSTGRES_DB: veleis
    volumes:
      - database:/var/lib/postgresql
    networks:
      - database
    healthcheck:
      test:
        [
          "CMD-SHELL",
          'PGPASSWORD="$${POSTGRES_PASSWORD}" psql --no-psqlrc --host=127.0.0.1 --username=veleis --dbname=veleis --tuples-only --no-align --command="SELECT 1" | grep -qx 1',
        ]
      interval: 3s
      timeout: 5s
      retries: 40
      start_period: 10s
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true

  migrate:
    image: ${VELEIS_IMAGE:?VELEIS_IMAGE must be set}
    entrypoint: ["/usr/local/bin/veleis-migrate"]
    environment:
      VELEIS_DATABASE_URL: postgres://veleis:${POSTGRES_PASSWORD}@database:5432/veleis?sslmode=disable
      VELEIS_MIGRATIONS_PATH: file:///srv/veleis/migrations
    depends_on:
      database:
        condition: service_healthy
    networks:
      - database
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    restart: "no"

  veleis:
    image: ${VELEIS_IMAGE:?VELEIS_IMAGE must be set}
    environment:
      VELEIS_DATABASE_URL: postgres://veleis:${POSTGRES_PASSWORD}@database:5432/veleis?sslmode=disable
      VELEIS_MASTER_KEY: ${VELEIS_MASTER_KEY:?VELEIS_MASTER_KEY must be set}
      VELEIS_LOG_LEVEL: info
      VELEIS_INSTANCE_ID: veleis-production
      VELEIS_TLS_ENABLED: "true"
      VELEIS_TLS_SOURCE: custom
      VELEIS_TLS_CERTIFICATE_PATH: /var/lib/veleis/tls/veleis.crt
      VELEIS_TLS_PRIVATE_KEY_PATH: /var/lib/veleis/tls/veleis.key
      VELEIS_HTTPS_ADDRESS: :8443
      VELEIS_PUBLIC_BASE_URL: ${VELEIS_PUBLIC_BASE_URL:?VELEIS_PUBLIC_BASE_URL must be set}
    ports:
      - "${VELEIS_HTTPS_PORT:-443}:8443"
    volumes:
      - ./data:/var/lib/veleis
    tmpfs:
      - /tmp:rw,noexec,nosuid,nodev,size=16m
    networks:
      - database
      - public
    depends_on:
      database:
        condition: service_healthy
      migrate:
        condition: service_completed_successfully
    read_only: true
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    init: true
    restart: unless-stopped

volumes:
  database:
    name: veleis-database-pg18

networks:
  database:
    internal: true
  public:
COMPOSE
}

if [[ "${1:-}" == "--print-compose" ]]; then
  write_compose
  exit 0
fi
if (($#)); then
  fail "unknown argument: $1"
fi

[[ "$INSTALL_ROOT" == /* && "$INSTALL_ROOT" != / ]] || fail "installation root must be a non-root absolute path"
if [[ ! "$HTTPS_PORT" =~ ^[0-9]+$ ]] || ((HTTPS_PORT < 1 || HTTPS_PORT > 65535)); then
  fail "HTTPS port must be between 1 and 65535"
fi

os_release="${VELEIS_OS_RELEASE_FILE:-/etc/os-release}"
[[ -r "$os_release" ]] || fail "cannot read $os_release"
# shellcheck disable=SC1090
source "$os_release"
case "${ID:-}" in
  debian | ubuntu) ;;
  *) fail "unsupported operating system '${ID:-unknown}'; Veleis 1.8.2 supports tested Debian and Ubuntu releases" ;;
esac
os_name="${PRETTY_NAME:-${ID} ${VERSION_ID:-unknown}}"

architecture="${VELEIS_ARCHITECTURE:-$(uname -m)}"
case "$architecture" in
  x86_64 | amd64) architecture=amd64 ;;
  *) fail "unsupported architecture '$architecture'; Veleis 1.8.2 supports linux/amd64" ;;
esac

if ((EUID == 0)); then
  SUDO=()
else
  command -v sudo >/dev/null 2>&1 || fail "root privileges are required and sudo is not installed"
  sudo -v || fail "sudo authorization failed"
  SUDO=(sudo)
fi

if as_root test -e "$INSTALL_ROOT"; then
  fail "existing Veleis installation or path detected at $INSTALL_ROOT; no files were overwritten"
fi
if as_root test -e /usr/local/bin/veleis; then
  fail "existing path detected at /usr/local/bin/veleis; it was not overwritten"
fi

install_packages=()
for requirement in curl openssl ip ss jq flock; do
  command -v "$requirement" >/dev/null 2>&1 || install_packages+=("$requirement")
done
if ((${#install_packages[@]})); then
  log "Installing required operating-system tools."
  as_root apt-get update
  package_names=(ca-certificates curl openssl iproute2 jq util-linux)
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${package_names[@]}"
fi

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker Engine from the ${ID} package repository."
  as_root apt-get update
  docker_packages=(docker.io)
  if [[ "$ID" == debian ]]; then
    docker_packages+=(docker-cli)
  fi
  as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "${docker_packages[@]}"
fi

if command -v systemctl >/dev/null 2>&1; then
  as_root systemctl enable --now docker
elif command -v service >/dev/null 2>&1; then
  as_root service docker start
fi
docker_ready=false
for _ in $(seq 1 30); do
  if docker_command version >/dev/null 2>&1; then
    docker_ready=true
    break
  fi
  sleep 1
done
[[ "$docker_ready" == true ]] || fail "Docker Engine is installed but its daemon did not become available within 30 seconds"

if ! docker_command compose version >/dev/null 2>&1; then
  log "Installing Docker Compose v2."
  compose_installed=false
  for package in docker-compose-v2 docker-compose-plugin docker-compose; do
    if as_root env DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends "$package"; then
      if docker_command compose version >/dev/null 2>&1; then
        compose_installed=true
        break
      fi
    fi
  done
  [[ "$compose_installed" == true ]] || fail "Docker Compose v2 could not be installed from the operating-system repositories"
fi

if ss -H -ltn "sport = :$HTTPS_PORT" | grep -q .; then
  fail "TCP port $HTTPS_PORT is already in use; Veleis did not stop or replace the existing service"
fi

hostname_value=$(hostname --fqdn 2>/dev/null || hostname)
[[ "$hostname_value" =~ ^[A-Za-z0-9.-]+$ ]] || hostname_value=veleis
primary_ip=$(ip -4 route get 1.1.1.1 2>/dev/null | awk '{for(field=1;field<=NF;field++) if($field=="src"){print $(field+1); exit}}')
if [[ ! "$primary_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  primary_ip=$(ip -o -4 address show scope global | awk '$2 !~ /^(docker|br-|veth|virbr|cni|flannel)/ {split($4,address,"/"); print address[1]; exit}')
fi
[[ "$primary_ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || primary_ip=127.0.0.1

TEMPORARY_DIRECTORY=$(mktemp -d)
umask 077
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$LIFECYCLE_URL" -o "$TEMPORARY_DIRECTORY/veleis"
curl --fail --silent --show-error --location --proto '=https' --tlsv1.2 "$RELEASE_METADATA_URL" -o "$TEMPORARY_DIRECTORY/release.json"
printf '%s  %s\n' "$LIFECYCLE_SHA256" "$TEMPORARY_DIRECTORY/veleis" | sha256sum --check --status || fail "lifecycle tool checksum mismatch"
printf '%s  %s\n' "$RELEASE_METADATA_SHA256" "$TEMPORARY_DIRECTORY/release.json" | sha256sum --check --status || fail "release metadata checksum mismatch"
bash -n "$TEMPORARY_DIRECTORY/veleis"
jq -e '.product == "Veleis" and .version == "1.8.2" and .schema == 33 and .backup_format_version == 1' "$TEMPORARY_DIRECTORY/release.json" >/dev/null || fail "release metadata is incompatible"
database_password=$(openssl rand -hex 32)
master_key=$(openssl rand -base64 32 | tr -d '\n')

cat >"$TEMPORARY_DIRECTORY/openssl.cnf" <<CERTIFICATE
[req]
distinguished_name = subject
x509_extensions = extensions
prompt = no
[subject]
CN = ${hostname_value}
[extensions]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature,keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alternative_names
[alternative_names]
DNS.1 = ${hostname_value}
DNS.2 = localhost
IP.1 = ${primary_ip}
IP.2 = 127.0.0.1
CERTIFICATE
openssl req -x509 -newkey rsa:3072 -sha256 -days 825 -nodes \
  -config "$TEMPORARY_DIRECTORY/openssl.cnf" \
  -keyout "$TEMPORARY_DIRECTORY/veleis.key" -out "$TEMPORARY_DIRECTORY/veleis.crt" >/dev/null 2>&1

write_compose >"$TEMPORARY_DIRECTORY/compose.yaml"
cat >"$TEMPORARY_DIRECTORY/environment" <<ENVIRONMENT
VELEIS_VERSION=${VELEIS_VERSION}
VELEIS_IMAGE=${VELEIS_IMAGE}
VELEIS_HTTPS_PORT=${HTTPS_PORT}
VELEIS_PUBLIC_BASE_URL=https://${primary_ip}${HTTPS_PORT:+:${HTTPS_PORT}}
POSTGRES_PASSWORD=${database_password}
VELEIS_MASTER_KEY=${master_key}
ENVIRONMENT
if [[ "$HTTPS_PORT" == 443 ]]; then
  sed -i "s#VELEIS_PUBLIC_BASE_URL=https://${primary_ip}:443#VELEIS_PUBLIC_BASE_URL=https://${primary_ip}#" "$TEMPORARY_DIRECTORY/environment"
fi

INSTALL_STARTED=true
as_root install -d -m 0755 "$INSTALL_ROOT"
as_root install -d -m 0750 "$INSTALL_ROOT/data" "$INSTALL_ROOT/data/tls" "$INSTALL_ROOT/data/avatars"
as_root chown "$CONTAINER_UID:$CONTAINER_GID" "$INSTALL_ROOT/data" "$INSTALL_ROOT/data/tls" "$INSTALL_ROOT/data/avatars"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/compose.yaml" "$INSTALL_ROOT/compose.yaml"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/release.json" "$INSTALL_ROOT/release.json"
as_root install -m 0600 "$TEMPORARY_DIRECTORY/environment" "$INSTALL_ROOT/.env"
as_root install -m 0644 "$TEMPORARY_DIRECTORY/veleis.crt" "$INSTALL_ROOT/data/tls/veleis.crt"
as_root install -m 0600 "$TEMPORARY_DIRECTORY/veleis.key" "$INSTALL_ROOT/data/tls/veleis.key"
as_root chown "$CONTAINER_UID:$CONTAINER_GID" "$INSTALL_ROOT/data/tls/veleis.crt" "$INSTALL_ROOT/data/tls/veleis.key"
printf 'Veleis %s\n' "$VELEIS_VERSION" >"$TEMPORARY_DIRECTORY/marker"
as_root install -m 0600 "$TEMPORARY_DIRECTORY/marker" "$INSTALL_ROOT/.veleis-installation"
as_root install -m 0755 "$TEMPORARY_DIRECTORY/veleis" /usr/local/bin/veleis

log "Pulling immutable public images."
(cd "$INSTALL_ROOT" && docker_command compose pull)
log "Starting the production stack and applying schema migrations."
(cd "$INSTALL_ROOT" && docker_command compose up -d)

ready=false
for _ in $(seq 1 90); do
  if curl --silent --show-error --fail --max-time 5 --cacert "$TEMPORARY_DIRECTORY/veleis.crt" \
    "https://127.0.0.1:${HTTPS_PORT}/health/ready" >/dev/null 2>&1; then
    ready=true
    break
  fi
  sleep 2
done
[[ "$ready" == true ]] || fail "Veleis did not become ready within 180 seconds"
curl --silent --show-error --fail --max-time 10 --cacert "$TEMPORARY_DIRECTORY/veleis.crt" \
  "https://${primary_ip}:${HTTPS_PORT}/api/v1/setup/status" | grep -q '"setup_required":true' || \
  fail "HTTPS is ready but the first-Owner setup state was not returned"

display_url="https://${primary_ip}:${HTTPS_PORT}/"
hostname_url="https://${hostname_value}:${HTTPS_PORT}/"
if [[ "$HTTPS_PORT" == 443 ]]; then
  display_url="https://${primary_ip}/"
  hostname_url="https://${hostname_value}/"
fi

cat <<SUMMARY

------------------------------------------------------------
Veleis installation completed successfully.
------------------------------------------------------------

Veleis:
  Version: ${VELEIS_VERSION}
  Status: Ready

Platform:
  ${os_name}
  Architecture: ${architecture}

Host:
  ${hostname_value}

Access Veleis:
  ${display_url}

Optional hostname address:
  ${hostname_url}

TLS:
  A unique self-signed TLS certificate was generated for this installation.
  Your browser may display a certificate trust warning. This is expected for
  the default certificate and does not mean Veleis is using plain HTTP.

First setup:
  Open the URL above and create the first Veleis Owner account.

Installation:
  ${INSTALL_ROOT}

Useful commands:
  Status:  sudo veleis status
  Logs:    sudo veleis logs -f veleis
  Backup:  sudo veleis backup
  Upgrade: sudo veleis upgrade <exact-version>
  Start:   cd ${INSTALL_ROOT} && sudo docker compose up -d
  Stop:    cd ${INSTALL_ROOT} && sudo docker compose stop
  Restart: cd ${INSTALL_ROOT} && sudo docker compose restart

Veleis listens on TCP ${HTTPS_PORT}. Ensure your firewall allows access if required.
No firewall rules were changed by this installer.
------------------------------------------------------------
SUMMARY
