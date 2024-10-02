#! /usr/bin/env bash

set -eu

function usage() {
	echo "Usage: $0" 2>&1
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

DATE=$(date +%F)
BACKUP_PATH=/data/backups/$DATE/traefik

mkdir -p $BACKUP_PATH

docker run --rm --volumes-from traefik \
	-v $BACKUP_PATH:/backup debian:latest \
	cp -a /acme.json /traefik.toml /backup/
