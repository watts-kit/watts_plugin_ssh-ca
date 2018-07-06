#!/bin/bash

if [ $? -ne 0 ]; then
	echoerr "json not valid"
	exit 1
fi


if [ ! -e $CA_USER ]; then
	echoerr "no ca user key found"
	exit 1
fi

if [ ! -e $COUNTERFILE ]; then
	echoerr "no counterfile found"
	exit 1
fi


key=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.key')

# Test if key is valid keyfile of key
printf "%s" "$key" | ssh-keygen -l -f - &> /dev/null

if [ $? -ne 0 ]; then
	echoerr "no valid key"
	exit 1
fi


principals=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.principals | join(",")' )
validity=$(echo "$SSH_ORIGINAL_COMMAND" | jq -r '.validity' )

counter=$(flock -x $COUNTERFILE sh -c 'COUNTER=$(cat '$COUNTERFILE'); echo $((COUNTER+1)) | tee '$COUNTERFILE)
keyfile=$HOME/certs/user/${counter}
certfile=$HOME/certs/user/${counter}-cert.pub

echo $key > $keyfile
ssh-keygen -s $CA_USER -I todo -n $principals -z $counter -V $validity $keyfile

echo -n "{"
echo -n '"serial" :'$counter','
echo -n '"principals" :"'$principals'",'
echo -n '"validity" :"'$validity'",'
echo -n '"key": "'$key'",'
echo -n '"cert": "'$(cat $certfile)'"'
echo -n "}"
