# Pokemon API - NestJS con Docker y Kubernetes

## 📋 Estructura del Proyecto

```
nest_api/
├── deploy/
│   ├── .env                          # Variables de entorno Docker
│   ├── docker-compose.yml            # Composición local de contenedores
│   ├── build_img/
│   │   └── Dockerfile                # Build del API NestJS
│   └── kubernetes/
│       ├── 01-namespace.yml          # Namespace del proyecto
│       ├── 02-secret.yml             # Secretos (credenciales DB)
│       ├── 03-configmap.yml          # Configuración
│       ├── 04-pvc.yml                # Volumen persistente PostgreSQL
│       ├── 05-deploy-postgres.yml    # Deployment PostgreSQL
│       ├── 06-service-postgres.yml   # Service PostgreSQL
│       ├── 07-deploy-api.yml         # Deployment API NestJS
│       ├── 08-service-api.yml        # Service API
│       ├── 09-ingress.yml            # Ingress (api.dangelomagallanes.me)
│       └── deploy.sh                 # Script de deploy
├── src/                              # Código fuente NestJS
│   ├── pokemon/                      # Módulo Pokemon
│   └── peliculas/                    # Módulo Peliculas
├── public/                           # Archivos estáticos
├── test/                             # Tests e2e
├── package.json
├── tsconfig.json
├── nest-cli.json
└── entrypoint.sh                     # Script de entrada del contenedor
```

## 🚀 Ejecución Local con Docker Compose

### Requisitos
- Docker Desktop instalado
- Docker Compose v3.8+
- Node.js 20+ (opcional, solo para desarrollo sin Docker)

### Pasos

1. **Clonar el repositorio**
```bash
cd Docker/Caronte/proyectos/nest_api
```

2. **Configurar variables de entorno**
```bash
cd deploy
# El archivo .env ya está configurado, pero puedes modificarlo si es necesario
cat .env
```

3. **Construir e iniciar los contenedores**
```bash
docker-compose up -d
```

4. **Ver logs**
```bash
docker-compose logs -f api
docker-compose logs -f postgres
```

5. **Acceder a la API**
- Local: http://localhost:3010
- Swagger (si está configurado): http://localhost:3010/api

6. **Detener los contenedores**
```bash
docker-compose down
```

## ☸️ Despliegue en Kubernetes

### Requisitos
- Cluster Kubernetes corriendo (minikube, Docker Desktop K8s, EKS, etc.)
- `kubectl` configurado y conectado al cluster
- NGINX Ingress Controller instalado
- Acceso DNS a `api.dangelomagallanes.me`

### Pasos

1. **Navegar al directorio de Kubernetes**
```bash
cd deploy/kubernetes
```

2. **Opción A: Usar el script automatizado**
```bash
chmod +x deploy.sh
./deploy.sh
```

3. **Opción B: Aplicar manifiestos manualmente**
```bash
kubectl apply -f 01-namespace.yml
kubectl apply -f 02-secret.yml
kubectl apply -f 03-configmap.yml
kubectl apply -f 04-pvc.yml
kubectl apply -f 05-deploy-postgres.yml
kubectl apply -f 06-service-postgres.yml
kubectl apply -f 07-deploy-api.yml
kubectl apply -f 08-service-api.yml
kubectl apply -f 09-ingress.yml
```

4. **Verificar el deployment**
```bash
kubectl -n proyecto-nest get pods
kubectl -n proyecto-nest get svc
kubectl -n proyecto-nest get ingress
```

5. **Ver logs de los pods**
```bash
kubectl -n proyecto-nest logs -f deployment/pokemon-api-deployment
kubectl -n proyecto-nest logs -f deployment/postgres-pokemon-deployment
```

## 🔧 Configuración

### Variables de Entorno (deploy/.env)

