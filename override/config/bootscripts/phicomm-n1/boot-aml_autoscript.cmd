setenv bootcmd 'run start_autoscript; run storeboot'
setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/emmc_autoscript || fatload mmc ${devnum} 1020000 emmc_autoscript; then autoscr 1020000; fi; done'
setenv start_mmc_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/s905_autoscript || fatload mmc ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done'
setenv start_usb_autoscript 'for devnum in 0 1 2 3; do if ext4load mmc ${devnum} 1020000 /boot/s905_autoscript || fatload mmc ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done'
setenv upgrade_step 2
saveenv
sleep 1
reboot
