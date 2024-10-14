#! /usr/bin/env bash

set -u

function usage() {
	echo "Usage: $0 <BUCKET_PATH> <DAYS>" 2>&1
	echo "Example: $0 s3://sos-backups/ 30" 2>&1
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

BACKUP_BUCKET_PATH=$1
DAYS=$2

S3CMD_IMAGE_VERSION=stable

cat > /tmp/backup-lifecycle-policy <<EOT
<LifecycleConfiguration xmlns="http://s3.amazonaws.com/doc/2006-03-01/">
  <Rule>
    <ID>Expire old logs</ID>
    <Status>Enabled</Status>
    <Expiration>
      <Days>$DAYS</Days>
    </Expiration>
  </Rule>
</LifecycleConfiguration>
EOT

docker run --rm \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	d3fk/s3cmd:$S3CMD_IMAGE_VERSION \
	--host $S3_HOST \
	--host-bucket "$S3_HOST_BUCKET" \
	getlifecycle $BACKUP_BUCKET_PATH > /dev/null

# We bail if there is already a lifecycle policy to avoid conflicts
# Check for 404 no policy (s3cmd exit code 12)
if [ $? -ne 12 ]; then
	echo "There is already a lifecycle policy on the bucket \"$BACKUP_BUCKET_PATH\"." 2>&1

	echo "=============EXISTING POLICY============="
	docker run --rm \
		-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
		-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
		d3fk/s3cmd:$S3CMD_IMAGE_VERSION \
		--host $S3_HOST \
		--host-bucket "$S3_HOST_BUCKET" \
		getlifecycle $BACKUP_BUCKET_PATH 2>&1

	echo "=============NEW POLICY================="
	cat /tmp/backup-lifecycle-policy

	echo -n "Are you sure you want to override the EXISTING POLICY with the NEW POLICY? (y/n): "

	read confirm

	if [ "$confirm" != "y" ]; then
		echo "Cancelled"
		rm -f /tmp/backup-lifecycle-policy
		exit 1
	else
		echo "Ok, overriding the existing lifecycle policy!"
	fi

fi

# Use docker image with backups mounted in to upload to S3-compatible storage
docker run --rm -v /tmp/backup-lifecycle-policy:/tmp/backup-lifecycle-policy \
	-e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
	-e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
	d3fk/s3cmd:$S3CMD_IMAGE_VERSION \
	--host $S3_HOST \
	--host-bucket "$S3_HOST_BUCKET" \
	setlifecycle /tmp/backup-lifecycle-policy $BACKUP_BUCKET_PATH

rm -f /tmp/backup-lifecycle-policy
