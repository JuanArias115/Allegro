#!/bin/sh
# Inyecta la configuración de runtime (URL del backend) en config.json antes de
# que Nginx empiece a servir. Lo ejecuta automáticamente el entrypoint de la
# imagen oficial de Nginx (archivos en /docker-entrypoint.d/).
#
# Variables públicas esperadas: API_BASE_URL y FIREBASE_WEB_*.
set -e

CONFIG_FILE=/usr/share/nginx/html/config.json

cat > "$CONFIG_FILE" <<EOF
{
  "apiBaseUrl": "${API_BASE_URL:-}",
  "googleAuthEnabled": ${GOOGLE_AUTH_ENABLED:-true},
  "firebase": {
    "apiKey": "${FIREBASE_WEB_API_KEY:-}",
    "authDomain": "${FIREBASE_WEB_AUTH_DOMAIN:-}",
    "projectId": "${FIREBASE_WEB_PROJECT_ID:-}",
    "storageBucket": "${FIREBASE_WEB_STORAGE_BUCKET:-}",
    "messagingSenderId": "${FIREBASE_WEB_MESSAGING_SENDER_ID:-}",
    "appId": "${FIREBASE_WEB_APP_ID:-}"
  }
}
EOF

echo "admin-web: configuración pública generada para ${FIREBASE_WEB_PROJECT_ID:-proyecto-no-definido}"
