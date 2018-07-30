#!/bin/bash

key=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.key')


ret=0
check_ca_key $CA_USER
ret=$(( ret + ? ))
check_counterfile $COUNTERFILE
ret=$(( ret + ? ))
check_key $key
ret=$(( ret + ? ))
[[ $ret -gt 0 ]] && exit 1



principals=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.principals | join(",")' )
validity=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.validity' )

counter=$(flock -x $COUNTERFILE sh -c 'COUNTER=$(cat '$COUNTERFILE'); echo $((COUNTER+1)) | tee '$COUNTERFILE)
keyfile=${CERT_USER_DIR}${counter}
certfile=${CERT_USER_DIR}${counter}-cert.pub

echo $key > $keyfile
ssh-keygen -s $CA_USER -I "$(hostname)-serial-$counter" -n $principals -z $counter -V $validity $keyfile

echo -n "{"
echo -n '"serial" :'$counter','
echo -n '"principals" :"'$principals'",'
echo -n '"validity" :"'$validity'",'
echo -n '"key": "'$key'",'
echo -n '"cert": "'$(cat $certfile)'"'
echo -n "}"
