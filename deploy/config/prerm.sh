#!/bin/bash
if [ -f "/usr/bin/initramfs-splash" ]; then
  echo "Prepare to remove ..."
  if [ "$1" == "remove" ]; then
    /usr/bin/initramfs-splash --clean >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/scripts/init-top/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/splash/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/splash/fbsplash.png" >/dev/null 2>&1
    echo "INFO: you can delete /boot/config-initramfs.txt and /boot/initramfs.img"
    echo "if you dont need initramfs image anymore, but please remove"
    echo "\"include config-initramfs.txt\" line in /boot/config.txt also!"
  else
    /usr/bin/initramfs-splash --remove >/dev/null 2>&1
  fi
fi
exit 0