#!/bin/bash
if [ "$(which initramfs-splash)" != "" ] && [ "$1" == "install" ]; then
  echo "The command \"initramfs-splash\" is already present. Can not install this."
  echo "File: \"$(which initramfs-splash)\""
  exit 1
fi
exit 0