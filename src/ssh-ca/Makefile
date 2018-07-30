keys/revocation:
	ssh-keygen -t ed25519 -f keys/revocation

keys/user_key:
	ssh-keygen -t ed25519 -f keys/user_key

keys/from_watts.pub:
	ssh-keygen -t ed25519 -f keys/from_watts

keys: keys/revocation keys/user_key

authorized_keys: keys/from_watts.pub
	echo "command=\"" > authorized_keys
	pwd >> authorized_keys
	echo "/watts_interface.sh\" " >> authorized_keys
	cat keys/from_watts.pub >> authorized_keys
	tr -d '\n' < authorized_keys | sponge authorized_keys


	

