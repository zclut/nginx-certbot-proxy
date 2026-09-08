#!/bin/sh
# Run periodically (e.g. a weekly cron job) to renew the cert before it
# expires. certbot no-ops if it's not due yet, so this is safe to run often.
set -e
cd "$(dirname "$0")/.."

if docker compose version >/dev/null 2>&1; then
  DC="docker compose"
else
  DC="docker-compose"
fi

$DC run --rm certbot renew --webroot -w /var/www/certbot
$DC exec nginx nginx -s reload
