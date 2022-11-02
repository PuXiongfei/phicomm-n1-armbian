# DO NOT EDIT THIS FILE
#
# Please edit /boot/armbianEnv.txt to set supported parameters
#

setenv scriptaddr "0x32000000"
setenv kernel_addr_r "0x34000000"
setenv fdt_addr_r "0x4080000"
setenv overlay_error "false"
# default values
setenv rootdev "/dev/mmcblk1p1"
setenv verbosity "1"
setenv console "both"
setenv bootlogo "false"
setenv rootfstype "ext4"
setenv docker_optimizations "on"

# phicomm-n1 check USB boot
setenv devtype "mmc"
setenv devnum 1
setenv prefix "/boot/"

if usb start; then
    if test -e usb 0 ${prefix}u-boot.bin; then
        echo "found usb 0 ${prefix}u-boot.bin"
        setenv devtype "usb"
        setenv devnum 0
    else
        if test -e usb 0 /u-boot.bin; then
            echo "found usb 0 /u-boot.bin"
            setenv devtype "usb"
            setenv devnum 0
            setenv prefix "/"
        else
            echo "Not found u-boot.bin"
        fi
    fi
else
    echo "No USB boot device"
fi

echo "devtype: ${devtype}"
echo "devnum: ${devnum}"
echo "prefix: ${prefix}"

# odroid c4 legacy kernel values from boot.ini

setenv dtb_loadaddr "0x1000000"
setenv k_addr "0x1100000"
setenv loadaddr "0x1B00000"
setenv initrd_loadaddr "0x4080000"

setenv display_autodetect "true"
# HDMI Mode
# Resolution Configuration
#    Symbol             | Resolution
# ----------------------+-------------
#    "480x272p60hz"     | 480x272 Progressive 60Hz
#    "480x320p60hz"     | 480x320 Progressive 60Hz
#    "480p60hz"         | 720x480 Progressive 60Hz
#    "576p50hz"         | 720x576 Progressive 50Hz
#    "720p60hz"         | 1280x720 Progressive 60Hz
#    "720p50hz"         | 1280x720 Progressive 50Hz
#    "1080p60hz"        | 1920x1080 Progressive 60Hz
#    "1080p50hz"        | 1920x1080 Progressive 50Hz
#    "1080p30hz"        | 1920x1080 Progressive 30Hz
#    "1080p24hz"        | 1920x1080 Progressive 24Hz
#    "1080i60hz"        | 1920x1080 Interlaced 60Hz
#    "1080i50hz"        | 1920x1080 Interlaced 50Hz
#    "2160p60hz"        | 3840x2160 Progressive 60Hz
#    "2160p50hz"        | 3840x2160 Progressive 50Hz
#    "2160p30hz"        | 3840x2160 Progressive 30Hz
#    "2160p25hz"        | 3840x2160 Progressive 25Hz
#    "2160p24hz"        | 3840x2160 Progressive 24Hz
#    "smpte24hz"        | 3840x2160 Progressive 24Hz SMPTE
#    "2160p60hz420"     | 3840x2160 Progressive 60Hz YCbCr 4:2:0
#    "2160p50hz420"     | 3840x2160 Progressive 50Hz YCbCr 4:2:0
#    "640x480p60hz"     | 640x480 Progressive 60Hz
#    "800x480p60hz"     | 800x480 Progressive 60Hz
#    "800x600p60hz"     | 800x600 Progressive 60Hz
#    "1024x600p60hz"    | 1024x600 Progressive 60Hz
#    "1024x768p60hz"    | 1024x768 Progressive 60Hz
#    "1280x800p60hz"    | 1280x800 Progressive 60Hz
#    "1280x1024p60hz"   | 1280x1024 Progressive 60Hz
#    "1360x768p60hz"    | 1360x768 Progressive 60Hz
#    "1440x900p60hz"    | 1440x900 Progressive 60Hz
#    "1600x900p60hz"    | 1600x900 Progressive 60Hz
#    "1600x1200p60hz"   | 1600x1200 Progressive 60Hz
#    "1680x1050p60hz"   | 1680x1050 Progressive 60Hz
#    "1920x1200p60hz"   | 1920x1200 Progressive 60Hz
#    "2560x1080p60hz"   | 2560x1080 Progressive 60Hz
#    "2560x1440p60hz"   | 2560x1440 Progressive 60Hz
#    "2560x1600p60hz"   | 2560x1600 Progressive 60Hz
#    "3440x1440p60hz"   | 3440x1440 Progressive 60Hz
setenv hdmimode "1080p60hz"
setenv monitor_onoff "false"
setenv overscan "100"
setenv sdrmode "auto"
setenv voutmode "hdmi"
setenv disablehpd "false"
setenv cec "false"
setenv disable_vu7 "true"
setenv max_freq_a55 "1908"
#setenv max_freq_a55 "2100"
setenv maxcpus "4"

