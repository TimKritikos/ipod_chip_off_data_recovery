#!/bin/sh
set -eu

p(){
	printf "\e[31m%s\e[0m\n" "$@"
}

if ! lsusb | grep Recovery\ Mode >/dev/null #FIXME
then
	p "Query UDID..."
	UDID=$(other_repos/libimobiledevice/tools/ideviceinfo -s -k UniqueDeviceID)
	p "got \"$UDID\""

	echo "entering recovery..."
	other_repos/libimobiledevice/tools/ideviceenterrecovery "$UDID"
else
	p "detected device in recovery mode"
fi

p "Get ready..."
for i in $(seq 3); do
	echo -n "$i "
	sleep 1
done

p "Power and home..."
for i in $(seq 8); do
	echo -n "$i "
	sleep 1
done

p "home..."
for i in $(seq 8); do
	echo -n "$i "
	sleep 1
done

if ! lsusb | grep DFU\ Mode > /dev/null #FIXME
then
	p 'failed to enter dfu'
fi

other_repos/primepwn/tmp/libirecovery/tools/primepwn
