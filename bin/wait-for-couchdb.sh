#!/bin/sh
# Attend que CouchDB soit prêt avant de démarrer l'application.
# Usage : ./bin/wait-for-couchdb.sh [max_retries] [retry_interval]

set -e

MAX_RETRIES="${1:-30}"
RETRY_INTERVAL="${2:-2}"
COUCHDB_URL="${COUCHDB_URL:-http://admin:admin@couchdb:5984}"

echo "Attente de CouchDB sur $COUCHDB_URL/_up ..."

i=0
until curl -sf "$COUCHDB_URL/_up" > /dev/null 2>&1; do
  i=$((i + 1))
  if [ "$i" -ge "$MAX_RETRIES" ]; then
    echo "CouchDB non disponible après $MAX_RETRIES tentatives. Abandon."
    exit 1
  fi
  echo "  tentative $i/$MAX_RETRIES - nouvelle tentative dans ${RETRY_INTERVAL}s..."
  sleep "$RETRY_INTERVAL"
done

echo "CouchDB est prêt."
