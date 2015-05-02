# Pi2buntu
###TL;DR
This is a script for creating a minimal Ubuntu image for the Raspberry Pi 2. This script only supports the Raspberry Pi 2 as it uses the Ubuntu armhf port which is optimized for armv7.

If you just want an image and don't want to mess around with creating your own, see the [release page](https://github.com/FuturePilot/Pi2buntu/releases).

**Default User:** pi

**Default Password:** Raspberry

**Note:** This image is intended for advanced users. It has no GUI. If you are not comfortable with the command line this image is not for you.

###Overview
**What does this thing do?**

This script utilizes debootstrap to create a minimal Ubuntu chroot using Ubuntu's armhf packages. It also uses qemu-debootstrap as this script is intended to be run on the x86(_64) architecture and that is the easiest way to set up a foreign architecture chroot. It then adds some custom tweaks and configs specific for the Raspberry Pi 2. Finally it creates a disk image that you can then put on an SD card.

**Kernel**

This setup uses the official Raspberry Pi kernel and not Ubuntu's kernel. These updates are managed through a [Raspberry Pi 2 PPA](https://launchpad.net/~fo0bar/+archive/ubuntu/rpi2) (thanks Ryan Finnie)

**Custom Tweaks**

There are a few custom tweaks that have been included. 

 - The sound module `snd_bcm2835` is loaded by default.
 - `snd_soc_pcm512x_i2c` `snd_soc_pcm512x` `snd_soc_tas5713` `snd_soc_wm8804` have been blacklisted as they are not applicable to the Raspberry Pi 2

**Things You May Notice Are Missing**

 - rpi-update
 As mentioned above the kernel and firmware are handled through the PPA. rpi-update is not needed
 - raspi-config
 There is no raspi-config so any of the things that it does will need to be done manually. However porting it over is something I would like to do eventually.

###Upgrading to new Ubuntu releases
See the [wiki page](https://github.com/FuturePilot/Pi2buntu/wiki/Upgrading-to-new-Ubuntu-releases) on how to do this

###Special Thanks
Not all of this is my work so this is to give credit where credit is due.

 - wintrmute for the resize_rootfs.sh script
 - Ryan Finnie for the Raspberry Pi 2 PPA and for creating the original script this one is based on
 - [https://wiki.ubuntu.com/UbuntuDevelopment/Ports](https://wiki.ubuntu.com/UbuntuDevelopment/Ports) for the `qemu-arm-static` idea