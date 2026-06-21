#!/usr/bin/env bash
# Rollback de Allegro a una imagen anterior (por su tag/SHA).
# Uso:  bash rollback.sh <image_tag_previo>
#
# Para ver los tags disponibles publicados en GHCR consulta el historial de
# despliegues (cada deploy etiqueta la imagen con el SHA del commit), o:
#   docker image ls 'ghcr.io/juanarias115/allegro-api'
set -euo pipefail

TAG="${1:?Uso: rollback.sh <image_tag_previo, ej. el SHA de un commit anterior>}"

echo ">> ROLLBACK a allegro-api:${TAG}"
exec bash "$(dirname "$0")/deploy.sh" "$TAG"
