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
GDT_LIMIT equ GDT_SIZE - 1

times 120 dd 0

SELECTOR_CODE equ (0x0001 << 3) + TI_GDT + RPL0
SELECTOR_DATA equ (0x0002 << 3) + TI_GDT + RPL0
SELECTOR_VIDEO equ (0x0003 << 3) + TI_GDT + RPL0

gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

loadermsg db '2 loader in real.'

loader_start:
        ; 调用10h中断显示字符串
        mov sp, LOADER_BASE_ADDR ; 设置栈顶
        mov bp, loadermsg ; 通过bp作为基址来访问字符串
        ; 设置字符串的长度
        mov cx, 17
        ; 子功能号，以及显示的方式
        mov ax, 0x1301  ; ah = 0x13 表示 0x10 中断的13号子功能，用于显示字符串 al=0x01 子功能的选项 光标跟随字符串移动到末尾的位置
        ; 页号0，蓝底白字
        mov bx, 0x001f ; 0x00 页号 bl=0x1f 属性字节 0001 1111 0-3位前景色 4-6位背景色 7位 闪烁
        mov dx, 0x1800
        int 0x10

        ; 打开A20地址线，可以访问超过1M大小的地址
        in al, 0x92      ; 从键盘控制器端口0x92读取当前状态
        or al, 00000010B ; 这是A20使能位，设置该位即可启用A20地址线
        out 0x92, al

        ; 设置gdt
        lgdt [gdt_ptr]

        ; CR0 第0个位置设置为1，开启保护模式
        mov eax, cr0
        or eax, 0x00000001
        mov cr0, eax

        ; 刷新流水线
        jmp dword SELECTOR_CODE:p_mode_start

[bits 32]
p_mode_start:
        mov ax, SELECTOR_DATA           ; 将数据段选择器加载到ax寄存器
        mov ds, ax
        mov es, ax
        mov ss, ax                      ; 栈段（ss）和栈指针（esp）
        mov esp, LOADER_STACK_TOP       ; 设置栈指针esp为LOADER_STACK_TOP（栈顶地址）
        mov ax, SELECTOR_VIDEO
        mov gs, ax                      ; gs寄存器指向视频段，用于访问显存

        mov byte [gs:160], 'P'          ; 在视频内存偏移160的位置写入字符'P'
        mov byte [gs:161], 0x1f
        jmp $

; ; 输出绿色背景 前景红色 并且跳动的字符串 "1 MBR"

; mov byte [gs:0x00], '2'
; mov byte [gs:0x01], 0xA4 ; A表示绿色背景闪烁, 4表示前景色为红色

; mov byte [gs:0x02], ' '
; mov byte [gs:0x03], 0xA4 

; mov byte [gs:0x04], 'L'
; mov byte [gs:0x05], 0xA4 

; mov byte [gs:0x06], 'O'
; mov byte [gs:0x07], 0xA4 

; mov byte [gs:0x08], 'A'
; mov byte [gs:0x09], 0xA4 

; mov byte [gs:0x0a], 'D'
; mov byte [gs:0x0b], 0xA4 

; mov byte [gs:0x0c], 'E'
; mov byte [gs:0x0d], 0xA4 

; mov byte [gs:0x0e], 'R'
; mov byte [gs:0x0f], 0xA4 

; jmp $