#!/bin/bash
set -e
#####################################
# by: Qitas
# Date: 2019-03-14
## ARM V8 compile toolchain
#####################################

if [ -z $TOOT ]; then
	ROOT=`cd .. && pwd`
fi

TOOLS="$ROOT/toolchain"
TOOLTARXZ="$ROOT/toolchain/toolchain_tar/toolchain"
TOOLTAR="$ROOT/toolchain/toolchain.tar.gz"
UBOOTTAR="$ROOT/toolchain/uboot-tools.tar.gz"
UBOOTTARXZ="$ROOT/toolchain/u-boot-compile-tools"
UBOOTS="$TOOLS/gcc-linaro-aarch"

whiptail --title "ARM V8 Build System" --msgbox "Installing Cross-Tools. Pls wait a mount." --ok-button Continue 10 40 0

clear
if [ ! -d $TOOLS/gcc-linaro-aarch ]; then
	echo -e "\e[1;31m Uncompress toolchain.. \e[0m"
	cat ${TOOLTARXZ}* > ${TOOLTAR}

	tar xzf $TOOLTAR -C $TOOLS 
	rm -rf $TOOLTAR 
fi

if [ -d $ROOT/toolchain/gcc-linaro-aarch/arm-linux-gnueabihf ]; then
	rm -rf $ROOT/toolchain/gcc-linaro-aarch/gcc-linaro
fi

if [ ! -d $TOOLS/gcc-linaro-aarch/arm-linux-gnueabi ]; then
	cat ${UBOOTTARXZ}* > ${UBOOTTAR}

	tar xzf $UBOOTTAR -C $UBOOTS
	rm -rf $UBOOTTAR 
        rm -rf $TOOLS/toolchain_tar
fi

whiptail --title "ARM V8 Build System" --msgbox "Cross-Tools has installed." 10 40 0
