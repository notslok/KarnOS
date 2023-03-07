ORG 0x7c00 ; offset...in boot process BIOS loads bootloader in this location 
BITS 16 ; telling assembler to assemble only 16 bit codes(architecture)

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

_start:
    jmp short start
    nop

times 33 db 0

start:
    jmp 0:step2; setting code segment to 0x7c0

step2:    
    cli ; clear interrupts
    mov ax, 0x00
    mov ds, ax
    mov es, ax
    mov ss, ax  ; setting stack segment
    mov sp, 0x7c00 ; setting stack pointer
    sti ; enables interrupts

.load_protected:
    cli ; clear interrupts
    lgdt[gdt_descriptor]    ; load GDT
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax    ; entering protected mode by setting control register
    jmp CODE_SEG:load32

; GDT -> Global Descriptor table for protected mode
gdt_start:
gdt_null:
    dd 0x0
    dd 0x0

; offset 0x8
gdt_code:     ; CS(Code Segment) should point to this 
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits  
    db 0      ; Base 16-23 bits
    db 0x9a   ; Acess byte
    db 11001111b ; HIgh 4 bit flags and low 4 bit flags
    db 0      ; Base 24-31

; offset 0x10
gdt_data:     ; DS, SS, ES, FS, GS
    dw 0xffff ; Segment limit first 0-15 bits
    dw 0      ; Base first 0-15 bits  
    db 0      ; Base 16-23 bits
    db 0x9a   ; Acess byte
    db 11001111b ; HIgh 4 bit flags and low 4 bit flags
    db 0      ; Base 24-31

gdt_end:

gdt_descriptor:
    dw gdt_end- gdt_start-1 ; size of GDT(  Global Descriptor Table)
    dd gdt_start    ; offset of GDT

[BITS 32]   ; all code under this is treated as 32 bit
load32:
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
    
    jmp $   ; now that at this point we are in protected mode, reading from disk would require creating a driver

times 510-($ - $$) db 0 ; setting boot signature
dw 0xAA55

buffer: ; label where we write data read from the disk

