setenv numlist "0 1 2 3"
setenv devtype "mmc"
if usb start; then
    setenv devtype "usb"
fi

if test "${loadlist}" = ""; then
    setenv loadlist "ext4load fatload"
    saveenv
    for load in ${loadlist}; do
        for devnum in ${numlist}; do
            if ${load} ${devtype} ${devnum} 1080000 aml_autoscript; then
                autoscr 1080000
            fi
        done
    done
fi

setenv ramdisk_addr_r "0x13000000"
setenv load_addr "0x01040000"
setenv kernel_addr_r "0x01080000"
setenv fdt_addr_r "0x01000000"
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

for load in ${loadlist}; do
    if test "${load}" = "fatload"; then
        setenv prefix
    fi
    for devnum in ${numlist}; do
        if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
            ${load} ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt
            env import -t ${load_addr} ${filesize}

            if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
            if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
            if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.armbian ${consoleargs}"; fi

            setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
            if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi

            ${load} ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}
            ${load} ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}
            ${load} ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
            fdt addr ${fdt_addr_r}

            booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
        fi
    done
done
