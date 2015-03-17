# Pi2buntu
###TL;DR
This is a script for creating a minimal Ubuntu image for the Raspberry Pi 2. This script only supports the Raspberry Pi 2 as it uses the Ubuntu armhf port which is optimized for armv7.

If you just want an image and don't want to mess around with creating your own, see the release page.
**Default User:** ubuntu
**Default Password:** ubuntu

**Note:** This image is intended for advanced users. It has no GUI. If you are not comfortable with the command line this image is not for you.

###Overview
**What does this thing do?**
This script utilizes debootstrap to create a minimal Ubuntu chroot using Ubuntu's armhf packages. It also uses qemu-debootstrap as this script is intended to be run on the x86(_64) architecture and that is the easiest way to set up a foreign architecture chroot. It then adds some custom tweaks and configs specific for the Raspberry Pi 2. Finally it creates a disk image that you can then put on an SD card.

**Kernel**
This setup uses the official Raspberry Pi kernel and not Ubuntu's kernel. These updates are managed through a [Raspberry Pi 2 PPA](https://launchpad.net/~fo0bar/+archive/ubuntu/rpi2) (thanks Ryan Finnie)

**Custom Tweaks**
There are a few custom tweaks that have been included

**Things You May Notice Are Missing**

 - rpi-update
 As mentioned above the kernel and firmware are handled through the PPA. rpi-update is not needed
 - raspi-config
 There is no raspi-config so any of the things that it does will need to be done manually. However porting it over is something I would like to do eventually.