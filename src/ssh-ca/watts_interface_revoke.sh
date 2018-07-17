#!/bin/bash

serial=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.serial')

echoerr $SSH_ORIGINAL_COMMAND


if [ ! -f ${CERTS_USER_DIR}/${serial}-cert.pub ]; then
	echoerr "serial has no valid associated cert"
	echo "{}"
	exit 1
fi

if [ ! -f ${REVOCATION} ]; then
	echoerr "revocation list does not exist"
	exit 2
fi


tmpfile=$( mktemp )
# the serial of the revoked key
echo "serial: " $serial > $tmpfile
# the minium serial of all certs
echo "serial: 1-"$(( $(ls ${CERT_USER_DIR} | head -n 1) - 1 )) >> $tmpfile

ssh-keygen -u -k -f ${REVOCATION}-s $CA_USER_PUB $tmpfile 1>&2



## Test if the revocation list revokes the key (exit code != 0)
ssh-keygen -Q -f ${REVOCATION} ${CERT_USER_DIR}${serial}-cert.pub 1>&2 


if [ $? -eq 0 ]; then
	echoerr "the key was not revoked"
	exit 1
fi
rm $tmpfile


# delete the cert
rm $HOME/certs/user/${serial}*

# push the revocation list to a new server
# TODO: find a securer way...
scp -q -i revocation ${REVOCATION} root@${REVOCATION_HOST}:/var/www/html/

echo -n "{"
echo -n '"serial" :' '"'$serial'"'
echo -n " }"
