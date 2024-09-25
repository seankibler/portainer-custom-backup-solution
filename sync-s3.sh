#! /usr/bin/env bash

set -eu

BACKUP_BUCKET_NAME=$1
BACKUP_PATH=/data/backups
AWSCLI_IMAGE_VERSION=2.17.57

docker run --rm -v $BACKUP_PATH:/backup \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	amazon/aws-cli:$AWSCLI_IMAGE_VERSION \
	aws s3 sync /backup s3://$BACKUP_BUCKET_NAME


# @todo ENCRYPT?
# openssl aes-256-cbc -in file.txt -out file.enc
# openssl aes-256-cbc -d -in file.enc -out file.txt
#

# @todo VERIFY!
#
# @todo CLEANUP LOCAL BACKUPS!
