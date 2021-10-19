setenv bootcmd 'run start_autoscript; run storeboot'
setenv loadlist "ext4load fatload"
setenv numlist "0 1 2 3"
setenv start_autoscript 'if mmcinfo; then run start_mmc_autoscript; fi; if usb start; then run start_usb_autoscript; fi; run start_emmc_autoscript'
setenv start_emmc_autoscript 'for load in ${loadlist}; do for devnum in ${numlist}; do if ${load} mmc ${devnum} 1020000 emmc_autoscript; then autoscr 1020000; fi; done; done;'
setenv start_mmc_autoscript 'for load in ${loadlist}; do for devnum in ${numlist}; do if ${load} mmc ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done; done;'
setenv start_usb_autoscript 'for load in ${loadlist}; do for devnum in ${numlist}; do if ${load} usb ${devnum} 1020000 s905_autoscript; then autoscr 1020000; fi; done; done;'
setenv upgrade_step 2
saveenv
sleep 1
reboot
