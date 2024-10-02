#! /usr/bin/env bash

set -eu

function usage() {
	echo "$0 <BUCKET_PATH> <STACK> <DATE>" 2>&1
	echo "Example: $0 s3://sos-backups sos-wordpress-www 2024-10-02"
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

DATE=$(date --date $3 +%F)
STACK=$2

echo $DATE
if [ $? -ne 0 ]; then
	echo "Invalid date format. Input date must be in YYYY-MM-DD format." 2>&1
	usage
	exit 1
fi

BACKUP_PATH=/data/backups/$DATE/$STACK
BACKUP_BUCKET_PATH=$1
S3CMD_IMAGE_VERSION=stable

# Use docker image with backups mounted in to upload to S3-compatible storage
docker run --rm -v $BACKUP_PATH:/backup \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	d3fk/s3cmd:$S3CMD_IMAGE_VERSION \
	--host $S3_HOST \
	--host-bucket "$S3_HOST_BUCKET" \
	sync ${BACKUP_BUCKET_PATH}/$DATE/$STACK/ /backup/


echo "Finished. Saved to ${BACKUP_PATH}"
