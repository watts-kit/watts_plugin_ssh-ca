#!/usr/bin/env python3
# -*- coding: utf-8 -*-
""" The watts part of watts-ssh-ca. """

#from urllib.parse import urlparse
import json
import base64
#import random
#import string
import sys
import traceback
#import time
#import os
import logging
import subprocess
import re


LOGFILE = sys.path[0] + "/ssh-ca.log"

logging.basicConfig(filename=LOGFILE, level=logging.DEBUG)

VERSION = "0.0.1"


def check_validity(validity):
    """ Checks if validity is in ssh time format """
    to_day = r"[0-9]{4}(0[0-9]|1[0-2])([0-2][0-9]|3[0-1])"
    to_ss = r"[0-9]{4}(0[0-9]|1[0-2])([0-2][0-9]|3[0-1])([0-1][0-9]|2[0-3])[0-5][0-9]([0-5][0-9])?"
    interval = r"(-[0-9]+[smhdw]?:)?\+[0-9]+[smhdw]?"

    combined = "(^(%s:)?%s$)|(^(%s:)?%s$)|(^%s$)" %(to_day, to_day, to_ss, to_ss, interval)

    return re.match(combined, validity)

def check_ssh_key(ssh_key):
    """ Checks if ssh_key is a valid ssh key """
    process = subprocess.run(["ssh-keygen", "-l", "-f", "-"], input=ssh_key.encode(),
                             stdout=subprocess.DEVNULL,
                             stderr=subprocess.DEVNULL)
    if process.returncode == 0:
        return True
    return False

def check_principals(principals_str, groups):
    """ Checks if principals_str is a comma separated list of groups"""
    regex = r"[a-zA-Z\-_/](,[a-zA-Z\-_/])*"

    if re.match(regex, principals_str):
        # the str is a comma separated list, lets check if only groups assigned groups are in it
        for princeps in principals_str.split(','):
            princeps = princeps.strip()
            if princeps == "nogroup":
                continue
            if not princeps in groups:
                return False
        return True

    return False


def list_params():
    """ Outputs the parameters of this plugin as requested by watts """
    params_request = [
        [{"key":"ssh_pub_key",
          "name":"SSH Public Key",
          "type":"textarea",
          "description":"Your public SSH Key that should be signed",
          "mandatory":True},
         {"key":"validity",
          "name":"Validity",
          "type":"textarea",
          "description":"The requested validity. If unfamiliar with ssh time dates, \
                        you could supply '+2w' for a certificate that is 2 weeks \
                        valid (from now on).",
          "mandatory":True},
         {"key":"principals",
          "name":"principals",
          "type":"textarea",
          "description":"The requested principals for the cert. Join them by comma. \
                  You can use 'nogroup' if you do not want any of your groups included \
                  or '*' for every group. You can only include your groups supplied \
                  by your identity provider to watts. See the info plugin for your groups.",
          "mandatory":True}
        ]
        ]
    params_conf = [
        {'name': 'ssh_ca',
         'type':'string',
         'default': ''},
        {'name': 'ssh_user',
         'type':'string',
         'default': ''},
        {'name': 'ssh_key',
         'type':'string',
         'default': ''},
        ]
    email = "info@konstantinzangerle.de"
    # compose all of this
    config = {'result':'ok',
              'conf_params': params_conf,
              'request_params': params_request,
              'version':VERSION,
              'features':{"stdin":True},
              'developer_email':email}
    return json.dumps(config)




def perform_request(host, keyfile, user, json_request):
    """ Request a ssh key from a ssh-ca server"""
    with subprocess.Popen(["ssh",
                           "%s@%s" % (user, host),
                           "-i",
                           keyfile,
                           json_request],
                          shell=False,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE) as ssh:
        stdout = ""
        for line in ssh.stdout:
            stdout += line.decode()
        logging.debug(stdout)
        logging.debug("stderr %s", (ssh.stderr.readlines(),))
        jstdout = json.loads(stdout)
        return jstdout


def create_json(principals, validity, key):
    """ Creates json as needed by the ssh-ca """
    request_dict = {"principals":principals,
                    "validity":validity,
                    "key":key,
                    "action":"sign"}

    return json.JSONEncoder().encode(request_dict)

