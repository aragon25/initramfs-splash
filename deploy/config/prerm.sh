#!/bin/bash
if [ -f "/usr/bin/initramfs-splash" ]; then
  echo "Prepare to remove ..."
  if [ "$1" == "remove" ]; then
    /usr/bin/initramfs-splash --clean >/dev/null 2>&1
    rm -rf "/usr/lib/initramfs-splash" >/dev/null 2>&1
  fi
fi
exit 0