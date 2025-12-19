# OS

学习记录

执行命令

```
# 1。 将mbr写入虚拟硬盘镜像

dd if=./mbr.bin of=/home/wang/Downloads/bochs-3.0/bin/hd60M.img bs=512 count=1 conv=notrunc
将mbr.bin 写到站hd60M.img的0块的512字节
./bochs -f bochsrc.disk
```
