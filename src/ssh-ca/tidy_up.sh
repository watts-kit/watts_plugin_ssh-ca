#!/bin/bash


#how many seconds is a cert valid
echo $(( $(date +%s --date="2019-06-25T11:49:29") - $(date +%s)))
