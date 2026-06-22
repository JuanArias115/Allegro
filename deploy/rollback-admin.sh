#!/usr/bin/env bash
set -euo pipefail

TAG="${1:?Uso: rollback-admin.sh <image_tag_previo>}"
echo ">> ROLLBACK a allegro-admin:${TAG}"
exec bash "$(dirname "$0")/deploy-admin.sh" "$TAG"
