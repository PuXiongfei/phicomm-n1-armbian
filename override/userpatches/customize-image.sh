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
	# X11 config file in meson64_common.inc
	cat <<-EOF >$SDCARD/etc/X11/xorg.conf.d/02-driver.conf
		Section "OutputClass"
		    Identifier "Amlogic"
		    MatchDriver "meson"
		    Driver "modesetting"
		    Option "PrimaryGPU" "true"
		EndSection
		Section "Screen"
		    Identifier      "Default Screen"
		    Device          "Meson"
		    Monitor         "foo"
		    DefaultDepth  24
		    SubSection "Display"
		       Depth    24
		       Modes    "1920x1080" "1440x900" "1280x720" "1280x1024" "1280x960" "1024x768" "800x600" "640x480" "720x400"
		    EndSubSection
		EndSection
	EOF

	cat <<-EOF >$SDCARD/etc/X11/xorg.conf
		Section "Device"
		    Identifier  "DRM Graphics Acclerated"

		    ## Use modesetting and glamor
		        Driver      "modesetting"
		        Option      "AccelMethod"    "glamor"     ### "glamor" to enable 3D acceleration, "none" to disable.
		        Option      "DRI"            "2"
		        Option      "Dri2Vsync"      "true"
		        Option      "TripleBuffer"   "True"
		    ## End glamor configuration

		    EndSection

		    Section "Screen"
		        Identifier "Default Screen"
		            SubSection "Display"
		                Depth 24
		            EndSubSection
		        EndSection
	EOF

	# copy some file for phicomm-n1
	mkimage -C none -A arm -T script -d /tmp/overlay/boot-env_default.cmd $SDCARD/boot/aml_env_default
	mkimage -C none -A arm -T script -d /tmp/overlay/boot-aml_autoscript.cmd $SDCARD/boot/aml_autoscript
	mkimage -C none -A arm -T script -d /tmp/overlay/boot-emmc_autoscript.cmd $SDCARD/boot/emmc_autoscript
	mkimage -C none -A arm -T script -d /tmp/overlay/boot-s905_autoscript.cmd $SDCARD/boot/s905_autoscript

	install -m 664 /tmp/overlay/BCM4345C0.hcd $SDCARD/usr/lib/firmware/brcm/BCM4345C0.hcd
	install -m 664 /tmp/overlay/cyfmac43455-sdio-standard.bin $SDCARD/usr/lib/firmware/brcm/brcmfmac43455-sdio.bin
	install -m 664 /tmp/overlay/cyfmac43455-sdio-standard.bin $SDCARD/usr/lib/firmware/brcm/brcmfmac43455-sdio.phicomm,n1.bin
	install -m 664 /tmp/overlay/cyfmac43455-sdio.clm_blob $SDCARD/usr/lib/firmware/brcm/brcmfmac43455-sdio.clm_blob
	install -m 664 /tmp/overlay/brcmfmac43455-sdio.txt $SDCARD/usr/lib/firmware/brcm/brcmfmac43455-sdio.txt
	install -m 664 /tmp/overlay/brcmfmac43455-sdio.txt $SDCARD/usr/lib/firmware/brcm/brcmfmac43455-sdio.phicomm,n1.txt

	if [[ $RELEASE == "bullseye" ]]; then
		install -m 664 /tmp/overlay/regulatory.db $SDCARD/usr/lib/firmware/regulatory.db-debian
		install -m 664 /tmp/overlay/regulatory.db.p7s $SDCARD/usr/lib/firmware/regulatory.db.p7s-debian
	fi

	install -m 755 /tmp/overlay/fixwlanmac.sh $SDCARD/root/fixwlanmac.sh

	# phicomm-n1 use mainline u-boot to overload boot
	if [[ -f /usr/lib/u-boot/platform_install.sh ]]; then
		DIR=$(grep "DIR" /usr/lib/u-boot/platform_install.sh | awk -F '=' '{print $2}')
		echo "mainline u-boot path: $DIR"
		# rename $DIR/u-boot.bin to u-boot-mainline.bin
		echo "rename $DIR/u-boot.bin to u-boot-mainline.bin"
		mv -f $DIR/u-boot.bin $DIR/u-boot-mainline.bin
		# copy $DIR/u-boot-mainline.bin to /boot/u-boot.bin
		echo "copy $DIR/u-boot-mainline.bin to /boot/u-boot.bin"
		\cp -af $DIR/u-boot-mainline.bin /boot/u-boot.bin
	fi

	# modify armbian-install for phicomm-n1
	echo "modify parted SECTOR 800M( (800 * 1024 * 1024) / 512 = 1638400 ) to 100%"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/armbian-install
	grep "FIRSTSECTOR=" /usr/sbin/armbian-install
	sed -i "/\t\tLASTSECTOR=/a\        [[ \$BOARD_NAME == \"phicomm-n1\" ]] && LASTSECTOR=\$(parted \$1 unit s print -sm | awk -F \":\" -v pattern=\"\$1\" '\$0 ~ pattern {printf (\"%d\", \$2)}') && echo \"LASTSECTOR=\$LASTSECTOR\" >> \$logfile" /usr/sbin/armbian-install
	grep "LASTSECTOR=" /usr/sbin/armbian-install

	echo "add backup bootloader when armbian-install"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck && $BOARD_NAME == "phicomm-n1" ]] && dd if=$emmccheck of=$DIR/u-boot.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot.bin ]] && echo "phicomm-n1 bootloader backup to $DIR/u-boot.bin" >> $logfile' /usr/sbin/armbian-install
	grep "u-boot.bin" /usr/sbin/armbian-install

	echo "disable 64bit when mkfs.ext4"
	sed -i "/^create_armbian/i\[[ \$BOARD_NAME == \"phicomm-n1\" ]] && mkopts[ext4]='-O ^64bit -qF' && echo \"mkopts[ext4]=\${mkopts[ext4]}\" >> \$logfile" /usr/sbin/armbian-install
	grep "mkopts\[ext4\]=" /usr/sbin/armbian-install

	echo "set parted mklabel msdos if empty"
	sed -i '/\tPART_TABLE_TYPE=/a\    [[ -z $PART_TABLE_TYPE && $BOARD_NAME == "phicomm-n1" ]] && PART_TABLE_TYPE="msdos" && echo "PART_TABLE_TYPE=$PART_TABLE_TYPE" >> $logfile' /usr/sbin/armbian-install
	grep "PART_TABLE_TYPE=" /usr/sbin/armbian-install

	# modify nand-sata-install for phicomm-n1
	echo "modify parted SECTOR 800M( (800 * 1024 * 1024) / 512 = 1638400 ) to 100%"
	sed -i 's/FIRSTSECTOR=.*/FIRSTSECTOR=1638400/' /usr/sbin/nand-sata-install
	grep "FIRSTSECTOR=" /usr/sbin/nand-sata-install
	sed -i "/\t\tLASTSECTOR=/a\        [[ \$BOARD_NAME == \"phicomm-n1\" ]] && LASTSECTOR=\$(parted \$1 unit s print -sm | awk -F \":\" -v pattern=\"\$1\" '\$0 ~ pattern {printf (\"%d\", \$2)}') && echo \"LASTSECTOR=\$LASTSECTOR\" >> \$logfile" /usr/sbin/nand-sata-install
	grep "LASTSECTOR=" /usr/sbin/nand-sata-install

	echo "add backup bootloader when nand-sata-install"
	sed -i '/^emmccheck=.*/a\[[ -n $emmccheck && $BOARD_NAME == "phicomm-n1" ]] && dd if=$emmccheck of=$DIR/u-boot.bin bs=1M count=4 conv=fsync >/dev/null 2>&1\n[[ -f $DIR/u-boot.bin ]] && echo "phicomm-n1 bootloader backup to $DIR/u-boot.bin" >> $logfile' /usr/sbin/nand-sata-install
	grep "u-boot.bin" /usr/sbin/nand-sata-install

	echo "disable 64bit when mkfs.ext4"
	sed -i "/^create_armbian/i\[[ \$BOARD_NAME == \"phicomm-n1\" ]] && mkopts[ext4]='-O ^64bit -qF' && echo \"mkopts[ext4]=\${mkopts[ext4]}\" >> \$logfile" /usr/sbin/nand-sata-install
	grep "mkopts\[ext4\]=" /usr/sbin/nand-sata-install

	echo "set parted mklabel msdos if empty"
	sed -i '/\tPART_TABLE_TYPE=/a\    [[ -z $PART_TABLE_TYPE && $BOARD_NAME == "phicomm-n1" ]] && PART_TABLE_TYPE="msdos" && echo "PART_TABLE_TYPE=$PART_TABLE_TYPE" >> $logfile' /usr/sbin/nand-sata-install
	grep "PART_TABLE_TYPE=" /usr/sbin/nand-sata-install

	# install docker
	echo "install docker"
	curl -fsSL https://get.docker.com | sh -

	# install some package
	if [[ $BUILD_DESKTOP == "yes" ]]; then
		echo "install some package"
		apt install -y \
			fonts-wqy-microhei fonts-wqy-zenhei \
			fonts-arphic-ukai fonts-arphic-uming \
			fonts-noto-cjk fonts-noto-cjk-extra \
			chromium-browser chromium-browser-l10n \
			libreoffice-l10n-zh-cn libreoffice-help-zh-cn

		case $RELEASE in
		jammy)
			echo "install jammy package"
			apt install -y \
				language-pack-zh-hans language-pack-gnome-zh-hans
			;;
		bullseye)
			echo "install bullseye package"
			;;
		esac
	fi

} # Main

Main "$@"
