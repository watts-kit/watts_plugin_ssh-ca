#!/bin/bash

key=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.key')

echoerr "debug purposes: \'" $key\' 

check_ca_key $CA_USER
ret_ca_key=$?
check_counterfile $COUNTERFILE
ret_counter=$?
check_key "$key"
ret_key=$?

(( ! ret_ca_key && ! ret_counter && ! ret_key )) || exit 1



principals=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.principals' )
validity=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.validity' )

counter=$(flock -x $COUNTERFILE sh -c 'COUNTER=$(cat '$COUNTERFILE'); echo $((COUNTER+1)) | tee '$COUNTERFILE)
keyfile=${CERT_USER_DIR}${counter}
certfile=${CERT_USER_DIR}${counter}-cert.pub

echo $key > $keyfile


if [[ $NEEDS_PASSWORD -gt 0 ]] 
then
	if [[ $SSH_VERSION -lt 77 ]];
	then
		pw_command=$(echo '{"action":"get","key":"ssh-ca"}' | netcat 127.0.0.1 6969 | jq '.value' )
		# ssh keyfile is encrypted and we cannot use ssh-agent
		ssh-keygen -s $CA_USER -P $pw_command -I "$(hostname)-serial-$counter" -n $principals -z $counter -V $validity $keyfile
	else
		# we can use ssh-agent
		ssh-keygen -Us $CA_USER_PUB -I "$(hostname)-serial-$counter" -n $principals -z $counter -V $validity $keyfile
	fi
	# 
else 
	ssh-keygen -s $CA_USER -I "$(hostname)-serial-$counter" -n $principals -z $counter -V $validity $keyfile
fi

echo -n "{"
echo -n '"serial" :'$counter','
echo -n '"principals" :"'$principals'",'
echo -n '"validity" :"'$validity'",'
echo -n '"key": "'$key'",'
echo -n '"cert": "'$(cat $certfile)'"'
echo -n "}"
