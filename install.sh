#! /usr/bin/env bash

# Copy files into place
cp ./backup.sh ./backup-wordpress.sh ./backup-nextcloud.sh ./backup-upload.sh \
	./backup-portainer.sh ./backup-traefik.sh /usr/local/bin/

# Set execute permission
chmod 755 /usr/local/bin/backup.sh /usr/local/bin/backup-wordpress.sh \
	/usr/local/bin/backup-nextcloud.sh /usr/local/bin/backup-upload.sh \
	/usr/local/bin/backup-portainer.sh /usr/local/bin/backup-traefik.sh
