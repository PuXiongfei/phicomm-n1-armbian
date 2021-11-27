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
	# timezone
	ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
	dpkg-reconfigure -f noninteractive tzdata
	# fonts-noto-cjk
	apt install -y fonts-noto-cjk
	# en_US.UTF-8 Locales settings
	if ! grep -q "^en_US.UTF-8 UTF-8" /etc/locale.gen; then
		sed -i 's/# en_US.UTF-8/en_US.UTF-8/' /etc/locale.gen
		locale-gen
	fi

} # Main

Main "$@"
