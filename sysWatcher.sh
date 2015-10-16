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
			if [ -e "/usr/local/etc/$defaultConfigName"]; then
				mainConfig="/usr/local/etc/$defaultConfigName"
			else
				echo "Error: no configuration found."
				exit 1
			fi
		fi
	fi
fi

if [ ! -r "$mainConfig" ]; then
	echo "Error: Configuration file \`$mainConfig' does not exist or is not readable."
	exit 1
fi

. $mainConfig

if [ -d /usr/share/sysWatcher ]; then
	sharedDir="/usr/share/sysWatcher"
else
	echo "Could not find the shared script directory."
	echo "Please install them first to use this script."
	echo "(These contain scripts that are also useful for the plugins.)"
	exit 1
fi

. $sharedDir/utils.sh

#scripts=`ls -B $eventDir/*`
# only normal files, no files starting with . and no files containing the symbol ~
scripts=`find -L $eventDir -maxdepth 1 -type f -regex '[^\/]*\/[^\.][^~]*'`

# run Script's function
runSFunc() {
	script=$1
	function=$2

	# It seems that the 'declare' bultin can not be used when called from the generic
	# /bin/sh shell. So we call this script with the current SHELL.
	result=`/bin/sh $sharedDir/runScriptFunc.sh $script $function`

	if [ $? = 1 ]; then
		[ $debugging = 1 ] && echo "An error happened when running a script" || echo ""
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

	if [ "$timeout" != "0" ]; then
		cat > $varDir/_${eventName}-timeout << EOF
$timeout
EOF
	fi

	case "`runSFunc \"$script\" \"triggerEventType\"`" in
		script)
			triggerScript="`runSFunc \"$script\" \"triggerEventScript\"`"
			triggerEventScriptContent="`runSFunc \"$script\" \"triggerEventScriptContent\"`"

			/bin/sh $triggerScript "$triggerEventScriptContent"
		;;

		email)
			triggerEventEmailContent="`runSFunc \"$script\" \"triggerEventEmailContent\"`"
			hostname=`hostname`

			if [ "$triggerEventEmailContent" != "" ]; then
				emailContent="$hostname `now` - This is the content of the event :\n\n$triggerEventEmailContent"
			else
				emailContent="$hostname `now` - There were no specific content released for this event."
			fi

			echo "$emailContent" | mail -s "$hostname: sysWatcher \`$eventName' event triggered" $email
		;;
	esac

}

handleScripts() {
	if [ "$1" = "" ]; then
		return
	fi

	tuple=`sep "$1"`
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
	[ "$timeout" = "0" ] && checkTimeout=`echo 0` || checkTimeout=`cmpDateTime "$(now)" "$timeout"`

	if [ "$checkTimeout" = "-1" ]; then
		echo "An error was detected with the timeout for the script \`$script'"
		echo "either '$timeout' is wrong or '`now`'"
		handleScripts $xs
		return
	fi

	if [ "$timeout" = "0" ] || [ $(( $checkTimeout <= 1)) = 1 ]; then
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

#echo `cmpDateTime "houba" "zim"`
#exit 0

#echo $((`cmpDateTime "$(now)" "2015-06-24 02:50:00"` <= 1))
#exit 0

# uncomment the next lines to make this script standalone
#while [ 1 = 1 ]; do
	handleScripts "$scripts"
#	sleep 5
#done
