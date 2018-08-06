
KEY = ~/.ssh/watts
WATTS_SERVER = watts-dev.data.kit.edu
WATTS_USER = watts
WATTS_PATH = /home/watts/.config/watts/SSH-CA/

SSH-CA_SERVER = internship-ssh-ca.data.kit.edu
SSH-CA_USER = ssh-ca
SSH-CA_PATH = /var/lib/ssh-ca/ssh-ca

#SSH-CA_SERVER = ssh-ca.local
#SSH-CA_USER = root
#SSH-CA_PATH = /home/ssh-ca

#WATTS_SERVER = watts.local
#WATTS_USER = root
#WATTS_PATH = /home/watts-dev/ssh-ca-watts

gather:
		scp -i $(KEY) $(WATTS_USER)@$(WATTS_SERVER):$(WATTS_PATH)/main.py src/watts/main.py
		rsync --progress -r -e "ssh -i $(KEY)" $(SSH-CA_USER)@$(SSH-CA_SERVER):$(SSH-CA_PATH)/ src/ssh-ca


deploy:
		scp -i $(KEY) src/watts/main.py $(WATTS_USER)@$(WATTS_SERVER):$(WATTS_PATH)/main.py
		rsync --progress -r -e "ssh -i $(KEY)" src/ssh-ca/ $(SSH-CA_USER)@$(SSH-CA_SERVER):$(SSH-CA_PATH)
