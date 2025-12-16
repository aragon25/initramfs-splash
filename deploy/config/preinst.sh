#!/bin/bash
if [ "$(which initramfs-splash)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"initramfs-splash\" is already present. Can not install this."
  echo "File: \"$(which initramfs-splash)\""
  exit 1
fi
if [ "$1" == "install" ]; then
  mkdir -p "/usr/lib/initramfs-splash" >/dev/null 2>&1
  touch "/usr/lib/initramfs-splash/first_install" 2>/dev/null
fi
exit 0