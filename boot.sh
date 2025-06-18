#!/bin/sh
set -eu

p(){
	printf "\e[31m%s\e[0m\n" "$@"
}

IBSS=bins/hacked_components/hacked_iBSS
IBEC=bins/hacked_components/hacked_iBEC
RAMDISK=bins/hacked_components/Ramdisk
DEVICE_TREE=bins/decrypted_components/apple_decrypted_DeviceTree
KERNEL=bins/hacked_components/KernelCache

if ! [ -e "$IBSS" ] || ! [ -e "$IBEC" ] || ! [ -e "$RAMDISK" ] || ! [ -e "$DEVICE_TREE" ] || ! [ -e "$KERNEL" ]
then
	echo One or more components for the boot process are missing. Make sure you run ./aquire.sh
	exit 1
fi

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
			return 1
		fi
		if  lsusb | grep DFU\ Mode > /dev/null #FIXME
		then
			break
		fi
		printf "%s " "$i"
		sleep .5
		if  lsusb | grep DFU\ Mode > /dev/null #FIXME
		then
			break
		fi
		sleep .5
	done

fi

p 'Entering pwndfu with primepwn'
other_repos/primepwn/tmp/libirecovery/tools/primepwn

p 'Uploading hacked iBSS'
other_repos/libirecovery/tools/irecovery -f "$IBSS"
p 'Uploading hacked iBEC'
other_repos/libirecovery/tools/irecovery -f "$IBEC"

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
other_repos/libirecovery/tools/irecovery -f "$RAMDISK"
p "Activating ramdisk"
other_repos/libirecovery/tools/irecovery -c "getenv ramdisk-delay"
other_repos/libirecovery/tools/irecovery -c ramdisk
sleep 2

p "Sending Apple's Device Tree"
other_repos/libirecovery/tools/irecovery -f "$DEVICE_TREE"
p "Sending Apple's Unmodified decrypted kernel"
other_repos/libirecovery/tools/irecovery -f "$KERNEL"
p "Sending the command to boot"
other_repos/libirecovery/tools/irecovery -c bootx
