#! /usr/bin/env bash

DATE=$(date +%F)
BACKUP_PATH=/data/backups/$DATE/traefik

mkdir -p $BACKUP_PATH

docker run --rm --volumes-from traefik \
	-v $BACKUP_PATH:/backup debian:latest \
	cp -a /acme.json /traefik.toml /backup/
