#!/bin/bash
if [ "$(which initramfs-splash)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"initramfs-splash\" is already present. Can not install this."
  echo "File: \"$(which initramfs-splash)\""
  exit 1
fi
if [ "$1" == "install" ]; then
  mkdir -p "/tmp" >/dev/null 2>&1
  touch "/tmp/initramfs-splash_inst" 2>/dev/null
fi
exit 0