#!/bin/bash -x

# create key to sign
ssh-keygen -t ed25519 -f signing -P ""

# create key to be signed
ssh-keygen -t ed25519 -f signed -P ""

# sign key
ssh-keygen -s signing -I "test" -n doesntmatter -z 1 -V +100 signed

# create request
echo "key: $(cat signing.pub)" > request

ssh-keygen -k -f krl -s signing.pub request

# test if this revokes
ssh-keygen -Q -f krl signed-cert.pub

