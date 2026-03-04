#!/bin/sh
set -e

LOG_DIR="/root/logs"
LOG_FILE="$LOG_DIR/next.log"

mkdir -p "$LOG_DIR"
touch "$LOG_FILE"

echo "=== Next.js Startup ===" >> "$LOG_FILE"
echo "Time: $(date)" >> "$LOG_FILE"

# Install npm deps
echo "npm install..." >> "$LOG_FILE"
npm install

# Build Next.js
echo "npm run build..." >> "$LOG_FILE"
npm run build

# Copy static files to nginx
echo "Copying Next.js export to /var/www/html..." >> "$LOG_FILE"
mkdir -p /var/www/html
cp -r out/* /var/www/html/ 2>/dev/null || true
chown -R www-data:www-data /var/www/html/ 2>/dev/null || true

# Start Nginx
echo "Starting Nginx..." >> "$LOG_FILE"
exec nginx -g 'daemon off;'
