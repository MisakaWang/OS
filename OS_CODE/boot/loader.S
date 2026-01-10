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

; 内存大小，字节单位，此处的内存地址是0xb00
total_memory_bytes dd 0

gdt_ptr dw GDT_LIMIT
        dd GDT_BASE

; loadermsg db '2 loader in real.'

ards_buf times 244 db 0

ards_nr dw 0

loader_start:
        cli ; 在进入保护模式前必须关闭中断，否则若无IDT会导致Triple Fault
        ; === 早期调试输出 - 在实模式下立即显示 '2' ===
        xor ebx, ebx; 清零 
        mov edx, 0x534d4150 ;  ASCII 字符 "SMAP" 的十六进制表示。
        mov di, ards_buf  

.e820_mem_get_loop:
        mov eax, 0x0000e820
        mov ecx, 20 ; 期望接收的数据结构的大小 指定 ARDS (Address Range Descriptor Structure) 结构体的大小
        int 0x15

        jc .e820_mem_get_failed ; 如果int 0x15失败，跳转到.e820_mem_get_failed

        add di, cx ; 指向下一个 ARDS 结构体
        inc word [ards_nr] ; ARDS 结构体数量加一
        cmp ebx, 0 ; 检查 ebx 是否为 0 int0x15的时候 会更新ebx的值
        jne .e820_mem_get_loop ; 如果 ebx 不为 0，继续循环

        mov cx, [ards_nr]
        mov ebx, ards_buf ; ; 这里是为了给下一段代码（找出最大内存）做准备
        xor edx, edx

.find_max_mem_area:
        ; edx 用来记录当前最大的内存的结束地址 其实就是内存的最大地址
        mov eax, [ebx] ; ARDS 结构体的头 4 个字节（即 BaseAddrLow）存入了 eax
        add eax, [ebx + 8] ; 起始地址 + 长度 = 当前内存块的结束地址
        add ebx, 20     ; 目前记录的最大内存地址” (edx) 与 “当前算出来的结束地址” (eax) 进行比较
        cmp edx, eax
        jge .next_ards
        mov edx, eax    ; 如果 “当前算出来的结束地址” 大于 “目前记录的最大内存地址”，则更新最大内存地址;

.next_ards:
        loop .find_max_mem_area
        jmp .mem_get_ok

.e820_mem_get_failed:
        mov byte [gs:0], 'f'
        mov byte [gs:2], 'a'
        mov byte [gs:4], 'i'
        mov byte [gs:6], 'l'
        mov byte [gs:8], 'e'
        mov byte [gs:10], 'd'
        ; 内存检测失败，不再继续向下执行
        jmp $

.mem_get_ok:
        mov [total_memory_bytes], edx
        ; 开始进入保护模式
        ; 打开A20地址线
        in al, 0x92   ; 从0x92端口读取一个字节 System Control Port A 包含 A20 Gate Enable System Reset
        or al, 00000010B
        out 0x92, al

        ; 加载gdt
        lgdt [gdt_ptr]

        ; cr0第0位置1
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

        
        ; 创建页目录及页表 并根据需要创建里面的内容
        call setup_page

        ; 保存gdt表
        sgdt [gdt_ptr]

        ; 重新设置gdt描述符， 使虚拟地址指向内核的第一个页表
        mov ebx, [gdt_ptr + 2]
        or dword [ebx + 0x18 + 4], 0xc0000000 ; 3GB, 视频段是第三个段描述符 每个8字节 24=0x18, 取高4位（段基址）
        add dword [gdt_ptr + 2], 0xc0000000

        add esp, 0xc0000000 ; 将栈指针同样映射到内核地址

        ; 页目录的地址赋值给cr3
        mov eax, PAGE_DIR_TABLE_POS
        mov cr3, eax

        ; 打开cr0 的pg位
        mov eax, cr0
        or eax, 0x80000000
        mov cr0, eax

        ; 开启分页后 用gdt 新的地址重新加载
        lgdt [gdt_ptr]

        mov byte [gs:160], 'V'          ; 在视频内存偏移160的位置写入字符'V'
        mov byte [gs:161], 0x1f
        
        jmp $

;----------------- 页表--------------------
setup_page:
        ; 页表目录占用4KB
        mov ecx, 4096   ; 清理计数：4096字节
        mov esi, 0      ; 清理起始地址, 源索引寄存器
.clear_page_dir:
        mov byte [PAGE_DIR_TABLE_POS + esi], 0
        inc esi
        loop .clear_page_dir ; 会将 ecx 寄存器的值 自动减1

; 创建页目录项 （用于索引页表，每个页目录项记录页表的物理地址 20位大小 因为页大小为4KB，低12位一定是0 所以忽略， 和页的属性）
.create_pde:
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x1000 ; 指向index=1 的页目录项
        mov ebx, eax ; 用来保存页目录表的地址

        or eax, PG_P | PG_US_U | PG_RW_W ; 设置属性 物理内存中存在 user 写
        mov [PAGE_DIR_TABLE_POS + 0x000], eax
        ; 按需分配 当前只在内核空间分配一个pde 768
        mov [PAGE_DIR_TABLE_POS + 0xc00], eax ; 0xc00 * 4M = 3GB  这个pde管理3GB开始的内存区域， 也就是内核空间
        sub eax, 0x1000
        mov [PAGE_DIR_TABLE_POS + 4092], eax ; 最后一个指向页目录表本身

; 创建pte 页表项
        mov ecx, 256 ; 4k
        mov esi, 0
        mov edx, PG_P | PG_US_U | PG_RW_W
.create_pte:
        mov [ebx + esi * 4], edx ; 一个pte的大小是4字节
        add edx, 4096 ; 因为内一个页表项 管理的内存的大小是4KB， 所以下一个管理的内存物理地址是上一个+4KB
        inc esi
        loop .create_pte

;创建内核其他的页目录项 之前只创建了3G开始的第一个
        mov eax, PAGE_DIR_TABLE_POS
        add eax, 0x2000 ; 8kB 也就是第三个页目录表起始地址
        or eax, PG_P | PG_US_U | PG_RW_W ; 设置属性 物理内存中存在 user 写
        mov ebx, PAGE_DIR_TABLE_POS
        mov ecx, 254 ; 设置循环计数器为254,1G = 256个页
        mov esi, 769 ; 内核内存第二个页
.create_kernel_pde:
        mov [ebx + esi * 4], eax
        inc esi
        add eax, 0x1000
        loop .create_kernel_pde
        ret








