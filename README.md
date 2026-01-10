# OS

学习记录

执行命令

```
# 1。 将mbr写入虚拟硬盘镜像

# 编译 MBR
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/mbr.bin OS_CODE/boot/mbr.S

# 编译 Loader
nasm -I OS_CODE/boot/include/ -o OS_CODE/boot/loader.bin OS_CODE/boot/loader.S

# 写入 MBR 到第 0 扇区
dd if=OS_CODE/boot/mbr.bin of=hd64M.img bs=512 count=1 conv=notrunc

# 写入 Loader 到第 2 扇区 (注意 seek=2)
# count=4 是为了确保即使 Loader 变大也能完整写入
dd if=OS_CODE/boot/loader.bin of=hd64M.img bs=512 count=4 seek=2 conv=notrunc

dd if=./mbr.bin of=/home/wang/Downloads/bochs-3.0/bin/hd60M.img bs=512 count=1 conv=notrunc
将mbr.bin 写到站hd60M.img的0块的512字节
./bochs -f bochsrc.disk
```
```
echo "Creating disk.img..."
bximage -mode=create -hd=10M -q disk.img

echo "Compiling..."
nasm -I include/ -o mbr.bin mbr.asm
nasm -I include/ -o loader.bin loader.asm

echo "Writing mbr and loader to disk..."
dd if=mbr.bin of=disk.img bs=512 count=1 conv=notrunc
dd if=loader.bin of=disk.img bs=512 count=4 seek=2 conv=notrunc

echo "Now start bochs and have fun!"
bochs -f bochsrc 
```

```
ld main.o -Ttext 0xc0001500 -e main -o kernel.bin
```