# Show what uboot default fdtfile is
echo "U-boot default fdtfile: ${fdtfile}"
echo "Current variant: ${variant}"
# there is a mismatch between u-boot and kernel in the n2-plus/n2_plus DTB filename.
# Also u-boot can't seem to decide between having, or not, 'amlogic/' in there.
if test "${variant}" = "n2_plus"; then
	setenv fdtfile "amlogic/meson-g12b-odroid-n2-plus.dtb"
	echo "For variant ${variant}, set default fdtfile: ${fdtfile}"
fi

if test "${variant}" = "n2-plus"; then
	setenv fdtfile "amlogic/meson-g12b-odroid-n2-plus.dtb"
	echo "For variant ${variant} (dash version, 2021.07 or up), set default fdtfile: ${fdtfile}"
fi

# legacy kernel values from boot.ini

if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
	load ${devtype} ${devnum} ${scriptaddr} ${prefix}armbianEnv.txt
	env import -t ${scriptaddr} ${filesize}
fi

# get PARTUUID of first partition on SD/eMMC it was loaded from
# mmc 0 is always mapped to device u-boot (2016.09+) was loaded from
if test "${devtype}" = "mmc"; then part uuid mmc ${devnum}:1 partuuid; fi
if test "${console}" = "display"; then setenv consoleargs "console=tty1"; fi

echo "Current fdtfile after armbianEnv: ${fdtfile}"

if test -e ${devtype} ${devnum} ${prefix}zImage; then
	# legacy kernel boot

	if test "${console}" = "serial"; then setenv consoleargs "console=ttyS0,115200"; fi
	if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyS0,115200 console=tty1"; fi
	if test "${console}" = "serial"; then setenv consoleargs "console=ttyS0,115200"; fi
	if test "${bootlogo}" = "true"; then
		setenv consoleargs "splash plymouth.ignore-serial-consoles ${consoleargs}"
	else
		setenv consoleargs "splash=verbose ${consoleargs}"
	fi

	setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} ${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 elevator=noop hdmimode=${hdmimode} cvbsmode=576cvbs max_freq_a55=${max_freq_a55} maxcpus=${maxcpus} voutmode=${voutmode} ${cmode} disablehpd=${disablehpd} cvbscable=${cvbscable} overscan=${overscan} ${hid_quirks} monitor_onoff=${monitor_onoff} ${cec_enable} sdrmode=${sdrmode}"
	echo "Legacy bootargs: ${bootargs}"

	load ${devtype} ${devnum} ${k_addr} boot/zImage
	load ${devtype} ${devnum} ${dtb_loadaddr} boot/dtb/${fdtfile}
	load ${devtype} ${devnum} ${initrd_loadaddr} boot/uInitrd
	fdt addr ${dtb_loadaddr}
	unzip ${k_addr} ${loadaddr}
	booti ${loadaddr} ${initrd_loadaddr} ${dtb_loadaddr}
else
	# modern kernel boot

	if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
	if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
	if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
	if test "${bootlogo}" = "true"; then
		setenv consoleargs "splash plymouth.ignore-serial-consoles ${consoleargs}"
	else
		setenv consoleargs "splash=verbose ${consoleargs}"
	fi
	if test "${disable_vu7}" = "false"; then setenv usbhidquirks "usbhid.quirks=0x0eef:0x0005:0x0004"; fi

	setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} ubootpart=${partuuid} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${usbhidquirks} ${extraargs} ${extraboardargs}"
	if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
	echo "Mainline bootargs: ${bootargs}"

	load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}uInitrd
	load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}Image
	load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
	fdt addr ${fdt_addr_r}
	fdt resize 65536
	for overlay_file in ${overlays}; do
		if load ${devtype} ${devnum} ${scriptaddr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
			echo "Applying kernel provided DT overlay ${overlay_prefix}-${overlay_file}.dtbo"
			fdt apply ${scriptaddr} || setenv overlay_error "true"
		fi
	done

	for overlay_file in ${user_overlays}; do
		if load ${devtype} ${devnum} ${scriptaddr} ${prefix}overlay-user/${overlay_file}.dtbo; then
			echo "Applying user provided DT overlay ${overlay_file}.dtbo"
			fdt apply ${scriptaddr} || setenv overlay_error "true"
		fi
	done

	if test "${overlay_error}" = "true"; then
		echo "Error applying DT overlays, restoring original DT"
		load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
	else
		if load ${devtype} ${devnum} ${scriptaddr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-fixup.scr; then
			echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
			source ${scriptaddr}
		fi
		if test -e ${devtype} ${devnum} ${prefix}fixup.scr; then
			load ${devtype} ${devnum} ${scriptaddr} ${prefix}fixup.scr
			echo "Applying user provided fixup script (fixup.scr)"
			source ${scriptaddr}
		fi
	fi

	booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
fi

# Recompile with:
# mkimage -C none -A arm -T script -d /boot/boot.cmd /boot/boot.scr
