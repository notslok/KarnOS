[BITS 32]   ; all code under this is treated as 32 bit

global _start ; exporting _start label
extern kernel_main

CODE_SEG equ 0x08
DATA_SEG equ 0x10

_start:
    mov ax, DATA_SEG    ; like int "step2:" level which was initialising registers in real mode...here we do the same for protected mode
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov ebp, 0x00200000
    mov esp, ebp

    ; Enabling A20 line
    in al, 0x92 ;  reading from the processor bus
    or al, 2
    out 0x92, al ;  writing into processor bus
    
    call kernel_main

    jmp $   ; now that at this point we are in protected mode, reading from disk would require creating a driver

times 512-($ - $$) db 0 ; for aligment of asm code with 16 bit clang code