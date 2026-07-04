#!/bin/sh
set -eu

REPO_ROOT=$(realpath "$(dirname "$0")")
cd "$REPO_ROOT"

##IMPORTANT: CHANGE THIS:
PYTHON2=../python2.7_for_ios-data/AppRun
# This is to run the scripts from iphone-dataprotection which use python2. I extracted the appimage off of somewhere and pip installed the required dependencies

if ! which "$PYTHON2" > /dev/null
then
	echo You need to chage the PYTHON2 variable in this script
fi


BUILD=10B500
ipod4_ipsw=$(cat builds/"$BUILD"/url)
json_keyfile=builds/"$BUILD"/index.html


if ! [ -e other_repos ]
then
	mkdir other_repos
fi
cd other_repos

if ! [ -e libimobiledevice ]
then
	git clone https://github.com/libimobiledevice/libimobiledevice
	cd libimobiledevice/
	git checkout 0bf0f9e941c85d06ce4b5909d7a61b3a4f2a6a05
	PKG_CONFIG_PATH=/usr/lib/pkgconfig/:$PKG_CONFIG_PATH ./autogen.sh
	make -j3
	cd ..
fi

if ! [ -e primepwn ]
then
	git clone https://github.com/LukeZGD/primepwn
	cd primepwn
	git checkout 02d4f7bb0478fd401187b1142d4c965e4d3acc70
	#patch to make the project compile
	patch -p0 < "$REPO_ROOT"/patches/primepwn_compile.patch

	./compile.sh
	cd ..
fi

if ! [ -e libirecovery ]
then
	git clone https://github.com/libimobiledevice/libirecovery
	cd libirecovery
	git checkout 638056a593b3254d05f2960fab836bace10ff105
	./autogen.sh
	./configure
	make -j3
	cd ..
fi

if ! [ -e iBoot32Patcher ]
then
	git clone https://github.com/iH8sn0w/iBoot32Patcher
	cd iBoot32Patcher
	git checkout 77ab155cb418d67f688e2e85f3e83c77a2431660
	clang iBoot32Patcher.c finders.c functions.c patchers.c -Wno-multichar -I. -o iBoot32Patcher
	cd ..
fi

if ! [ -e xpwn ]
then
	export CMAKE_POLICY_VERSION_MINIMUM=3.5 #Added on the second data recovery attempt for ipod touch 5

	git clone https://github.com/LukeeGD/xpwn
	cd xpwn
	git checkout d1d2d3da2081b197b2946f2699d68b2a4acfbfb2
	#Patch to make the project compile
	patch -p1 < "$REPO_ROOT"/patches/dfu-util-compile.patch
	mkdir build
	cd build
	cmake ..
	make -j3
	cd ../..
fi

if ! [ -e iphone-dataprotection ]
then
	git clone https://github.com/nabla-c0d3/iphone-dataprotection
	cd iphone-dataprotection
	git checkout 572dd5cd8c07f5f14f7ea9488041031dd22a26bb #shouldn't be necessary project is read only but just to make sure
	#Patch kernel_patcher.py to take in decrypted raw kernels and patch them
	patch -p1 < "$REPO_ROOT"/patches/iphone-dataprotection-patch-supplied-decrypted-kernels.patch
	#Patch kernel_patcher to also apply the IOFlashControllerUserClient::externalMethod patch #TODO: is the comment accurate ?
	patch -p1 < "$REPO_ROOT"/patches/iphone-dataprotection-add-ipod4-settings.patch

	cd ../
fi

cd ..

if ! [ -e generated_bins ]
then
	mkdir generated_bins
fi
cd generated_bins

##########################################
## Get Apple's IPSW that has the bootloader kernel and ramdisk
##########################################

IPSW_FILENAME="$(basename "$ipod4_ipsw")"
if ! [ -e "$IPSW_FILENAME" ]
then
	wget "$ipod4_ipsw"
fi

if ! [ -e extracted_ipsw ]
then
	mkdir extracted_ipsw
	cd extracted_ipsw
	7z x ../"$IPSW_FILENAME"  -y
	cd ..
fi

cd ..

##########################################
## Decrypt the components
##########################################

#[input file location in ipsw] [name in keyfile]
decrypt(){
	infile=generated_bins/extracted_ipsw/"$1"
	name="$2"
	outfile=generated_bins/decrypted_components/apple_decrypted_"$name"

	iv=$( jq -r '.keys[] | select(.image == "'"$name"'") | .iv' < "$json_keyfile" )
	key=$( jq -r '.keys[] | select(.image == "'"$name"'") | .key' < "$json_keyfile" )

	if [ "$iv" = "" ] || [ "$key" = "" ]
	then
		p 'Error, couldnt find key for component '"$name"
	fi

	other_repos/xpwn/build/ipsw-patch/xpwntool "$infile" "$outfile" -iv "$iv" -k "$key" -decrypt
}

