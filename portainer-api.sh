#! /usr/bin/env bash

set -eu

if [ -z $(which jq) ]; then
	echo "jq is not detected and is required, please install jq" 2>&1
	exit 1
fi

function stack_details() {
	stack=$1
	curl -H "X-API-Key: $PORTAINER_API_TOKEN" https://$PORTAINER_HOST/api/stacks | \
		jq --arg stack $1 '.[] | select(.Name | contains($stack))'
}
