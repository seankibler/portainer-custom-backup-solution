#! /usr/bin/env bash

set -u

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
