#! /bin/sh

# this script imports an unlimited amount of scripts and runs only a single function from these scripts
# and returns the result. It is possible to pass arguments to the script granted you place the function
# and the arguments between single or double quotes as the last parameter of the script when calling it.

# include all scripts. The last argument is the function name
typeset -a allScripts
i=1
temp=""
oldTemp=""
while [ 1 = 1 ]; do
	oldTemp=$temp
	if [ "$1" = "" ]; then
		function=$oldTemp
		break
	fi

	if [ "$oldTemp" != "" ]; then
		allScripts[$i]=$oldTemp
		i=$((i + 1))
	fi

	temp=$1

	shift 1
done

#echo "scripts : ${allScripts[@]} - ${#allScripts[@]}"
#echo "function : $function"

i=1
while [ $((i <= ${#allScripts[@]})) = 1 ]; do
	if [ ! -e ${allScripts[$i]} ]; then
		#echo "error script '${allScripts[$i]}\` don't exist"
		exit 1;
	fi
	#echo "including : ${allScripts[$i]}"

	. ${allScripts[$i]}
	i=$((i + 1))
done

functionName="`echo \"$function\" | sed -e 's/\([^ ]*\) .*/\1/'`"

#echo $functionName
# we first check if the actual function exists
if [ "`declare -f | grep \"$functionName\"`" != "" ]; then
	eval $function
	exit 0
else
	echo "could not find the function"
	exit 1
fi
