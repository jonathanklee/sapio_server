# nginx configuration

Canonical copies of the nginx config for Sapio. The live files on the Pi are
installed from these.

## Files

- `checksap.io.conf` -> `/etc/nginx/sites-available/checksap.io`
                        (website + API, the current configuration)
- `strapi.conf`      -> `/etc/nginx/sites-available/strapi.conf`
                        (legacy `server.sapio.ovh`, still proxying)
- `upstream.conf`    -> `/etc/nginx/conf.d/upstream.conf`

Both vhost files are symlinked into `/etc/nginx/sites-enabled/`.

Two legacy redirect hosts also exist on the Pi and are not tracked here:
`sapio-apex.conf` (`sapio.ovh` -> `checksap.io`) and `website.conf`
(`website.sapio.ovh` -> `checksap.io`).

## Domains

`checksap.io` replaced `sapio.ovh` in July 2026.

| Host | Role |
|------|------|
| `checksap.io`, `www.checksap.io` | website |
| `server.checksap.io` | API (Strapi) |
| `server.sapio.ovh` | legacy API, still proxying - see `strapi.conf` |
| `sapio.ovh`, `website.sapio.ovh` | redirect to `checksap.io` |

## Logging

`access_log off` is set on every server block deliberately. The README
promises that visitor IPs never reach a log file. If you add a vhost, carry
that setting over.

## Install / update on a fresh machine

```sh
sudo cp deploy/nginx/checksap.io.conf /etc/nginx/sites-available/checksap.io
sudo cp deploy/nginx/strapi.conf      /etc/nginx/sites-available/strapi.conf
sudo cp deploy/nginx/upstream.conf    /etc/nginx/conf.d/upstream.conf
sudo ln -sf /etc/nginx/sites-available/checksap.io /etc/nginx/sites-enabled/checksap.io
sudo ln -sf /etc/nginx/sites-available/strapi.conf /etc/nginx/sites-enabled/strapi.conf

sudo nginx -t        # validate before reloading
sudo systemctl reload nginx
```

## TLS

Certificates are issued by Certbot (Let's Encrypt) and live under
`/etc/letsencrypt/`. They are NOT in git. On a rebuild:

```sh
sudo certbot --nginx -d checksap.io -d www.checksap.io -d server.checksap.io
```
