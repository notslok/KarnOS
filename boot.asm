ORG 0 ; offset...in boot process BIOS loads bootloader in this location 
BITS 16 ; telling assembler to assemble only 16 bit codes(architecture)
_start:
    jmp short start
    nop

times 33 db 0

start:
    jmp 0x7c0:step2; setting code segment to 0x7c0

step2:    
    cli ; clear interrupts
    mov ax, 0x7c0
    mov ds, ax
    mov es, ax
    mov ax, 0x00
    mov ss, ax  ; setting stack segment
    mov sp, 0x7c00 ; setting stack pointer
    sti ; enables interrupts

    mov ah, 2 ; Read sector command
    mov al, 1 ; One sector to read from
    mov ch, 0 ; Cylinder lower 8 bits -> using CHS here
    mov cl, 2 ; Read sector 2
    mov dh, 0 ; Head number
    mov bx, buffer
    int 0x13
    jc error ; if carray flag(returned by interrupt 0x13) is set -> jump to error label below 

    mov si, buffer ; after reading from disk is done and written in buffer label, move the read data to si register
    call print ; print the content of si register
    
    jmp $

error:
    mov si, error_message ; get the error message
    call print ;  call the routine to print error message stored in si register
    jmp $

print:
    mov bx, 0
.loop:    
    lodsb
    cmp al, 0
    je .done
    call print_char
    jmp .loop
.done:
    ret

print_char:
    mov ah, 0eh
    int 0x10    ; calling bios interrupt
    ret

error_message: db 'Failed to load sector!', 0

times 510-($ - $$) db 0 ; setting boot signature
dw 0xAA55

buffer: ; label where we write data read from the disk

