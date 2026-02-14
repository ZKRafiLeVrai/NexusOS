/* NexusOS Kernel Linker Script */

ENTRY(kernel_entry)

SECTIONS
{
    /* Le kernel commence à 1MB en mémoire physique */
    . = 1M;

    .boot :
    {
        *(.multiboot)
    }

    /* Section de code */
    .text ALIGN(4K) : AT(ADDR(.text))
    {
        *(.text*)
    }

    /* Section des données en lecture seule */
    .rodata ALIGN(4K) : AT(ADDR(.rodata))
    {
        *(.rodata*)
    }

    /* Section des données initialisées */
    .data ALIGN(4K) : AT(ADDR(.data))
    {
        *(.data*)
    }

    /* Section BSS (données non initialisées) */
    .bss ALIGN(4K) : AT(ADDR(.bss))
    {
        *(COMMON)
        *(.bss*)
        kernel_end = .;
    }
}
