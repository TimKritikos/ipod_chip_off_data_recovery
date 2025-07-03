#!/bin/sh
set -eu

##IMPORTANT: CHANGE THIS:
PYTHON2=~/python2.7_for_ios-data/AppRun
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
	./autogen.sh
	make -j3
	cd ..
fi

if ! [ -e primepwn ]
then
	git clone https://github.com/LukeZGD/primepwn
	cd primepwn
	git checkout 02d4f7bb0478fd401187b1142d4c965e4d3acc70
	#patch to make the project compile
	echo 'XQAAgAD//////////wAW6AQNp5MiqdGiG5emIt0zhK3sN60zPkM3EytixETdSu+N7Knjkkokc8EvDC9IZc4KjWcbsoy1luP8+Z1ru/jt0SnzJbPolzttHDtY4ocho+CvVCzXEgy7R1YMuzQpOvR7hCbFzAAhi6hJEPxtNcHQm5kurGO2BOe65FPpOTu3KOa6Fy7kaBK/GJulUXbiZda2FT49917NnRsyryEMb8Ok0v16oMsb6K/bxYGuTWwKTTcMu8GZvyTrwTkbVdIhS9OFbfK68zw9njzR1HNmCUPw2SZ01Vzo8ia4HvtGVdLw/iynlDDny+/yuSh5SlVxE8RHGdhIZHIYmQ35wZQdXagS34pvqxcu3OEBEuAcLIHj5YeSPT/Hh64KMbOV7567gAgF1sBmGURRPWJINNZtHsBm11BgNJUcNW+f7nOxrQo64Wg/gi3K7zQQ6OZqu/9NhhdTMXILm/9vHvFhTRiG6vkutQxq/ZZ4ZN+13ELG/a2/vm4YrnqyxFl0bl4CcG6YFs5fnn+njYqfR3Mui+Oh053tbqeiKPm2vxdlKAZhy/a6tff+IDqIgogIOsLc9pcU7zwh8yeRFRtEcw4H1nzBjYYbWMND6gtSF6L8aNgnMm8Io6+pJe0N/qmIEEayFKLXXveNSzbl8qtDZyGXeifFlEHz1kZ9b+Yp7rIlwFOF3fIzOwD9GO9O+PtH7fuci/ybg0rdmceqFclA2g+DGOFj/AmF7RsLbGnEV72937O7UxucHhBkIJc3B3+1/XzqjrmJcFNUpgMrRXF63MIhTuOD0PwWz/kxyzhnQxNbLfeiQjzv3gTqk1YRAPJhiFfbR3W4pzQ6It4ebw8yB4e3WnElw86b411C23zLtAW/p25BvBbvv2ovqptx/0btUvrYEq6u1s9WI0M9llFdgR6SBU8LrM1+sFMkgQe+sJrGYVRonQ7LZTGO8fkWGI58rBZVEdSPfaCo6sLWX57W/kXOWdz16ZlaIOTvJzP1YCiD6xBBm93I6EiqhIk8hZM7TmXccazSN8Ze3PZwuiEEcfcEcPQJ7QB+TObKP0v15tiwRyQsLpA0HHuCng+d+ow0y9Z+djTR+GzIvJF6P2pldvEYDN+jIg2ooTUgC60kMPmwDYMva+KQg2En7e/19UJizygFj1zq2+SA95aiqJ25BfSZytfzlyFjJEclwiqxWFnKpS0vR7gPeCPSB6TfUvxSKHiBq8Z3UKm1wh8f0uMFlzI9zdew5rRPjq07tJ3j06xjOP2yX3eJz74j5WhYP1vS34FsAlEugoXD6on3oM74cApM1VP2fFJ8s6o7s7C6R9vHG/NNvoho1A17FQtPF6I/UnDkuD2oQSCy/GuIpLGmc9YiFPUGZ9TjfMIF3Si14DlING84cvqeIgaaJ6EL5v7ela8v1cGmpU97PivPfV+Vyr24sNangt9BVnqDBD4MA4j1volDx+arBisxqGVU6h2LCZgo3FVY5xxrLLK2CwCXU+ra7udoi3cIB7U6oWRfZ9OzaU78KojTNjAkN5Rn1cXrk7l5ARFuO5Qkq1yIZwxGXP21grM5bZzmbzgigJCrSUvJY+6Ev7Yswo9QeyNKKIJ0U22qEoWg1gUWqr0pHTYvMkhmYUWDeTZo9cev8d860SpEIMFZ7vR/wa/9h/oqWDCz3r/W/48m7UWnknDH/UlgH+j3cN01eRMnNNAziRe4Jq366zn486Vo/6bC1c4=' | base64 -d |lzma -d |  patch -p0

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
	git clone https://github.com/LukeeGD/xpwn
	cd xpwn
	git checkout d1d2d3da2081b197b2946f2699d68b2a4acfbfb2
	#Patch to make the project compile
	echo 'H4sIAAAAAAAAA51VbW/iRhD+jH/FSJUqgl+wwUAQl9NxwHFUJJGAVqmqylp7x2Z1xrbsJSFX3X/v7hoI4CQ9FVl4PDszO/PsM7OUhSGYZsQ4kCYNt+aWs1gK1hr8C4XGEoo78PH6mrRbltVtOdgiNji23XVdzTTNSgxN1/VqnE+fwHRs1+iALl8uCEWwJnkDxLpXcMLR46kQcpZEdWAJB6WEq4EGGgRpUnDlAI2Dw7Y48Tg4bAvlYMpviv42El+/YEJZqNFX6y7IpidTDE5zPir39ZNeq91xZP2B37dD5436X9wuMHhZkDi0bKMLuvjvCRREehRDliDce59nd8PFn2AfUwZNxx3HPIHTepoNDaAhn9Fi1G4JcChCzrIMKaSixjpJKBBKMo70CsI83QBfI3yPmW86lmO1gTIJmy9ySxPwn+E3JIkZp9sMpoTF8TPICLck/wZDGmNulftB4xxDlhVPZkZ4sG6K0LvsKVEovqbe4xiSjt8OBY4UMeh28RzHVx1LJF9dkli6AkTdPSDJkiDeCjA+lKyw1h8leeZpdItFQSIckTj2SfAN4jQ6yAPNVLySiJMkEYYDTYeKSp3ANE59Eot4c3zEWDFTqmebqD3GIH/O+JwInt7AavH7ZCAOCr4M58sJhGkOH26gR9quY6hFpfooVIHjutBovonsI4kZFY1wCe2L/tCjThC6nZ5l9brdTsv138T2xLMC7smaYmr/2ugLqqqX7FhZYnpLIhbUHzp2Hxo724C95ByllqFBTf7kt7dc3S8m3mj1AI2A7wQ451ovwae6bNpLD0KpF2DO6wVPczRgZ/+UlSOsTGXFRCtc7MUSxuu/ijQMONi3DLCv4OYGnCv4Z+95kbhXIPfCmETF3lct/+F9mQ+n3mx6p8wWs9VsNJwfd3/Z/hFzFj6XWUr/l930d/N8J039P9L8iSz1d7I8S7KEvFbbJgWLEjFjVG9s6F/Lr0NvPJtOlitvPrmbrr7+PTgay7AZyTkj8ZhFWPDTSLVmEx4eHuAJIUERkKcQxiyDyWg2BtWfPor+QFiTYi36WHGx7Tiy18vX/+BirfbjKOWPgoaL5XBfdP1uNvaKNRFeG2pApS4D8oIsWTQmnBzkOSZKPHJShH+dPEEspus2K49+8MbRHYxKGzjL98Q0zBFLph+sfpxPDjkam0UeNMsZmWWivyu6/cQQ86Hdwb5luaEd9IPwfGJUvcppUdWru10dzv5sNNgW4tggIRssMhIgMD9NxT02qK4UnKoLuzqD9zdfdRJr8JgyCivBqs/PHO9zinn9ShME+xcPszPx2wgAAA==' | base64 -d | gzip -d | patch -p1
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
	echo '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' | base64 -d | gzip -d | patch -p1
	#Patch kernel_patcher to also apply the IOFlashControllerUserClient::externalMethod patch
	echo 'H4sIAAAAAAAAA7VU227TQBB9z1cM4aVVLt31ZS+RKtV2YtEHaAVUPCBkOfaaWA22ZbtqIn6emXVCaYHSFyxrNDs7e86Z3dnNy6KA2exr2UN61uz7TV0lXdaWTd+d3Zq2MtukSftsY9p5s4f1P1NGZZWbHehMGM/o+bwwmW9EDpwx6fuj2Wz2Ap7RZDJ5CdfFBcxcNhUwQSsBh5dXcZRcBx+jN8nlu/gKzuH7COgbl9eIZdwpT8ScJZwFHnOT96br69bMy6a7Hy/gM9uhaLXOp0Ae08ojL1VkHT8zmR0XRe5mvut/mT7Bdv4jtvs8ttT5AVtq76/YqVID9mTAburcO65XKuV2vYq1eLTeOJ4dx3GgVmpptQ3qXld1D91d09Rtb3JY76E1eVexe9ib/reNl1QADzzh/6EA7UiVukSjuUkzS51aWlWINRv0S2e9znPktyev7MnrZ07eBm3D4HhzMo4ZhD5oASGDZQyxAh2RH4fgecA88AQsBQgNjIHjw9KhHJeBZMA4OA75QpGvbZB8Rj7NonWt74D2QXKQAXAOsZ1lMXDkioFpcLjNQetTJlNkMZP82Nqltd4BOUAWQT7SoUIWko86V5oYMWHlgohhibMSmDxq04QcIt2KViH+ilGxFLe1EMsxM+Rkf8VxtOXyyToBUQ+7oRVViguJS9Csy2lWaRAhqEFDRAkBIzSsNAiIkRA4IeBWu67dYU5omB9JimOEfknBId+LSFVgufiKROL+I+MQcdSDT2gMuD1ZOuXl+JSaNDcF2PNPsBW2abeJ6qpv6+3WtDedaaNtaao+Mbse35Z0+9bgg5OfUFNW6TczheHJOV0M9+UYPz9cnKHBywLoFjzpv/km7ZJbs/8JhiBw/Jq2rHoY31QPV+fy+sMnKOoWntG5WDwWOlQGr8YPyK3p79rqoHv0A6JNk6HdBQAA' | base64 -d | gzip -d | patch -p1
	cd ../
