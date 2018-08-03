#!/bin/bash



DIR=$(dirname $0)
cd $DIR

source $DIR/lib.sh

DATA_DIR=$DIR
CA_USER=${DATA_DIR}/keys/user_key
CA_USER_PUB=${DATA_DIR}/keys/user_key.pub
COUNTERFILE=${DATA_DIR}/certs/counter

REVOCATION=${DATA_DIR}/certs/revocation_list

CERT_USER_DIR=${DATA_DIR}/certs/user/

REVOCATION_HOST=internship-ssh-revocation.data.kit.edu
REVOCATION_USER=ssh-ca-revocation
REVOCATION_PATH=/var/www/htdocs



# test if the ssh ca key is password less
# this actually tests if the passphrase can be changed (correct phrase required)
# if PASSWORD=0 we do not need a password
ssh-keygen -p -P '' -N '' -f $CA_USER &> /dev/null
NEEDS_PASSWORD=$?
SSH_VERSION=$(ssh -V 2>&1 | grep -Po '(?<=OpenSSH_)[0-9]\.[0-9]' | tr -d '.')


action=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.action')


if [ "$action" = "sign" ]; then
	source $DIR/watts_interface_sign.sh
elif [ "$action" = "revoke" ]; then
	source $DIR/watts_interface_revoke.sh
fi


