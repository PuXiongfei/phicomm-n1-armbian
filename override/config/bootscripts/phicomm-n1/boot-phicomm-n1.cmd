setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/emmc_autoscript || fatload mmc ${devnum} 1020000 emmc_autoscript; then autoscr 1020000; fi; done'
setenv start_mmc_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/s905_autoscript || fatload mmc ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done'
setenv start_usb_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/s905_autoscript || fatload mmc ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done'
setenv upgrade_step 2
saveenv

setenv ramdisk_addr_r "0x13000000"
setenv load_addr "0x32000000"
setenv kernel_addr_r "0x34000000"
setenv fdt_addr_r "0x4080000"
# default values
setenv rootdev "/dev/mmcblk1p1"
setenv verbosity "1"
setenv console "both"
setenv bootlogo "false"
setenv rootfstype "ext4"
setenv docker_optimizations "on"
setenv prefix "/boot/"
setenv INITRD "uInitrd"
setenv LINUX "Image"

setenv devtype "mmc"
if usb start; then
    setenv devtype "usb"
fi
echo "devtype: ${devtype}"

for devnum in 0 1 2 3; do
    if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt || test -e ${devtype} ${devnum} armbianEnv.txt; then
        ext4load ${devtype} ${devnum} ${prefix}armbianEnv.txt || fatload ${devtype} ${devnum} armbianEnv.txt
        env import -t ${load_addr} ${filesize}
    else
        echo "Not found armbianEnv.txt"
    fi

    echo "Current fdtfile after armbianEnv: ${fdtfile}"

    if test -e ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX} || test -e ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}; then
        ext4load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX} || fatload ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}
    else
        echo "Not found LINUX"
    fi

    if test -e ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD} || test -e ${devtype} ${devnum} ${ramdisk_addr_r} ${INITRD}; then
        ext4load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD} || fatload ${devtype} ${devnum} ${ramdisk_addr_r} ${INITRD}
    else
        echo "Not found INITRD"
    fi

    if test -e ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile} || ${devtype} ${devnum} ${fdt_addr_r} dtb/${fdtfile}; then
        ext4load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile} || fatload ${devtype} ${devnum} ${fdt_addr_r} dtb/${fdtfile}
        fdt addr ${fdt_addr_r}
        fdt resize 65536
    else
        echo "Not found DTB"
    fi

    if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
    if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
    if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.armbian ${consoleargs}"; fi

    setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
    if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
    echo "bootargs: ${bootargs}"

    booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
done
