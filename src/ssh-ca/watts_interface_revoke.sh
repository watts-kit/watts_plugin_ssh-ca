#!/bin/bash

serial=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.serial')

echoerr "$SSH_ORIGINAL_COMMAND"


if [ ! -f "${CERT_USER_DIR}/${serial}-cert.pub" ]; then
	echoerr "serial has no valid associated cert"
	echo "{}"
	exit 1
fi

if [ ! -f "${REVOCATION}" ]; then
	echoerr "revocation list does not exist"
	exit 2
fi


min_serial=$(( $(ls "${CERT_USER_DIR}" | head -n 1) - 1 ))
create_revocation "$serial" "$min_serial" "$REVOCATION" "$CA_USER_PUB"

## Test if the revocation list revokes the key (exit code != 0)
check_revocation "$REVOCATION" "${CERT_USER_DIR}${serial}-cert.pub" || exit 1



# delete the cert
rm "${CERT_USER_DIR}/${serial}*"

# push the revocation list to a new server
scp -q -i keys/revocation "${REVOCATION}" "${REVOCATION_USER}@${REVOCATION_HOST}:${REVOCATION_PATH}" || exit 1

echo -n "{"
echo -n '"serial" : "'"$serial"'"'
echo -n " }"
