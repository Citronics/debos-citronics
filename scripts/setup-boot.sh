#!/bin/bash
set -euo pipefail

KVER=$(ls /boot/vmlinuz-* 2>/dev/null | head -1 | sed "s|/boot/vmlinuz-||" || true)
if [ -z "$KVER" ]; then
  echo "WARNING: No kernel found in /boot, skipping boot setup"
  exit 0
fi

echo "Kernel version: $KVER"

deviceinfo_arch=""
deviceinfo_dtb=""

DEVICEINFO="/usr/share/deviceinfo/deviceinfo"
if [ -f "$DEVICEINFO" ]; then
  . "$DEVICEINFO"
fi

if [ "$deviceinfo_arch" = "aarch64" ]; then
  cp "/boot/vmlinuz-$KVER" /boot/Image.gz
  echo "Copied vmlinuz-$KVER to /boot/Image.gz"
else
  cp "/boot/vmlinuz-$KVER" /boot/zImage
  echo "Copied vmlinuz-$KVER to /boot/zImage"
fi

DTB_SRC="/usr/lib/linux-image-$KVER/qcom"
if [ -d "$DTB_SRC" ] && [ -n "$deviceinfo_dtb" ]; then
  for DTB in $deviceinfo_dtb; do
    if [ -f "$DTB_SRC/$DTB" ]; then
      cp "$DTB_SRC/$DTB" /boot/
      echo "Copied DTB: $DTB"
    else
      echo "WARNING: $DTB not found in $DTB_SRC, skipping"
    fi
  done
fi

if [ -f "/boot/initrd.img-$KVER" ]; then
  mv "/boot/initrd.img-$KVER" /boot/initramfs.gz
  echo "Renamed initrd.img-$KVER to /boot/initramfs.gz"
fi

echo "Removing kernel-package files from /boot to keep boot partition lean"
rm -f "/boot/vmlinuz-$KVER"
rm -f "/boot/System.map-$KVER"
rm -f "/boot/config-$KVER"
