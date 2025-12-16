#!/bin/bash
function undo_changes(){
  /usr/bin/initramfs-splash --clean >/dev/null 2>&1
  exit 1
}
if [ -f "/usr/lib/initramfs-splash/first_install" ]; then
  rm -f "/usr/lib/initramfs-splash/first_install" >/dev/null 2>&1
  echo "activate initramfs-splash ..."
  /usr/bin/initramfs-splash --initramfs_active >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "activate plymouth-splash ..."
  /usr/bin/initramfs-splash --plymouth_active >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "activate splash in cmdline ..."
  /usr/bin/initramfs-splash -f -s -t  >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
else
  /usr/bin/initramfs-splash --update >/dev/null 2>&1
fi
exit 0