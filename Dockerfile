# syntax=docker/dockerfile:1

# Strapi 4.3.2 declares engines node ">=12.x.x <=16.x.x", so 16 is the newest supported.
FROM node:16-bullseye-slim AS build

WORKDIR /srv/app

# better-sqlite3 ships no prebuilt binary for this image and is compiled from source.
RUN apt-get update \
    && apt-get install -y --no-install-recommends python3 make g++ \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN NODE_ENV=production npm run build


FROM node:16-bullseye-slim AS runtime

ENV NODE_ENV=production
WORKDIR /srv/app

COPY --from=build --chown=node:node /srv/app ./

# .tmp and public/uploads are the state that must outlive the container;
# database/migrations is created by Strapi on boot, so the app dir itself
# has to belong to node - WORKDIR created it as root.
RUN mkdir -p .tmp public/uploads database/migrations \
    && chown -R node:node /srv/app

USER node
EXPOSE 1337

CMD ["npm", "run", "start"]
