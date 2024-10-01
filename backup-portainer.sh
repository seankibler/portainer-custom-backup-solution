#! /usr/bin/env bash

set -e

DATE=$(date +%F)
BACKUP_PATH=/data/backups/$DATE/portainer

mkdir -p $BACKUP_PATH

if [ -z "${PORTAINER_BACKUP_PASSWORD}" ]; then
	PAYLOAD=$(jq -n '{password: ""}')
	curl -H "X-API-Key:$PORTAINER_API_TOKEN" -H 'Content-Type: application/json' \
		-d "$PAYLOAD" \
		-o $BACKUP_PATH/portainer.tar.gz \
		"'${PORTAINER_URL}/api/backup'"
else
	PAYLOAD=$(jq -n --arg pass "$PORTAINER_BACKUP_PASSWORD" '{password: $pass}')
	curl -H "X-API-Key:$PORTAINER_API_TOKEN" -H 'Content-Type: application/json' \
		-d "$PAYLOAD" \
		-o $BACKUP_PATH/portainer.tar.gz.encrypted \
		"'${PORTAINER_URL}/api/backup'"
fi
