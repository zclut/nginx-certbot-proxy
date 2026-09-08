#!/bin/sh
# First-time HTTPS bootstrap.
#
# nginx can't start with a config that points at
# /etc/letsencrypt/live/<domain>/fullchain.pem before that file exists, and
# certbot can't get that file without nginx already serving the HTTP-01
# challenge — so this script does it in the right order:
#   1. render an HTTP-only nginx config from DOMAIN_MAP (no SSL block yet)
#   2. bring up nginx
#   3. ask certbot for the certificate over plain HTTP, for every domain in
#      DOMAIN_MAP (.env)
#   4. render the real HTTP+HTTPS config and reload nginx
#
# Requires the app container of every DOMAIN_MAP entry to already be up and
# joined to the shared "proxy" network — this repo only owns nginx/certbot,
# not the apps.
#
# Safe to re-run: certbot skips issuance if a valid cert already exists.
set -e
cd "$(dirname "$0")/.."
. ./scripts/lib.sh

detect_dc
echo "==> Using: $DC"

load_env
parse_domain_map
echo "==> Domains: $DOMAIN_ARGS"

echo "==> [1/5] Writing bootstrap (HTTP-only) nginx config..."
./scripts/generate-conf.sh bootstrap

echo "==> [2/5] Starting nginx..."
$DC up -d nginx

echo "==> [3/5] Waiting for nginx to come up..."
sleep 3

echo "==> [4/5] Requesting certificate from Let's Encrypt..."
$DC run --rm certbot certonly --webroot \
  --webroot-path=/var/www/certbot \
  --email "$EMAIL" \
  --agree-tos \
  --no-eff-email \
  --non-interactive \
  $DOMAIN_ARGS

echo "==> [5/5] Switching nginx to the HTTPS config..."
./scripts/generate-conf.sh
$DC exec nginx nginx -s reload

echo "==> Done."
