#!/bin/sh

###########################################################################################################
# rpi2-build-image
# Copyright (C) 2015 Ryan Finnie <ryan@finnie.org>
# Copyright (C) 2015 Saeid Ghazagh <sghazagh@elar-systems.com>
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
##########################################################################################################
#    See "###### Build the image file ######" sction to adjust SD Card sizes as per your requirement     #
##########################################################################################################

# This is a stub from rpi-build-image.sh. Useful for rebuilding the image after making minor changes that don't 
# require the entire chroot be rebuilt

#set -e
#set -x

RELEASE=vivid
BASEDIR=/srv/rpi2/${RELEASE}
BUILDDIR=${BASEDIR}/build
SHELL=/bin/bash

# Set up environment
export TZ=UTC
R=${BUILDDIR}/chroot

# Unmount mounted filesystems
umount $R/proc || true
umount $R/sys || true

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

###### Build the image file ######
#--- Adjust as per your need ----
BOOTSIZE=64
MIN_PARTITION_FREE_SIZE=10
#-------------------------------

ROOTFSPATH=$R
echo "Creating RPi2 SDCard Image ..."
echo "=======================================" 
DATE="$(date +%Y-%m-%d)"
NUMBER_OF_FILES=`sudo find ${ROOTFSPATH} | wc -l`
EXT_SIZE=`sudo du -DsB1 ${ROOTFSPATH} | awk -v min=$MIN_PARTITION_FREE_SIZE -v f=${NUMBER_OF_FILES} \
	'{rootfs_size=$1+f*512;rootfs_size=int(rootfs_size/1024/985); print (rootfs_size+min) }'`

echo "rootfs -->" ${ROOTFSPATH}
echo "Number of files -->" ${NUMBER_OF_FILES}

BOOT_SIZE=$BOOTSIZE"M"
echo "Size of Partition 1 -->" $BOOT_SIZE
echo "Size of Partition 2 -->" ${EXT_SIZE}"M"

SD_SIZE=$(($BOOTSIZE + $EXT_SIZE))
echo "Total Size of SD Card Image -->" $SD_SIZE"M"
sleep 5
image="$BASEDIR/${DATE}-ubuntu-${RELEASE}.img"
bmap="$BASEDIR/${DATE}-ubuntu-${RELEASE}.bmap"

dd if=/dev/zero of=$image bs=1M count=${SD_SIZE}
device=`losetup -f --show $image`
echo "Image $image created and mounted as $device ..."

fdisk $device << EOF
n
p
1

+$BOOT_SIZE
t
c
n
p
2


a
1
w
EOF

losetup -d $device
device=`kpartx -va $image | sed -E 's/.*(loop[0-9])p.*/\1/g' | head -1`
device="/dev/mapper/${device}"
echo ${device}

VFAT_LOOP=${device}p1
EXT4_LOOP=${device}p2

mkfs.vfat -n BOOT $VFAT_LOOP
mkfs.ext4 -L rootfs $EXT4_LOOP

MOUNTDIR="$BUILDDIR/mount"

mkdir -p "$MOUNTDIR"
mount "$EXT4_LOOP" "$MOUNTDIR"

mkdir -p "$MOUNTDIR/boot/firmware"
mount "$VFAT_LOOP" "$MOUNTDIR/boot/firmware"

rsync -a "$R/" "$MOUNTDIR/"

umount "$MOUNTDIR/boot/firmware"

#To keep a copy of $R/boot/Firmware folder inside the EXT4 folder as a backup/reference
rsync -a "$R/boot/firmware/" "$MOUNTDIR/boot/firmware/"
umount "$MOUNTDIR"

kpartx -d $image

bmaptool create -o "$bmap" "$image"

echo =============================================================================
echo "Created image $image"
echo =============================================================================

#Done
