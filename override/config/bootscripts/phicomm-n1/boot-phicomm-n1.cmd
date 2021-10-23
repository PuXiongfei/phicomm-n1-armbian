setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'if ext4load mmc 1 ${loadaddr} /boot/emmc_autoscript || fatload mmc 1 ${loadaddr} emmc_autoscript; then autoscr ${loadaddr}; fi'
setenv start_mmc_autoscript 'if ext4load mmc 0 ${loadaddr} /boot/s905_autoscript || fatload mmc 0 ${loadaddr} s905_autoscript; then autoscr ${loadaddr}; fi'
setenv start_usb_autoscript 'for devnum in 0 1 2 3; do if ext4load usb ${devnum} ${loadaddr} /boot/s905_autoscript || fatload usb ${devnum} ${loadaddr} s905_autoscript; then autoscr ${loadaddr}; fi; done'
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
    echo "devnum: ${devnum}"

    if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
        echo "ext4load: ${prefix}armbianEnv.txt"
        ext4load ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt
        env import -t ${load_addr} ${filesize}
    elif test -e ${devtype} ${devnum} armbianEnv.txt; then
        echo "fatload: armbianEnv.txt"
        fatload ${devtype} ${devnum} ${load_addr} armbianEnv.txt
        env import -t ${load_addr} ${filesize}
    else
        echo "Not found armbianEnv.txt"
    fi

    echo "Current fdtfile after armbianEnv: ${fdtfile}"

    if test -e ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}; then
        echo "ext4load: ${prefix}${LINUX}"
        ext4load ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}
    elif test -e ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}; then
        echo "fatload: ${LINUX}"
        fatload ${devtype} ${devnum} ${kernel_addr_r} ${LINUX}
    else
        echo "Not found LINUX"
    fi

    if test -e ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}; then
        echo "ext4load: ${prefix}${INITRD}"
        ext4load ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}
    elif test -e ${devtype} ${devnum} ${ramdisk_addr_r} ${INITRD}; then
        echo "fatload: ${INITRD}"
        fatload ${devtype} ${devnum} ${ramdisk_addr_r} ${INITRD}
    else
        echo "Not found INITRD"
    fi

    if test -e ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}; then
        echo "ext4load: ${prefix}dtb/${fdtfile}"
        ext4load ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
    elif ${devtype} ${devnum} ${fdt_addr_r} dtb/${fdtfile}; then
        echo "fatload: dtb/${fdtfile}"
        fatload ${devtype} ${devnum} ${fdt_addr_r} dtb/${fdtfile}
    else
        echo "Not found DTB"
    fi

    fdt addr ${fdt_addr_r}
    fdt resize 65536

    if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
    if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
    if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.armbian ${consoleargs}"; fi

    setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
    if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
    echo "bootargs: ${bootargs}"

    booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
done
