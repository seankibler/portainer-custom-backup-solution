#! /usr/bin/env bash

set -eu

function usage() {
	echo "Usage: $0 <STACK>" 2>&1
}

if [ "$1" = "-h" -o "$1" = "--help" ]; then
	usage
	exit 0
fi

if [ -z $1 ]; then
	echo "STACK is a required argument." 2>&1
	usage
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
WP_CONTAINER_NAME=${STACK}-blog-1
DB_CONTAINER_NAME=${STACK}-mysql-1

mkdir -p $BACKUP_PATH

#
# Backup Files
#
WP_STATUS=$(docker inspect $WP_CONTAINER_NAME | jq -r '.[].State.Status')

if [[ $WP_STATUS = "running" ]]; then
	docker run --rm --volumes-from $WP_CONTAINER_NAME \
		-v $BACKUP_PATH:/backup debian:latest \
		tar -czvf /backup/wordpress.tar.gz /var/www/html

	docker exec $WP_CONTAINER_NAME grep -i 'wp_version =' wp-includes/version.php | awk -F"'" '{ print $2 }' > ${BACKUP_PATH}/wp_version.txt
fi


#
# Backup Database
#
DB_STATUS=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[].State.Status')

if [[ $DB_STATUS = "running" ]]; then
	ROOT_PASSWORD=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_ROOT_PASSWORD"))) | first | match("MYSQL_ROOT_PASSWORD=(.*+)"; "g") | .captures | first | .string')
	DATABASE_NAME=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_DATABASE"))) | first | match("MYSQL_DATABASE=(.*+)"; "g") | .captures | first | .string')
	MYSQL_VERSION=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_MAJOR"))) | first | match("MYSQL_MAJOR=(.*+)"; "g") | .captures | first | .string')

	echo "${MYSQL_VERSION}" > ${BACKUP_PATH}/mysql_version.txt

	# Build a credential file and mount it in. This is for better security versus
	# providing the password in command line argument.
	touch /tmp/mysql-$STACK-credential
	chmod 600 /tmp/mysql-$STACK-credential
	echo -e "[client]\npassword=\"$ROOT_PASSWORD\"" > /tmp/mysql-$STACK-credential

	docker run --rm -v $BACKUP_PATH:/backup -v /tmp/mysql-$STACK-credential:/root/.my.cnf \
		--network container:$DB_CONTAINER_NAME \
		mysql:$MYSQL_VERSION \
		mysqldump --databases $DATABASE_NAME --host $DB_CONTAINER_NAME \
		--user root \
		--result-file /backup/wordpress.sql

	# Clean up credential file on host filesystem
	rm -f /tmp/mysql-$STACK-credential
fi
