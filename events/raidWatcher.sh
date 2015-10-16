#! /bin/sh

debugging=0

# raid watcher, this scripts reads the configuration file raidWatcher.conf.

. /usr/share/sysWatcher/utils.sh


exampleRaid1="\
Personalities : [raid1]\n\
md2 : active raid1 sda1[1](F) sdb1[2]\n\
      40112000 blocks super 1.2 [2/2] [U_]\n\
      \n\
unused devices: <none>\
"

exampleRaid2="\
Personalities : [raid1]\n\
md127 : active raid1 dm-2[0] dm-1[2]\n\
      40112000 blocks super 1.2 [2/2] [UU]\n\
      \n\
md2 : active raid1 sda1[1](F) sdb1[2]\n\
      40112000 blocks super 1.2 [2/2] [U_]\n\
      \n\
md5 : active raid5 sdg1[4](F) sdf1[3] sde1[2](F) sdd1[1] sdc1[0]
      2104384 blocks super 1.2 [4/5] [UUUUU]\n\
      \n\
unused devices: <none>\
"

exampleRaid3="\
Personalities : [raid1]\n\
md2 : active raid1 sda1[1](F) sdb1[2]\n\
      40112000 blocks super 1.2 [2/2] [UU]\n\
      \n\
unused devices: <none>\
"

exampleRaid4="\
Personalities : [raid1]\n\
md2 : active raid1 sda1[1] sdb1[2]\n\
      40112000 blocks super 1.2 [2/2] [_U]\n\
      \n\
unused devices: <none>\
"

exampleRaid5="\
Personalities : [raid1]\n\
md2 : active raid1 sda1[1] sdb1[2]\n\
      40112000 blocks super 1.2 [2/2] [UU]\n\
      \n\
unused devices: <none>\
"


# output error status or no output at all when everything is fine
interpretRaidLine() {
	device=$1
	result=""

	[ $debugging = 1 ] && echo "device : $device"

	while [ 1 != 2 ]; do 

		shift

		[ "$1" = "" ] && break

		[ "`echo \"$1\" | sed -e 's/^\([a-z]\|[A-Z]\|-\)\+[0-9]\+.*/1/; t zim; s/.*/0/; :zim b'`" = "1" ] && dType="disk" || dType=""

		[ "$dType" = "" ] && if [ "`echo \"$1\" | sed -e 's/\[[0-9]\+\/[0-9]\+\]/1/; t zim; s/.*/0/; :zim b'`" = "1" ]; then
				dType="numStatus"
			else	
				dType=""
			fi

		[ "$dType" = "" ] && if [ "`echo \"$1\" | sed -e 's/\[\(U\|_\)\+\]/1/; t zim; s/.*/0/; :zim b'`" = "1" ]; then
				dType="uStatus"
			else 
				dType=""
			fi

		[ "$dType" = "" ] && dType="unknown"

		[ $debugging = 1 ] && echo "$dType : $1"

		case $dType in
			disk)
				if [ "`echo $1 | sed -e '/(F)/ {s/.*/1/; b}; {s/.*/0/; b}'`" = "0" ]; then
					[ $debugging = 1 ] && echo "\tstatus: All fine"
				else
					[ $debugging = 1 ] && echo "\tstatus: Error found"
					[ "$result" = "" ] && result="device $device has an error : disk $1 is faulty" || result="$result, disk $1 is faulty"
				fi
			;;

			numStatus)
				tuple=`sep '\/' "\`echo $1 | sed -e 's/\(\[\|\]\)//g'\`"`

				num1=`fst $tuple`
				num2=`snd $tuple`

				if [ $num1 = $num2 ]; then
					[ $debugging = 1 ] && echo "\tstatus: All fine"
				else
					[ $debugging = 1 ] && echo "\tstatus: Error found"
					[ "$result" = "" ] && result="device $device has an error : found by wrong num status" || result="$result, found error by num status"
				fi
			;;

			uStatus)
				if [ "`echo $1 | sed -e 's/_/a/; t zum; s/.*/0/; b; :zum {s/.*/1/; b}'`" = "0" ]; then
					[ $debugging = 1 ] && echo "\tstatus: All fine"
				else
					[ $debugging = 1 ] && echo "\tstatus: Error found"
					[ "$result" = "" ] && result="device $device has an error : found by wrong U status" || result="$result, found error by U status"
				fi
			;;

			unknown)
			;;
		esac
	done

	[ $debugging = 1 ] && echo ""
	printf "$result"
}

getRaidErrors() {
	currentRaid=`cat /proc/mdstat`
	toCheckOutput=$currentRaid
	#toCheckOutput=$exampleRaid5
	# this version does not add the second line
	#result=`printf $exampleGoodRaid | sed -n -e "s/\(md[0-9]*\) : [^ ]* [^ ]* \(.*\)/\1 \2/; t zim" -e "b ; :zim {p}"`
	# this version adds stuff from the second line
	parsedOutput=`printf "$toCheckOutput" | sed -n -e "/^md/ {N; s/\(md[0-9]*\) : [^ ]* [^ ]* \(.*\)\n\( \|\t\)*[0-9]* blocks [^\[]* \(.*\)$/\1 \2 \4/; t zim}" -e "b ; : zim {p}"`
	parsedOutput="`printf \"$parsedOutput\" | sed -n -e '1 {h; b}; $ {H; x; s/\n/,/g; p; b}; H'`"

	xs="$parsedOutput"
	result=""
	while [ 1 != 2 ]; do
		if [ "$xs" = "" ]; then
			break;
		fi

		tuple=`sep ',' "$xs"`
		x="`fst \"$tuple\"`"
		xs="`snd \"$tuple\"`"


		checkResult="`interpretRaidLine $x`"
		[ "$checkResult" != "" ] && result="$result$checkResult\n"
	done

	printf "$result"
}

#getRaidErrors

eventName() {
	echo "raidWatcher"
}

eventIsTrue() {
	[ "`getRaidErrors`" != "" ] && echo 1 || echo 0
}

triggerEventType() {
	echo email
}

triggerEventEmailContent() {
	printf "`getRaidErrors`"
}

# we trigger this event once every hour
triggerTimeout() {
	echo `addHours "\`now\`" 1`
}
