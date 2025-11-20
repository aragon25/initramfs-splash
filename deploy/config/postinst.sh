#!/bin/bash
function undo_changes(){
  /usr/bin/initramfs-splash --clean >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/scripts/init-top/fbsplash" >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/hooks/fbsplash" >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/hooks/splash/fbsplash" >/dev/null 2>&1
  rm -f "/etc/initramfs-tools/hooks/splash/fbsplash.png" >/dev/null 2>&1
  exit 1
}
if [ -f "/usr/bin/initramfs-splash" ]; then
  echo "update initramfs-tools folder ..."
  /usr/bin/initramfs-splash --install >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
  echo "generate initramfs-image/s ..."
  /usr/bin/initramfs-splash --update_initramfs >/dev/null 2>&1
  [ $? -ne 0 ] && undo_changes
fi
exit 0