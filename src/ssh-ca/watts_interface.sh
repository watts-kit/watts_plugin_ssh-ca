#!/bin/bash


CA_USER=$HOME/user_key
CA_USER_PUB=$HOME/user_key.pub
COUNTERFILE=$HOME/certs/counter


echoerr() { echo "$@" 1>&2; }


action=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.action')


if [ $action = "sign" ]; then
	source watts_interface_sign.sh
elif [ $action = "revoke" ]; then
	source watts_interface_revoke.sh
fi


