#! /bin/sh

. /usr/share/sysWatcher/utils.sh

eventName() {
	echo "monitor"
}

eventIsTrue() {
	echo 1
}

triggerEventType() {
	echo email
}

triggerEventEmailContent() {
	#echo "`ps aux`"
	echo ""
}

triggerTimeout() {
	echo "`addMinutes \"\`now\`\" 5`"
}
