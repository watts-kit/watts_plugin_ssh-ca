#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from urllib.parse import urlparse
import json
import base64
import random
import string
import sys
import traceback
import time
import os
import logging
import subprocess



logging.basicConfig(filename='/home/watts-dev/ssh-ca.log',level=logging.DEBUG)

VERSION="0.0.1"

def list_params():
    RequestParams = [
                     [{  "key":"ssh_pub_key", 
                         "name":"SSH Public Key", 
                         "type":"textarea", 
                         "description":"Your public SSH Key that should be signed", 
                         "mandatory":True},
                     {  "key":"validity", 
                         "name":"Validity", 
                         "type":"textarea", 
                         "description":"The requested validity", 
                         "mandatory":True},
                     {  "key":"principals", 
                         "name":"principals", 
                         "type":"textarea", 
                         "description":"The requested principals (usernames) for the cert. Join them by comma", 
                         "mandatory":True}
                     ]
                    ] 
    ConfParams = [
                  { 'name': 'ssh_ca', 
                    'type':'string', 
                    'default': ''},
                  { 'name': 'ssh_user', 
                    'type':'string', 
                    'default': ''},
                  { 'name': 'ssh_key', 
                    'type':'string', 
                    'default': ''},
                    ]
    Email = "info@konstantinzangerle.de"
    Config = {'result':'ok', 
            'conf_params': ConfParams, 
            'request_params': RequestParams, 
            'version':VERSION, 
            'features': { "stdin" : True },
            'developer_email':Email}
    return json.dumps(Config)

def perform_request(host, keyfile, user, json_request):
    with subprocess.Popen(["ssh", "%s@%s" % (host,user), "-i", "%s" % keyfile, "%s" % json_request], 
            shell = False,
            stdout = subprocess.PIPE,
            stderr = subprocess.PIPE) as ssh:
        stdout = ""
        for line in ssh.stdout:
            stdout += line.decode()
        logging.debug(stdout)
        logging.debug("stderr %s" % ssh.stderr.readlines())
        jstdout = json.loads(stdout)
        return jstdout


def create_json(principals, validity, key):
    request_dict = { "principals" : principals,
            "validity" : validity,
            "key" : key,
            "action" : "sign" }

    return json.JSONEncoder().encode(request_dict)

def request(JObject):
    Params = JObject['params']
    ConfParams = JObject['conf_params']

    logging.debug("Request params are %s" % (Params,))

    request_json = create_json(["root", "anotheruser"],"+52w",Params["ssh_pub_key"])
    cert = perform_request(ConfParams["ssh_ca"], ConfParams["ssh_key"], ConfParams["ssh_user"],request_json)

    return json.dumps({'result':'ok', 'credential': [ {"name" : "todo", "type": "text", "value": cert['cert'] }], 'state': cert['serial']})


def revoke(JObject):
    logging.debug('try to revoke %s' % (JObject,))

    request_dict = { "action" : "revoke", "serial" : JObject['cred_state'] }
    json_request = json.JSONEncoder().encode(request_dict)

    ConfParams = JObject['conf_params']

    host = ConfParams["ssh_ca"] 
    user = ConfParams["ssh_user"]
    keyfile = ConfParams["ssh_key"]


    with subprocess.Popen(["ssh", "%s@%s" % (host,user), "-i", "%s" % keyfile, "%s" % json_request], 
            shell = False,
            stdout = subprocess.PIPE,
            stderr = subprocess.PIPE) as ssh:
        stdout = ""
        for line in ssh.stdout:
            stdout += line.decode()
        logging.debug(stdout)
        logging.debug("stderr %s" % ssh.stderr.readlines())
        jstdout = json.loads(stdout)
        logging.debug(jstdout)

    return json.dumps({'result': 'ok'})


def get_jobject(str_input=None):
       if str_input:
               str_input = str_input.encode()
               missing_padding = len(str_input) % 4
               if missing_padding != 0:
                       str_input += b'='* (4 - missing_padding)
               logging.debug('Padded str_input is %s' % (str_input,))
               decoded_input = base64.b64decode(str_input).decode()
               logging.debug("Decoded input %s" % (decoded_input,))
               JObject = json.loads(decoded_input)
       logging.debug("JObject is %s " % (JObject,))
#        JObject = json.loads(str(base64.urlsafe_b64decode(Json)))
       return JObject



def main():
    logging.debug("Hello to ssh-ca watts")
    logging.debug("sys.argv is %s" % (sys.argv,))
    try:
        UserMsg = "Internal error, please contact the administrator"
        JObject = None
        if len(sys.argv) > 1:
            str_input = sys.argv[1]
            if type(str_input) is bytes:
                str_input = str_input.decode('ascii')
                
        else:
            str_input = sys.stdin.read()
        logging.debug("Read input string %s" % (str_input,))
        JObject = get_jobject(str_input)


        if JObject != None:
            Action = JObject['action']
            logging.debug(Action + " is requested")
            if Action == "parameter":
                logging.debug("Requested parameter list %s" %(list_params))
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
            print (json.dumps({"result":"error", "user_msg":"no_parameter"}))
    except Exception as E:
        TraceBack = traceback.format_exc(),
        LogMsg = "the plugin failed with %s - %s"%(str(E), TraceBack)
        print (json.dumps({'result':'error', 'user_msg':UserMsg, 'log_msg':LogMsg}))

if __name__ == "__main__":
    main()
