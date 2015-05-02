#!/bin/sh

########################################################################
# rpi2-build-image
# Copyright (C) 2015 Ryan Finnie <ryan@finnie.org>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
########################################################################

set -e
set -x

RELEASE=vivid
BASEDIR=/srv/rpi2/${RELEASE}
BUILDDIR=${BASEDIR}/build
SHELL=/bin/bash

# Don't clobber an old build
if [ -e "$BUILDDIR" ]; then
  echo "$BUILDDIR exists, not proceeding"
  exit 1
fi

# Set up environment
export TZ=UTC
R=${BUILDDIR}/chroot
mkdir -p $R

# Base debootstrap
apt-get -y install ubuntu-keyring debootstrap bmap-tools qemu-user-static
qemu-debootstrap --arch armhf $RELEASE $R http://ports.ubuntu.com/

# Mount required filesystems
mount -t proc none $R/proc
mount -t sysfs none $R/sys

# Prepair for foreign chroot
# This shouldn't be needed anymore because of qemu-debootstrap
# cp /usr/bin/qemu-arm-static $R/usr/bin/

# Set up initial sources.list
cat ./configs/etc/apt/sources.list > $R/etc/apt/sources.list

# Prevent daemons from starting up
cat ./configs/usr/sbin/policy-rc.d > $R/usr/sbin/policy-rc.d
chmod +x $R/usr/sbin/policy-rc.d

# Update, upgrade, and set up PPAs
chroot $R $SHELL -c "apt-get update"
# I do not know why the hell python 3.4 is failing to install in debootstrap but this will work around the problem until I figure out why
chroot $R $SHELL -c "apt-get install -y -f"
chroot $R $SHELL -c "apt-get -y install software-properties-common ubuntu-keyring"
chroot $R $SHELL -c "apt-add-repository -y ppa:futurepilot/raspberry-pi-2"
cat ./configs/etc/apt/preferences.d/rpi2-ppa > $R/etc/apt/preferences.d/rpi2-ppa
chroot $R $SHELL -c "apt-add-repository -y ppa:fo0bar/rpi2"
chroot $R $SHELL -c "apt-get update"
chroot $R $SHELL -c "apt-get -y -u dist-upgrade"

# Standard packages
chroot $R $SHELL -c "apt-get -y install ubuntu-standard initramfs-tools raspberrypi-bootloader-nokernel rpi2-ubuntu-errata language-pack-en openssh-server wpasupplicant linux-firmware libraspberrypi-bin libraspberrypi-bin-nonfree dphys-swapfile fake-hwclock"

# Kernel installation
# Install flash-kernel last so it doesn't try (and fail) to detect the
# platform in the chroot.
chroot $R $SHELL -c "apt-get -y --no-install-recommends install linux-image-rpi2"
chroot $R $SHELL -c "apt-get -y install flash-kernel"
VMLINUZ="$(ls -1 $R/boot/vmlinuz-* | sort | tail -n 1)"
[ -z "$VMLINUZ" ] && exit 1
cp $VMLINUZ $R/boot/firmware/kernel7.img

# Set up fstab
cat ./configs/etc/fstab > $R/etc/fstab

# Set up hosts
echo raspberry-pi2 > $R/etc/hostname
cat ./configs/etc/hosts > $R/etc/hosts

# Set up default user
chroot $R $SHELL -c "adduser --gecos 'Raspberry Pi' --add_extra_groups --disabled-password pi"
# Escape $s
chroot $R $SHELL -c "usermod -a -G sudo,adm -p '\$6\$OPqOymJb94Nigm2N\$eKgV1B5x.QymW0cR4gKzP6GRdqx3Pi0lvJv6slITN8INP4vWg6bRFvgE6HrzaV52q4ph/L6pQoK8f3G4uFBWI/' pi"

