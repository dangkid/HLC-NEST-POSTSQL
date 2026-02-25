# Stage 1: Build
FROM node:20-alpine AS builder

WORKDIR /build

# Copiar archivos de dependencias
COPY package.json package-lock.json ./

# Instalar dependencias
RUN npm ci --only=production

# Copiar todo el código fuente
COPY . .

# Build de la aplicación
RUN npm run build

# Stage 2: Runtime (imagen más pequeña)
FROM node:20-alpine

WORKDIR /app

# Instalar netcat para health checks
RUN apk add --no-cache netcat-openbsd

# Copiar node_modules del builder
COPY --from=builder /build/node_modules ./node_modules
COPY --from=builder /build/dist ./dist
COPY --from=builder /build/package.json ./package.json

# Copiar entrypoint
COPY entrypoint.sh ./
RUN chmod +x ./entrypoint.sh

# Crear directorio de logs
RUN mkdir -p /root/logs

# Exponer puerto
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD nc -z localhost 3001 || exit 1

ENTRYPOINT ["./entrypoint.sh"]
