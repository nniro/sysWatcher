#! /bin/sh

if [ -e _testFile ]; then
	echo 'Event Triggered!'
	touch ~/IT_WORKED
	rm _testFile
else
	touch _testFile
fi