| Variable | Valor | Descripción |
|----------|-------|-------------|
| `DB_HOST` | `postgres-pokemon` (Docker) / `postgres-pokemon-service` (K8s) | Host de PostgreSQL |
| `DB_PORT` | `5432` | Puerto de PostgreSQL |
| `DB_USER` | `pokemonuser` | Usuario de PostgreSQL |
| `DB_PASSWORD` | `pokemonpass123` | Contraseña (⚠️ cambiar en producción) |
| `DATABASE` | `pokemondb` | Nombre de la base de datos |
| `PORT` | `3001` | Puerto del API |
| `NODE_ENV` | `development` | Entorno (development/production) |

### Secretos de Kubernetes

Los secretos están definidos en `02-secret.yml`. En producción:

```bash
kubectl -n proyecto-nest create secret generic pokemon-secret \
  --from-literal=POSTGRES_USER=pokemonuser \
  --from-literal=POSTGRES_PASSWORD=<PASSWORD_SEGURA> \
  --from-literal=POSTGRES_DB=pokemondb \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 📊 Monitoreo

### Con Docker Compose
```bash
# Ver estadísticas de contenedores
docker stats

# Inspeccionar logs
docker-compose logs api --tail 100 -f
```

### Con Kubernetes
```bash
# Ver pods y su estado
kubectl -n proyecto-nest get pods -w

# Ver recursos consumidos
kubectl -n proyecto-nest top pods

# Describir un pod (útil para troubleshooting)
kubectl -n proyecto-nest describe pod <pod-name>

# Ver eventos del namespace
kubectl -n proyecto-nest get events --sort-by='.lastTimestamp'
```

## 🐛 Troubleshooting

### Pod no inicia (ImagePullBackOff)
```bash
# Compilar y pushear la imagen a tu registro
docker build -t dangelomagallanes/nest-api:latest .
docker push dangelomagallanes/nest-api:latest

# Forzar un nuevo deploy
kubectl -n proyecto-nest rollout restart deployment/pokemon-api-deployment
```

### Error de conexión a PostgreSQL
```bash
# Verificar que PostgreSQL está corriendo
kubectl -n proyecto-nest get pods -l app=postgres-pokemon

# Ver logs de PostgreSQL
kubectl -n proyecto-nest logs -l app=postgres-pokemon

# Acceder a PostgreSQL desde dentro del cluster
kubectl -n proyecto-nest exec -it <api-pod> -- psql -h postgres-pokemon-service -U pokemonuser -d pokemondb
```

### Ingress no funciona
```bash
# Verificar que NGINX Ingress está instalado
kubectl get ingressclass

# Ver estado del Ingress
kubectl -n proyecto-nest describe ingress pokemon-api-ingress

# Verificar logs del NGINX Ingress
kubectl -n ingress-nginx logs -l app.kubernetes.io/name=ingress-nginx --tail 50
```

## 🔐 Información Importante para Producción

- **Cambiar contraseñas**: Reemplazar `pokemonpass123` con contraseñas fuertes
- **Certificados SSL**: Configurar con Let's Encrypt usando cert-manager
- **Backups**: Configurar snapshots automáticos del volumen PostgreSQL
- **Recursos**: Ajustar `requests` y `limits` según necesidad
- **Réplicas**: El deployment está configurado con 3 réplicas por defecto
- **Dominio**: Asegurar que `api.dangelomagallanes.me` apunta al Ingress Controller

## 🔄 Actualizaciones

### Actualizar la imagen del API
```bash
# 1. Construir nueva imagen
docker build -t dangelomagallanes/nest-api:v1.0.0 .

# 2. Pushear a registro
docker push dangelomagallanes/nest-api:v1.0.0

# 3. Actualizar el deployment (en 07-deploy-api.yml cambiar la versión)
kubectl -n proyecto-nest set image deployment/pokemon-api-deployment \
  pokemon-api=dangelomagallanes/nest-api:v1.0.0

# Ver progreso del rolling update
kubectl -n proyecto-nest rollout status deployment/pokemon-api-deployment
```

## 📝 Notas

- El namespace es `proyecto-nest`
- PostgreSQL usa almacenamiento persistente
- El API escala automáticamente con 3 réplicas
- Los logs se guardan en un emptyDir (volumen temporal)
- El Ingress redirige `api.dangelomagallanes.me` al servicio
