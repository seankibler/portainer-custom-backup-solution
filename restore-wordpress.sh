#! /usr/bin/env bash

set -eu

function usage() {
	echo "Usage: $0 <STACK_NAME> <DATE>" 2>&1
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

if [ -z $2 ]; then
	echo "DATE is a required argument." 2>&1
	usage
	exit 1
fi

DATE=$2
STACK=$1
BACKUP_PATH=/data/backups/$DATE/$STACK

if [ ! -e ${BACKUP_PATH}/wordpress.tar.gz ]; then
	echo "Backup file does not exist, ${BACKUP_PATH}/wordpress.tar.gz please retrieve first." 2>&1
	exit 2
fi

if [ ! -e ${BACKUP_PATH}/wordpress.sql ]; then
	echo "Backup file does not exist, ${BACKUP_PATH}/wordpress.tar.gz please retrieve first." 2>&1
	exit 2
fi

# NOTICE!
# These must match the Docker container names that the Stack deploys!
#
# If the service names are changed in the Docker Compose file then
# the name suffixes here will need to be updated to match, otherwise the
# backup will fail!
WP_CONTAINER_NAME=${STACK}-blog-1
DB_CONTAINER_NAME=${STACK}-mysql-1

echo "About to restore containers \"${WP_CONTAINER_NAME}\" and \"${DB_CONTAINER_NAME}\" using backup files in \"${BACKUP_PATH}\"!"
echo -n "Are you sure you want to continue? (y/n): "

read confirm

if [ "$confirm" != "y" ]; then
	echo "Cancelled!"
	exit 0
fi

# PROCEED

echo "Restoring WordPress files"

docker run --rm --volumes-from $WP_CONTAINER_NAME \
	-v ${BACKUP_PATH}:/backup \
	debian:latest \
	sh -c 'tar -xvzf /backup/wordpress.tar.gz'

echo "Finished!"

echo "Restoring Database"

ROOT_PASSWORD=$(docker inspect $DB_CONTAINER_NAME | jq -r '.[0] | .Config.Env | map(select(. | startswith("MYSQL_ROOT_PASSWORD"))) | first | match("MYSQL_ROOT_PASSWORD=(.*+)"; "g") | .captures | first | .string')

# Build a credential file and mount it in. This is for better security versus
# providing the password in command line argument.
touch /tmp/mysql-$STACK-credential
chmod 600 /tmp/mysql-$STACK-credential
echo -e "[client]\npassword=\"$ROOT_PASSWORD\"" > /tmp/mysql-$STACK-credential

docker cp /tmp/mysql-$STACK-credential ${DB_CONTAINER_NAME}:/root/.my.cnf
docker cp ${BACKUP_PATH}/wordpress.sql ${DB_CONTAINER_NAME}:/tmp/wordpress.sql
docker exec -it ${DB_CONTAINER_NAME} sh -c 'mysql -u root -v < /tmp/wordpress.sql'

echo "Finished!"
