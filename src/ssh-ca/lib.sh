#!/bin/bash

echoerr() { echo "$@" 1>&2; }

function check_validity {
	to_day="[0-9]{4}(0[0-9]|1[0-2])([0-2][0-9]|3[0-1])"
	to_ss="[0-9]{4}(0[0-9]|1[0-2])([0-2][0-9]|3[0-1])([0-1][0-9]|2[0-3])[0-5][0-9]([0-5][0-9])?"
	interval="(-[0-9]+[smhdw]?:)?\+[0-9]+[smhdw]?"
	regex='(^('${to_day}':)?'${to_day}'$)|(^('${to_ss}')?'${to_ss}'$)|(^'${interval}'$)'
	#echo $regex
	if [[ "$1" =~ $regex ]]; 
	then
		return 0
	else
		echoerr "validity does not match regex"
		return 1
	fi
}


function check_ca_key {

	if [ ! -e $1 ]; then
		echoerr "no ca user key found"
		return 1
	fi
}
function check_counterfile {
	if [ ! -e $1 ]; then
		echoerr "no counterfile found"
		return 1
	fi
}
function check_key {
	# Test if key is valid keyfile of key
	printf "%s" "$1" | ssh-keygen -l -f - >&2 

	if [ $? -ne 0 ]; then
		echoerr " $1 no valid key"
		return 1
	fi
}
