# nginx configuration

Canonical copies of the nginx config for Sapio. The live files on the Pi are
installed from these.

## Files

- `checksap.io.conf`      -> `/etc/nginx/sites-available/checksap.io`
                             (website + API, the current configuration)
- `legacy-redirects.conf` -> `/etc/nginx/sites-available/legacy-redirects.conf`
                             (`sapio.ovh`, `www.sapio.ovh`, `website.sapio.ovh`)
- `strapi.conf`           -> `/etc/nginx/sites-available/strapi.conf`
                             (legacy `server.sapio.ovh`, still proxying)
- `legacy-log.conf`       -> `/etc/nginx/conf.d/legacy-log.conf`
- `upstream.conf`         -> `/etc/nginx/conf.d/upstream.conf`

The vhost files are symlinked into `/etc/nginx/sites-enabled/`. Keep them as
symlinks: three of these used to be independent copies in `sites-enabled`, and
they silently drifted from `sites-available` - edits to the tracked file had no
effect on the running server.

## Domains

`checksap.io` replaced `sapio.ovh` in July 2026.

| Host | Role |
|------|------|
| `checksap.io`, `www.checksap.io` | website |
| `server.checksap.io` | API (Strapi) |
| `server.sapio.ovh` | legacy API, still proxying - see `strapi.conf` |
| `sapio.ovh`, `www.sapio.ovh`, `website.sapio.ovh` | redirect to `checksap.io` |

## Logging

`access_log off` is set on every server block deliberately. The README promises
that visitor IPs never reach a log file. If you add a vhost, carry that setting
over.

The single exception is the `:443` block of `strapi.conf`, which uses the
`legacy_count` format: timestamp, method, path and status, and nothing that
identifies anyone. It exists only to answer "can server.sapio.ovh be retired
yet?", which is otherwise unanswerable with logging off.

```sh
wc -l /var/log/nginx/legacy-usage.log     # still in use?
```

## Install / update on a fresh machine

```sh
sudo cp deploy/nginx/checksap.io.conf      /etc/nginx/sites-available/checksap.io
sudo cp deploy/nginx/legacy-redirects.conf /etc/nginx/sites-available/legacy-redirects.conf
sudo cp deploy/nginx/strapi.conf           /etc/nginx/sites-available/strapi.conf
sudo cp deploy/nginx/legacy-log.conf       /etc/nginx/conf.d/legacy-log.conf
sudo cp deploy/nginx/upstream.conf         /etc/nginx/conf.d/upstream.conf

for f in checksap.io legacy-redirects.conf strapi.conf; do
    sudo ln -sf /etc/nginx/sites-available/$f /etc/nginx/sites-enabled/$f
done

sudo nginx -t        # validate before reloading
sudo systemctl reload nginx
```

## TLS

Certificates are issued by Certbot (Let's Encrypt) and live under
`/etc/letsencrypt/`. They are NOT in git.

```sh
sudo certbot --nginx -d checksap.io -d www.checksap.io -d server.checksap.io
sudo certbot certonly --cert-name sapio.ovh --webroot -w /var/www/sapio-website \
    -d sapio.ovh -d www.sapio.ovh -d website.sapio.ovh
```
