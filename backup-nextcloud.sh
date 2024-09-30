#! /usr/bin/env bash

set -eu

if [ -z $1 ]; then
	echo "STACK is a required argument." 2>&1
	echo "Usage: $0 <STACK_NAME>" 2>&1
	exit 1
fi

DATE=$(date +%F)
STACK=$1
BACKUP_PATH=/data/backups/$DATE/$STACK

# NOTICE!
# These must match the Docker container names that the Stack deploys!
#
# If the service names are changed in the Docker Compose file then
# the name suffixes here will need to be updated to match, otherwise the
# backup will fail!
NC_CONTAINER_NAME=${STACK}-nextcloud-1
DB_CONTAINER_NAME=${STACK}-mysql-1

mkdir -p $BACKUP_PATH

#
# Backup Files
#
NC_STATUS=$(docker inspect $NC_CONTAINER_NAME | jq -r '.[].State.Status')

if [[ $NC_STATUS = "running" ]]; then
	docker run --rm --volumes-from $NC_CONTAINER_NAME \
		-v $BACKUP_PATH:/backup debian:latest \
		tar -czvf /backup/nextcloud.tar.gz /var/www/html

	docker exec -u www-data $NC_CONTAINER_NAME php occ --version > ${BACKUP_PATH}/nextcloud_version.txt
fi


#
# Backup Database
#
DB_STATUS=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[].State.Status')

if [[ $DB_STATUS = "running" ]]; then
	ROOT_PASSWORD=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_ROOT_PASSWORD"))) | first | match("MYSQL_ROOT_PASSWORD=(.*+)"; "g") | .captures | first | .string')
	DATABASE_NAME=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_DATABASE"))) | first | match("MYSQL_DATABASE=(.*+)"; "g") | .captures | first | .string')
	MARIADB_IMAGE_VERSION=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config | .Labels | ."org.opencontainers.image.version"')

	echo "${MARIADB_IMAGE_VERSION}" > ${BACKUP_PATH}/mariadb_version.txt

	# Build a credential file and mount it in. This is for better security versus
	# providing the password in command line argument.
	touch /tmp/mysql-$STACK-credential
	chmod 600 /tmp/mysql-$STACK-credential
	echo -e "[client]\npassword=$ROOT_PASSWORD" > /tmp/mysql-$STACK-credential

	docker run --rm -v $BACKUP_PATH:/backup -v /tmp/mysql-$STACK-credential:/root/.my.cnf \
		--network container:$DB_CONTAINER_NAME \
		mariadb:${MARIADB_IMAGE_VERSION} \
		mariadb-dump --databases $DATABASE_NAME --host $DB_CONTAINER_NAME \
		--user root \
		--result-file /backup/nextcloud.sql

	# Clean up credential file on host filesystem
	rm -f /tmp/mysql-$STACK-credential
fi
