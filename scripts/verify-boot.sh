#!/bin/bash
set -euo pipefail

# Verify the boot partition contract: every file referenced by
# extlinux.conf (what lk2nd actually loads) must exist under /boot.
# A missing entry means an unbootable image, so fail the build here
# rather than shipping a brick.

CONF="/boot/extlinux/extlinux.conf"

if [ ! -f "$CONF" ]; then
  echo "ERROR: $CONF not found"
  exit 1
fi

STATUS=0
while read -r key value _; do
  case "$key" in
    kernel|fdt|initrd)
      if [ -f "/boot$value" ]; then
        echo "OK: $key $value"
      else
        echo "ERROR: $CONF references '$value' but /boot$value is missing"
        STATUS=1
      fi
      ;;
  esac
done < "$CONF"

if [ "$STATUS" -ne 0 ]; then
  echo "ERROR: boot partition verification failed"
  ls -la /boot
fi
exit $STATUS
