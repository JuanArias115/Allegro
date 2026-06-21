#!/usr/bin/env bash
# Despliegue de Allegro en el servidor. Se ejecuta desde /opt/allegro.
# Uso:  bash deploy.sh <image_tag>     (ej. el SHA del commit; por defecto 'latest')
set -euo pipefail

TAG="${1:-latest}"
COMPOSE_DIR="/opt/allegro"
COMPOSE_FILE="docker-compose.production.yml"

cd "$COMPOSE_DIR"

if [ ! -f .env ]; then
  echo "ERROR: no existe $COMPOSE_DIR/.env (copia .env.production.example y complétalo)." >&2
  exit 1
fi

# Fija la imagen a desplegar en el .env (persiste para reinicios).
if grep -q '^IMAGE_TAG=' .env; then
  sed -i "s|^IMAGE_TAG=.*|IMAGE_TAG=${TAG}|" .env
else
  echo "IMAGE_TAG=${TAG}" >> .env
fi

echo ">> Desplegando ghcr.io/juanarias115/allegro-api:${TAG}"
docker compose -f "$COMPOSE_FILE" pull
docker compose -f "$COMPOSE_FILE" up -d

echo ">> Esperando a que allegro-api quede healthy (/health/ready)..."
for i in $(seq 1 30); do
  status="$(docker inspect --format '{{.State.Health.Status}}' allegro-api 2>/dev/null || echo starting)"
  echo "   intento ${i}/30: ${status}"
  if [ "$status" = "healthy" ]; then
    echo ">> Despliegue correcto: allegro-api:${TAG} está healthy."
    exit 0
  fi
  if [ "$status" = "unhealthy" ]; then
    break
  fi
  sleep 5
done

echo "ERROR: allegro-api no respondió correctamente en /health/ready." >&2
docker compose -f "$COMPOSE_FILE" logs --tail 60 allegro-api || true
exit 1
