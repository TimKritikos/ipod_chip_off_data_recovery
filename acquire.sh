#!/bin/sh
set -eu

BUILD=10B500
ipod4_ipsw=$(cat builds/"$BUILD"/url)
json_keyfile=builds/"$BUILD"/index.html

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
	#git clone https://github.com/malus-security/xpwn -b testing
	#cd xpwn
	#echo 'XQAAgAD//////////wAyGkkJwvwRfVDeCk9H1035Ev/ES/io9MOpK8LIvaHA55pdrKDHKLE8jowgaPUD7bLlo2o7cHSRIzbGcB0jmybgMfWnpYElIFJJ4F9+U2nq57Xla1XNKxYCM2ZeF0Nm15DCf8BMC2PsVY73/W/kBIXLskazJAQJoaC6lQglHanZ+IupI8Lw+7dxO1S0uE7xbMFz7aqp+mWflZtrAuwm+7yXA+/G2TzBQd8/827ZwJIRYOHTfby7u13FmhlxhZ+WHf83nHuVcep5JSrunUliHv9swAu8c7YAhEk2CvZUjFqM4rWPeztUltD1TH/Y3Q60wMmfZujT/6mGPCp0w4W0+tuCeIExRoFqK1Fh5Lyi3EiK3Yun/A4M7CBmDMIT2FBDGnQ5MQZhYc7rv1Hpe8fASSJocvv7y3CmkY/nDJ9hcQ9bhz0XuClwa3+tunK/HALD/NKLz7/Z7a208hVQ6HRntitdho6zLSJ1wpQnW7kGo1YGIutT+EEa0keeNpeExHss9yeUqy9liVs5tcYwaqh9lm2+b6DF7JrHklIJMSBefOjRxr7+DEIrQpbWios9reO7jPsbftRD/lODwB92daDrdltwFTksAnBQznb+gSRroABDY4gwTKz9tBNd29HaUUXqw6YQrav5Xm9QQso/oRTsPnNDjhRidm7VklpMziQQYESzkjU2FIyB/zi+p6Gno83wX2lDPUpRzG7wg06i+UwFMhncbokKta3nu5VEDY8L6sXm+WSFL4lycJNyI+3nQGzxwwOerzChM2NhXVZ1VTrdcn0JcYqJvK+4Jbk8/D1/KIGLHBFuq2IFbHJgGxz3QlBmctCE048GKEctN4iEfSYQZp/P9fWu16rlXwn/w5Toxw==' | base64 -d | lzma -d | patch -p1
	#mkdir build
	#cd build
	#cmake ..
	#make -j3
	#cd ../..
	git clone https://github.com/LukeeGD/xpwn
	cd xpwn
	echo 'H4sIAAAAAAAAA51VbW/iRhD+jH/FSJUqgl+wwUAQl9NxwHFUJJGAVqmqylp7x2Z1xrbsJSFX3X/v7hoI4CQ9FVl4PDszO/PsM7OUhSGYZsQ4kCYNt+aWs1gK1hr8C4XGEoo78PH6mrRbltVtOdgiNji23XVdzTTNSgxN1/VqnE+fwHRs1+iALl8uCEWwJnkDxLpXcMLR46kQcpZEdWAJB6WEq4EGGgRpUnDlAI2Dw7Y48Tg4bAvlYMpviv42El+/YEJZqNFX6y7IpidTDE5zPir39ZNeq91xZP2B37dD5436X9wuMHhZkDi0bKMLuvjvCRREehRDliDce59nd8PFn2AfUwZNxx3HPIHTepoNDaAhn9Fi1G4JcChCzrIMKaSixjpJKBBKMo70CsI83QBfI3yPmW86lmO1gTIJmy9ySxPwn+E3JIkZp9sMpoTF8TPICLck/wZDGmNulftB4xxDlhVPZkZ4sG6K0LvsKVEovqbe4xiSjt8OBY4UMeh28RzHVx1LJF9dkli6AkTdPSDJkiDeCjA+lKyw1h8leeZpdItFQSIckTj2SfAN4jQ6yAPNVLySiJMkEYYDTYeKSp3ANE59Eot4c3zEWDFTqmebqD3GIH/O+JwInt7AavH7ZCAOCr4M58sJhGkOH26gR9quY6hFpfooVIHjutBovonsI4kZFY1wCe2L/tCjThC6nZ5l9brdTsv138T2xLMC7smaYmr/2ugLqqqX7FhZYnpLIhbUHzp2Hxo724C95ByllqFBTf7kt7dc3S8m3mj1AI2A7wQ451ovwae6bNpLD0KpF2DO6wVPczRgZ/+UlSOsTGXFRCtc7MUSxuu/ijQMONi3DLCv4OYGnCv4Z+95kbhXIPfCmETF3lct/+F9mQ+n3mx6p8wWs9VsNJwfd3/Z/hFzFj6XWUr/l930d/N8J039P9L8iSz1d7I8S7KEvFbbJgWLEjFjVG9s6F/Lr0NvPJtOlitvPrmbrr7+PTgay7AZyTkj8ZhFWPDTSLVmEx4eHuAJIUERkKcQxiyDyWg2BtWfPor+QFiTYi36WHGx7Tiy18vX/+BirfbjKOWPgoaL5XBfdP1uNvaKNRFeG2pApS4D8oIsWTQmnBzkOSZKPHJShH+dPEEspus2K49+8MbRHYxKGzjL98Q0zBFLph+sfpxPDjkam0UeNMsZmWWivyu6/cQQ86Hdwb5luaEd9IPwfGJUvcppUdWru10dzv5sNNgW4tggIRssMhIgMD9NxT02qK4UnKoLuzqD9zdfdRJr8JgyCivBqs/PHO9zinn9ShME+xcPszPx2wgAAA==' | base64 -d | gzip -d | patch -p1
	mkdir build
	cd build
	cmake ..
	make -j3
	cd ../..
