#!/usr/bin/env bash
set -euo pipefail

TAG="${1:-latest}"
COMPOSE_DIR="/opt/allegro"
COMPOSE_FILE="docker-compose.admin.yml"

cd "$COMPOSE_DIR"

if [ ! -f .env ]; then
  echo "ERROR: no existe $COMPOSE_DIR/.env." >&2
  exit 1
fi

required=(
  FIREBASE_WEB_API_KEY
  FIREBASE_WEB_AUTH_DOMAIN
  FIREBASE_WEB_PROJECT_ID
  FIREBASE_WEB_STORAGE_BUCKET
  FIREBASE_WEB_MESSAGING_SENDER_ID
  FIREBASE_WEB_APP_ID
)
for name in "${required[@]}"; do
  if ! grep -q "^${name}=." .env; then
    echo "ERROR: falta ${name} en $COMPOSE_DIR/.env." >&2
    exit 1
  fi
done

if grep -q '^ADMIN_IMAGE_TAG=' .env; then
  sed -i "s|^ADMIN_IMAGE_TAG=.*|ADMIN_IMAGE_TAG=${TAG}|" .env
else
  echo "ADMIN_IMAGE_TAG=${TAG}" >> .env
fi

echo ">> Desplegando ghcr.io/juanarias115/allegro-admin:${TAG}"
docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d

echo ">> Esperando health check de allegro-admin..."
for i in $(seq 1 24); do
  status="$(docker inspect --format '{{.State.Health.Status}}' allegro-admin 2>/dev/null || echo starting)"
  echo "   intento ${i}/24: ${status}"
  if [ "$status" = "healthy" ]; then
    echo ">> Despliegue correcto: allegro-admin:${TAG}."
    exit 0
  fi
  if [ "$status" = "unhealthy" ]; then
    break
  fi
  sleep 5
done

echo "ERROR: allegro-admin no quedó healthy." >&2
docker compose -f "$COMPOSE_FILE" logs --tail 80 allegro-admin || true
exit 1
