#!/bin/bash
#############################################################
# SCRIPT PARA SUBIR TODAS LAS IMÁGENES A DOCKER HUB
#############################################################

set -e

DOCKER_USER="dangelomagallanes"

echo "Iniciando sesión en Docker Hub..."
docker login

IMAGES=(
  "ubbase"
  "ubseguridad"
  "nginx1"
  "postgre"
  "pokeapi"
  "pokeapinext"
  "nginxpokeapi"
  "pokeapi_next_finalizado"
)

for img in "${IMAGES[@]}"; do
  echo ""
  echo "Subiendo $DOCKER_USER/$img..."
  docker push $DOCKER_USER/$img
  echo "✅ $DOCKER_USER/$img subida"
done

echo ""
echo "=========================================="
echo " ¡Todas las imágenes subidas a Docker Hub!"
echo "=========================================="
