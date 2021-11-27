#!/bin/sh

echo "Fix Wlan Mac"
if [ -x /root/fixwlanmac.sh ]; then
	/root/fixwlanmac.sh
fi

echo "Start script create MBR and filesystem"

hasdrives=$(lsblk | grep -oE '(mmcblk[0-9])' | sort | uniq)
if [ "$hasdrives" = "" ]
then
	echo "UNABLE TO FIND ANY EMMC OR SD DRIVES ON THIS SYSTEM!!! "
	exit 1
fi
avail=$(lsblk | grep -oE '(mmcblk[0-9]|sda[0-9])' | sort | uniq)
if [ "$avail" = "" ]
then
	echo "UNABLE TO FIND ANY DRIVES ON THIS SYSTEM!!!"
	exit 1
fi
runfrom=$(lsblk | grep /$ | grep -oE '(mmcblk[0-9]|sda[0-9])')
if [ "$runfrom" = "" ]
then
	echo " UNABLE TO FIND ROOT OF THE RUNNING SYSTEM!!! "
	exit 1
fi
emmc=$(echo $avail | sed "s/$runfrom//" | sed "s/sd[a-z][0-9]//g" | sed "s/ //g")
if [ "$emmc" = "" ]
then
	echo " UNABLE TO FIND YOUR EMMC DRIVE OR YOU ALREADY RUN FROM EMMC!!!"
	exit 1
fi
if [ "$runfrom" = "$avail" ]
then
	echo " YOU ARE RUNNING ALREADY FROM EMMC!!! "
	exit 1
fi
if [ $runfrom = $emmc ]
then
	echo " YOU ARE RUNNING ALREADY FROM EMMC!!! "
	exit 1
fi
if [ "$(echo $emmc | grep mmcblk)" = "" ]
then
	echo " YOU DO NOT APPEAR TO HAVE AN EMMC DRIVE!!! "
	exit 1
fi

DEV_EMMC="/dev/$emmc"

echo $DEV_EMMC

echo "Start backup u-boot default"

dd if="${DEV_EMMC}" of=/root/u-boot-default-aml.img bs=1M count=4

echo "Start create MBR and partittion"

parted -s "${DEV_EMMC}" mklabel msdos
parted -s "${DEV_EMMC}" mkpart primary ext4 700M 100%

echo "Start restore u-boot"

dd if=/root/u-boot-default-aml.img of="${DEV_EMMC}" conv=fsync bs=1 count=442
dd if=/root/u-boot-default-aml.img of="${DEV_EMMC}" conv=fsync bs=512 skip=1 seek=1

sync

echo "Done"

echo "Start copy system for eMMC."

mkdir -p /ddbr
chmod 777 /ddbr

PART_ROOT="${DEV_EMMC}p1"
DIR_INSTALL="/ddbr/install"

if [ -d $DIR_INSTALL ] ; then
    rm -rf $DIR_INSTALL
fi
mkdir -p $DIR_INSTALL

if grep -q $PART_ROOT /proc/mounts ; then
    echo "Unmounting ROOT partiton."
    umount -f $PART_ROOT
fi

echo "Formatting ROOT partition..."
node_number=
mkfs.ext4 -F -q -m 2 -O ^64bit,^metadata_csum -N $((128*${node_number})) $PART_ROOT
tune2fs -o journal_data_writeback $PART_ROOT
echo "done."

echo "Copying ROOTFS."

mount -o rw $PART_ROOT $DIR_INSTALL

cd /
echo "Copy BIN"
tar -cf - bin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy BOOT"
mkdir -p $DIR_INSTALL/boot
tar -cf - boot | (cd $DIR_INSTALL; tar -xpf -)
echo "Create DEV"
mkdir -p $DIR_INSTALL/dev
#tar -cf - dev | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy ETC"
tar -cf - etc | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy HOME"
tar -cf - home | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy LIB"
tar -cf - lib | (cd $DIR_INSTALL; tar -xpf -)
#echo "Copy LIB64"
#tar -cf - lib64 | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MEDIA"
mkdir -p $DIR_INSTALL/media
#tar -cf - media | (cd $DIR_INSTALL; tar -xpf -)
echo "Create MNT"
mkdir -p $DIR_INSTALL/mnt
#tar -cf - mnt | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy OPT"
tar -cf - opt | (cd $DIR_INSTALL; tar -xpf -)
echo "Create PROC"
mkdir -p $DIR_INSTALL/proc
echo "Copy ROOT"
tar -cf - root | (cd $DIR_INSTALL; tar -xpf -)
echo "Create RUN"
mkdir -p $DIR_INSTALL/run
echo "Copy SBIN"
tar -cf - sbin | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SELINUX"
tar -cf - selinux | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy SRV"
tar -cf - srv | (cd $DIR_INSTALL; tar -xpf -)
echo "Create SYS"
mkdir -p $DIR_INSTALL/sys
echo "Create TMP"
mkdir -p $DIR_INSTALL/tmp
echo "Copy USR"
tar -cf - usr | (cd $DIR_INSTALL; tar -xpf -)
echo "Copy VAR"
tar -cf - var | (cd $DIR_INSTALL; tar -xpf -)
sync

echo "Edit fstab"
ROOT_UUID=$(blkid -s UUID -o value $PART_ROOT)
sed -e "s/.*rootdev=.*/rootdev=UUID=${ROOT_UUID}/g" \
 -i "$DIR_INSTALL/boot/armbianEnv.txt"
echo "UUID=${ROOT_UUID} / ext4 defaults,noatime,commit=600,errors=remount-ro 0 1" > $DIR_INSTALL/etc/fstab
echo "tmpfs /tmp tmpfs defaults,nosuid 0 0" >> $DIR_INSTALL/etc/fstab
echo "Done"

rm -r $DIR_INSTALL/boot/'System Volume Information'
rm $DIR_INSTALL/boot/s9*
rm $DIR_INSTALL/boot/aml*
rm $DIR_INSTALL/root/*.sh
rm $DIR_INSTALL/usr/bin/ddbr

cd /
sync

umount $DIR_INSTALL

echo "*******************************************"
echo "Complete copy OS to eMMC "
echo "*******************************************"
