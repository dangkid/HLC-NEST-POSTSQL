# Guía de Despliegue Automático con Helm

Este proyecto incluye scripts automatizados para desplegar la arquitectura completa de 8 capas Docker con Helm en Kubernetes.

## 📋 Requisitos Previos

Antes de ejecutar los scripts, asegúrate de tener:

### Local (Máquina de desarrollo)
```bash
# Verificar instalaciones
docker --version          # Docker 20.10+
helm --version           # Helm 3.0+
kubectl --version        # kubectl v1.20+
```

### En la VPS
```bash
# SSH accesible
ssh -p 23456 dangelo@37.60.238.102

# Kubernetes (microk8s)
microk8s status

# Helm instalado
microk8s helm version
```

### Credenciales Docker Hub
```bash
# Asegúrate de estar logueado en Docker Hub
docker login
# Usuario: dangekid
# Contraseña: [tu contraseña de Docker Hub]
```

## 🚀 Despliegue Rápido (Recomendado)

### Opción 1: Despliegue Remoto (Preferido)
```bash
chmod +x deploy_remote.sh
./deploy_remote.sh dangelo@37.60.238.102
```

Este script:
1. ✅ Conecta a la VPS automáticamente
2. ✅ Actualiza el código del repositorio
3. ✅ Crea el namespace `proyecto-nest`
4. ✅ Despliega NestJS API con Helm
5. ✅ Despliega Next.js Frontend con Helm
6. ✅ Verifica que todos los servicios estén listos
7. ✅ Muestra URLs de acceso

**Tiempo estimado: 3-5 minutos**

### Opción 2: Despliegue Local
```bash
chmod +x deploy_helm.sh
./deploy_helm.sh proyecto-nest
```

Este script:
1. 🔨 Construye los 8 Docker images en orden
2. 📤 Empuja los images a Docker Hub
3. 🚀 Despliega con Helm en Kubernetes local
4. ✅ Verifica que los pods estén ready

**Tiempo estimado: 15-20 minutos (incluye build)**

## 📊 Arquitectura de 8 Capas

```
Layer 1: ubbase
   ↓
Layer 2: ubseguridad
   ├→ Layer 3: nginx1
   │   ├→ Layer 4: pokeapi (NestJS)
   │   │   └→ Layer 5: nginxpokeapi ✅
   │   └→ Layer 4b: pokeapinext (Next.js)
   │       └→ Layer 5b: nginxpokeapi_next ✅
   └→ Layer 3b: postgre (PostgreSQL)
```

### Imágenes en Docker Hub
- `dangekid/ubbase`
- `dangekid/ubseguridad`
- `dangekid/nginx1`
- `dangekid/postgre`
- `dangekid/pokeapi`
- `dangekid/pokeapinext`
- `dangekid/nginxpokeapi`
- `dangekid/nginxpokeapi_next`

## 🔧 Despliegue Manual Paso a Paso

### Paso 1: Construir Imágenes
```bash
cd /docker/dangelomagallanes
./build_all.sh
```

### Paso 2: Empujar a Docker Hub
```bash
# Asegúrate de estar logueado
docker login

# Empujar las 8 imágenes
docker push dangekid/ubbase
docker push dangekid/ubseguridad
docker push dangekid/nginx1
docker push dangekid/postgre
docker push dangekid/pokeapi
docker push dangekid/pokeapinext
docker push dangekid/nginxpokeapi
docker push dangekid/nginxpokeapi_next
```

### Paso 3: Desplegar con Helm
```bash
# Crear namespace
kubectl create namespace proyecto-nest

# Desplegar NestJS API
helm upgrade --install nest-api ./proyecto/personal/nest-con-helm \
    --namespace proyecto-nest

# Desplegar Next.js Frontend
helm upgrade --install next-frontend ./proyecto/personal/pokeapi-next-helm \
    --namespace proyecto-nest
```

### Paso 4: Verificar Despliegue
```bash
# Ver pods
kubectl get pods -n proyecto-nest

# Ver servicios
kubectl get svc -n proyecto-nest

# Ver logs
kubectl logs -n proyecto-nest -l app=nest-api
kubectl logs -n proyecto-nest -l app=next-frontend
```

## 🌐 URLs de Acceso

Una vez desplegado:

```
API NestJS:
  http://37.60.238.102:30010/pokemon

Frontend Next.js:
  http://37.60.238.102:30087/

API Docs (Swagger - si está configurado):
  http://37.60.238.102:30010/api/
```

## 📝 Configuración de Helm

