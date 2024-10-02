#! /usr/bin/env bash

set -eu

function usage() {
	echo "Usage: $0 <BUCKET_PATH>" 2>&1
	echo "Example: $0 s3://sos-backups/" 2>&1
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

BACKUP_BUCKET_PATH=$1
BACKUP_PATH=/data/backups
S3CMD_IMAGE_VERSION=stable

# Use docker image with backups mounted in to upload to S3-compatible storage
docker run --rm -v $BACKUP_PATH:/backup \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	d3fk/s3cmd:$S3CMD_IMAGE_VERSION \
	--host $S3_HOST \
	--host-bucket "$S3_HOST_BUCKET" \
	sync /backup/ $BACKUP_BUCKET_PATH

# Remove backups older than yesterday from local filesystem
touch -t $(date --date 'yesterday' +%Y%m%d0000) /tmp/backup-cleanup

find /data/backups/ ! -newer /tmp/backup-cleanup -print0 | xargs -0 rm -rf

rm -f /tmp/backup-cleanup-ref
