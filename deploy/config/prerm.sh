#!/bin/bash
if [ -f "/usr/bin/initramfs-splash" ]; then
  echo "Prepare to remove ..."
  if [ "$1" == "remove" ]; then
    /usr/bin/initramfs-splash --clean >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/scripts/init-top/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/splash/fbsplash" >/dev/null 2>&1
    rm -f "/etc/initramfs-tools/hooks/splash/fbsplash.png" >/dev/null 2>&1
  else
    /usr/bin/initramfs-splash --remove >/dev/null 2>&1
  fi
fi
exit 0