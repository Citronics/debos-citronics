#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CITRONICS_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUTPUT_IMG="${SCRIPT_DIR}/ubuntu-lime-fp3.img"
PHONE="fp3"
CARRIER="lime"
SUITE="ubuntu"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --phone)
      PHONE="$2"
      shift 2
      ;;
    --carrier)
      CARRIER="$2"
      shift 2
      ;;
    --suite)
      SUITE="$2"
      shift 2
      ;;
    --output)
      OUTPUT_IMG="${SCRIPT_DIR}/$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker is not installed or not in PATH"
  exit 1
fi

ARCH="arm64"
if [ "$PHONE" = "fp2" ]; then
  ARCH="armhf"
fi

if [ -z "$OUTPUT_IMG" ]; then
  OUTPUT_IMG="${SCRIPT_DIR}/ubuntu-lime-${PHONE}.img"
fi

echo "=== Building disk image for $PHONE (arch: $ARCH, carrier: $CARRIER) ==="
echo "Output: $OUTPUT_IMG"

docker run --rm --privileged \
  -v "$CITRONICS_ROOT:/citronics" \
  ubuntu:noble bash -c '
set -euo pipefail

PHONE="'"$PHONE"'"
CARRIER="'"$CARRIER"'"
SUITE="'"$SUITE"'"
ARCH="'"$ARCH"'"
OUTPUT_IMG_BASENAME="'"$(basename "$OUTPUT_IMG")"'"
DOCKER_OUTPUT_IMG="/citronics/debos-citronics/$OUTPUT_IMG_BASENAME"

apt-get update -qq
apt-get install -y mmdebstrap qemu-user-static rsync fdisk util-linux e2fsprogs kpartx

IMG="/tmp/disk.img"
ROOTFS="/tmp/rootfs"
ROOT_MNT="/mnt/root"
LOOP=""

cleanup() {
  umount "$ROOT_MNT/boot" 2>/dev/null || true
  umount "$ROOT_MNT" 2>/dev/null || true
  [ -n "$LOOP" ] && kpartx -d "$LOOP" 2>/dev/null || true
  [ -n "$LOOP" ] && losetup -d "$LOOP" 2>/dev/null || true
  umount "$ROOTFS/dev/pts" 2>/dev/null || true
  umount "$ROOTFS/dev" 2>/dev/null || true
  umount "$ROOTFS/sys" 2>/dev/null || true
  umount "$ROOTFS/proc" 2>/dev/null || true
}
trap cleanup EXIT

rm -rf "$ROOTFS"
mkdir -p "$ROOTFS"

echo "=== Installing rootfs with mmdebstrap for $ARCH ==="
update-binfmts --enable qemu-aarch64 2>/dev/null || true

if [ "$SUITE" = "ubuntu" ]; then
  MIRROR="http://ports.ubuntu.com/ubuntu-ports/"
  SUITE_NAME="resolute"
else
  MIRROR="http://deb.debian.org/debian"
  SUITE_NAME="bookworm"
fi

mmdebstrap \
  --arch="$ARCH" --mode=root --variant=minbase \
  --components="main,universe" \
  --include="apt,ca-certificates,coreutils,sudo,openssh-server,adduser,systemd,systemd-sysv,systemd-resolved,nano,vim,qrtr-tools,libqmi-utils,rmtfs,udev,kmod,network-manager,modemmanager,wpasupplicant,ifupdown,isc-dhcp-client,isc-dhcp-server,systemd-timesyncd,bluetooth,kpartx,cloud-utils,fake-hwclock,wireless-regdb,usbutils,iputils-ping,initramfs-tools,busybox-static,inetutils-telnetd,parted" \
  "$SUITE_NAME" "$ROOTFS" "$MIRROR"

echo "=== Preparing chroot environment ==="
cp /usr/bin/qemu-aarch64-static "$ROOTFS/usr/bin/" 2>/dev/null || true
cp /usr/bin/qemu-arm-static "$ROOTFS/usr/bin/" 2>/dev/null || true

for DIR in proc sys dev dev/pts; do
  mkdir -p "$ROOTFS/$DIR"
done

mount -t proc proc "$ROOTFS/proc"
mount -t sysfs sysfs "$ROOTFS/sys"
mount --rbind /dev "$ROOTFS/dev"
mount -t devpts devpts "$ROOTFS/dev/pts"

