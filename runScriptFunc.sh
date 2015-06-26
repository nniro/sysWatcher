#! /bin/sh

# this script imports a script and runs only a single function from that script
# without any arguments and returns the result.

script=$1
function=$2

if [ ! -e $script ]; then
	exit 1;
fi

. $script

# we first check if the actual function exists
if [ "`declare -f | grep $function`" != "" ]; then
	echo `$function`
	exit 0
else
	exit 1
fi
