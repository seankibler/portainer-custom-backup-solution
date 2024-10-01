#! /usr/bin/env bash

# Copy files into place
cp -v ./backup.sh ./backup-wordpress.sh ./backup-nextcloud.sh ./backup-upload.sh \
	./backup-portainer.sh ./backup-traefik.sh /usr/local/bin/
#Set ownership

chown root:root /usr/local/bin/backup.sh /usr/local/bin/backup-wordpress.sh \
	/usr/local/bin/backup-nextcloud.sh /usr/local/bin/backup-upload.sh \
	/usr/local/bin/backup-portainer.sh /usr/local/bin/backup-traefik.sh

# Set execute permission
chmod 755 /usr/local/bin/backup.sh /usr/local/bin/backup-wordpress.sh \
	/usr/local/bin/backup-nextcloud.sh /usr/local/bin/backup-upload.sh \
	/usr/local/bin/backup-portainer.sh /usr/local/bin/backup-traefik.sh
