#! /bin/sh

# this script imports a script and runs only a single function from that script
# without any arguments and returns the result.

script=$1
function=$2

if [ ! -e $script ]; then
	exit 1;
fi

. $script

echo `$function`

exit 0;
