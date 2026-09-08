#!/bin/sh
# Renders nginx/conf.d/default.conf from DOMAIN_MAP in .env — one HTTP+HTTPS
# server-block pair per entry, from nginx/templates/server-block.template.
#
# Adding an app container is then just adding one "domain=container:port"
# entry to DOMAIN_MAP and re-running expand-cert.sh: nginx templates and
# docker-compose.yml never need to change.
#
# Pass "bootstrap" as $1 to render the HTTP-only single-block config used
# before a certificate exists (see init-letsencrypt.sh).
set -e
cd "$(dirname "$0")/.."
. ./scripts/lib.sh

load_env
parse_domain_map
mkdir -p nginx/conf.d
OUT=nginx/conf.d/default.conf

if [ "$1" = "bootstrap" ]; then
  render_template nginx/templates/bootstrap-block.template \
    "ALL_DOMAINS=$ALL_DOMAINS" \
    "FIRST_UPSTREAM=$FIRST_UPSTREAM" \
    > "$OUT"
  echo "==> Wrote bootstrap config for: $ALL_DOMAINS -> $FIRST_UPSTREAM"
  exit 0
fi

: > "$OUT"
OLDIFS=$IFS
IFS=';'
for entry in $DOMAIN_MAP; do
  [ -z "$entry" ] && continue
  domain=${entry%%=*}
  upstream=${entry#*=}
  render_template nginx/templates/server-block.template \
    "DOMAIN=$domain" \
    "UPSTREAM=$upstream" \
    "CERT_DOMAIN=$CERT_DOMAIN" \
    >> "$OUT"
  printf '\n' >> "$OUT"
done
IFS=$OLDIFS
echo "==> Wrote app config for: $ALL_DOMAINS"
