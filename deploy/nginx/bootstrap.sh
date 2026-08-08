#!/bin/sh
#
# Bring nginx up on a fresh machine, certificates included.
#
#   sudo ./deploy/nginx/bootstrap.sh you@example.com
#
# The vhosts reference /etc/letsencrypt/live/<name>/fullchain.pem, and nginx
# refuses to start when those files are missing - but certbot needs nginx
# listening on :80 to answer the HTTP-01 challenge. So this runs in three
# steps: a :80-only config, then certbot, then the real config.
#
# DNS for every name below must already point at this machine, otherwise the
# challenges fail. To migrate without a DNS cutover window, obtain the
# certificates through a DNS-01 challenge instead and skip step 2.

set -eu

EMAIL="${1:-}"
HERE="$(cd "$(dirname "$0")" && pwd)"
WEBROOT="/var/www/sapio-website"

CERTS="
checksap.io:checksap.io,www.checksap.io
server.checksap.io:server.checksap.io
sapio.ovh:sapio.ovh,www.sapio.ovh,website.sapio.ovh
server.sapio.ovh:server.sapio.ovh
"

if [ -z "$EMAIL" ]; then
    echo "usage: sudo ./bootstrap.sh you@example.com" >&2
    exit 1
fi

if [ "$(id -u)" -ne 0 ]; then
    echo "run me as root" >&2
    exit 1
fi

command -v certbot >/dev/null || { echo "certbot is not installed" >&2; exit 1; }

echo "==> 1/3  temporary :80-only vhost"
mkdir -p "$WEBROOT"
cat > /etc/nginx/sites-available/bootstrap.conf <<EOF
server {
    access_log off;
    listen 80 default_server;
    server_name _;

    location /.well-known/acme-challenge/ {
        root $WEBROOT;
    }

    location / {
        return 404;
    }
}
EOF

# Park anything already enabled so nginx can start without certificates.
mkdir -p /etc/nginx/sites-enabled.bootstrap-backup
find /etc/nginx/sites-enabled -mindepth 1 -maxdepth 1 \
    -exec mv -t /etc/nginx/sites-enabled.bootstrap-backup {} + 2>/dev/null || true
ln -sf /etc/nginx/sites-available/bootstrap.conf /etc/nginx/sites-enabled/bootstrap.conf

cp "$HERE/upstream.conf" /etc/nginx/conf.d/upstream.conf
cp "$HERE/legacy-log.conf" /etc/nginx/conf.d/legacy-log.conf

nginx -t
systemctl reload nginx 2>/dev/null || systemctl start nginx

echo "==> 2/3  certificates"
for entry in $CERTS; do
    name="${entry%%:*}"
    domains="${entry#*:}"

    if [ -f "/etc/letsencrypt/live/$name/fullchain.pem" ]; then
        echo "    $name already present, skipping"
        continue
    fi

    # shellcheck disable=SC2086
    certbot certonly --webroot -w "$WEBROOT" \
        --cert-name "$name" \
        $(echo "$domains" | tr ',' '\n' | sed 's/^/-d /' | tr '\n' ' ') \
        --email "$EMAIL" --agree-tos --non-interactive
    echo "    $name issued"
done

echo "==> 3/3  real vhosts"
rm -f /etc/nginx/sites-enabled/bootstrap.conf /etc/nginx/sites-available/bootstrap.conf

cp "$HERE/checksap.io.conf"      /etc/nginx/sites-available/checksap.io
cp "$HERE/legacy-redirects.conf" /etc/nginx/sites-available/legacy-redirects.conf
cp "$HERE/strapi.conf"           /etc/nginx/sites-available/strapi.conf

# Symlinks, never copies: independent copies in sites-enabled silently drift
# from the tracked files and edits stop taking effect.
for f in checksap.io legacy-redirects.conf strapi.conf; do
    ln -sf "/etc/nginx/sites-available/$f" "/etc/nginx/sites-enabled/$f"
done

nginx -t
systemctl reload nginx

echo "==> done"
echo "    parked config from before: /etc/nginx/sites-enabled.bootstrap-backup"
certbot certificates 2>/dev/null | grep -E "Certificate Name|Domains" | sed 's/^ */    /'