def request(JObject):
    """ Interface function for perform_request. Checks parameters."""
    Params = JObject['params']
    ConfParams = JObject['conf_params']

    logging.debug("Request params are %s", (Params,))

    if not check_validity(Params['validity']):
        return json.dumps({'result':'error',
                           "user_msg":"The validity you entered does not match regex",
                           "log_msg":"Wrong validity"})

    if not check_ssh_key(Params["ssh_pub_key"]):
        return json.dumps({'result':'error',
                           'user_msg':"The ssh key you entered does not seem to be an ssh key",
                           'log_msg':"Wrong ssh key"})

    principals = Params['principals']
    principals = principals.replace(" ", "")
    if principals == '*':
        logging.debug("User requested all groups")
        principals = ','.join(str(x) for x in JObject["user_info"]["groups"])
        # if the user has no group, add the nogroup
        if principals == '':
            principals = 'nogroup'
        logging.debug('principals is now %s', (principals, ))

    if not check_principals(principals, JObject["user_info"]["groups"]):
        return json.dumps({'result': 'error',
                           "user_msg" : "The principals list you entered does not fit",
                           "log_msg" : "Wrong principals"})


    request_json = create_json(principals, Params['validity'], Params["ssh_pub_key"])

    logging.debug("SSH Watts json is:%s", (request_json,))

    try:
        cert = perform_request(ConfParams["ssh_ca"],
                               ConfParams["ssh_key"],
                               ConfParams["ssh_user"],
                               request_json)
    except json.JSONDecodeError:
        return json.dumps({'result':
                           'error',
                           "user_msg" : "There was an error at the ssh-ca",
                           "log_msg" : "Error at ssh-ca"})

    if cert['cert'] == '':
        return json.dumps({'result': 'error',
                           "user_msg" : "There was an error at the ssh-ca",
                           "log_msg" : "Error at ssh-ca"})
    return_string = {'result':'ok',
                     'credential': [{
                         "name" : "SSH Certificate",
                         "type": "textfile",
                         "value": cert['cert'],
                         'save_as': 'YOURKEY-cert.pub'}],
                     'state': cert['serial']}
    return json.dumps(return_string)


def revoke(JObject):
    """ Revokes a key with serial number in JObject"""
    logging.debug('try to revoke %s', (JObject,))

    request_dict = {"action" : "revoke", "serial" : JObject['cred_state']}
    json_request = json.JSONEncoder().encode(request_dict)

    ConfParams = JObject['conf_params']

    host = ConfParams["ssh_ca"]
    user = ConfParams["ssh_user"]
    keyfile = ConfParams["ssh_key"]


    with subprocess.Popen(["ssh",
                           "%s@%s" % (user, host),
                           "-i",
                           "%s" % keyfile,
                           "%s" % json_request],
                          shell=False,
                          stdout=subprocess.PIPE,
                          stderr=subprocess.PIPE) as ssh:
        stdout = ""
        for line in ssh.stdout:
            stdout += line.decode()
        logging.debug(stdout)
        logging.debug("stderr %s", (ssh.stderr.readlines(),))
        jstdout = json.loads(stdout)
        logging.debug(jstdout)

    return json.dumps({'result': 'ok'})


def get_jobject(str_input=None):
    """ Fixes the padding of a base64 object and loads the json object"""
    if str_input:
        str_input = str_input.encode()
        missing_padding = len(str_input) % 4
        if missing_padding != 0:
            str_input += b'='* (4 - missing_padding)
        logging.debug('Padded str_input is %s', (str_input,))
        decoded_input = base64.b64decode(str_input).decode()
        logging.debug("Decoded input %s", (decoded_input,))
        JObject = json.loads(decoded_input)
    logging.debug("JObject is %s ", (JObject,))
#     JObject = json.loads(str(base64.urlsafe_b64decode(Json)))
    return JObject



def main():
    """Entry point for watts """
    logging.debug("Hello to ssh-ca watts")
    logging.debug("sys.argv is %s", (sys.argv,))
    try:
        UserMsg = "Internal error, please contact the administrator"
        JObject = None
        if len(sys.argv) > 1:
            str_input = sys.argv[1]
            if isinstance(str_input) is bytes:
                str_input = str_input.decode('ascii')

        else:
            str_input = sys.stdin.read()
        logging.debug("Read input string %s", (str_input,))
        JObject = get_jobject(str_input)


        if JObject != None:
            Action = JObject['action']
            logging.debug("%s,%s", Action, " is requested")
            if Action == "parameter":
                logging.debug("Requested parameter list %s", (list_params,))
                print(list_params())
            elif Action == "request":
                print(request(JObject))
            elif Action == "revoke":
                logging.debug("Revoke permissions")
                print(revoke(JObject))
            else:
                print(json.dumps({"result":"error", "user_msg":"unknown_action"}))
        else:
            logging.debug('Error no input parameter')
            print(json.dumps({"result":"error", "user_msg":"no_parameter"}))
    except Exception as E:
        TraceBack = traceback.format_exc()
        LogMsg = "the plugin failed with %s - %s"%(str(E), TraceBack)
        print(json.dumps({'result':'error', 'user_msg':UserMsg, 'log_msg':LogMsg}))

if __name__ == "__main__":
    main()
