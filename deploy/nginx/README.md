# nginx configuration

Canonical copies of the nginx config for the Sapio Strapi server.
The live files on the Pi are installed from these.

## Files

- `strapi.conf`   -> `/etc/nginx/sites-available/strapi.conf`
                     (symlinked into `/etc/nginx/sites-enabled/`)
- `upstream.conf` -> `/etc/nginx/conf.d/upstream.conf`

## Install / update on a fresh machine

```sh
sudo cp deploy/nginx/strapi.conf   /etc/nginx/sites-available/strapi.conf
sudo cp deploy/nginx/upstream.conf /etc/nginx/conf.d/upstream.conf
sudo ln -sf /etc/nginx/sites-available/strapi.conf /etc/nginx/sites-enabled/strapi.conf

sudo nginx -t        # validate before reloading
sudo systemctl reload nginx
```

## TLS

Certificates are issued by Certbot (Lets Encrypt) for `server.sapio.ovh`
and live under `/etc/letsencrypt/`. They are NOT in git. On a rebuild,
re-run: `sudo certbot --nginx -d server.sapio.ovh`
