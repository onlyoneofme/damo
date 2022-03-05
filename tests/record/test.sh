#!/bin/bash
# SPDX-License-Identifier: GPL-2.0

bindir=$(dirname "$0")
cd "$bindir"

damo="../../damo"

cleanup_files()
{
	files_to_remove="./damon.data ./damon.data.perf.data"
	for file in $files_to_remove
	do
		if [ -f "$file" ]
		then
			if ! rm "$file"
			then
				echo "removing $file failed"
				exit 1
			fi
		fi
	done
}

test_record_permission()
{
	sudo "$damo" record "sleep 1" --output_permission 611 &> /dev/null
	if [ ! "$(stat -c %a damon.data)" = "611" ]
	then
		echo "FAIL record-permission"
		exit 1
	fi
	cleanup_files

	echo "PASS record-permission"
}

test_leave_perf_data()
{
	if ! sudo "$damo" record "sleep 2" --leave_perf_data &> /dev/null
	then
		echo "FAIL record-leave-perf-data (damo-record command failed)"
		exit 1
	fi

	if [ ! -f ./damon.data.perf.data ]
	then
		echo "FAIL record-leave-perf-data (perf.data not found)"
		exit 1
	fi

	cleanup_files

	echo "PASS record-leave-perf-data"
}

test_record_validate()
{
	if [ $# -ne 3 ]
	then
		echo "Usage: $0 <target> <timeout> <damon interface to use>"
		exit 1
	fi

	target=$1
	timeout=$2
	damon_interface=$3

	testname="record-validate \"$target\" $timeout $damon_interface"

	if [ "$target" = "paddr" ] && ! sudo "$damo" features \
		--damon_interface "$damon_interface" supported | \
		grep -w paddr > /dev/null
	then
		echo "SKIP record-validate $target $timeout (paddr unsupported)"
		return
	fi

	sudo timeout "$timeout" "$damo" record "$target" \
		--damon_interface "$damon_interface" &> /dev/null
	rc=$?
	if [ $? -ne 0 ] && [ $? -ne 124 ]
	then
		echo "FAIL $testname"
		echo "(damo-record command failed with value $rc)"
		exit 1
	fi

	if ! "$damo" validate
	then
		echo "FAIL $testname (record fild is not valid)"
		exit 1
	fi

	if [ -f ./damon.data.perf.data ]
	then
		echo "FAIL $testname (perf.data is not removed)"
		exit 1
	fi

	permission=$(stat -c %a damon.data)
	if [ ! "$permission" = "600" ]
	then
		echo "FAIL $testname (out file permission $permission)"
		exit 1
	fi

	cleanup_files

	echo "PASS $testname"
}

if [ ! -d /sys/kernel/debug/damon ]
then
	echo "SKIP $(basename $(pwd)) (DAMON debugfs not found)"
	exit 0
fi

test_record_validate "sleep 3" 4 "debugfs"
test_record_validate "sleep 3" 4 "sysfs"
test_record_validate "paddr" 3 "debugfs"
test_record_validate "paddr" 3 "sysfs"
test_leave_perf_data
test_record_permission

echo "PASS $(basename $(pwd))"
