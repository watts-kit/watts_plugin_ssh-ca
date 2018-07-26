#!/bin/bash


DATA_DIR=$HOME

CA_USER=${DATA_DIR}/keys/user_key
CA_USER_PUB=${DATA_DIR}/keys/user_key.pub
COUNTERFILE=${DATA_DIR}/certs/counter

REVOCATION=${DATA_DIR}/certs/revocation_list

CERT_USER_DIR=${DATA_DIR}/certs/user/

REVOCATION_HOST=revocation



echoerr() { echo "$@" 1>&2; }


# test if the ssh ca key is password less
# this actually tests if the passphrase can be changed (correct phrase required)
# if PASSWORD=0 we do not need a password
ssh-keygen -p -P '' -N '' -f $CA_USER &> /dev/null
NEEDS_PASSWORD=$?


action=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.action')


if [ $action = "sign" ]; then
	source watts_interface_sign.sh
elif [ $action = "revoke" ]; then
	source watts_interface_revoke.sh
fi