fi

#if ! [ -e bsdiff ]
#then
#	git clone https://github.com/mendsley/bsdiff
#	cd bsdiff
#	./autogen.sh
#	./configure
#	make -j3
#	cd ..
#fi

cd ../bins

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

if ! [ -e bins/decrypted_components ]
then
	mkdir bins/decrypted_components
	for component in iBSS iBEC DeviceTree Kernelcache
	do
		if ! [ -e work/decrypted_apple_"$component" ]
		then
			#Get Apple's keys
			iv=$( jq -r '.keys[] | select(.image == "'"$component"'") | .iv' < "$json_keyfile" )
			key=$( jq -r '.keys[] | select(.image == "'"$component"'") | .key' < "$json_keyfile" )

			#Find the file
			for i in bins/extracted_ipsw/Firmware/dfu/"$component".n81ap.RELEASE.dfu bins/extracted_ipsw/Firmware/all_flash/all_flash.n81ap.production/"$component".n81ap.img3 bins/extracted_ipsw/"$(echo $component | tr K k)".release.n81 end
			do
				if [ "$i" = end ]
				then
					echo "Couldn't find file for $component"
					exit 1
				elif [ -e "$i" ]
				then
					#Decrypt it
					other_repos/xpwn/build/ipsw-patch/xpwntool "$i" bins/decrypted_components/apple_decrypted_"$component" -iv "$iv" -k "$key" -decrypt
					break
				fi
			done
		fi
	done
fi

##########################################
## Remove checks from the iBSS bootloader
##########################################

if ! [ -e bins/hacked_components ]
then
	mkdir bins/hacked_components
	for component in iBSS iBEC
	do
		DECRYPTED_iBSS=bins/decrypted_components/apple_decrypted_"$component"
		      RAW_iBSS=bins/hacked_components/apple_decrypted_"$component".raw
		   HACKED_iBSS=bins/hacked_components/hacked_"$component".raw
		 BOOTABLE_iBSS=bins/hacked_components/hacked_"$component"

		other_repos/xpwn/build/ipsw-patch/xpwntool "$DECRYPTED_iBSS" "$RAW_iBSS"

		if [ "$component" = "iBEC" ]
		then
			bootargs="rd=md0 -v amfi=0xff amfi_get_out_of_my_way=1 cs_enforcement_disable=1 pio-error=0"
		else
			bootargs=""
		fi

		other_repos/iBoot32Patcher/iBoot32Patcher "$RAW_iBSS" "$HACKED_iBSS" --rsa --debug -b "$bootargs"

		other_repos/xpwn/build/ipsw-patch/xpwntool "$HACKED_iBSS" "$BOOTABLE_iBSS" -t "$DECRYPTED_iBSS"
	done
fi

echo All fetched correctly
