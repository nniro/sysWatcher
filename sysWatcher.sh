#! /bin/sh

# this script uses a configuration file sysWatcher.conf and
# a directory containing special scripts that set the events 
# that need to be watched.
# If an event is triggered, we do the action related to the
# event like emailing to the system administrator.
# This script is meant to be ran as a cron job as often as
# possible to ensure faster response.
# A special time out variable is also meant to avoid spam of
# event consequences.

defaultConfigName="sysWatcher.conf"

# sysWatcher.conf
#
# email=<email> # the default system administrator's email
# eventDir=<path to script with events> # something like : /etc/sysWatcher.d/
# varDir=<path to var dir> # this contains temporary values like PID and timeout values.
# 

#
# the event scripts need to contain minimum 2 functions (these are called by this script,
# the rest can be anything as this script won't access them) :
# eventName	# the name of the event for logging and emailing
# eventIsTrue	# this function should return 1 when it is triggered and the event should be called
#		# and return 0 when no event should be triggered
# triggerEventType	# this function sets which type of action needs to be done,
#			# currently supported actions are : email and script
# triggerEventScript	# the script to run if triggerEventType = script. The script
#			# needs to accept an argument : the content of triggerEventScriptContent.
# triggerEventScriptContent # specific data sent to the script
# triggerEventEmail	# the email address to send the report to (leave empty for default)
# triggerEventEmailContent # specific data to send in the email
# triggerTimeout	# The name of the variable is a bit misleading because it is
#			# in fact the date and time at which the event shall be reactivated
#			# time the event can be retriggered format is : YYYY-MM-DD hh:mm:ss
#			# a value of -1 makes the event trigger only once.
#			# a value of 0 makes the event trigger not use any timeout
# 

debugging=1

mainConfig=$1

if [ "$mainConfig" = "" ]; then
	# we'll check in the default places for the main config
	if [ -e "./$defaultConfigName" ]; then
		mainConfig="./$defaultConfigName"
	else
		if [ -e "/etc/$defaultConfigName" ]; then
			mainConfig="/etc/$defaultConfigName"
		else
			echo "Error: no configuration found."
			exit 1
		fi
	fi
fi

if [ ! -r $mainConfig ]; then
	echo "Error: Configuration file \`$mainConfig' does not exist or is not readable."
	exit 1
fi

. $mainConfig

#scripts=`ls -B $eventDir/*`
# only normal files, no files starting with . and no files containing the symbol ~
scripts=`find $eventDir -maxdepth 1 -type f -regex '[^\/]*\/[^\.][^~]*'`

function mkTuple() {
	# using '@' characters to support the content even if they contain commas inside of them
	# now if the content contains '@', we are screwed so we encode both '@' characters and ','
	# characters.
	first=`echo $1 | sed -e 's/\@/%40/g; s/,/%2c/g'`
	second=`echo $2 | sed -e 's/\@/%40/g; s/,/%2c/g'`
	echo "(@$first@,@$second@)"
}

function isTuple() {
	if [[ "`echo \"$1\" | sed -e 's/^(\@[^\@]*\@,\@[^\@]*\@)$//'`" == "" ]]; then
		echo 1
	else
		echo 0
	fi
}

# output the first element of a tuple
function fst() {
	if [[ `isTuple "$1"` == 0 ]]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@\(.*\)\@,\@.*\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

# output the second element of a tuple
function snd() {
	if [[ `isTuple "$1"` == 0 ]]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@[^\@]*\@,\@\([^\@]*\)\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

function sep() {
	if [[ "$2" == "" ]]; then
		local sepChr=" "
		local data="$1"
	else
		local sepChr="$1"
		local data="$2"
	fi
	#mkTuple `echo "$data" | sed -e "s/^\([^$sepChr]*\)$sepChr\(.*\)$/\"\1\" \"\2\"/"`
	#echo "$data" | sed -e "s/^\([^$sepChr]*\)$sepChr\(.*\)$/\"\1\" \"\2\"/"
	mkTuple "`echo \"$data\" | sed -e \"s/^\([^$sepChr]*\)\($sepChr\)\(.*\)$/\1/\"`" "`echo \"$data\" | sed -ne \"s/^\([^$sepChr]*\)$sepChr\(.*\)$/\2/ p\"`"
}

testDateTime="2015-01-05 22:32:11"


getYear() {
	input=$1
	case $input in
		-1)
			return -1
		;;
		0)
			return 0
		;;

		*)
			printf $input | sed -e 's/\([0-9]\{4\}\)-[0-9]\{2\}-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}/\1/'
		;;
	esac
}

getMonth() {
	input=$1
	case $input in
		-1)
			return -1
		;;
		0)
			return 0
		;;

		*)
			printf $input | sed -e 's/[0-9]\{4\}-\([0-9]\{2\}\)-[0-9]\{2\} [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}/\1/'
		;;
	esac
}

getDay() {
	input=$1
	case $input in
		-1)
			return -1
		;;
		0)
			return 0
		;;

		*)
			printf $input | sed -e 's/[0-9]\{4\}-[0-9]\{2\}-\([0-9]\{2\}\) [0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}/\1/'
		;;
	esac
}

getTime() {
	input=$1
	case $input in
		-1)
			return -1
		;;
		0)
			return 0
		;;

		*)
			printf $input | sed -e 's/[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\} \([0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}\)/\1/'
		;;
	esac
}

#getDay $testDateTime
#getTime $testDateTime

