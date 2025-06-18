#!/bin/sh
set -eu

p(){
	printf "\e[31m%s\e[0m\n" "$@"
}

if ! lsusb | grep DFU\ Mode > /dev/null #FIXME
then
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
	for i in $(seq 12); do
		if [ "$i" = 12 ]
		then
			p 'failed to enter dfu'
		fi
		printf "%s " "$i"
		sleep .5
		if  lsusb | grep DFU\ Mode > /dev/null #FIXME
		then
			break
		fi
		sleep .5
		if  lsusb | grep DFU\ Mode > /dev/null #FIXME
		then
			break
		fi
	done

fi

p 'Entering pwndfu with primepwn'
other_repos/primepwn/tmp/libirecovery/tools/primepwn

p 'Uploading hacked iBSS'
other_repos/libirecovery/tools/irecovery -f bins/hacked_components/hacked_iBSS
p 'Uploading hacked iBEC'
other_repos/libirecovery/tools/irecovery -f bins/hacked_components/hacked_iBEC

for i in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 END
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

p "Sending the ramdisk"
other_repos/libirecovery/tools/irecovery -f bins/hacked_components/Ramdisk
p "Activating ramdisk"
other_repos/libirecovery/tools/irecovery -c "getenv ramdisk-delay"
other_repos/libirecovery/tools/irecovery -c ramdisk
sleep 2

p "Sending Apple's Device Tree"
other_repos/libirecovery/tools/irecovery -f bins/decrypted_components/apple_decrypted_DeviceTree
p "Sending Apple's Unmodified decrypted kernel"
other_repos/libirecovery/tools/irecovery -f bins/hacked_components/KernelCache
p "Sending the command to boot"
other_repos/libirecovery/tools/irecovery -c bootx
