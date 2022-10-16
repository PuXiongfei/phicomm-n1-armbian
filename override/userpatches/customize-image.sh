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
	# phicomm-n1 use mainline u-boot to overload boot
	if [[ -f /usr/lib/u-boot/platform_install.sh ]]; then
		DIR=$(grep "DIR" /usr/lib/u-boot/platform_install.sh | awk -F '=' '{print $2}')
		echo "u-boot path: $DIR"
		# rename $DIR/u-boot.bin to u-boot-mainline.bin
		echo "rename $DIR/u-boot.bin to u-boot-mainline.bin"
		mv -f $DIR/u-boot.bin $DIR/u-boot-mainline.bin
		# copy $DIR/u-boot-mainline.bin to /boot/u-boot.bin
		echo "copy $DIR/u-boot-mainline.bin to /boot/u-boot.bin"
		cp -af $DIR/u-boot-mainline.bin /boot/u-boot.bin
	fi

	# modify armbian-install for phicomm-n1
	echo "modify parted SECTOR (800 * 1024 * 1024) / 512"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/armbian-install
	grep "FIRSTSECTOR=" /usr/sbin/armbian-install

	echo "add backup bootloader when armbian-install for phicomm-n1"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck ]] && dd if=$emmccheck of=$DIR/u-boot.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot.bin ]] && echo "bootloader backup $DIR/u-boot.bin"' /usr/sbin/armbian-install
	grep "u-boot.bin" /usr/sbin/armbian-install

	# modify nand-sata-install for phicomm-n1
	echo "modify parted SECTOR (800 * 1024 * 1024) / 512"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/nand-sata-install
	grep "FIRSTSECTOR=" /usr/sbin/nand-sata-install

	echo "add backup bootloader when nand-sata-install for phicomm-n1"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck ]] && dd if=$emmccheck of=$DIR/u-boot.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot.bin ]] && echo "bootloader backup $DIR/u-boot.bin"' /usr/sbin/nand-sata-install
	grep "u-boot.bin" /usr/sbin/nand-sata-install

	# modify exclude.txt for phicomm-n1
	echo "include /boot for phicomm-n1"
	sed -i '/boot/d' /usr/lib/nand-sata-install/exclude.txt
	cat /usr/lib/nand-sata-install/exclude.txt

	# install docker
	echo "install docker"
	curl -fsSL https://get.docker.com | sh -

} # Main

Main "$@"
