# Debos recipes for Citronics boards

This repository contains debos recipes to build bootable disk images for Citronics boards. It serves as the main entry point for the Citronics ecosystem, aggregating packages into ready-to-flash images.

## Ecosystem Overview

The Citronics ecosystem consists of several specialized repositories that feed into the final image build process:

```
citronics-kernel ──────────────────────────────┐
citronics-firmware ─────────────────────────── ▼
citronics-initramfs ───────────────────────► deb-packages (APT repo)
unudhcpd-deb ──────────────────────────────────┘
                                               │
                                               ▼
                                        debos-citronics
                                       (builds disk images)
                                               │
                                               ▼
                                     ubuntu.img / debian.img
                                    (flashed via fastboot)
```

- **citronics-kernel**: Kernel packaging for FP2 (armhf) and FP3 (arm64).
- **citronics-firmware**: Firmware .deb packaging for FP2 and FP3.
- **citronics-initramfs**: Custom initramfs with USB networking, rootfs resize, and debug shell.
- **unudhcpd-deb**: USB DHCP daemon for device-side networking.
- **deb-packages**: GitHub Pages APT repo aggregating all the above — live at `https://citronics.github.io/deb-packages/`.
- **debos-citronics**: THIS repo — builds bootable disk images using packages from the APT repo.

## Supported Boards

| Board | Name | Architecture | Carrier |
|-------|------|--------------|---------|
| `fp2` | Fairphone 2 | armhf | lime |
| `fp3` | Fairphone 3 | arm64 | lime |

Architecture is auto-derived from the board name (fp3 is arm64, others are armhf). You can override it with `-t architecture:arm64` if needed.

## Available Recipes

- `ubuntu.yaml`: Ubuntu Resolute (26.04 LTS).
- `debian.yaml`: Debian Trixie.
- `raspap.yaml`: Debian Bookworm with RaspAP WiFi AP and MobileDataManager.

## Prerequisites

You must flash lk2nd to the boot partition for these images to work:

- **FP3**: Flash `lk2nd-msm8953.img` to `boot_a` partition.
- **FP2**: Flash `lk2nd-20.0-hack-noscreen.img` to `boot` partition.

Install debos and sparse image tools:

```bash
sudo apt install debos android-sdk-libsparse-utils
```

## Building images

Run debos with the carrier and board parameters:

```bash
# FP2 — Ubuntu
sudo debos -t carrier:lime -t board:fp2 ubuntu.yaml

# FP3 — Ubuntu
sudo debos -t carrier:lime -t board:fp3 ubuntu.yaml

# FP2 — Debian
sudo debos -t carrier:lime -t board:fp2 debian.yaml

# FP3 — RaspAP
sudo debos -t carrier:lime -t board:fp3 raspap.yaml
```

## Flashing

After building, create a sparse image before flashing.

### Fairphone 2

```bash
img2simg ubuntu-lime-fp2.img sparse-ubuntu-lime-fp2.img
fastboot flash userdata sparse-ubuntu-lime-fp2.img
```

### Fairphone 3

⚠️ **CRITICAL**: Only flash the `userdata` partition. Never flash `system_a` or other partitions.

```bash
img2simg ubuntu-lime-fp3.img sparse-ubuntu-lime-fp3.img
fastboot flash userdata sparse-ubuntu-lime-fp3.img
```

## Directory Structure

```
debos-citronics/
├── ubuntu.yaml              # Generic Ubuntu recipe (FP2 + FP3)
├── debian.yaml              # Generic Debian recipe (FP2 + FP3)
├── raspap.yaml              # RaspAP recipe (FP2 + FP3)
├── carriers/
│   └── lime/
│       └── overlays/        # Lime carrier overlays (carrierinfo)
├── boards/
│   ├── fp2/
│   │   ├── overlays/        # FP2-specific overlays (deviceinfo, extlinux.conf)
│   │   └── scripts/         # FP2 networking setup
│   └── fp3/
│       ├── overlays/        # FP3-specific overlays (deviceinfo, extlinux.conf)
│       └── scripts/         # FP3 networking setup
├── overlays/                # Common overlays (all boards)
└── scripts/                 # Common scripts
```

## Adding a New Board

1. Create `boards/<board>/overlays/usr/share/deviceinfo/deviceinfo`:
   ```bash
   deviceinfo_name="My Board"
   deviceinfo_codename="myboard"
   deviceinfo_getty="ttyMSM0;115200"
   deviceinfo_arch="arm64"
   deviceinfo_modules_initfs="module1 module2"
   ```
2. Create `boards/<board>/overlays/boot/extlinux/extlinux.conf` with appropriate kernel params.
3. Create `boards/<board>/scripts/setup-networking.sh`.
4. Create meta-package `citronics-<carrier>-<board>` in [deb-packages](https://github.com/Citronics/deb-packages).
5. Build: `sudo debos -t carrier:lime -t board:<board> ubuntu.yaml`

## Adding a New Carrier

1. Create `carriers/<carrier>/overlays/usr/share/carrierinfo/carrierinfo`:
   ```bash
   carrierinfo_name="My Carrier"
   carrierinfo_codename="mycarrier"
   ```
2. Create kernel and firmware repos for the new carrier.
3. Add meta-packages to [deb-packages](https://github.com/Citronics/deb-packages).
4. Build: `sudo debos -t carrier:<carrier> -t board:<board> ubuntu.yaml`

## Post-boot setup

### Using WiFi

Networking is managed by Network Manager's `nmcli`.

1. Connect to your device via SSH.
2. Run: `nmcli --ask dev wifi connect <YOURSSID>`

### Using the modem

1. Connect to your device via SSH.
2. Create the connection: `nmcli connection add type gsm ifname '*' con-name gsm apn <YOUR APN>`
3. Bring the connection up: `nmcli connection up gsm`

## Resizing the rootfs

The rootfs expands automatically to fill the `userdata` partition during the first boot. Wait a few seconds for the process to complete.
