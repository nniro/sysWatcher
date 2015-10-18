#! /bin/sh

eventName() {
	echo "simpleTest"
}

eventIsTrue() {
	echo 1
}

triggerEventType() {
	echo script
}

triggerEventScript() {
	echo $eventDir/simpleTest/testTrigger.sh
}

triggerTimeout() {
	# every 5 minutes
	echo `addMinutes "\`now\`" 5`
}
