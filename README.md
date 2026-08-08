# Sapio server

Backend for [Sapio](https://github.com/jonathanklee/Sapio) — community
compatibility data for Android apps running without Google Play Services.

Serves the public API at **https://server.checksap.io/api** and stores the app
icons shown on [checksap.io](https://checksap.io) and in the Android app.

- **Strapi 4.3.2** on Node 16 (Strapi declares `>=12 <=16`)
- **SQLite** — the dataset is small, a few thousand evaluations
- **nginx** in front, terminating TLS; Strapi itself only listens on `127.0.0.1:1337`

## Deploying to a fresh machine

```sh
sudo ./deploy/nginx/bootstrap.sh you@example.com   # nginx + Let's Encrypt certificates
./deploy.sh user@host --with-data                  # Strapi + database + uploads
```

`bootstrap.sh` is only needed once per machine. Afterwards, redeploying is a
single command:

```sh
./deploy.sh user@host
```

It syncs the source, pushes `.env`, rebuilds the image on the target and
restarts. Data is never deleted remotely — `--with-data` only adds.

Requirements on the target: docker, the compose plugin, your SSH key, and DNS
already pointing at it (the certificates use an HTTP-01 challenge).

## Running it locally

```sh
cp .env.example .env      # then fill in the secrets
docker compose up --build
```

Strapi comes up on <http://127.0.0.1:1337>, admin panel at `/admin`, against an
empty database under `./data/db`.

## State that matters

Two directories hold everything worth keeping. Both are gitignored and mounted
as volumes.

| Path | Contents |
|------|----------|
| `data/db/data.db` | evaluations, admin accounts, **role permissions** |
| `data/uploads/` | app icons — roughly 8000 files, ~200 MB |

**The database cannot be regenerated.** The Android app submits evaluations
anonymously, with no API token, which only works because the *public* role has
create and update permissions — and those permissions live in the database. A
fresh database answers 403 to every submission.

## Secrets

Everything needed to run lives in `.env` (see `.env.example`); there is no key
material anywhere else. TLS is handled by certbot and lives under
`/etc/letsencrypt`, never in this repo.

None of the secrets are tied to the data — regenerating them only forces an
admin re-login. Generate each with:

```sh
openssl rand -base64 32
```

## nginx

Configuration is tracked in [`deploy/nginx/`](deploy/nginx/README.md), which
also covers the domains, the legacy `sapio.ovh` hosts, and why access logging
is off everywhere.

## Strapi CLI

```sh
npm run develop    # autoReload enabled
npm run start      # autoReload disabled
npm run build      # rebuild the admin panel
```

See the [Strapi documentation](https://docs.strapi.io) for the rest.
