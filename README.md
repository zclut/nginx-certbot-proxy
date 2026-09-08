# nginx-certbot-proxy

Reverse proxy (nginx + Let's Encrypt/certbot) compartido para varios contenedores de apps, cada uno en su propio compose project.

## Setup

1. `cp .env.example .env` y rellena:
   - `EMAIL`: para las notificaciones de Let's Encrypt.
   - `DOMAIN_MAP`: `dominio=contenedor:puerto` separado por `;`. El primer dominio es el que nombra el certificado (multi-SAN).
2. Cada app externa debe unirse a la red `${PROXY_NETWORK_NAME}` (por defecto `proxy`) como `external: true` y estar levantada **antes** de pedir el certificado.
3. Primer arranque: `./scripts/init-letsencrypt.sh`.
4. Renovación periódica (cron): `./scripts/renew-cert.sh`.

## Añadir un dominio/contenedor nuevo

1. Añade la entrada `dominio=contenedor:puerto` a `DOMAIN_MAP` en `.env`.
2. `./scripts/expand-cert.sh`.

No hace falta tocar `docker-compose.yml` ni los templates de `nginx/templates/` — se regeneran solos desde `DOMAIN_MAP`.

## A tener en cuenta

- `nginx/conf.d/default.conf` es generado (`scripts/generate-conf.sh`), no lo edites a mano — se sobrescribe en cada `expand-cert.sh`/`init-letsencrypt.sh`.
- Todos los dominios de `DOMAIN_MAP` comparten un único certificado (SAN), emitido a nombre del primer dominio de la lista.
- `.env` nunca se commitea (real domains/email) — usa `.env.example` como plantilla.
