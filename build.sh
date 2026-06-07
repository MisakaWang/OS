#!/bin/sh
set -e

: > bochs.out
# 编译 MBR
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/mbr.bin OS_CODE/boot/mbr.S

# 编译 Loader
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/loader.bin OS_CODE/boot/loader.S

# 写入 MBR 到第 0 扇区
dd if=OS_CODE/boot/mbr.bin of=hd64M.img bs=512 count=1 conv=notrunc

# 写入 Loader 到第 2 扇区 (注意 seek=2)
# count=4 是为了确保即使 Loader 变大也能完整写入
dd if=OS_CODE/boot/loader.bin of=hd64M.img bs=512 count=4 seek=2 conv=notrunc

echo "mbr.bin:    $(stat -c %s OS_CODE/boot/mbr.bin) bytes"
echo "loader.bin: $(stat -c %s OS_CODE/boot/loader.bin) bytes"
echo "loader sha1: $(sha1sum OS_CODE/boot/loader.bin | awk '{print $1}')"
# 回读镜像第2扇区起的4扇区，与 loader.bin 做前N字节比对
dd if=hd64M.img of=/tmp/loader.from.img.bin bs=512 count=4 skip=2 status=none
cmp -n "$(stat -c %s OS_CODE/boot/loader.bin)" OS_CODE/boot/loader.bin /tmp/loader.from.img.bin
echo "disk verify: loader.bin == image sectors [2..5] (prefix)"

bochs -q -f bochsrc.disk
