
KEY = ~/.ssh/praktikum
WATTS_SERVER = watts.local
WATTS_USER = root
WATTS_PATH = /home/watts-dev/ssh-ca-watts

SSH-CA_SERVER = ssh-ca.local
SSH-CA_USER = root
SSH-CA_PATH = /home/ssh-ca



gather:
		scp -i $(KEY) $(WATTS_USER)@$(WATTS_SERVER):$(WATTS_PATH)/main.py src/watts/main.py
		scp -r -i $(KEY) $(SSH-CA_USER)@$(SSH-CA_SERVER):$(SSH-CA_PATH)/* src/ssh-ca


deploy:
		scp -i $(KEY) src/watts/main.py $(WATTS_USER)@$(WATTS_SERVER):$(WATTS_PATH)/main.py
		scp -r -i $(KEY) src/ssh-ca $(SSH-CA_USER)@$(SSH-CA_SERVER):$(SSH-CA_PATH) 
