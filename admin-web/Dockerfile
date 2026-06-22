# ---- Build ----
FROM node:22-alpine AS build
WORKDIR /app

COPY package*.json ./
# package-lock.json fue generado con la versión declarada en packageManager.
# Node 22 Alpine incluye npm 10, que no resuelve el lock de npm 11 de forma idéntica.
RUN npm install --global npm@11.6.2
RUN npm ci

COPY . .
RUN npm run build

# ---- Runtime (Nginx) ----
FROM nginx:1.27-alpine AS runtime

# Config de Nginx (SPA fallback + health + gzip).
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Artefactos estáticos compilados.
COPY --from=build /app/dist/admin-web/browser /usr/share/nginx/html

# Entrypoint: inyecta config.json en runtime desde API_BASE_URL y arranca Nginx.
COPY docker-entrypoint.sh /docker-entrypoint.d/40-app-config.sh
RUN chmod +x /docker-entrypoint.d/40-app-config.sh

EXPOSE 80

# Health check simple contra el endpoint estático /healthz.
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget -qO- http://localhost/healthz || exit 1
