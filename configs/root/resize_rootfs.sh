#!/bin/bash
fdisk /dev/mmcblk0 <<EOF
d
2
n
p
2
133120

p
w
EOF

partprobe /dev/mmcblk0

resize2fs /dev/mmcblk0p2