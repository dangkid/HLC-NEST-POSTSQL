#!/bin/bash
#############################################################
# SCRIPT DE CONSTRUCCIÓN DE IMÁGENES DOCKER - D'Angelo Magallanes
# 
# Este script construye todas las imágenes Docker en orden.
# Cada imagen depende de la anterior (cadena de imágenes).
#
# ORDEN DE CONSTRUCCIÓN:
# 1. ubbase         (FROM ubuntu)
# 2. ubseguridad    (FROM dangekid/ubbase)
# 3. nginx1         (FROM dangekid/ubseguridad)
# 4. postgre        (FROM dangekid/ubseguridad)
# 5. pokeapi        (FROM dangekid/nginx1) - NestJS
# 6. pokeapinext    (FROM dangekid/nginx1) - Next.js
# 7. nginxpokeapi   (FROM dangekid/pokeapi) - FINAL NestJS
# 8. pokeapi_next_finalizado (FROM dangekid/pokeapinext) - FINAL Next.js
#############################################################

set -e

DOCKER_USER="dangekid"
BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
DOCKERFILES_DIR="$BASE_DIR/dockerfiles"

echo "=========================================="
echo " Construyendo imágenes Docker"
echo " Usuario: $DOCKER_USER"
echo "=========================================="

# 1. ubbase
echo ""
echo "[1/8] Construyendo $DOCKER_USER/ubbase..."
docker build -t $DOCKER_USER/ubbase -f $DOCKERFILES_DIR/ubbase/damgubbase $BASE_DIR
echo "✅ $DOCKER_USER/ubbase construida"

# 2. ubseguridad
echo ""
echo "[2/8] Construyendo $DOCKER_USER/ubseguridad..."
docker build -t $DOCKER_USER/ubseguridad -f $DOCKERFILES_DIR/ubseguridad/damgubseguridad $BASE_DIR
echo "✅ $DOCKER_USER/ubseguridad construida"

# 3. nginx1
echo ""
echo "[3/8] Construyendo $DOCKER_USER/nginx1..."
docker build -t $DOCKER_USER/nginx1 -f $DOCKERFILES_DIR/sweb/nginx/damgnginx $BASE_DIR
echo "✅ $DOCKER_USER/nginx1 construida"

# 4. postgre
echo ""
echo "[4/8] Construyendo $DOCKER_USER/postgre..."
docker build -t $DOCKER_USER/postgre -f $DOCKERFILES_DIR/postgre/damgpostgre $BASE_DIR
echo "✅ $DOCKER_USER/postgre construida"

# 5. pokeapi (NestJS + Node 22)
echo ""
echo "[5/8] Construyendo $DOCKER_USER/pokeapi..."
docker build -t $DOCKER_USER/pokeapi -f $DOCKERFILES_DIR/nest/damgpokeapi $BASE_DIR
echo "✅ $DOCKER_USER/pokeapi construida"

# 6. pokeapinext (Next.js + Node 20)
echo ""
echo "[6/8] Construyendo $DOCKER_USER/pokeapinext..."
docker build -t $DOCKER_USER/pokeapinext -f $DOCKERFILES_DIR/node_next/dockerfiles $BASE_DIR
echo "✅ $DOCKER_USER/pokeapinext construida"

# 7. nginxpokeapi (FINAL NestJS)
echo ""
echo "[7/8] Construyendo $DOCKER_USER/nginxpokeapi..."
docker build -t $DOCKER_USER/nginxpokeapi -f $DOCKERFILES_DIR/nginxpokeapi/damgnginxpokeapi $BASE_DIR
echo "✅ $DOCKER_USER/nginxpokeapi construida"

# 8. pokeapi_next_finalizado (FINAL Next.js)
echo ""
echo "[8/8] Construyendo $DOCKER_USER/pokeapi_next_finalizado..."
docker build -t $DOCKER_USER/pokeapi_next_finalizado -f $DOCKERFILES_DIR/nginxpokeapi_next/dockerfiles $BASE_DIR
echo "✅ $DOCKER_USER/pokeapi_next_finalizado construida"

echo ""
echo "=========================================="
echo " ¡Todas las imágenes construidas!"
echo "=========================================="
echo ""
docker images | grep $DOCKER_USER
echo ""
echo "=========================================="
echo " Para subir a Docker Hub:"
echo "  docker login"
echo "  docker push $DOCKER_USER/ubbase"
echo "  docker push $DOCKER_USER/ubseguridad"
echo "  docker push $DOCKER_USER/nginx1"
echo "  docker push $DOCKER_USER/postgre"
echo "  docker push $DOCKER_USER/pokeapi"
echo "  docker push $DOCKER_USER/pokeapinext"
echo "  docker push $DOCKER_USER/nginxpokeapi"
echo "  docker push $DOCKER_USER/pokeapi_next_finalizado"
echo "=========================================="
