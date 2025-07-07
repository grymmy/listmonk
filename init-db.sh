#!/bin/sh

set -e  # Exit on any error
set -x  # Print commands as they execute

echo "=== INIT-DB.SH STARTING ==="
echo "Current working directory: $(pwd)"
echo "Available files: $(ls -la)"

# Parse DATABASE_URL into individual components for listmonk
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL not provided"
  exit 1
fi

echo "=== PARSING DATABASE_URL ==="
echo "DATABASE_URL is set: ${DATABASE_URL}"

# Remove protocol prefix (postgres:// or postgresql://)
DB_PARAMS=$(echo "$DATABASE_URL" | sed 's|^postgres://||' | sed 's|^postgresql://||')
echo "DB_PARAMS after protocol removal: $DB_PARAMS"

# Extract user:password part (before @)
USER_PASS=$(echo "$DB_PARAMS" | cut -d'@' -f1)
echo "USER_PASS: $USER_PASS"

DB_USER=$(echo "$USER_PASS" | cut -d':' -f1)
DB_PASSWORD=$(echo "$USER_PASS" | cut -d':' -f2)
echo "Extracted DB_USER: $DB_USER"
echo "Extracted DB_PASSWORD: [REDACTED - length $(echo "$DB_PASSWORD" | wc -c)]"

# Extract host:port/database part (after @)
HOST_DB=$(echo "$DB_PARAMS" | cut -d'@' -f2)
HOST_PORT=$(echo "$HOST_DB" | cut -d'/' -f1)
DB_HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
DB_PORT=$(echo "$HOST_PORT" | cut -d':' -f2)
DB_NAME=$(echo "$HOST_DB" | cut -d'/' -f2 | cut -d'?' -f1)

echo "Extracted DB_HOST: $DB_HOST"
echo "Extracted DB_PORT: $DB_PORT"
echo "Extracted DB_NAME: $DB_NAME"

# Set listmonk environment variables
export LISTMONK_db__user="$DB_USER"
export LISTMONK_db__password="$DB_PASSWORD"
export LISTMONK_db__host="$DB_HOST"
export LISTMONK_db__port="$DB_PORT"
export LISTMONK_db__database="$DB_NAME"
export LISTMONK_db__ssl_mode="${DATABASE_SSL_MODE:-require}"
export LISTMONK_db__max_open=25
export LISTMONK_db__max_idle=25
export LISTMONK_db__max_lifetime=300s

echo "=== FINAL DATABASE CONFIG ==="
echo "Database config: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME (SSL: ${DATABASE_SSL_MODE:-require})"

# Print all LISTMONK env vars for debugging
echo "=== LISTMONK ENVIRONMENT VARIABLES ==="
env | grep LISTMONK || echo "No LISTMONK env vars found"

# Run listmonk with installation and upgrade
echo "=== STARTING LISTMONK INSTALLATION ==="
echo "Running: ./listmonk --install --idempotent --yes --config ''"
./listmonk --install --idempotent --yes --config '' 2>&1 | tee /tmp/install.log

echo "=== STARTING LISTMONK UPGRADE ==="
echo "Running: ./listmonk --upgrade --yes --config ''"
./listmonk --upgrade --yes --config '' 2>&1 | tee /tmp/upgrade.log

echo "=== STARTING LISTMONK MAIN ==="
echo "Running: ./listmonk --config ''"
./listmonk --config '' 