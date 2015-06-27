#!/bin/bash
#Read the BOOTSIZE (VFAT Partition Size) from the file. This size set by user inside the build image scripts
file="/root/vfat_part_size" 
BOOTSIZE=$(cat "$file")
let EXT4_START_SECTOR=($BOOTSIZE+1)*1024*1024/512

fdisk /dev/mmcblk0 <<EOF
d
2
n
p
2
$EXT4_START_SECTOR
p
w
EOF

#Delete/clean the file that keeps the value of BOOTSIZE (VFAT Partition)
rm -f  $file

partprobe /dev/mmcblk0

resize2fs /dev/mmcblk0p2

tune2fs -m 1 /dev/mmcblk0p2
