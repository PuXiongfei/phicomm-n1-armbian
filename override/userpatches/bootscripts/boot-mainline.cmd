setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'if ext4load mmc 1 0x08000000 /boot/emmc_autoscript; then autoscr 0x08000000; fi'
setenv start_usb_autoscript 'if fatload usb 0 0x08000000 s905_autoscript; then autoscr 0x08000000; fi'
saveenv

# default values
setenv devnum 1
setenv devtype "mmc"
setenv loader "ext4load"
setenv prefix "/boot/"

if usb start; then
    setenv devnum 0
    setenv devtype "usb"
    setenv loader "fatload"
    setenv prefix "/"
fi

echo "devnum: ${devnum}"
echo "devtype: ${devtype}"
echo "Current loader: ${loader}"
echo "Current prefix: ${prefix}"

if test -e ${devtype} ${devnum} ${prefix}u-boot.bin; then
    echo "${loader} ${devtype} ${devnum} 0x01000000 ${prefix}u-boot.bin"
    ${loader} ${devtype} ${devnum} 0x01000000 ${prefix}u-boot.bin && go 0x01000000
else
    echo "Not found u-boot.bin"
fi
