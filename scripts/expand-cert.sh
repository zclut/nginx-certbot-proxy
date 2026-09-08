#!/bin/sh
# Re-run when DOMAIN_MAP in .env gained a new domain after a cert already
# exists (init-letsencrypt.sh skips issuance in that case since it sees a
# valid cert already).
#
# The nginx config regenerates automatically from DOMAIN_MAP — no template
# editing needed, just add the new "domain=container:port" entry to
# DOMAIN_MAP first.
set -e
cd "$(dirname "$0")/.."
. ./scripts/lib.sh

detect_dc
load_env
parse_domain_map
echo "==> Expanding cert for: $DOMAIN_ARGS"

$DC run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  --expand \
  $DOMAIN_ARGS

./scripts/generate-conf.sh
$DC exec nginx nginx -s reload

echo "==> Done."
