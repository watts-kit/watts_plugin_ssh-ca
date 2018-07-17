Network Structure
==================

The simplest network structure is given in the next figure.


    -----------        -------
    | SSH - CA| <----> |WATTS|   <---> User
    -----------        -------
          ^                      
          |                         
          v                       
    --------------------       ---------------------
    | Revocation Server| <---> | Application Server|
    --------------------       ---------------------

The main code is split in a "ssh-ca" part and a "watts" part.
The application must be set up according to the following section,
but is no "special" software must be installed.
You can add as many application server as you want.
The revocation server is a simple Webserver with the only
purpose to distribute a revocation list of ssh certificates.


How the SSH-CA is set up:
=========================

Use a special user for key signing, here $CA_USER

Perform these initialization steps:

- Create CA_USER
- Generate two ssh keys
    - `ssh-keygen -f ssh_ca_host -t ed25519`
    - `ssh-keygen -f ssh_ca_user -t ed25519`
- Copy ssh_ca_host.pub and ssh_ca_user.pub to all collaborating servers.
- Sign the own host key (see how a application Server is set up)


How an Application Server is set up:
===================================

- Sign the host key (on ssh-ca)
    - `ssh-keygen -s ssh_ca_host -I ${FQDN}-host-key -h -n ${FQDN},${hostname} -V +52W ~/ssh-ca/hosts/{$FQDN}.pub`
- Publish the host key ~/ssh-ca/hosts/${FQDN}-cert.pub
- Add the following lines to /etc/ssh/sshd_config:

        HostCertificate /etc/ssh/ssh_host/ecdsa_key-cert.pub
        TrustedUserCAKeys /etc/ssh/ssh_ca_user.pub


How Watts talks with the ssh-ca
===================================

Must be encrypted.
TLS Channel? -> needs certificates.
SSH? -> yes, but use force commands.
Interface?

sign $SSH_PUBKEY
revoke $SSH_PUBKEY

Note:
1) Other Arguments (principal???)
2) json?
3) Output?

How the SSH Signing works
===================================

- The public key must be in ~/ssh-ca/users/${username}.pub
- Run the command
  ssh-keygen -s ssh_ca_user -I {username}-user-key -n {principal name} -V +52W ~/ssh-ca/hosts/${username}.pub
- Return ~/ssh-ca/users/${username}-cert.pub

Note:
1) ssh_ca_user and ssh_ca_hosts should be encrypted ssh files.
By now, it is not possible to sign certs with ssh-agent, although
it is already implemented. Debian Packages are slightly too young.
With Debian Buster this will be possible.


TODO: Add serial counter?


How revocation works:
===================================

- Retrieve serial from ~/ssh-ca/users/${username}-cert.pub
- ssh-keygen -k -f krl_file -z COUNTER [see testable]
- Remove Certfile (?)

Test with:
[testable] ssh-keygen -Q -f krl_file ~/ssh-ca/users/${username}-cert.pub

Plugin Configuration
===================================


Here is a sample config for the SSH-CA plugin.


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



Security Considerations
===================================


Compromised SSH-CA
-----------------------------------

This should not happen. Secure your SSH CA better!
On your revocation server create the following key revocation list:
ssh-keygen -k -f new_krlfile -s ssh_ca_user (?)

Test if certificate is ok:
ssh-keygen -Q -f new_krlfile user-certfile


Compromised Application Server
------------------------------------

Create a key revocation lists for server (?)


Compromised Watts
------------------------------------

Revocate all certificates,
Remove watts ssh key from ssh-ca



Comfortability: Known Host Keys:
===================================

- Add the following line to your ~/.ssh/known_hosts:
  @cert-authority $WILDCARD $ssh_ca_host.pub
