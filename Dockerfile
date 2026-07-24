# syntax = docker/dockerfile:1

# ---- Build stage ----
# Pinned to the exact Node version this Nuxt 2 app requires (>=16 <18).
# This entire stage - and every one of its build-tool dependencies - is
# discarded after `npm run generate`. Nothing from here reaches the final
# image or a visitor's browser.
FROM node:16.17.0-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run generate

# ---- Runtime stage ----
# Pin an explicit nginx version rather than floating :alpine/:latest, and
# re-check this periodically the same way as the other two services.
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="EnBizCard (self-hosted, unmodified)"

# Only the generated static output ever reaches this image - no Node
# runtime, no node_modules, no build tooling.
COPY --from=build --chown=nginx:nginx /app/public /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

# nginx:alpine's own low-privilege user - avoid running as root.
USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
