# syntax = docker/dockerfile:1

# ---- Build stage ----
FROM node:16.17.0-alpine AS build

WORKDIR /app
COPY package*.json ./
RUN npm install --legacy-peer-deps
COPY . .
RUN npm run generate

# ---- Runtime stage ----
FROM nginx:1.27-alpine

LABEL org.opencontainers.image.title="EnBizCard (self-hosted, unmodified)"

COPY --from=build --chown=nginx:nginx /app/public /usr/share/nginx/html
COPY --chown=nginx:nginx nginx.conf /etc/nginx/nginx.conf

RUN mkdir -p /var/cache/nginx/client_temp \
             /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp \
             /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp \
  && chown -R nginx:nginx /var/cache/nginx

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:8080/ || exit 1

CMD ["nginx", "-g", "daemon off;"]
