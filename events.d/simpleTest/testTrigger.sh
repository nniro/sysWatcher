#! /bin/sh

varDir=$HOME/tmp/sysWatcher/events/var

if [ ! -e "$varDir/simpleTest.log" ]; then touch $varDir/simpleTest.log; fi
echo "`date`: Triggered" >> $varDir/simpleTest.log
