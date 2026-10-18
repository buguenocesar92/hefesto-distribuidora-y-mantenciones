#!/usr/bin/env bash
# Verifica que los compose del contrato Coolify cumplan los puntos 1 y 2.
# Falla con código 1 y un mensaje "servicio: motivo" si algo no cumple.
#
# Uso: bash scripts/coolify-check.sh
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail=0

# Detecta apps con compose del contrato (los que Coolify usaría).
apps=()
while IFS= read -r -d '' f; do
  apps+=("$(dirname "$f")")
done < <(find "$repo_root" -maxdepth 2 -name 'compose.supabase.yaml' -print0 | sort -z)

if [[ ${#apps[@]} -eq 0 ]]; then
  echo "ERROR: no se encontró ningún compose.supabase.yaml bajo $repo_root" >&2
  exit 1
fi

# Extrae todas las ${VAR}, ${VAR:-default} y ${VAR:?mensaje}.
required_vars() {
  grep -oE '\$\{[A-Z_][A-Z0-9_]*[^}]*\}' "$1" \
    | sed -E 's/^\$\{([A-Z_][A-Z0-9_]*).*/\1/' \
    | sort -u
}

# Variables que por su nombre o por aparecer como URL deben recibir un host ficticio.
is_url_var() {
  case "$1" in
    *URL*|*ORIGIN*|*HOST*|*ENDPOINT*|*SITE*) return 0 ;;
    *) return 1 ;;
  esac
}

# Crea un .env temporal con valores ficticios para todas las variables del compose.
make_env() {
  local compose="$1" envfile="$2"
  : > "$envfile"
  while IFS= read -r v; do
    [[ -z "$v" ]] && continue
    if is_url_var "$v"; then
      printf '%s=https://ejemplo.invalid\n' "$v" >> "$envfile"
    else
      printf '%s=x1234567890abcdef\n' "$v" >> "$envfile"
    fi
  done < <(required_vars "$compose")
}

# Valida que un servicio no tenga claves prohibidas por el contrato punto 1.
check_no_leak() {
  local name="$1" svc="$2" rendered="$3"
  local -a forbidden=(
    'ports' 'container_name' 'privileged' 'cap_add' 'devices'
    'docker.sock'
  )
  for key in "${forbidden[@]}"; do
    if [[ "$(jq -r --arg s "$svc" '.services[$s] // empty | if has("'"$key"'") then "yes" else "no" end' "$rendered")" == "yes" ]]; then
      echo "FAIL ${name}/${svc}: clave prohibida '${key}' presente (contrato 1)"
      return 1
    fi
  done

  # network_mode / pid / ipc no deben ser host.
  for key in network_mode pid ipc; do
    val="$(jq -r --arg s "$svc" --arg k "$key" '.services[$s][$k] // empty' "$rendered")"
    if [[ "$val" == "host" ]]; then
      echo "FAIL ${name}/${svc}: ${key}=host (contrato 1)"
      return 1
    fi
  done

  # security_opt no debe incluir unconfined.
  if jq -e --arg s "$svc" '.services[$s].security_opt // [] | index("unconfined")' "$rendered" >/dev/null 2>&1; then
    echo "FAIL ${name}/${svc}: security_opt incluye unconfined (contrato 1)"
    return 1
  fi

  # Binds fuera del repo o con docker.sock.
  while IFS= read -r bind; do
    [[ -z "$bind" ]] && continue
    case "$bind" in
      *docker.sock*|*:/var/run/docker.sock*)
        echo "FAIL ${name}/${svc}: volumen monta docker.sock (contrato 1): $bind"
        return 1 ;;
      /*) : ;; # ruta absoluta — el chequeo fino de "fuera del repo" lo hace Coolify
    esac
  done < <(jq -r --arg s "$svc" '.services[$s].volumes // [] | .[] | select(type=="object") | .source // empty' "$rendered")

  return 0
}

# Valida que no haya name: fijos en el YAML fuente (contrato 2).
check_no_fixed_names() {
  local name="$1" compose="$2"
  if grep -qE '^name:[[:space:]]' "$compose"; then
    echo "FAIL ${name}: 'name' fijado a nivel raíz (contrato 2)"
    return 1
  fi
  if grep -qE '^[[:space:]]+name:[[:space:]]' "$compose"; then
    echo "FAIL ${name}: red o volumen con 'name' fijado (contrato 2)"
    return 1
  fi
  return 0
}

# Para supabase-pg: en el render deben aparecer mvp_prueba y disable.
check_pg_params() {
  local name="$1" envfile="$2" rendered="$3"
  local found=0
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    if [[ "$line" == *"mvp_prueba"* && "$line" == *"disable"* ]]; then
      found=1
      break
    fi
  done < <(jq -r '.. | strings' "$rendered")
  if [[ $found -ne 1 ]]; then
    echo "FAIL ${name}: app supabase-pg sin DB_NAME=mvp_prueba y DB_SSLMODE=disable (contrato 3)"
    return 1
  fi
  return 0
}

tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

for app in "${apps[@]}"; do
  rel="${app#"$repo_root"/}"
  compose="$app/compose.supabase.yaml"
  envfile="$tmpdir/${rel//\//_}.env"
  rendered="$tmpdir/${rel//\//_}.json"

  make_env "$compose" "$envfile"

  if ! docker compose --project-directory "$app" -f "$compose" --env-file "$envfile" config --format json > "$rendered" 2> "$tmpdir/${rel//\//_}.err"; then
    echo "FAIL ${rel}: 'docker compose config' falló:"
    cat "$tmpdir/${rel//\//_}.err"
    fail=1
    continue
  fi

  if ! check_no_fixed_names "$rel" "$compose"; then
    fail=1
    continue
  fi

  for svc in $(jq -r '.services | keys[]' "$rendered"); do
    # Servicios con profiles se excluyen (son para bootstrap / ops, no para runtime).
    profiles="$(jq -r --arg s "$svc" '.services[$s].profiles // [] | length' "$rendered")"
    if [[ "$profiles" != "0" ]]; then
      continue
    fi
    if ! check_no_leak "$rel" "$svc" "$rendered"; then
      fail=1
    fi
  done

  # Si el compose tiene services con imagen de Postgres o volumen de datos Postgres, es supabase-pg.
  if grep -qE 'image:[[:space:]]*(postgres|supabase/postgres)' "$compose" \
     || jq -e '.. | objects | select(has("image")) | .image | test("postgres")' "$rendered" >/dev/null 2>&1; then
    if ! check_pg_params "$rel" "$envfile" "$rendered"; then
      fail=1
    fi
  fi
done

if [[ $fail -ne 0 ]]; then
  echo "coolify-check: FAIL"
  exit 1
fi

echo "coolify-check: OK"
