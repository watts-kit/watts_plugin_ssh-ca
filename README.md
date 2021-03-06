The WATTS SSH-CA Plugin
=======================

Hi.
We wanted a simple way to access our vms via ssh.
Deploying all keys to all vms was not an option, so we use
ssh key certificates and automatized the process of
creation and revocation of keys.


Goals
====================

* Ease login to automatically set up vms.
* Application server set up should not require much effort, should be done automatically by configuration management.

Requirements
====================

* For password keys (until the new openssh version comes out),
passwordd (https://github.com/watts-kit/passwordd) is required.
* SSH is required
* watts script runs with python
* ssh-ca runs with bash and jq (json command line processor)

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

- To do all step, use the makefile provided.
- Create CA_USER
- Generate two ssh keys
    - `ssh-keygen -f ssh_ca_host -t ed25519`
    - `ssh-keygen -f ssh_ca_user -t ed25519`
- Copy ssh_ca_host.pub and ssh_ca_user.pub to all collaborating servers.
- Sign the own host key (see how a application Server is set up)


How an Application Server is set up:
===================================

- Sign the host key (on ssh-ca) (optional)
    - `ssh-keygen -s ssh_ca_host -I ${FQDN}-host-key -h -n ${FQDN},${hostname} -V +52W ~/ssh-ca/hosts/{$FQDN}.pub`
- Publish the host key ~/ssh-ca/hosts/${FQDN}-cert.pub
- Add the following lines to /etc/ssh/sshd_config:

        HostCertificate /etc/ssh/ssh_host/ecdsa_key-cert.pub
        TrustedUserCAKeys /etc/ssh/ssh_ca_user.pub
        RevokedKeys /etc/ssh/krl

- Add the following cronjob (/etc/cron.d/revoked_ssh_ca)

        * * * * * root wget --quiet -O /etc/ssh/krl http://<REVOCATION-HOST>/krl

  This will fetch the newest revocation list from the server every minute.

- This plugin saves the groups as principals in the certificate. You can specify which users are allowed to log in with
  The AuthorizedPrincipalsFile. Add this line to the sshd_config:
    
        AuthorizedPrincipalsFile /etc/ssh/principals/%u
        
   Add the groups that are allowed to login as user (%u) linewise into the /etc/ssh/principals/%u.



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

How the SSH Signing works (manual)
===================================

- The public key must be in ~/ssh-ca/users/${username}.pub
- Run the command
  ssh-keygen -s ssh_ca_user -I {username}-user-key -n {principal name} -V +52W ~/ssh-ca/hosts/${username}.pub
- This will create a certificate for the principal with a life time from of about one year (52w).  
- Return ~/ssh-ca/users/${username}-cert.pub

Note:
1) ssh_ca_user and ssh_ca_hosts should be encrypted ssh files.
By now, it is not possible to sign certs with ssh-agent, although
it is already implemented. Debian Packages are slightly too young.
With Debian Buster this will be possible.


How revocation works (manual):
===================================

- Retrieve serial from ~/ssh-ca/users/${username}-cert.pub
- ssh-keygen -k -f krl_file -z COUNTER [see testable]
- Remove Certfile (?)

Test with:
[testable] ssh-keygen -Q -f krl_file ~/ssh-ca/users/${username}-cert.pub


How signing and revocation works with this plugin
==================================================

Just click on receive or revoke and the plugin will do the rest.
We use serial numbers to revoke the certificate but the rest is basically the same as
demonstrated above.


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