if ! [ -e generated_bins/decrypted_components ]
then
	mkdir generated_bins/decrypted_components

	ramdisk_filename=$(jq < builds/10B500/index.html '.keys[] | select(.image=="RestoreRamdisk").filename' -r)

	decrypt Firmware/dfu/iBSS.n81ap.RELEASE.dfu                                    iBSS
	decrypt Firmware/dfu/iBEC.n81ap.RELEASE.dfu                                    iBEC
	decrypt Firmware/all_flash/all_flash.n81ap.production/DeviceTree.n81ap.img3    DeviceTree
	decrypt kernelcache.release.n81                                                Kernelcache
	decrypt "$ramdisk_filename"                                                    RestoreRamdisk

fi

##########################################
## Remove checks from the iBSS bootloader
##########################################

if ! [ -e generated_bins/hacked_components ]
then
	mkdir generated_bins/hacked_components

	# Remove security checks from iBSS and iBEC

	for component in iBSS iBEC
	do
		DECRYPTED_iBSS=generated_bins/decrypted_components/apple_decrypted_"$component"
		      RAW_iBSS=generated_bins/hacked_components/apple_decrypted_"$component".raw
		   HACKED_iBSS=generated_bins/hacked_components/hacked_"$component".raw
		 BOOTABLE_iBSS=generated_bins/hacked_components/hacked_"$component"

		other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_iBSS" "$RAW_iBSS"

		if [ "$component" = "iBEC" ]
		then
			bootargs="rd=md0 -v amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0 nand-disable=1"
		else
			bootargs=""
		fi

		other_repos/iBoot32Patcher/iBoot32Patcher "$RAW_iBSS" "$HACKED_iBSS" --rsa --debug -b "$bootargs"

		other_repos/xpwn/build/ipsw-patch/xpwntool "$HACKED_iBSS" "$BOOTABLE_iBSS" -t "$DECRYPTED_iBSS"
	done

	# Patch the kernel, i think this is to allow us to read the DKey and access the AES engine

	DECRYPTED_KERNEL=generated_bins/decrypted_components/apple_decrypted_Kernelcache
	RAW_KERNEL=generated_bins/hacked_components/KernelCache.raw
	PATCHED_KERNEL=generated_bins/hacked_components/KernelCache.patched
	KERNEL_MYPATCHES=generated_bins/hacked_components/KernelCache.my_patches
	BOOTABLE_KERNEL=generated_bins/hacked_components/KernelCache

	other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_KERNEL" "$RAW_KERNEL"

	TMPFILE=$(mktemp)

	"$PYTHON2" other_repos/iphone-dataprotection/python_scripts/kernel_patcher.py "$RAW_KERNEL" "$PATCHED_KERNEL" | tee "$TMPFILE"
	if grep 'do not boot that kernel it wont work' "$TMPFILE" > /dev/null
	then
		echo It seems that the kernel patching script failed
		rm "$TMPFILE"
		exit 1
	fi
	rm "$TMPFILE"

	bspatch "$PATCHED_KERNEL" "$KERNEL_MYPATCHES" bins/no-crash-no-mount+others.bspatch
	#cp "$PATCHED_KERNEL" "$KERNEL_MYPATCHES"

	other_repos/xpwn/build/ipsw-patch/xpwntool "$KERNEL_MYPATCHES" "$BOOTABLE_KERNEL" -t "$DECRYPTED_KERNEL"

	# Hack the ramdisk to run device_infos ASAP to get the key!

	DECRYPTED_RAMDISK=generated_bins/decrypted_components/apple_decrypted_RestoreRamdisk
	WORK_IN_PROGRESS_RAMDISK=generated_bins/hacked_components/Ramdisk.raw
	HACKED_RAMDISK=generated_bins/hacked_components/Ramdisk

	other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_RAMDISK" "$WORK_IN_PROGRESS_RAMDISK"
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" grow 30000000

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/fsck
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/fsck_hfs

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" untar ../Legacy-iOS-Kit/resources/sshrd/ssh.tar
	#other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add ../mods/private/etc/rc.boot private/etc/rc.boot

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add bins/device_infos /var/root/device_infos
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add bins/ioflashstoragekit /var/root/ioflashstoragekit
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add bins/restored_external /var/root/restored_external

	for i in /var/root/{ioflashstoragekit,device_infos,restored_external} /sbin/launchd
	do
		other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" chmod 777 "$i"
	done

	#other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/launchd
#	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add generated_bins/device_infos /sbin/fsck
	other_repos/xpwn/build/ipsw-patch/xpwntool "$WORK_IN_PROGRESS_RAMDISK" "$HACKED_RAMDISK" -t "$DECRYPTED_RAMDISK"
fi


echo Finished getting all parts. Note, if you now re-run the script and something failed the first time it could still be incomplete