### NestJS (nest-con-helm)
- **Deployment:** `nginx1` container con entrypoint personalizado
- **Service:** NodePort 30010
- **Puerto interno:** 3001
- **Replicas:** 1 (modificable en values.yaml)
- **Database:** PostgreSQL 15

Archivo de configuración:
```bash
./proyecto/personal/nest-con-helm/values.yaml
```

### Next.js (pokeapi-next-helm)
- **Deployment:** `nginxpokeapi_next` container
- **Service:** NodePort 30087
- **Puerto interno:** 80
- **Replicas:** 1 (modificable en values.yaml)

Archivo de configuración:
```bash
./proyecto/personal/pokeapi-next-helm/values.yaml
```

## 🐛 Troubleshooting

### Los pods no alcanzan estado Ready
```bash
# Ver logs detallados
kubectl describe pod <pod-name> -n proyecto-nest
kubectl logs <pod-name> -n proyecto-nest -f

# Posible causa: Las imágenes no existen en Docker Hub
# Solución: Ejecutar `docker login` y empujar las imágenes nuevamente
```

### Error de conexión a la VPS
```bash
# Verificar SSH
ssh -p 23456 -v dangelo@37.60.238.102

# Verificar que el puerto 23456 está abierto
nc -zv 37.60.238.102 23456
```

### Helm release ya existe
```bash
# Eliminar y reinstalar
helm uninstall nest-api -n proyecto-nest
helm uninstall next-frontend -n proyecto-nest

# O usar upgrade para actualizar
helm upgrade --install nest-api ./nest-con-helm -n proyecto-nest
```

### Error: "imagePullBackOff"
```bash
# Las imágenes no están disponibles en Docker Hub
# Soluciones:
1. Construir las imágenes localmente: ./build_all.sh
2. Empujar a Docker Hub: docker push dangekid/*
3. Redeplegar: helm upgrade --install nest-api ./nest-con-helm
```

## 📦 Archivos Importantes

```
docker/dangelomagallanes/
├── deploy_helm.sh              ← Script de despliegue local
├── deploy_remote.sh            ← Script de despliegue en VPS
├── build_all.sh                ← Script para construir 8 imágenes
├── README_DEPLOYMENT.md        ← Esta guía
├── dockerfiles/
│   ├── ubbase/
│   ├── ubseguridad/
│   ├── nginx1/
│   ├── postgre/
│   ├── nginxpokeapi/
│   └── nginxpokeapi_next/
└── proyecto/personal/
    ├── nest-con-helm/          ← Helm chart para NestJS
    │   └── values.yaml
    └── pokeapi-next-helm/      ← Helm chart para Next.js
        └── values.yaml
```

## 🔄 Actualizar Despliegue

Para actualizar después de cambios en el código:

```bash
# Opción 1: Despliegue remoto rápido
./deploy_remote.sh dangelo@37.60.238.102

# Opción 2: Manual
./build_all.sh                    # Construir nuevamente
docker push dangekid/*            # Empujar imágenes
helm upgrade nest-api ./nest-con-helm -n proyecto-nest
helm upgrade next-frontend ./pokeapi-next-helm -n proyecto-nest
```

## ✅ Checklist de Despliegue

- [ ] Docker instalado y logueado en Docker Hub
- [ ] Helm 3 instalado
- [ ] kubectl configurado (apunta a microk8s)
- [ ] SSH funciona: `ssh -p 23456 dangelo@37.60.238.102`
- [ ] Scripts son ejecutables: `chmod +x deploy_*.sh build_all.sh`
- [ ] Código actualizado: `git pull origin main`
- [ ] Ejecutar despliegue: `./deploy_remote.sh dangelo@37.60.238.102`
- [ ] Verificar pods: `kubectl get pods -n proyecto-nest`
- [ ] Probar API: `curl http://37.60.238.102:30010/pokemon`
- [ ] Probar Frontend: Visitar en navegador

## 📞 Soporte

Si encuentras problemas:

1. **Revisar logs locales:**
   ```bash
   ./deploy_helm.sh proyecto-nest 2>&1 | tee deployment.log
   ```

2. **Revisar logs en VPS:**
   ```bash
   ssh -p 23456 dangelo@37.60.238.102
   kubectl get events -n proyecto-nest
   kubectl logs -n proyecto-nest --all-containers=true --tail=50
   ```

3. **Reiniciar despliegue:**
   ```bash
   # En la VPS
   helm uninstall nest-api -n proyecto-nest
   helm uninstall next-frontend -n proyecto-nest
   ./deploy_remote.sh dangelo@37.60.238.102
   ```

---

**Última actualización:** Marzo 2026
**Arquitectura:** 8 capas Docker con Helm 3
**Plataforma:** microk8s en Contabo VPS
