#! /bin/sh

mkTuple () {
	# using '@' characters to support the content even if they contain commas inside of them
	# now if the content contains '@', we are screwed so we encode both '@' characters and ','
	# characters.
	first=`echo $1 | sed -e 's/\@/%40/g; s/,/%2c/g'`
	second=`echo $2 | sed -e 's/\@/%40/g; s/,/%2c/g'`
	echo "(@$first@,@$second@)"
}

isTuple() {
	if [ "`echo \"$1\" | sed -e 's/^(\@[^\@]*\@,\@[^\@]*\@)$//'`" = "" ]; then
		echo 1
	else
		echo 0
	fi
}

# output the first element of a tuple
fst() {
	if [ "`isTuple \"$1\"`" = "0" ]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@\(.*\)\@,\@.*\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

# output the second element of a tuple
snd() {
	if [ "`isTuple \"$1\"`" = "0" ]; then
		echo "Input is not a tuple"
		exit 1
	fi
	echo "$1" | sed -e 's/(\@[^\@]*\@,\@\([^\@]*\)\@)/\1/' | sed -e 's/%40/\@/g; s/%2c/,/g'
}

sep() {
	if [ "$2" = "" ]; then
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

# returns 1 if yes and 0 if no
isValidTime() {
	echo `echo $1 | sed -e 's/[0-9]\{1,2\}:[0-9]\{1,2\}:[0-9]\{1,2\}/1/; t zum; s/.*/0/; :zum; b'`
}

# returns 1 if yes and 0 if no
isValidDate() {
	echo `echo $1 | sed -e 's/[0-9]\{2,4\}-[0-9]\{1,2\}-[0-9]\{1,2\}/1/; t zum; s/.*/0/; :zum; b'`
}

# takes a year as input
# returns if a year is bissextile or not
isLeapYear() {
	if [ $(($1 % 4 == 0)) = 0 ]; then
		if [ $(($1 % 100 == 0)) = 0 ]; then
			if [ $(($1 % 400 == 0)) = 0 ]; then
				echo 0
				return
			fi
		fi
	fi

	echo 1
}

#isLeapYear 2016

addYearMonthDay() {
	local input=$1
	local toAddYears=$2
	local toAddMonths=$3
	local toAddDays=$4

	local date=""
	local time=""

	declare -A daysPerMonth
	daysPerMonth[1]=31 # january
	daysPerMonth[2]=28 # can be 29 too on bissextile years
	daysPerMonth[3]=31 # march
	daysPerMonth[4]=30 # april
	daysPerMonth[5]=31 # may
	daysPerMonth[6]=30 # june
	daysPerMonth[7]=31 # july
	daysPerMonth[8]=31 # august
	daysPerMonth[9]=30 # september
	daysPerMonth[10]=31 # october
	daysPerMonth[11]=30 # november
	daysPerMonth[12]=31 # december

	local tuple=`sep ' ' "$input"`

	if [ "`snd $tuple`" = "" ]; then
		# we expect that this is only a time format (but we will check if it really is)
		date=`fst $tuple`
	else
		# we expect dateTime format but we will type check
		date=`fst $tuple`
		time=`snd $tuple`
	fi

	if [ "`isValidDate \"$date\"`" = "0" ]; then
		echo "Invalid date format"
		echo ""
		return
	fi

	[ "$time" != "" ] && if [ "`isValidTime \"$time\"`" = "0" ]; then 
		echo "Invalid time format"
		echo ""
		return
	fi

	local tuple2=`sep '-' "$date"`
	local year=`fst $tuple2`
	local tuple2=`sep '-' "\`snd $tuple2\`"`
	local month=`fst $tuple2`
	local tuple2=`sep '-' "\`snd $tuple2\`"`
	local day=`fst $tuple2`

	local curYear=$year
	local curMonth=`echo $month | sed -e 's/0\([0-9]\)/\1/'`
	local curDay=$day
	while [ $(($toAddDays > 0)) = 1 ]; do
		if [ "$curMonth" = "2" ]; then # february is very special
			[ "`isLeapYear $curYear`" = "1" ] && local dpm=29 || local dpm=28
		else
			local dpm=${daysPerMonth[$curMonth]}
		fi

		if [ $(($toAddDays > ($dpm - $curDay))) = 1 ]; then
			local toAddDays=$(($toAddDays - ($dpm - $curDay + 1) ))
			local curDay=01

			local curMonth=$(($curMonth + 1))

			if [ $(($curMonth > 12)) = 1 ]; then
				curMonth="01"

				curYear=$(($curYear + 1))
			fi
		else
			# we are done.
			local curDay=`printf "%02d" $(($curDay + $toAddDays))`
			local toAddDays=0
		fi
	done

	local newMonth=$(($curMonth + $toAddMonths))
	if [ $(($newMonth > 12)) = 1 ]; then
		local toAddYears2=$((($newMonth / 12)))
		local newMonth=$(($newMonth - ($toAddYears2 * 12)))

		local toAddYears=$(($toAddYears + $toAddYears2))
	fi

	local newYear=$(($curYear + $toAddYears))

	[ "$time" != "" ] && time=" $time"
	# "`printf \"%02d\" $(())`"
	echo "$newYear-`printf \"%02d\" \"$newMonth\"`-${curDay}$time"
}

#addYearMonthDay "2000-01-01 23:11:10" 0 0 1

#exit 0

addYear() {
	addYearMonthDay $1 $2 0 0
}

addMonth() {
	addYearMonthDay $1 0 $2 0
}

addDay() {
	addYearMonthDay $1 0 0 $2
}


addSeconds() {
	local input="$1" # time or dateTime supported
	local toAdd="$2"

	local date=""
	local time=""

	local tuple=`sep ' ' "$input"`

	if [ "`snd $tuple`" = "" ]; then
		# we expect that this is only a time format (but we will check if it really is)
		time=`fst $tuple`
	else
		# we expect dateTime format but we will type check
		date=`fst $tuple`
		time=`snd $tuple`
	fi

	if [ "`isValidTime \"$time\"`" = "0" ]; then 
		echo "Invalid time format"
		echo ""
		return
	fi

	[ "$date" != "" ] && if [ "`isValidDate \"$date\"`" = "0" ]; then
		echo "Invalid date format"
		echo ""
		return
	fi

	if [ "`echo $toAdd | sed -e 's/[0-9]\+/1/; t zum; s/.*/0/; :zum; b'`" = "0" ]; then
		echo "Invalid toAdd input (must be an number)"
		echo ""
		return
	fi

	local tuple2=`sep ':' "$time"`
	local hours=`fst $tuple2 | sed -e 's/0*\([0-9]*\)/\1/; s/^$/0/'`
	local tuple2=`sep ':' "\`snd $tuple2\`"`
	local minutes=`fst $tuple2 | sed -e 's/0*\([0-9]*\)/\1/; s/^$/0/'`
	local tuple2=`sep ':' "\`snd $tuple2\`"`
	local seconds=`fst $tuple2 | sed -e 's/0*\([0-9]*\)/\1/; s/^$/0/'`

	local newHours=$hours
	local newMinutes=$minutes
	local newSeconds=$seconds

	if [ $((($toAdd + $newSeconds) >= 60)) = 1 ]; then
		local toAddMinutes=$((($toAdd + $newSeconds) / 60))
		local newSeconds=$((($toAdd + $newSeconds) - ($toAddMinutes * 60)))
		local newMinutes=$(($newMinutes + $toAddMinutes))
	else
		local newSeconds=$(($newSeconds + $toAdd))
	fi

	if [ $(($newMinutes >= 60)) = 1 ]; then
		local toAddHours=$(($newMinutes / 60))
		local newMinutes=$(($newMinutes - ($toAddHours * 60)))
		local newHours=$(($newHours + $toAddHours))
	fi

	if [ $(($newHours >= 24)) = 1 ]; then
		local toAddDays=$(($newHours / 24))
		local newHours=$(($newHours - ($toAddDays * 24)))

		date=`addDay "$date" $toAddDays`
	fi

	if [ "$date" != "" ]; then
		printf "$date "
	fi
	echo "`printf \"%02d\" $newHours`:`printf \"%02d\" $newMinutes`:`printf \"%02d\" $newSeconds`"
}

addMinutes() {
	addSeconds "$1" $(($2 * 60))
}

addHours() {
	addMinutes "$1" $(($2 * 60))
}

#addSeconds "2015-11-01 23:59:59" 1

#getDay $testDateTime
#getTime $testDateTime

# compare 2 special format digits
# arguments : <separation symbol> <first digit (string)> <second digit (string)>
# result: 
# -1 : error
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDigits() {
	sepSymbol=$1
	digits1="$2"
	digits2="$3"

	tuple1=`mkTuple "" "$digits1"`
	tuple2=`mkTuple "" "$digits2"`

	while [ 1 != 2 ]; do

		if [ "`snd $tuple1`" = "" ] || [ "`snd $tuple2`" = "" ]; then
			break
		fi

		tuple1=`sep "$sepSymbol" \`snd $tuple1\``
		tuple2=`sep "$sepSymbol" \`snd $tuple2\``

		val1=`fst $tuple1 | sed -e 's/0*\([0-9]*\)/\1/; s/^$/0/'`
		val2=`fst $tuple2 | sed -e 's/0*\([0-9]*\)/\1/; s/^$/0/'`

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
# -1 : error
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDate() {
	if [ "`isValidDate \"$1\"`" = "0" ] || [ "`isValidDate \"$2\"`" = "0" ]; then
		echo -1
		return
	fi
	echo `cmpDigits '-' "$1" "$2"`
}

# compare 2 times
# result: 
# -1 : error
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpTime() {
	if [ "`isValidTime \"$1\"`" = "0" ] || [ "`isValidTime \"$2\"`" = "0" ]; then
		echo -1
		return
	fi
	echo `cmpDigits ':' "$1" "$2"`
}

# compare 2 dateTimes
# result: 
# -1 : error
# 0 : equal
# 1 : first time higher
# 2 : first time lower
cmpDateTime() {
	dateTime1="$1"
	dateTime2="$2"

	#echo $dateTime1
	#return

	tuple1=`sep " " "$dateTime1"`
	tuple2=`sep " " "$dateTime2"`

	date1=`fst $tuple1`
	date2=`fst $tuple2`

	time1=`snd $tuple1`
	time2=`snd $tuple2`

	result=`cmpDate "$date1" "$date2"`

	if [ $result = 0 ]; then
		echo `cmpTime "$time1" "$time2"`
	else
		echo $result
	fi
}

now() {
	date +'%F %T'
}

#echo `cmpTime "22:32:22" "22:32:23"`
#echo `cmpDateTime "2015-01-01 22:32:22" "2015-01-01 22:32:21"`

#echo `addSeconds "\`now\`" 3600`

#exit 0