echo "Installing common local .deb packages"
if [ -d "/citronics/debos-citronics/local-debs/common" ]; then
  COMMON_DEBS=$(find /citronics/debos-citronics/local-debs/common -maxdepth 1 -name "*.deb" 2>/dev/null)
  if [ -n "$COMMON_DEBS" ]; then
    mkdir -p "$ROOTFS/tmp/local-debs"
    cp /citronics/debos-citronics/local-debs/common/*.deb "$ROOTFS/tmp/local-debs/"
  fi
fi

echo "Installing $PHONE-specific local .deb packages"
if [ -d "/citronics/debos-citronics/local-debs/$PHONE" ]; then
  PHONE_DEBS=$(find /citronics/debos-citronics/local-debs/$PHONE -maxdepth 1 -name "*.deb" 2>/dev/null)
  if [ -n "$PHONE_DEBS" ]; then
    mkdir -p "$ROOTFS/tmp/local-debs"
    cp /citronics/debos-citronics/local-debs/$PHONE/*.deb "$ROOTFS/tmp/local-debs/"
  fi
fi

if [ -d "$ROOTFS/tmp/local-debs" ]; then
  chroot "$ROOTFS" bash -c "dpkg -i --force-depends /tmp/local-debs/*.deb" || echo "WARNING: Some packages failed to install"
  rm -rf "$ROOTFS/tmp/local-debs"
fi

echo "=== Checking hooks after deb install ==="
ls "$ROOTFS/etc/initramfs-tools/hooks/" && echo "Hooks OK" || echo "Hooks dir EMPTY or MISSING"
ls "$ROOTFS/usr/share/citronics-initramfs/" 2>/dev/null && echo "citronics-initramfs share OK" || echo "citronics-initramfs share MISSING"

echo "=== Ensuring citronics-initramfs files are present ==="
if [ ! -f "$ROOTFS/etc/initramfs-tools/hooks/01-copy-custom-init" ]; then
  echo "WARNING: Hooks missing - extracting directly from deb"
  dpkg-deb -x /citronics/debos-citronics/local-debs/common/citronics-initramfs_1.0.9_all.deb "$ROOTFS/"
  echo "Direct extraction complete, hooks now:"
  ls "$ROOTFS/etc/initramfs-tools/hooks/"
fi

echo "=== Applying overlays ==="
if [ -d "/citronics/debos-citronics/overlays" ]; then
  rsync -av --exclude=.git /citronics/debos-citronics/overlays/ "$ROOTFS/" 2>/dev/null || true
fi

if [ -d "/citronics/debos-citronics/carriers/$CARRIER/overlays" ]; then
  rsync -av --exclude=.git /citronics/debos-citronics/carriers/"$CARRIER"/overlays/ "$ROOTFS/" 2>/dev/null || true
fi

BOARD="$PHONE"
if [ -d "/citronics/debos-citronics/boards/$BOARD/overlays" ]; then
  rsync -av --exclude=.git /citronics/debos-citronics/boards/"$BOARD"/overlays/ "$ROOTFS/" 2>/dev/null || true
fi

echo "=== Setting up user and hostname ==="
if [ -f "/citronics/debos-citronics/boards/$BOARD/scripts/setup-user.sh" ]; then
  cp "/citronics/debos-citronics/boards/$BOARD/scripts/setup-user.sh" "$ROOTFS/tmp/setup-user.sh"
  chroot "$ROOTFS" bash /tmp/setup-user.sh
  rm "$ROOTFS/tmp/setup-user.sh"
elif [ -f "/citronics/debos-citronics/scripts/setup-user.sh" ]; then
  cp /citronics/debos-citronics/scripts/setup-user.sh "$ROOTFS/tmp/setup-user.sh"
  chroot "$ROOTFS" bash /tmp/setup-user.sh
  rm "$ROOTFS/tmp/setup-user.sh"
fi

echo "citronics" > "$ROOTFS/etc/hostname"

echo "=== Enabling services ==="
for SERVICE in isc-dhcp-server.service msm-modem-uim-selection.service; do
  SERVICE_FILE="$ROOTFS/etc/systemd/system/multi-user.target.wants/$SERVICE"
  if [ -f "$ROOTFS/lib/systemd/system/$SERVICE" ]; then
    mkdir -p "$(dirname "$SERVICE_FILE")"
    ln -sf "/lib/systemd/system/$SERVICE" "$SERVICE_FILE" 2>/dev/null || true
  fi
done

echo "=== Generating initramfs ==="
chroot "$ROOTFS" bash -c "update-initramfs -c -k all" || echo "WARNING: update-initramfs had errors"

echo "=== Verifying initramfs contents ==="
KVER_CHECK=$(ls "$ROOTFS/boot/initrd.img-"* 2>/dev/null | head -1 | sed "s|.*/initrd.img-||" || true)
if [ -n "$KVER_CHECK" ]; then
  echo "Checking initramfs for critical files:"
  for F in init functions.sh usr/share/misc/source_deviceinfo usr/share/deviceinfo/deviceinfo lib/modules/initramfs.load; do
    if zcat "$ROOTFS/boot/initrd.img-$KVER_CHECK" | cpio -t 2>/dev/null | grep -q "^$F$"; then
      echo "  OK: $F"
    else
      echo "  MISSING: $F"
    fi
  done
