#!/bin/sh

# Parse DATABASE_URL into individual components for listmonk
if [ -z "$DATABASE_URL" ]; then
  echo "ERROR: DATABASE_URL not provided"
  exit 1
fi

echo "Parsing DATABASE_URL for listmonk configuration..."

# Remove protocol prefix (postgres:// or postgresql://)
DB_PARAMS=$(echo "$DATABASE_URL" | sed 's|^postgres://||' | sed 's|^postgresql://||')

# Extract user:password part (before @)
USER_PASS=$(echo "$DB_PARAMS" | cut -d'@' -f1)
DB_USER=$(echo "$USER_PASS" | cut -d':' -f1)
DB_PASSWORD=$(echo "$USER_PASS" | cut -d':' -f2)

# Extract host:port/database part (after @)
HOST_DB=$(echo "$DB_PARAMS" | cut -d'@' -f2)
HOST_PORT=$(echo "$HOST_DB" | cut -d'/' -f1)
DB_HOST=$(echo "$HOST_PORT" | cut -d':' -f1)
DB_PORT=$(echo "$HOST_PORT" | cut -d':' -f2)
DB_NAME=$(echo "$HOST_DB" | cut -d'/' -f2 | cut -d'?' -f1)

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

echo "Database config: $DB_USER@$DB_HOST:$DB_PORT/$DB_NAME"

# Run listmonk with installation and upgrade
echo "Starting listmonk installation and setup..."
./listmonk --install --idempotent --yes --config '' && \
./listmonk --upgrade --yes --config '' && \
./listmonk --config '' 