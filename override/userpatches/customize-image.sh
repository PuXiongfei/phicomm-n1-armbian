#!/bin/bash

# arguments: $RELEASE $LINUXFAMILY $BOARD $BUILD_DESKTOP
#
# This is the image customization script

# NOTE: It is copied to /tmp directory inside the image
# and executed there inside chroot environment
# so don't reference any files that are not already installed

# NOTE: If you want to transfer files between chroot and host
# userpatches/overlay directory on host is bind-mounted to /tmp/overlay in chroot
# The sd card's root path is accessible via $SDCARD variable.

RELEASE=$1
LINUXFAMILY=$2
BOARD=$3
BUILD_DESKTOP=$4

Main() {
	# modify armbian-install for phicomm-n1
	echo "modify parted SECTOR (800 * 1024 * 1024) / 512"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/armbian-install
	grep "FIRSTSECTOR=" /usr/sbin/armbian-install

	echo "add backup bootloader when armbian-install for phicomm-n1"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck ]] && dd if=$emmccheck of=$DIR/u-boot-default.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot-default.bin ]] && echo "bootloader backup success"' /usr/sbin/armbian-install
	grep "u-boot-default.bin" /usr/sbin/armbian-install

	# modify nand-sata-install for phicomm-n1
	echo "modify parted SECTOR (800 * 1024 * 1024) / 512"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/nand-sata-install
	grep "FIRSTSECTOR=" /usr/sbin/nand-sata-install

	echo "add backup bootloader when nand-sata-install for phicomm-n1"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck ]] && dd if=$emmccheck of=$DIR/u-boot-default.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot-default.bin ]] && echo "bootloader backup success"' /usr/sbin/nand-sata-install
	grep "u-boot-default.bin" /usr/sbin/nand-sata-install

	# modify exclude.txt for phicomm-n1
	echo "copy /boot for phicomm-n1"
	sed -i '/boot/d' /usr/lib/nand-sata-install/exclude.txt
	cat /usr/lib/nand-sata-install/exclude.txt

	# install docker
	echo "install docker"
	curl -fsSL https://get.docker.com | sh -

} # Main

Main "$@"