fi

echo "=== Setting up boot partition ==="
KVER=$(ls "$ROOTFS/boot/vmlinuz-"* 2>/dev/null | head -1 | sed "s|.*/vmlinuz-||" || true)
if [ -n "$KVER" ]; then
  echo "Kernel version: $KVER"
  cp "$ROOTFS/boot/vmlinuz-$KVER" "$ROOTFS/boot/Image.gz"
  DTB_DIR="$ROOTFS/usr/lib/linux-image-$KVER"
  if [ -d "$DTB_DIR" ]; then
    if [ "$BOARD" = "fp3" ]; then
      echo "Copying FP3 DTBs to /boot"
      cp "$DTB_DIR/qcom/sdm632-fairphone-fp3.dtb" "$ROOTFS/boot/" 2>/dev/null || true
      cp "$DTB_DIR/qcom/sdm632-fairphone-fp3p.dtb" "$ROOTFS/boot/" 2>/dev/null || true
    elif [ "$BOARD" = "fp2" ]; then
      echo "Copying FP2 DTBs to /boot"
      find "$DTB_DIR" -name "*fairphone*fp2*.dtb" -exec cp {} "$ROOTFS/boot/" \; 2>/dev/null || true
      find "$DTB_DIR" -name "*msm8974*fairphone*.dtb" -exec cp {} "$ROOTFS/boot/" \; 2>/dev/null || true
    else
      echo "Copying all DTBs for board $BOARD"
      find "$DTB_DIR" -name "*.dtb" -exec cp {} "$ROOTFS/boot/" \; 2>/dev/null || true
    fi
  fi
  if [ -f "$ROOTFS/boot/initrd.img-$KVER" ]; then
    mv "$ROOTFS/boot/initrd.img-$KVER" "$ROOTFS/boot/initramfs.gz"
    echo "Renamed initrd.img-$KVER to initramfs.gz"
  fi
fi

echo "=== Creating disk image ==="
fallocate -l 2G "$IMG"
printf "o\nn\np\n1\n\n+50M\na\nn\np\n2\n\n\nw\n" | fdisk "$IMG" > /dev/null 2>&1

LOOP=$(losetup --find --show "$IMG")

kpartx -av "$LOOP" > /dev/null
sleep 1

LOOP_BASE=$(basename "$LOOP")
P1="/dev/mapper/${LOOP_BASE}p1"
P2="/dev/mapper/${LOOP_BASE}p2"

echo "=== Formatting partitions ==="
mkfs.ext2 -F -L boot "$P1" > /dev/null 2>&1
mkfs.ext4 -F -L root "$P2" > /dev/null 2>&1

mkdir -p "$ROOT_MNT"

mount "$P2" "$ROOT_MNT"
mkdir -p "$ROOT_MNT/boot"
mount "$P1" "$ROOT_MNT/boot"

echo "=== Deploying filesystem ==="
rsync -av \
  --exclude=/proc \
  --exclude=/sys \
  --exclude=/dev \
  --exclude=/tmp \
  "$ROOTFS/" "$ROOT_MNT/" > /dev/null

BOOT_UUID=$(blkid -s UUID -o value "$P1")
ROOT_UUID=$(blkid -s UUID -o value "$P2")

cat > "$ROOT_MNT/etc/fstab" << EOF
UUID=$ROOT_UUID / ext4 defaults 0 1
UUID=$BOOT_UUID /boot ext2 defaults 0 2
EOF

echo "=== Verifying boot partition ==="
BOOT_FILES=$(find "$ROOT_MNT/boot" -maxdepth 1 -type f | wc -l)
echo "Boot partition contains $BOOT_FILES files"
ls -lh "$ROOT_MNT/boot/" | tail -n +2

for REQUIRED in Image.gz initramfs.gz; do
  if [ ! -f "$ROOT_MNT/boot/$REQUIRED" ]; then
    echo "WARNING: /boot/$REQUIRED missing from image"
  fi
done

umount "$ROOT_MNT/boot"
umount "$ROOT_MNT"
kpartx -d "$LOOP"
losetup -d "$LOOP"
LOOP=""

mv "$IMG" "$DOCKER_OUTPUT_IMG"
echo "=== Image created: $DOCKER_OUTPUT_IMG ==="
ls -lh "$DOCKER_OUTPUT_IMG"
'

echo "=== Build complete ==="
