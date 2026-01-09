# Debos recipes for Citronics' Lemon board

This repository allows you to build a debian or ubuntu image to be flashed on the Limeboard userdata partition.
It uses a pre-built kernel and initramfs.

After building, you should use `img2simg` to create a sparse image before flashing it with fastboot.

It is part of the `android-sdk-libsparse-utils` on debian bookworm so be sure to install it with:
```
sudo apt install android-sdk-libsparse-utils
```

Or the equivalent for your linux distribution and version.

## Prerequisite

You need to have lk2nd flashed on the boot partition of your Lemon's fairphone 2 for these images to work. Download it [here](https://github.com/Citronics/lk2nd-noscreen/releases/download/20.0-noscreen/lk2nd-20.0-hack-noscreen.img) and run:
```
fastboot flash boot lk2nd-20.0-hack-noscreen.img
fastboot reboot
```

## Building

Install debos:

```
sudo apt install debos
```

Then, run the following commands:

```
sudo debos debian.yml # or ubuntu.yml
img2simg debian-lemon.img sparse-debian-lemon.img # or ubuntu.img ...
# Configure the dipswitch in fairphone 2 mode (fp2) and follow the instructions to set it in fastboot mode
fastboot flash userdata sparse-debian-lemon.img
# Unplug the board once done and reconfigure the dipswitch back to host mode
# Plug it and enjoy running debian or ubuntu on your Lemon board
```

## Flashing pre built images

Go to releases on this github page, select one, download either `sparse-debian-lemon.img` or `sparse-ubuntu-lemon.img` and flash it with fastboot as explained above.

## Using Wifi

The networking setup is done with Network Manager's `nmcli` and to have wifi working you will need to ssh to your Lemon using the method above and use the follwing:

1. Make sure you can ssh to your Lemon by following the previous section
2. Use `nmcli --ask dev wifi connect <YOURSSID>`

You should now be connected to your wifi network.

## Using the modem

The modem configuration is also done with Network Manager's `nmcli` and to connect to your APN, you can use the following:

1. Make sure you can ssh to your Lemon by following the previous section
2. Use `nmcli connection add type gsm ifname '*' con-name gsm apn <YOUR APN>` to create the connection
3. Then type `nmcli connection up gsm`

And you should be connected to your APN.

## Resizing the rootfs to take all the userdata empty space

During the first boot after flashing, the rootfs will be expanded to take all available space on your Lemon's fairphone 2 userdata partition, so there is nothing more to do than wait a couple more seconds during the first boot.
