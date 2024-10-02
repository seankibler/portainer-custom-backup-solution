#! /usr/bin/env bash

set -u

function usage() {
	echo "Usage: $0 <BUCKET_PATH>" 2>&1
	echo "Example: $0 s3://sos-backups/" 2>&1
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

BUCKET_PATH=$1

# System services
/usr/local/bin/backup-portainer.sh
/usr/local/bin/backup-traefik.sh

# WordPress Sites
/usr/local/bin/backup-wordpress.sh therealandiekat-wordpress-www
/usr/local/bin/backup-wordpress.sh averybros-wordpress-www
/usr/local/bin/backup-wordpress.sh seahunny-wordpress-www
/usr/local/bin/backup-wordpress.sh fieldday-wordpress-www
/usr/local/bin/backup-wordpress.sh tipsytraveler-wordpress-www
/usr/local/bin/backup-wordpress.sh sos-wordpress-www
/usr/local/bin/backup-wordpress.sh solaris-wordpress-www-new


# Nextcloud
/usr/local/bin/backup-nextcloud.sh nextcloud

# Upload to cloud
/usr/local/bin/backup-upload.sh $BUCKET_PATH
