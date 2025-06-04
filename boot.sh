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

	p "entering recovery..."
	other_repos/libimobiledevice/tools/ideviceenterrecovery "$UDID"
else
	p "detected device in recovery mode"
fi

p "Get ready..."
for i in $(seq 3); do
	printf "%s " "$i"
	sleep 1
done

p "Power and home..."
for i in $(seq 8); do
	printf "%s " "$i"
	sleep 1
done

p "home..."
for i in $(seq 8); do
	printf "%s " "$i"
	sleep 1
done

if ! lsusb | grep DFU\ Mode > /dev/null #FIXME
then
	p 'failed to enter dfu'
fi

p 'Entering pwndfu with primepwn'
other_repos/primepwn/tmp/libirecovery/tools/primepwn

p 'Uploading hacked iBSS'
other_repos/libirecovery/tools/irecovery -f /home/user/customhacks/bins/hacked_components/hacked_iBSS
p 'Uploading hacked iBEC'
other_repos/libirecovery/tools/irecovery -f /home/user/customhacks/bins/hacked_components/hacked_iBEC

for i in 1 2 3 4 5 6 7 END
do
	if ! lsusb | grep Recovery\ Mode  > /dev/null
	then
		if [ "$i" = END ]
		then
			p "Failed to start the hacked iBEC bootloader"
			exit 1
		fi
		sleep .5
	else
		break
	fi
done

p "Successfully booted to iBEC that has no verification checks"
