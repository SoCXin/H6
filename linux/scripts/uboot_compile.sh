#!/bin/bash
set -e
#################################
##
## Compile U-boot
## This script will compile u-boot and merger with scripts.bin, bl31.bin and dtb.
#################################
# ROOT must be top direct.
if [ -z $ROOT ]; then
	ROOT=`cd .. && pwd`
fi
# PLATFORM.
if [ -z $PLATFORM ]; then
	PLATFORM="OnePlus"
fi
# Uboot direct
UBOOT=$ROOT/uboot
# Compile Toolchain
TOOLS=$ROOT/toolchain/gcc-linaro-aarch/gcc-linaro/bin/arm-linux-gnueabihf-
KERNEL=${ROOT}/kernel
DTC_COMPILER=${KERNEL}/scripts/dtc/dtc

BUILD=$ROOT/output
CORES=$((`cat /proc/cpuinfo | grep processor | wc -l` - 1))
if [ $CORES -eq 0 ]; then
	CORES=1
fi

# Perpar souce code
if [ ! -d $UBOOT ]; then
	whiptail --title "OrangePi Build System" \
		--msgbox "u-boot doesn't exist, pls perpare u-boot source code." \
		10 50 0
	exit 0
fi

cd $UBOOT
clear
echo "Compile U-boot......"
if [ ! -f $UBOOT/u-boot-sun50iw6p1.bin ]; then
	make  sun50iw6p1_config
fi
make -j8
echo "Complete compile...."

echo "Compile boot0......"
if [ ! -f $UBOOT/sunxi_spl/boot0/boot0_sdcard.bin ]; then
	make  sun50iw6p1_config
fi
make spl 
cd -
#####################################################################
###
### Merge uboot with different binary
#####################################################################

if [ ! -f $DTC_COMPILER ]; then
	echo " "
	echo -e "\e[1;31m ================================================\e[0m"
	echo -e "\e[1;31m In order to merge uboot with different binary,\e[0m"
	echo -e "\e[1;31m you have to compile the kernel first!!!\e[0m"
	echo -e "\e[1;31m ================================================\e[0m"
	echo " "

	whiptail --title "OrangePi Build System" --msgbox \
		"In order to merge uboot with different binary, you have to compile the kernel first!!!" \
		10 60 0 --cancel-button Exit
else
	cd $ROOT/scripts/pack/
	chmod 777 pack
	./pack

	###
	# Cpoy output file
	cp $ROOT/output/pack/out/boot0_sdcard.fex $ROOT/output/boot0.bin
	cp $ROOT/output/pack/out/boot_package.fex $ROOT/output/uboot.bin

	#rm -rf $ROOT/output/pack

	# Change to scripts direct.
	cd -

	echo " "
	echo -e "\e[1;31m =======================================\e[0m"
	echo -e "\e[1;31m         Complete compile....		 \e[0m"
	echo -e "\e[1;31m =======================================\e[0m"
	echo " "

	whiptail --title "OrangePi Build System" \
		--msgbox "Build uboot finish. The output path: $BUILD" 10 60 0
fi
