#! /bin/sh

eventName() {
	echo "testEvent"
}

eventIsTrue() {
	if [ -e _testFile ]; then
		echo 1
	else
		echo 0
	fi
}

triggerEventType() {
	echo script
}

triggerEventScript() {
	echo ~/scripts/testTrigger.sh
}

triggerTimeout() {
	echo "2015-06-23 17:20:00"
}
