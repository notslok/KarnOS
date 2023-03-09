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

; sepearated 32 bit kernel code from here
[BITS 32]
load32:
    mov eax, 1  ;starting sector to load from (LBA -> Logical Bloack Address)
    mov ecx, 100 ; total no. of sector we want to load
    mov edi, 0x0100000 ; location where we want to load
    call ata_lba_read ; calling driver to read data from the disk
    jmp CODE_SEG:0x100000

ata_lba_read:
    mov ebx, eax ; Backup the LBA(Logical Block Address)
    
    ; Send highest 8 bits of LBA to hard disk controller
    shr eax, 24   ; (sh)IFT (r)IGHT by 24 bits (-> LBA's value)
    or eax, 0xE0  ; or Select the master drive
    mov dx, 0x1F6 ; loading address of CPU's I/O port bus in dx
    out dx, al    ; Transferring data from al register to I/O bus
    ; Finished sending the highest 8 bits of the LDA

    ; Send the total sectors to read
    mov eax, ecx  ; eax <- ecx(=100)
    mov dx, 0x1F2 ; storing port number of another I/O bus
    out dx, al    ; Transferring data from al register to I/O bus
    ; Finished reading total number of sectors to read  

    ; Send more bits of the LBA
    mov eax, ebx ; Restore the backup LBA
    mov dx, 0x1F3
    out dx, al
    ; Finished sending more bits of the LBA

    ; Send more bits of the LBA
    mov dx, 0x1F4
    mov eax, ebx ; Restore and backup LBA
    shr eax, 8
    out dx, al
    ; Finished sending more bits of LBA

    ; Send upper 16 bits of the LBA
    mov dx, 0x1F5
    mov eax, ebx
    shr eax, 16
    out dx, al
    ; Finished sending upper 16 bits of the LBA

    mov dx, 0x1f7
    mov al, 0x20
    out dx, al

; Read all sectors into memory
.next_sector:
    push ecx

; Checking if we need to read
.try_again:
    mov dx, 0x1f7
    in al, dx
    test al, 8
    jz .try_again

; We need to read 256 words at a time
    mov ecx, 256    ; loading another sector in ecx
    mov dx, 0x1F0
    rep insw  ; INSW -> Input word from I/O port specified in DX into memory location specified in ES:(E)DI
    pop ecx
    loop .next_sector
    ; End of reading sectors into memory
    ret

times 510-($ - $$) db 0 ; setting boot signature
dw 0xAA55