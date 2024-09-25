#! /usr/bin/env bash

set -eu

DATE=$(date +%F)
STACK=$1
BACKUP_PATH=/data/backups/$DATE/$STACK

# @todo Dynamically get database name, and docker network or receive as inputs

source ./portainer-api.sh

if [ -z $STACK ]; then
	echo "STACK is a required argument." 2>&1
	echo "Usage: $0 <STACK_NAME>" 2>&1
	exit 1
fi

mkdir -p $BACKUP_PATH

# Files
docker run --rm --volumes-from $STACK-wordpress-1 \
	-v $BACKUP_PATH:/backup debian:latest \
	tar -czvf /backup/wordpress.tar.gz /var/www/html


ROOT_PASSWORD=$(stack_details $STACK | \
	jq -r '.Env | .[] | select(.name | contains("MYSQL_DATABASE_PASSWORD")) | .value')

touch /tmp/mysql-$STACK-credential
chmod 600 /tmp/mysql-$STACK-credential
echo -e "[client]\npassword=$ROOT_PASSWORD" > /tmp/mysql-$STACK-credential

#Database
docker run --rm -v $BACKUP_PATH:/backup -v /tmp/mysql-$STACK-credential:/root/.my.cnf \
	--network ${STACK}_default \
	mysql:5.7 \
	mysqldump --databases wordpress --host $STACK-db-1 \
	--user root \
	--result-file /backup/wordpress.sql

rm -f /tmp/mysql-$STACK-credential
