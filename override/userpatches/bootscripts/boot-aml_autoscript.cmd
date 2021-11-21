env default -a
setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'if ext4load mmc 1 0x08000000 /boot/emmc_autoscript || fatload mmc 1 0x08000000 emmc_autoscript; then autoscr 0x08000000; fi'
setenv start_usb_autoscript 'if ext4load usb 0 0x08000000 /boot/s905_autoscript || fatload usb 0 0x08000000 s905_autoscript; then autoscr 0x08000000; fi'
setenv upgrade_step 2
saveenv
sleep 1
reboot
