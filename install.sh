#! /usr/bin/env bash

install -v -m 0755 -o root -g root -t /usr/local/bin/ \
	backup-nextcloud.sh backup-portainer.sh \
	backup-traefik.sh  backup-upload.sh  \
	backup-wordpress.sh  backup.sh retrieve.sh \
	recover-wordpress.sh
