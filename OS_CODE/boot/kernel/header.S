header:
    program_length dd program_end-program_start ; 5字节
    start_addr     dd program_start             ; 8字节

body:
program_start:      ; 偏移 4+4 8字节
    mov ax, 0x1234  ; 3字节
    jmp $           ; 2字节
program_end:
