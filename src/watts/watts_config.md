service.ssh-ca.description = SSH-CA plugin
service.ssh-ca.display_prio = 11
service.ssh-ca.cmd = /home/watts-dev/ssh-ca-watts/main.py
service.ssh-ca.credential_limit = infinite
service.ssh-ca.connection.type = local
service.ssh-ca.parallel_runner = infinite
service.ssh-ca.authz.allow.any.sub.any = true
#The Name of the ssh-ca
service.ssh-ca.plugin.ssh_ca = ssh-ca
service.ssh-ca.plugin.ssh_key = /home/watts-dev/ssh-ca-force-command
service.ssh-ca.plugin.ssh_user = ssh-ca

