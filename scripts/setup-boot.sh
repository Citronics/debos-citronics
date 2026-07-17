#!/bin/bash
set -euo pipefail

# Derive the kernel version from /lib/modules: kernel postinst hooks
# (e.g. citronics-initramfs' zz-citronics-boot) may already have renamed
# or removed /boot/vmlinuz-*, so /boot is not a reliable source.
KVER=$(ls /lib/modules 2>/dev/null | sort -V | tail -1 || true)
if [ -z "$KVER" ]; then
  echo "ERROR: no kernel found in /lib/modules"
  exit 1
fi

echo "Kernel version: $KVER"

deviceinfo_arch=""
deviceinfo_dtb=""

DEVICEINFO="/usr/share/deviceinfo/deviceinfo"
if [ -f "$DEVICEINFO" ]; then
  . "$DEVICEINFO"
fi

if [ "$deviceinfo_arch" = "aarch64" ] || [ "$deviceinfo_arch" = "arm64" ]; then
  KIMG="Image.gz"
else
  KIMG="zImage"
fi

if [ -f "/boot/vmlinuz-$KVER" ]; then
  cp "/boot/vmlinuz-$KVER" "/boot/$KIMG"
  echo "Copied vmlinuz-$KVER to /boot/$KIMG"
elif [ -f "/boot/$KIMG" ]; then
  echo "/boot/$KIMG already present (copied by kernel postinst hook)"
else
  echo "ERROR: neither /boot/vmlinuz-$KVER nor /boot/$KIMG found"
  exit 1
fi

# deviceinfo may not declare the DTB (FP2's does not) — fall back to the
# fdt entries in extlinux.conf, which is what the bootloader will load.
if [ -z "$deviceinfo_dtb" ] && [ -f /boot/extlinux/extlinux.conf ]; then
  deviceinfo_dtb=$(awk '$1 == "fdt" { sub("^/", "", $2); print $2 }' /boot/extlinux/extlinux.conf | sort -u | tr '\n' ' ')
  echo "deviceinfo_dtb not set, using extlinux.conf fdt entries: $deviceinfo_dtb"
fi
if [ -z "${deviceinfo_dtb// /}" ]; then
  echo "ERROR: no DTB configured ($DEVICEINFO and extlinux.conf both lack one)"
  exit 1
fi

# Kernel packages ship DTBs either flat in /usr/lib/linux-image-$KVER/ or
# under a qcom/ subdirectory, depending on the package version.
for DTB in $deviceinfo_dtb; do
  DTB_NAME="$(basename "$DTB")"
  if [ -f "/usr/lib/linux-image-$KVER/$DTB" ]; then
    cp "/usr/lib/linux-image-$KVER/$DTB" "/boot/$DTB_NAME"
    echo "Copied DTB: $DTB"
  elif [ -f "/usr/lib/linux-image-$KVER/qcom/$DTB_NAME" ]; then
    cp "/usr/lib/linux-image-$KVER/qcom/$DTB_NAME" "/boot/$DTB_NAME"
    echo "Copied DTB: qcom/$DTB_NAME"
  else
    echo "ERROR: DTB $DTB not found in /usr/lib/linux-image-$KVER"
    exit 1
  fi
done

# The recipe's `update-initramfs -c -k all` enumerates kernels via
# /boot/vmlinuz-*, which kernel postinst hooks may have removed — if no
# initramfs was produced, generate it here explicitly by version.
if [ -f "/boot/initrd.img-$KVER" ]; then
  mv "/boot/initrd.img-$KVER" /boot/initramfs.gz
  echo "Renamed initrd.img-$KVER to /boot/initramfs.gz"
elif [ ! -f /boot/initramfs.gz ]; then
  echo "No initramfs found, generating for $KVER"
  update-initramfs -c -k "$KVER"
  # citronics-initramfs' post-update hook normally renames the initrd;
  # handle the plain initramfs-tools case as well.
  if [ -f "/boot/initrd.img-$KVER" ]; then
    mv "/boot/initrd.img-$KVER" /boot/initramfs.gz
  fi
fi

if [ ! -f /boot/initramfs.gz ]; then
  echo "ERROR: /boot/initramfs.gz missing after initramfs generation"
  exit 1
fi

# Keep /boot/vmlinuz-$KVER: update-initramfs needs it to enumerate kernels
# for regenerations on the device. Only drop files the boot flow never reads.
echo "Removing System.map/config from /boot to keep boot partition lean"
rm -f "/boot/System.map-$KVER"
rm -f "/boot/config-$KVER"
