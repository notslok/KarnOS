ENTRY(_start) /* Linker Script to link our bootloader and kernel*/
OUTPUT_FORMAT(binary)
SECTIONS
{
    . = 1M; /*Our kernel will be loaded at 1MiB into the memory(from start) also, 1 MiB = 1024^2 bits(in decimal) = 1000^2 bits(in hex)*//*We specify 1M because kernel is being loaded (starting from)this address in the memory so linker should also be operating at at the address and onwards*/    
    .text : ALIGN(4096)/* defining text section */
    {
        *(.text)
    }        

    .rodata : ALIGN(4096)
    {
        *(.rodata)
    }

    .data : ALIGN(4096)
    {
        *(.data)
    }

    .bss : ALIGN(4096)
    {
        *(COMMON)
        *(.bss)
    }

    .asm : ALIGN(4096)
    {
        *(.asm)
    }
}