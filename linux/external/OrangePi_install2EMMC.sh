#!/bin/bash

if [ "$(id -u)" != "0" ]; then
   echo "Script must be run as root !"
   exit 0
fi


_format=${1}

fatsize=64

sdcard="/dev/mmcblk0"
odir="/tmp/_extdir"
bootdir="/tmp/_fatdir"

if [ ! -b ${sdcard}boot0 ]; then
    echo "Error: EMMC not found."
    exit 1
fi
if [ ! -f /opt/boot/boot0.bin ]; then
    echo "Error: /opt/boot/boot0.bin not found."
    exit 1
fi
if [ ! -f /opt/boot/uboot.bin ]; then
    echo "Error: /opt/boot/uboot.bin not found."
    exit 1
fi

umount ${sdcard}* > /dev/null 2>&1
#----------------------------------------------------------
echo ""
echo -n "WARNING: EMMC WILL BE ERASED !, Continue (y/N)?  "
read -n 1 ANSWER

if [ ! "${ANSWER}" = "y" ] ; then
    echo "."
    echo "Canceled.."
    exit 0
fi
echo ""
#----------------------------------------------------------

echo "Erasing EMMC ..."
dd if=/dev/zero of=${sdcard} bs=1M count=32 > /dev/null 2>&1
sync
sleep 1

echo "Creating new filesystem on EMMC ..."
echo -e "o\nw" | fdisk ${sdcard} > /dev/null 2>&1
sync
echo "  New filesystem created on $sdcard."
sleep 1
partprobe -s ${sdcard} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR."
    exit 1
fi
sleep 1

echo "Partitioning EMMC ..."
sfat=40960
efat=$(( $fatsize * 1024 * 1024 / 512 + $sfat - 1))
echo "  Creating boot & linux partitions"
sext4=$(( $efat + 1))
eext4=""
echo -e "n\np\n1\n$sfat\n$efat\nn\np\n2\n$sext4\n$eext4\nt\n1\nb\nt\n2\n83\nw" | fdisk ${sdcard} > /dev/null 2>&1
echo "  OK."
sync
sleep 2
partprobe -s ${sdcard} > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR."
    exit 1
fi
sleep 1

echo "Formating fat partition ..."
dd if=/dev/zero of=${sdcard}p1 bs=1M count=1 oflag=direct > /dev/null 2>&1
sync
sleep 1
mkfs.vfat -n EMMCBOOT ${sdcard}p1 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "  ERROR formating fat partition."
    exit 1
fi
echo "  fat partition formated."

dd if=/dev/zero of=${sdcard}p2 bs=1M count=1 oflag=direct > /dev/null 2>&1
sync
sleep 1

echo "Formating linux partition (ext4), please wait ..."
mkfs.ext4 -L emmclinux ${sdcard}p2 > /dev/null 2>&1
if [ $? -ne 0 ]; then
	echo "ERROR formating ext4 partition."
    exit 1
fi
echo "  linux partition formated."

#************************************************************************
echo ""
echo "Instaling u-boot to EMMC ..."
dd if=/opt/boot/boot0.bin of=${sdcard} bs=1k seek=8 > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR installing u-boot."
    exit 1
fi
dd if=/opt/boot/uboot.bin of=${sdcard} bs=1k seek=16400 > /dev/null 2>&1
if [ $? -ne 0 ]; then
echo "ERROR installing u-boot."
exit 0
fi
sync
#************************************************************************

# -------------------------------------------------------------------
    
if [ ! -d $bootdir ]; then
    mkdir -p $bootdir
fi
rm $bootdir/* > /dev/null 2>&1
sync
umount $bootdir > /dev/null 2>&1

if [ ! -d $odir ]; then
    mkdir -p $odir
fi
rm -rf $odir/* > /dev/null 2>&1
sync
umount $odir > /dev/null 2>&1
sleep 1

# ================
# MOUNT PARTITIONS
# ================

_mntopt=""

echo ""
echo "Mounting EMMC partitions..."

if ! mount ${sdcard}p1 $bootdir; then
    echo "ERROR mounting fat partitions..."
    exit 1
fi
if ! mount ${_mntopt} ${sdcard}p2 $odir; then
    echo "ERROR mounting linux partitions..."
    umount $bootdir
    exit 1
fi
echo "FAT partitions mounted to $bootdir"
echo "linux partition mounted to $odir"


#-----------------------------------------------------------------------------------------------
echo ""
echo "Copying file system to EMMC ..."
echo ""

#-----------------------------------------------------------------------------------------
rsync -r -t -p -o -g -x --delete -l -H -D --numeric-ids -s --stats / $odir/ > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "  ERROR."
fi
#-----------------------------------------------------------------------------------------
sync

echo "  Creating \"fstab\""
echo "# OrangePI fstab" > $odir/etc/fstab
if [ "${_format}" = "btrfs" ] ; then
    echo "/dev/mmcblk0p2  /  btrfs subvolid=0,noatime,nodiratime,compress=lzo  0 1" >> $odir/etc/fstab
else
    echo "/dev/mmcblk0p2  /  ext4  errors=remount-ro,noatime,nodiratime  0 1" >> $odir/etc/fstab
fi
echo "/dev/mmcblk0p1  /media/boot  vfat  defaults  0 0" >> $odir/etc/fstab
echo "tmpfs /tmp  tmpfs nodev,nosuid,mode=1777  0 0" >> $odir/etc/fstab
sync

#-----------------------------------------------------------------------------------------
rsync -r -t -p -o -g -x --delete -l -H -D --numeric-ids -s --stats /boot/ $bootdir/ > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "  ERROR."
fi
#-----------------------------------------------------------------------------------------

cp /opt/boot/uEnv.txt $bootdir/ 

sync


# UMOUNT
if ! umount $bootdir; then
  echo "ERROR unmounting fat partition."
  exit 1
fi
rm -rf $bootdir/* > /dev/null 2>&1
rmdir $bootdir > /dev/null 2>&1

if ! umount $odir; then
    echo "ERROR unmounting linux partitions."
    exit 0
fi

rm -rf $odir/* > /dev/null 2>&1
rmdir $odir > /dev/null 2>&1
sync

echo ""
echo -e "\033[36m*******************************"
echo "Linux system installed to EMMC."
echo -e "*******************************\033[37m"
setterm -default
echo ""

exit 0
