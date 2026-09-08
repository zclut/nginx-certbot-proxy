#!/bin/sh
# Shared helpers sourced by init-letsencrypt.sh, expand-cert.sh and
# generate-conf.sh. Not meant to be run directly.

detect_dc() {
  if docker compose version >/dev/null 2>&1; then
    DC="docker compose"
  elif command -v docker-compose >/dev/null 2>&1; then
    DC="docker-compose"
  else
    echo "Neither 'docker compose' nor 'docker-compose' works on this host. Install one." >&2
    exit 1
  fi
}

load_env() {
  if [ ! -f .env ]; then
    echo ".env not found — copy .env.example to .env and fill in EMAIL/DOMAIN_MAP first." >&2
    exit 1
  fi
  set -a
  . ./.env
  set +a
  : "${EMAIL:?EMAIL not set in .env}"
  : "${DOMAIN_MAP:?DOMAIN_MAP not set in .env}"
}

# Parses DOMAIN_MAP ("domain=host:port;domain=host:port;...") and sets:
#   DOMAIN_ARGS    - "-d domain1 -d domain2 ..." for certbot
#   ALL_DOMAINS    - space-separated domain list (bootstrap server_name)
#   CERT_DOMAIN    - first domain (the cert's lineage name — matches how
#                    certbot names a multi-SAN cert after its first -d)
#   FIRST_UPSTREAM - upstream of the first entry (used by the bootstrap
#                    block, which just needs any app to answer the challenge)
parse_domain_map() {
  DOMAIN_ARGS=""
  ALL_DOMAINS=""
  CERT_DOMAIN=""
  FIRST_UPSTREAM=""
  OLDIFS=$IFS
  IFS=';'
  for entry in $DOMAIN_MAP; do
    [ -z "$entry" ] && continue
    domain=${entry%%=*}
    upstream=${entry#*=}
    if [ -z "$CERT_DOMAIN" ]; then
      CERT_DOMAIN=$domain
      FIRST_UPSTREAM=$upstream
    fi
    DOMAIN_ARGS="$DOMAIN_ARGS -d $domain"
    ALL_DOMAINS="$ALL_DOMAINS $domain"
  done
  IFS=$OLDIFS
  ALL_DOMAINS=${ALL_DOMAINS# }
}

# render_template <template-file> <KEY=value> [<KEY=value> ...]
# Replaces literal "${KEY}" placeholders with value, printed to stdout.
# Plain sed instead of envsubst — envsubst isn't installed by default on
# macOS or minimal Linux, and this runs on the host, not in a container.
render_template() {
  tmpl=$1
  shift
  content=$(cat "$tmpl")
  for kv in "$@"; do
    key=${kv%%=*}
    val=${kv#*=}
    esc_val=$(printf '%s' "$val" | sed -e 's/[\/&]/\\&/g')
    content=$(printf '%s\n' "$content" | sed "s/\${$key}/$esc_val/g")
  done
  printf '%s\n' "$content"
}
