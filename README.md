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
│       ├── overlays/        # Lime carrier overlays (carrierinfo, STM32 tools, HA agent)
│       └── scripts/         # Lime carrier setup (packages, services)
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
2. Create `carriers/<carrier>/scripts/setup-carrier.sh`, run in the image after the overlays (it may do nothing).
3. Create kernel and firmware repos for the new carrier.
4. Add meta-packages to [deb-packages](https://github.com/Citronics/deb-packages).
5. Build: `sudo debos -t carrier:<carrier> -t board:<board> ubuntu.yaml`

## Post-boot setup

### Using WiFi

Networking is managed by Network Manager's `nmcli`.

1. Connect to your device via SSH.
2. Run: `nmcli --ask dev wifi connect <YOURSSID>`

### Using the modem

1. Connect to your device via SSH.
2. Create the connection: `nmcli connection add type gsm ifname '*' con-name gsm apn <YOUR APN>`
3. Bring the connection up: `nmcli connection up gsm`

### Lime: the header (GPIO, I2C, SPI, ADC, UART)

With the Limeboard I/O firmware on its STM32, the Lime's Raspberry Pi style header shows up as standard Linux devices through the kernel's `citronics-dln2` driver, with the Pi's BCM numbering: GPIO chip `citronics-dln2` (lines 0-27 = GPIO0-27, 28-31 = RGB LED and user button), I2C buses on GPIO2/3 and GPIO0/1, SPI0 on GPIO7-11 and SPI1 on GPIO16-21, an 8-channel IIO ADC, and the UART (GPIO14/15) as `/dev/serial0`. Use the usual tools: libgpiod or `/sys/class/gpio`, `i2cdetect -y -r <bus>`, `spidev`, the IIO files. The driver binds to the firmware's USB ID by itself; it needs a kernel built with `CONFIG_CITRONICS_DLN2`.

As on a Raspberry Pi, the I2C and SPI buses are off until `/etc/limeboard/config.txt` turns them on, with the same lines (`dtparam=i2c_arm=on`, `dtparam=spi=on`, `dtoverlay=spi1-3cs`, `dtoverlay=i2c0`); `sudo limeboard-config enable i2c1` adds a line and applies it at once.

Raspberry Pi gpiozero code runs unchanged with `GPIOZERO_PIN_FACTORY=limeboard`: the `limeboard` pin factory is gpiozero's lgpio factory on the `citronics-dln2` chip, and names the onboard LED and button `LED_R`, `LED_G`, `LED_B` and `BUTTON`. Use `LED` and `RGBLED(..., pwm=False)`: the firmware has no PWM. RPi.GPIO (rpi-lgpio) and Adafruit Blinka work as well: at Python startup, `limeboard_compat` selects the `limeboard` factory, points RPi.GPIO at the `citronics-dln2` chip and gives Blinka the Limeboard's `board` module (Blinka itself is installed with pip). `LIMEBOARD_COMPAT=0` turns it off.

To update the firmware to the version the image carries: `sudo limeboard-config firmware update`. `limeboard-config` is also the Limeboard's `raspi-config`: it turns the buses and a login console on `/dev/serial0` on and off, and a `raspi-config` command answers HAT installers' `raspi-config nonint` calls through it.

By hand: `dfu-util -e` reboots the STM32 into its ROM bootloader (also reached by holding the user button at power-on), then `dfu-util -d 0483:df11 -a 0 -s 0x08000000:leave -D limeboard-io.bin`. Back up the whole flash first with `dfu-util -d 0483:df11 -a 0 -s 0x08000000:524288:leave -U backup.bin`.

### Lime: Home Assistant

`limeboard-ha` (one Python script on paho-mqtt, psutil and gpiozero) makes the board a Home Assistant device through MQTT discovery: the phone's system sensors, its accelerometer (with a tilt angle), gyroscope, magnetometer, and light and proximity sensors when present (every second), a reboot button, and the board's RGB LED (8 colours) and user button.

1. In Home Assistant: install the Mosquitto broker add-on, add the MQTT integration, and create a user for the board (`homeassistant` is reserved by the add-on).
2. On the board: set `MQTT_HOST`, `MQTT_USER` and `MQTT_PASSWORD` in `/etc/limeboard-ha.conf`, then `systemctl restart limeboard-ha`.

The board appears under Settings > Devices & services > MQTT. Entities, MQTT topics and design: `/usr/share/doc/limeboard-ha/README.md`.

## Resizing the rootfs

The rootfs expands automatically to fill the `userdata` partition during the first boot. Wait a few seconds for the process to complete.
