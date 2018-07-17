#!/bin/bash


DATA_DIR=$HOME

CA_USER=${DATA_DIR}/keys/user_key
CA_USER_PUB=${DATA_DIR}/keys/user_key.pub
COUNTERFILE=${DATA_DIR}/certs/counter


echoerr() { echo "$@" 1>&2; }


action=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.action')


if [ $action = "sign" ]; then
	source watts_interface_sign.sh
elif [ $action = "revoke" ]; then
	source watts_interface_revoke.sh
fi


