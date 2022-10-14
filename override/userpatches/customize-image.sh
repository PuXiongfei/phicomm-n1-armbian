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
	# modify armbian-install FIRSTSECTOR for phicomm-n1
	# (800 * 1024 * 1024) / 512
	grep FIRSTSECTOR= /usr/sbin/armbian-install
	sed -i s/^FIRSTSECTOR=.*/FIRSTSECTOR=1638400/ /usr/sbin/armbian-install
	grep FIRSTSECTOR= /usr/sbin/armbian-install

	grep FIRSTSECTOR= /usr/sbin/nand-sata-install
	sed -i s/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/ /usr/sbin/nand-sata-install
	grep FIRSTSECTOR= /usr/sbin/nand-sata-install

	# modify exclude.txt /boot for phicomm-n1
	sed -i '/boot/d' /usr/lib/nand-sata-install/exclude.txt
	cat /usr/lib/nand-sata-install/exclude.txt

	# docker
	curl -fsSL https://get.docker.com | sh -

} # Main

Main "$@"
