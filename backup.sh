#! /usr/bin/env bash

set -u

BUCKET_PATH=$1

# System services
backup-portainer.sh
backup-traefik.sh

# WordPress Sites
backup-wordpress.sh therealandiekat-wordpress-www
backup-wordpress.sh averybros-wordpress-www
backup-wordpress.sh seahunny-wordpress-www
backup-wordpress.sh fieldday-wordpress-www
backup-wordpress.sh tipsytraveler-wordpress-www
backup-wordpress.sh sos-wordpress-www
backup-wordpress.sh solaris-wordpress-www-new


# Nextcloud
backup-nextcloud.sh nextcloud

# Upload to cloud
backup-upload.sh $BUCKET_PATH