# We want to configure the time zone on first login
cp $R/home/pi/.profile $R/home/pi/.profile_new
cat ./configs/home/pi/dotprofile > $R/home/pi/.profile
chroot $R $SHELL -c "chown 1000:1000 /home/pi/.profile*"

# Clean cached downloads
chroot $R $SHELL -c "apt-get clean"

# Set up interfaces
cat ./configs/etc/network/interfaces > $R/etc/network/interfaces

# Set up firmware config
cat ./configs/boot/firmware/config.txt > $R/boot/firmware/config.txt
ln -sf firmware/config.txt $R/boot/config.txt
echo 'dwc_otg.lpm_enable=0 console=tty1 root=/dev/mmcblk0p2 rootwait' > $R/boot/firmware/cmdline.txt
ln -sf firmware/cmdline.txt $R/boot/cmdline.txt

# Load sound module on boot
cat ./configs/lib/modules-load.d/rpi2.conf > $R/lib/modules-load.d/rpi2.conf

# Blacklist platform modules not applicable to the RPi2
cat ./configs/etc/modprobe.d/rpi2.conf > $R/etc/modprobe.d/rpi2.conf

# Configure swap
# Set swap to 500 MB
sed -i 's/#CONF_SWAPSIZE=/CONF_SWAPSIZE=500/' $R/etc/dphys-swapfile

# Set up first boot scripts
cat ./configs/etc/rc.local > $R/etc/rc.local

cat ./configs/root/resize_rootfs.sh > $R/root/resize_rootfs.sh

chmod +x $R/root/resize_rootfs.sh
touch $R/root/first_boot

# Unmount mounted filesystems
umount $R/proc
umount $R/sys

# Clean up files
rm -f $R/etc/apt/sources.list.save
rm -f $R/etc/resolvconf/resolv.conf.d/original
rm -rf $R/run
mkdir -p $R/run
rm -f $R/etc/*-
rm -f $R/root/.bash_history
rm -rf $R/tmp/*
rm -f $R/var/lib/urandom/random-seed
[ -L $R/var/lib/dbus/machine-id ] || rm -f $R/var/lib/dbus/machine-id
rm -f $R/etc/machine-id
rm -f $R/usr/bin/qemu-arm-static
rm -f $R/etc/ssh/ssh_host_*
rm -fr $R/usr/sbin/policy-rc.d

# Build the image file
# Currently hardcoded to a 1.75GiB image
DATE="$(date +%Y-%m-%d)"
dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=1
dd if=/dev/zero of="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" bs=1M count=0 seek=1792
sfdisk -f "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img" <<EOM
unit: sectors

1 : start=     2048, size=   131072, Id= c, bootable
2 : start=   133120, size=  3536896, Id=83
3 : start=        0, size=        0, Id= 0
4 : start=        0, size=        0, Id= 0
EOM
VFAT_LOOP="$(losetup -o 1M --sizelimit 64M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
EXT4_LOOP="$(losetup -o 65M --sizelimit 1727M -f --show $BASEDIR/${DATE}-ubuntu-${RELEASE}.img)"
mkfs.vfat -n BOOT "$VFAT_LOOP"
mkfs.ext4 -L rootfs "$EXT4_LOOP"
MOUNTDIR="$BUILDDIR/mount"
mkdir -p "$MOUNTDIR"
mount "$EXT4_LOOP" "$MOUNTDIR"
mkdir -p "$MOUNTDIR/boot/firmware"
mount "$VFAT_LOOP" "$MOUNTDIR/boot/firmware"
rsync -a "$R/" "$MOUNTDIR/"
umount "$MOUNTDIR/boot/firmware"
umount "$MOUNTDIR"
losetup -d "$EXT4_LOOP"
losetup -d "$VFAT_LOOP"
bmaptool create -o "$BASEDIR/${DATE}-ubuntu-${RELEASE}.bmap" "$BASEDIR/${DATE}-ubuntu-${RELEASE}.img"


# Done!
