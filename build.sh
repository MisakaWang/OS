#!/bin/sh
# 编译 MBR
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/mbr.bin OS_CODE/boot/mbr.S

# 编译 Loader
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/loader.bin OS_CODE/boot/loader.S

# 写入 MBR 到第 0 扇区
dd if=OS_CODE/boot/mbr.bin of=hd64M.img bs=512 count=1 conv=notrunc

# 写入 Loader 到第 2 扇区 (注意 seek=2)
# count=4 是为了确保即使 Loader 变大也能完整写入
dd if=OS_CODE/boot/loader.bin of=hd64M.img bs=512 count=2 seek=2 conv=notrunc

bochs -f bochsrc.disk -q