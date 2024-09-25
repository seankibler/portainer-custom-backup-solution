#! /usr/bin/env bash

DATE=$(date +%F)
BACKUP_PATH=/data/backups/$DATE/portainer
PAYLOAD=$(jq -n --arg pass "$PORTAINER_BACKUP_PASSWORD" '{password: pass}')

mkdir -p $BACKUP_PATH

curl -H "X-API-Key:$PORTAINER_API_TOKEN" -d "$PAYLOAD" \
	-o $BACKUP_PATH/portainer.tar.gz.encrypted \
	https://$PORTAINER_HOST/api/backup
