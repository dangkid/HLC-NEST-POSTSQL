# HLC-NEST-POSTSQL - D'Angelo Magallanes

## Proyecto Docker + Kubernetes + NestJS + Next.js

### Estructura del Proyecto

```
docker/dangelomagallanes/
├── build_all.sh              # Script para construir todas las imágenes
├── push_all.sh               # Script para subir todas las imágenes a Docker Hub
├── common/                   # Archivos comunes (SSH key)
├── dockerfiles/              # Todos los Dockerfiles
│   ├── ubbase/               # 1. Imagen base Ubuntu
│   ├── ubseguridad/          # 2. Seguridad (port scanning)
│   ├── sweb/nginx/           # 3. Nginx
│   ├── postgre/              # 4. PostgreSQL
│   ├── nest/                 # 5. NestJS + Node 22
│   ├── node_next/            # 6. Next.js + Node 20
│   ├── nginxpokeapi/         # 7. NestJS FINAL (nginx + postgres + nest)
│   └── nginxpokeapi_next/    # 8. Next.js FINAL (nginx + static export)
└── proyecto/
    ├── pbase/deploy/         # Docker Compose - ubbase
    ├── pseguridad/deploy/    # Docker Compose - ubseguridad
    ├── pnginx/deploy/        # Docker Compose - nginx1
    ├── ppostgre/deploy/      # Docker Compose - postgre
    ├── pnode/deploy/         # Docker Compose - pokeapi
    ├── pnode_next/deploy/    # Docker Compose - pokeapinext
    ├── nest_api/deploy/      # Docker Compose - nginxpokeapi (FINAL NestJS)
    ├── next_api/deploy/      # Docker Compose - pokeapi_next_finalizado
    ├── kubernetes/           # Manifiestos Kubernetes
    └── personal/
        ├── nest-con-helm/    # Helm chart NestJS
        └── pokeapi-next-helm/# Helm chart Next.js
```

### Cadena de Imágenes Docker

```
ubuntu
  └─► dangelomagallanes/ubbase
        └─► dangelomagallanes/ubseguridad
              ├─► dangelomagallanes/nginx1
              │     ├─► dangelomagallanes/pokeapi (NestJS + Node 22)
              │     │     └─► dangelomagallanes/nginxpokeapi (FINAL NestJS)
              │     └─► dangelomagallanes/pokeapinext (Next.js + Node 20)
              │           └─► dangelomagallanes/pokeapi_next_finalizado (FINAL Next.js)
              └─► dangelomagallanes/postgre
```

### Despliegue en VPS

#### 1. Clonar el repositorio
```bash
cd /home/dangelo
git clone https://github.com/dangkid/HLC-NEST-POSTSQL.git
cd HLC-NEST-POSTSQL/docker/dangelomagallanes
```

#### 2. Construir todas las imágenes
```bash
chmod +x build_all.sh push_all.sh
./build_all.sh
```

#### 3. Subir a Docker Hub
```bash
./push_all.sh
```

#### 4. Desplegar con Docker Compose (NestJS)
```bash
cd proyecto/nest_api/deploy
docker compose up -d
```

#### 5. Desplegar con Docker Compose (Next.js)
```bash
cd ../../next_api/deploy
docker compose up -d
```

#### 6. Desplegar con Kubernetes
```bash
cd ../../kubernetes/kubernetes
kubectl apply -f namespacepokeapi.yml
kubectl apply -f secretpostgre.yml
kubectl apply -f configmappostgre.yml
kubectl apply -f pvcpostgre.yml
kubectl apply -f deploypostgre.yml
kubectl apply -f servicepostgre.yml
kubectl apply -f deploypokeapi.yml
kubectl apply -f servicepokeapi.yml
kubectl apply -f ingresspokeapi.yml
```

#### 7. Desplegar con Helm
```bash
cd ../../personal/nest-con-helm
helm install nest-api . -n proyecto-nest --create-namespace

cd ../pokeapi-next-helm
helm install next-api . -n proyecto-next --create-namespace
```

### API Endpoints

- **Pokemon**: `GET /pokemon`, `GET /pokemon/:id`, `GET /pokemon/nombre/:nombre`, `GET /pokemon/tipo/:tipo`
- **Peliculas**: `GET /peliculas`, `GET /peliculas/:id`, `GET /peliculas/titulo/:titulo`

### Dominios
- NestJS API: `api.dangelomagallanes.me`
- Next.js Frontend: `pokeapi.dangelomagallanes.me`
