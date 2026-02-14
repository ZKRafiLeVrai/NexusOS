/* NexusOS Kernel Linker Script */

ENTRY(kernel_entry)

SECTIONS
{
    /* Le kernel commence à 1MB en mémoire physique */
    . = 0x100000;

    /* Section de boot (multiboot) doit être au début */
    .boot ALIGN(4K) :
    {
        *(.multiboot)
    }

    /* Section de code */
    .text ALIGN(4K) :
    {
        *(.text*)
    }

    /* Section des données en lecture seule */
    .rodata ALIGN(4K) :
    {
        *(.rodata*)
    }

    /* Section des données initialisées */
    .data ALIGN(4K) :
    {
        *(.data*)
    }

    /* Section BSS (données non initialisées) */
    .bss ALIGN(4K) :
    {
        *(COMMON)
        *(.bss*)
    }
    
    /* Note GNU-stack section */
    .note.GNU-stack (NOLOAD) :
    {
        *(.note.GNU-stack)
    }

    /* Fin du kernel */
    . = ALIGN(4K);
    kernel_end = .;
}