; 内核加载器

%include "boot.inc"
section loader vstart=LOADER_BASE_ADDR
LOADER_STACK_TOP equ LOADER_BASE_ADDR ; 0x900 loader在内存中的物理位置

jmp loader_start

; 构建 gdt 及内部的描述符
; x86架构规定GDT的第0项必须为空 8字节
GDT_BASE: dd 0x00000000  ; 描述符的低32位
          dd 0x00000000  ; 描述符的高32位

; 代码段描述符，一个dd为4字节，段描述符为8字节，上面为低4字节
CODE_DESC: dd 0x0000FFFF
           dd DESC_CODE_HIGH4

; 栈段描述符，和数据段共用
DATA_STACK_DESC: dd 0x0000FFFF
                 dd DESC_DATA_HIGH4

; 显卡段，非平坦
VIDEO_DESC: dd 0x80000007
            dd DESC_VIDEO_HIGH4

GDT_SIZE equ $ - GDT_BASE

loader_start:

; 输出绿色背景 前景红色 并且跳动的字符串 "1 MBR"

mov byte [gs:0x00], '2'
mov byte [gs:0x01], 0xA4 ; A表示绿色背景闪烁, 4表示前景色为红色

mov byte [gs:0x02], ' '
mov byte [gs:0x03], 0xA4 

mov byte [gs:0x04], 'L'
mov byte [gs:0x05], 0xA4 

mov byte [gs:0x06], 'O'
mov byte [gs:0x07], 0xA4 

mov byte [gs:0x08], 'A'
mov byte [gs:0x09], 0xA4 

mov byte [gs:0x0a], 'D'
mov byte [gs:0x0b], 0xA4 

mov byte [gs:0x0c], 'E'
mov byte [gs:0x0d], 0xA4 

mov byte [gs:0x0e], 'R'
mov byte [gs:0x0f], 0xA4 

jmp $