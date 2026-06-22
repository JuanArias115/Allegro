#!/bin/sh
# Inyecta la configuración de runtime (URL del backend) en config.json antes de
# que Nginx empiece a servir. Lo ejecuta automáticamente el entrypoint de la
# imagen oficial de Nginx (archivos en /docker-entrypoint.d/).
#
# Variable esperada:
#   API_BASE_URL  URL del backend (p. ej. https://allegro.juanariasdev.com)
set -e

CONFIG_FILE=/usr/share/nginx/html/config.json

if [ -n "$API_BASE_URL" ]; then
  echo "{\"apiBaseUrl\":\"$API_BASE_URL\"}" > "$CONFIG_FILE"
  echo "admin-web: apiBaseUrl=$API_BASE_URL"
else
  echo "{}" > "$CONFIG_FILE"
  echo "admin-web: sin API_BASE_URL; se usa el valor compilado en environment."
fi