# compare 2 special format digits
# arguments : <separation symbol> <first digit (string)> <second digit (string)>
# result: 
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDigits() {
	sepSymbol=$1
	time1=$2
	time2=$3

	tuple1=`mkTuple "" $time1`
	tuple2=`mkTuple "" $time2`

	while [ 1 != 2 ]; do

		if [ "`snd $tuple1`" = "" ] || [ "`snd $tuple2`" = "" ]; then
			break
		fi

		tuple1=`sep "$sepSymbol" \`snd $tuple1\``
		tuple2=`sep "$sepSymbol" \`snd $tuple2\``

		val1=`fst $tuple1`
		val2=`fst $tuple2`

		if [ $val1 = $val2 ]; then
			continue
		else
			if [ $(($val1 > $val2)) = 1 ]; then
				echo 1
				return
			else
				echo 2
				return
			fi
		fi
	done

	echo 0
	return
}

# compare 2 dates
# result: 
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDate() {
	echo `cmpDigits '-' $1 $2`
}

# compare 2 times
# result: 
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpTime() {
	echo `cmpDigits ':' $1 $2`
}

# compare 2 dateTimes
# result: 
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDateTime() {
	dateTime1=$1
	dateTime2=$2

	tuple1=`sep " " $dateTime1`
	tuple2=`sep " " $dateTime2`

	date1=`fst $tuple1`
	date2=`fst $tuple2`

	time1=`snd $tuple1`
	time2=`snd $tuple2`

	result=`cmpDate $date1 $date2`

	if [ $result = 0 ]; then
		echo `cmpTime $time1 $time2`
	else
		echo $result
	fi
}

now() {
	date +'%F %T'
}

#echo `cmpTime "22:32:22" "22:32:23"`
#echo `cmpDateTime "2015-01-01 22:32:22" "2015-01-01 22:32:21"`

#exit 0

# run Script's function
runSFunc() {
	script=$1
	function=$2

	result=`/bin/sh runScriptFunc.sh $script $function`

	if [ $? = 1 ]; then
		echo "An error happened when running a script"
	else
		echo $result
	fi
}

isScriptValid() {
	script=$1
	getErrorType=$2
	# check if the script is valid or not
	# we check if certain important functions are
	# set for that. (And if they contain valid values)

	if [ ! -e $script ]; then
		[ "$getErrorType" != "" ] && echo "script file does not exist" || echo 0; return
	fi

	if [ "`runSFunc \"$script\" \"eventName\"`" = "" ]; then
		[ "$getErrorType" != "" ] && echo "eventName is empty" || echo 0; return
	fi

	case "`runSFunc \"$script\" \"triggerEventType\"`" in
		script)
			triggerEventScript="`runSFunc \"$script\" \"triggerEventScript\"`"
			if [ "$triggerEventScript" = "" ]; then
				[ "$getErrorType" != "" ] && echo "triggerEventScript is empty for triggerEventType script" || echo 0; return
			else
				if [ ! -e $triggerEventScript ]; then
					[ "$getErrorType" != "" ] && echo "the script \`$triggerEventScript' to run on triggerEvent does not exist" || echo 0; return
				fi
			fi
		;;

		email)
		;;

		*)
			[ "$getErrorType" != "" ] && echo "Invalid triggerEventType, must be script or email" || echo 0; return
		;;

	esac

	echo 1
}

# remove any newline or superflux spaces
scripts=`echo $scripts | sed -n -e 'H; $ b e' -e 'b; : e {x; s/\n/ /g; p;q}' | sed -e '1 s/^ *\(.*\)/\1/'`

handleTriggerEvent() {
	script=$1

	eventName="`runSFunc \"$script\" \"eventName\"`"
	timeout="`runSFunc \"$script\" \"triggerTimeout\"`"

	if [ $timeout != 0 ]; then
		cat > $varDir/_${eventName}-timeout << EOF
$timeout
EOF
	fi

	case "`runSFunc \"$script\" \"triggerEventType\"`" in
		script)
			triggerScript="`runSFunc \"$script\" \"triggerEventScript\"`"

			/bin/sh $triggerScript
		;;

		email)
		;;
	esac

}

handleScripts() {

	if [ "$1" = "" ]; then
		return
	fi

	tuple=`sep $1`
	script=`fst $tuple`
	xs=`snd $tuple`

	[ $debugging = 1 ] && echo $script

	if [ `isScriptValid $script` = 0 ]; then
		[ $debugging = 1 ] && echo "The script \`$script' contains an error and is thus invalid."
		[ $debugging = 1 ] && echo "error message : `isScriptValid $script 1`"
		handleScripts $xs
		return
	fi

	eventName="`runSFunc \"$script\" \"eventName\"`"
	if [ -e $varDir/_${eventName}-timeout ]; then
		timeout=`cat $varDir/_${eventName}-timeout`
	else
		timeout="0"
	fi

	[ $debugging = 1 ] && echo "Checking \`$script' script for \`$eventName'"

	# if $timeout = -1 we never run that event again
	if [ $timeout = 0 ] || [ $((`cmpDateTime "$(now)" "$timeout"` <= 1)) = 1 ]; then
		if [ `runSFunc "$script" "eventIsTrue"` = 1 ]; then
			handleTriggerEvent $script
		else
			[ $debugging = 1 ] && [ $timeout != 0 ] && echo "\`cmpDateTime '`now`' '$timeout' '\` == `cmpDateTime \"$(now)\" \"$timeout\"`"
			[ $debugging = 1 ] && echo "Trigger is off"
			[ -e $varDir/_${eventName}-timeout ] && rm $varDir/_${eventName}-timeout
		fi
	fi

	handleScripts $xs
}

while [ 1 = 1 ]; do
	handleScripts $scripts
	sleep 5
done
