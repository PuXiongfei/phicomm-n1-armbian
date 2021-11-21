setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if usb start; then run start_usb_autoscript; fi; if mmcinfo; then run start_mmc_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'if ext4load mmc 1 0x08000000 /boot/emmc_autoscript || fatload mmc 1 0x08000000 emmc_autoscript; then autoscr 0x08000000; fi'
setenv start_mmc_autoscript 'if ext4load mmc 0 0x08000000 /boot/s905_autoscript || fatload mmc 0 0x08000000 s905_autoscript; then autoscr 0x08000000; fi'
setenv start_usb_autoscript 'for devnum in 0 1 2 3; do if ext4load usb ${devnum} 0x08000000 /boot/s905_autoscript || fatload usb ${devnum} 0x08000000 s905_autoscript; then autoscr 0x08000000; fi; done'
saveenv

# default values
setenv loader "ext4load"
setenv prefix "/boot/"

for devtype in "usb mmc"; do
    echo "devtype: ${devtype}"
    for devnum in 0 1 2 3; do
        echo "devnum: ${devnum}"

        if test -e ${devtype} ${devnum} /u-boot.bin; then
            setenv loader "fatload"
            setenv prefix "/"
        fi

        echo "Current loader: ${loader}"
        echo "Current prefix: ${prefix}"

        if test -e ${devtype} ${devnum} ${prefix}u-boot.bin; then
            echo "${loader} ${devtype} ${devnum} 0x01000000 ${prefix}u-boot.bin"
            ${loader} ${devtype} ${devnum} 0x01000000 ${prefix}u-boot.bin && go 0x01000000
        else
            echo "Not found u-boot.bin"
        fi
    done
done