fi

cd ..

if ! [ -e bins ]
then
	mkdir bins
fi
cd bins

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
	infile=bins/extracted_ipsw/"$1"
	name="$2"
	outfile=bins/decrypted_components/apple_decrypted_"$name"

	iv=$( jq -r '.keys[] | select(.image == "'"$name"'") | .iv' < "$json_keyfile" )
	key=$( jq -r '.keys[] | select(.image == "'"$name"'") | .key' < "$json_keyfile" )

	if [ "$iv" = "" ] || [ "$key" = "" ]
	then
		p 'Error, couldnt find key for component '"$name"
	fi

	other_repos/xpwn/build/ipsw-patch/xpwntool "$infile" "$outfile" -iv "$iv" -k "$key" -decrypt
}

if ! [ -e bins/decrypted_components ]
then
	mkdir bins/decrypted_components

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

if ! [ -e bins/hacked_components ]
then
	mkdir bins/hacked_components

	# Remove security checks from iBSS and iBEC

	for component in iBSS iBEC
	do
		DECRYPTED_iBSS=bins/decrypted_components/apple_decrypted_"$component"
		      RAW_iBSS=bins/hacked_components/apple_decrypted_"$component".raw
		   HACKED_iBSS=bins/hacked_components/hacked_"$component".raw
		 BOOTABLE_iBSS=bins/hacked_components/hacked_"$component"

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

	DECRYPTED_KERNEL=bins/decrypted_components/apple_decrypted_Kernelcache
	RAW_KERNEL=bins/hacked_components/KernelCache.raw
	PATCHED_KERNEL=bins/hacked_components/KernelCache.patched
	KERNEL_MYPATCHES=bins/hacked_components/KernelCache.my_patches
	BOOTABLE_KERNEL=bins/hacked_components/KernelCache

	other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_KERNEL" "$RAW_KERNEL"
	"$PYTHON2" other_repos/iphone-dataprotection/python_scripts/kernel_patcher.py "$RAW_KERNEL" "$PATCHED_KERNEL"
	bspatch "$PATCHED_KERNEL" "$KERNEL_MYPATCHES" bins/no-crash-no-mount+others.bspatch
	other_repos/xpwn/build/ipsw-patch/xpwntool "$KERNEL_MYPATCHES" "$BOOTABLE_KERNEL" -t "$DECRYPTED_KERNEL"

	# Hack the ramdisk to run device_infos ASAP to get the key!

	DECRYPTED_RAMDISK=bins/decrypted_components/apple_decrypted_RestoreRamdisk
	WORK_IN_PROGRESS_RAMDISK=bins/hacked_components/Ramdisk.raw
	HACKED_RAMDISK=bins/hacked_components/Ramdisk

	other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_RAMDISK" "$WORK_IN_PROGRESS_RAMDISK"
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" grow 30000000

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/fsck
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/fsck_hfs

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" untar /home/user/Legacy-iOS-Kit/resources/sshrd/ssh.tar
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add /home/user/mods/private/etc/rc.boot private/etc/rc.boot

	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add /home/user/customhacks/bins/device_infos /var/root/device_infos
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add /home/user/customhacks/bins/ioflashstoragekit /var/root/ioflashstoragekit
	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add /home/user/customhacks/bins/restored_external /var/root/restored_external

	for i in /var/root/{ioflashstoragekit,device_infos,restored_external}  private/etc/rc.boot /sbin/launchd
	do
		other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" chmod 777 "$i"
	done

	#other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" rm /sbin/launchd
#	other_repos/xpwn/build/hfs/hfsplus "$WORK_IN_PROGRESS_RAMDISK" add bins/device_infos /sbin/fsck
	other_repos/xpwn/build/ipsw-patch/xpwntool "$WORK_IN_PROGRESS_RAMDISK" "$HACKED_RAMDISK" -t "$DECRYPTED_RAMDISK"
fi


echo All fetched correctly
