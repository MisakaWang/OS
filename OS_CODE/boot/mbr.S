; 主引导程序
;------------------------------
SECTION MBR vstart=0x7c00 ;告诉编译器起始地址编译为0x7c00
    mov ax, cs  ; 将CS（代码段寄存器）的值复制到AX寄存器
    mov ds, ax  ; 设置数据段寄存器DS = CS
    mov es, ax  ; 设置附加段寄存器ES = CS
    mov ss, ax  ; 设置堆栈段寄存器SS = CS
    mov fs, ax  ; 设置FS寄存器 = CS
    mov sp, 0x7c00 ; 设置堆栈指针SP指向0x7c00 将堆栈顶部设置在MBR加载地址（0x7c00）处
    mov ax, 0xb800 ; 用于文本显示适配器起始地址 也就是显示文本模式
    mov gs, ax      ; 附加段寄存器

; 清屏利用0x06功能，上卷全部行 实现清屏
;------------------------------
; INT 0x10
; AH 功能号 0x06
; AL = 上卷的行数 0表示全部
; BH = 上卷行的属性
; CL,CH = 屏幕左上角坐标(x,y)
; DL,DH = 屏幕右下角坐标(x,y)

    mov ax, 0x0600
    mov bx, 0x0700  ;设置新滚动行的显示属性（白字黑底）
    mov cx, 0x0000  ;(0,0)
    mov dx, 0x184f  ;(80,25) VGA文本模式一行只能80个字节 25行
                    ; 0x18 = 24, 0x4f = 79
    int 0x10

mov byte [gs:0x00], '1'
mov byte [gs:0x01], 0xA4 ; A表示绿色背景闪烁 4表示前景色为红色

mov byte [gs:0x02], ' '
mov byte [gs:0x03], 0xA4

mov byte [gs:0x04], 'M'
mov byte [gs:0x05], 0xA4

mov byte [gs:0x06], 'B'
mov byte [gs:0x07], 0xA4

mov byte [gs:0x08], 'R'
mov byte [gs:0x09], 0xA4


;; ;;;;;;;; 获取光标的位置;;;; 
;; ;get_cursor_pos:
;;     mov ah, 0x3      ;输入 3号子功能 获取光标的位置
;;     mov bh, 0x0000      ;bh寄存器存储的是光标的页号
;;     int 0x10            ;输出 ch=光标开始行  cl=光标结束行 dh=光标所在行  dl=光标所在列号
;; 
;; ;;;; 获取光标位置结束;;;; 
;; 
;; ;;;; 打印字符串;;;; 
;; ; 13号子功能打印字符串
;;     mov ax, message
;;     mov bp, ax          ;es:bp为串首地址，es此时与cs一致 开头时已经为sreg初始化
;; 
;; ; 光标位置要用到dx寄存器中的内容，cx中的光标位置可以忽略
;;     mov cx, 5           ;cx为串长度，不包括结束符0的字符个数
;;     mov ax, 0x1301      ;子功能号为13 显示字符及属性中要存入ah寄存器
;;                         ;al 设置写字符的方式 ah = 01显示字符串，光标跟随移动
;;     mov bx, 0x2         ;bh存储要显示的页号，此处是第0页，bl是字符属性 黑底绿字
;;     int 0x10            ;执行者0x10中断

;;;; 打印字符串结束;;;; 
jmp $       ;使程序停在此处 $表示当前位置的地址 $$：当前段的起始地址

;; message db "1 MBR"
times 510-($-$$) db 0   ; 当前位置离段起始位置的偏移，然后填充0到510字节
db 0x55,0xaa            ; 添加两个字节，0x55 0xaa