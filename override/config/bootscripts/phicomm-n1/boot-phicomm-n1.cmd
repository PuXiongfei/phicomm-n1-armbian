setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'if ext4load mmc 1 ${loadaddr} /boot/emmc_autoscript || fatload mmc 1 ${loadaddr} emmc_autoscript; then autoscr ${loadaddr}; fi'
setenv start_mmc_autoscript 'if ext4load mmc 0 ${loadaddr} /boot/s905_autoscript || fatload mmc 0 ${loadaddr} s905_autoscript; then autoscr ${loadaddr}; fi'
setenv start_usb_autoscript 'for devnum in 0 1 2 3; do if ext4load usb ${devnum} ${loadaddr} /boot/s905_autoscript || fatload usb ${devnum} ${loadaddr} s905_autoscript; then autoscr ${loadaddr}; fi; done'
saveenv

setenv load_addr "0x01100000"
setenv kernel_addr_r "0x02000000"
setenv fdt_addr_r "0x01000000"
setenv ramdisk_addr_r "0x04080000"
setenv overlay_error "false"
# default values
setenv rootdev "/dev/mmcblk1p1"
setenv verbosity "1"
setenv console "both"
setenv bootlogo "false"
setenv rootfstype "ext4"
setenv docker_optimizations "on"
setenv loader "ext4load"
setenv prefix "/boot/"
setenv INITRD "uInitrd"
setenv LINUX "Image"

for devtype in "usb mmc"; do
    echo "devtype: ${devtype}"
    for devnum in 0 1 2 3; do
        echo "devnum: ${devnum}"

        # Show what uboot default fdtfile is
        echo "U-boot default fdtfile: ${fdtfile}"
        echo "Current variant: ${variant}"

        if test -e ${devtype} ${devnum} armbianEnv.txt; then
            setenv loader "fatload"
            setenv prefix ""
        fi

        echo "Current loader: ${loader}"
        echo "Current prefix: ${prefix}"

        if test -e ${devtype} ${devnum} ${prefix}armbianEnv.txt; then
            echo "${loader} ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt"
            ${loader} ${devtype} ${devnum} ${load_addr} ${prefix}armbianEnv.txt
            env import -t ${load_addr} ${filesize}
            echo "Current fdtfile after armbianEnv: ${fdtfile}"
        else
            echo "Not found armbianEnv.txt"
        fi

        if test "${console}" = "serial"; then setenv consoleargs "console=ttyAML0,115200"; fi
        if test "${console}" = "display" || test "${console}" = "both"; then setenv consoleargs "console=ttyAML0,115200 console=tty1"; fi
        if test "${bootlogo}" = "true"; then setenv consoleargs "bootsplash.bootfile=bootsplash.armbian ${consoleargs}"; fi

        setenv bootargs "root=${rootdev} rootwait rootfstype=${rootfstype} ${consoleargs} consoleblank=0 coherent_pool=2M loglevel=${verbosity} libata.force=noncq usb-storage.quirks=${usbstoragequirks} ${extraargs} ${extraboardargs}"
        if test "${docker_optimizations}" = "on"; then setenv bootargs "${bootargs} cgroup_enable=memory swapaccount=1"; fi
        echo "bootargs: ${bootargs}"

        if test -e ${devtype} ${devnum} ${prefix}${LINUX}; then
            echo "${loader} ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}"
            ${loader} ${devtype} ${devnum} ${kernel_addr_r} ${prefix}${LINUX}
        else
            echo "Not found LINUX"
        fi

        if test -e ${devtype} ${devnum} ${prefix}${INITRD}; then
            echo "${loader} ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}"
            ${loader} ${devtype} ${devnum} ${ramdisk_addr_r} ${prefix}${INITRD}
        else
            echo "Not found INITRD"
        fi

        if test -e ${devtype} ${devnum} ${prefix}dtb/${fdtfile}; then
            echo "${loader} ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}"
            ${loader} ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
            fdt addr ${fdt_addr_r}
            fdt resize 65536
        else
            echo "Not found DTB"
        fi

        for overlay_file in ${overlays}; do
            if ${loader} ${devtype} ${devnum} ${load_addr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-${overlay_file}.dtbo; then
                echo "Applying kernel provided DT overlay ${overlay_prefix}-${overlay_file}.dtbo"
                fdt apply ${load_addr} || setenv overlay_error "true"
            fi
        done

        for overlay_file in ${user_overlays}; do
            if ${loader} ${devtype} ${devnum} ${load_addr} ${prefix}overlay-user/${overlay_file}.dtbo; then
                echo "Applying user provided DT overlay ${overlay_file}.dtbo"
                fdt apply ${load_addr} || setenv overlay_error "true"
            fi
        done

        if test "${overlay_error}" = "true"; then
            echo "Error applying DT overlays, restoring original DT"
            ${loader} ${devtype} ${devnum} ${fdt_addr_r} ${prefix}dtb/${fdtfile}
        else
            if ${loader} ${devtype} ${devnum} ${load_addr} ${prefix}dtb/amlogic/overlay/${overlay_prefix}-fixup.scr; then
                echo "Applying kernel provided DT fixup script (${overlay_prefix}-fixup.scr)"
                source ${load_addr}
            fi
            if test -e ${devtype} ${devnum} ${prefix}fixup.scr; then
                ${loader} ${devtype} ${devnum} ${load_addr} ${prefix}fixup.scr
                echo "Applying user provided fixup script (fixup.scr)"
                source ${load_addr}
            fi
        fi

        booti ${kernel_addr_r} ${ramdisk_addr_r} ${fdt_addr_r}
    done
done
