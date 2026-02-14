; NexusOS Bootloader - Multiboot2 compliant
; Architecture: x86_64 (64-bit)

section .multiboot
align 8
multiboot_header_start:
    ; Magic number Multiboot2
    dd 0xE85250D6
    ; Architecture (i386)
    dd 0
    ; Header length
    dd multiboot_header_end - multiboot_header_start
    ; Checksum
    dd -(0xE85250D6 + 0 + (multiboot_header_end - multiboot_header_start))
    
    ; Framebuffer tag
    align 8
    dw 5        ; type: framebuffer
    dw 0        ; flags
    dd 20       ; size
    dd 1024     ; width
    dd 768      ; height
    dd 32       ; depth
    
    ; End tag
    align 8
    dw 0        ; type: end
    dw 0        ; flags
    dd 8        ; size
multiboot_header_end:

section .bss
align 16
stack_bottom:
    resb 16384  ; 16 KiB stack
stack_top:

; Page tables pour le mode 64-bit
align 4096
pml4_table:
    resb 4096
pdp_table:
    resb 4096
pd_table:
    resb 4096

section .text
bits 32
global kernel_entry
extern kernel_main

kernel_entry:
    ; Sauvegarder les registres Multiboot
    mov edi, ebx        ; Multiboot info structure
    mov esi, eax        ; Multiboot magic number
    
    ; Configurer la pile
    mov esp, stack_top
    
    ; Vérifier le support du mode long
    call check_cpuid
    call check_long_mode
    
    ; Configurer les tables de pagination
    call setup_page_tables
    
    ; Activer la pagination
    call enable_paging
    
    ; Charger le GDT 64-bit
    lgdt [gdt64.pointer]
    
    ; Passer en mode long
    jmp gdt64.code:long_mode_start

check_cpuid:
    ; Vérifier si CPUID est supporté
    pushfd
    pop eax
    mov ecx, eax
    xor eax, 1 << 21
    push eax
    popfd
    pushfd
    pop eax
    push ecx
    popfd
    cmp eax, ecx
    je .no_cpuid
    ret
.no_cpuid:
    mov al, 'C'
    jmp error

check_long_mode:
    ; Vérifier le support du mode long
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .no_long_mode
    
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .no_long_mode
    ret
.no_long_mode:
    mov al, 'L'
    jmp error

setup_page_tables:
    ; Mapper les premiers 2MB de mémoire
    ; PML4[0] -> PDP
    mov eax, pdp_table
    or eax, 0b11        ; Present + writable
    mov [pml4_table], eax
    
    ; PDP[0] -> PD
    mov eax, pd_table
    or eax, 0b11
    mov [pdp_table], eax
    
    ; PD[0] -> 2MB page
    mov eax, 0x0
    or eax, 0b10000011  ; Present + writable + huge page
    mov [pd_table], eax
    
    ret

enable_paging:
    ; Charger PML4 dans CR3
    mov eax, pml4_table
    mov cr3, eax
    
    ; Activer PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    
    ; Activer le mode long dans EFER MSR
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; Activer la pagination
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    
    ret

error:
    ; Afficher un code d'erreur sur l'écran
    mov dword [0xb8000], 0x4f524f45  ; 'ER' en rouge
    mov dword [0xb8004], 0x4f3a4f52  ; 'R:' en rouge
    mov byte [0xb8008], al
    hlt

bits 64
long_mode_start:
    ; Initialiser les segments
    mov ax, gdt64.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Appeler le kernel C/C++
    call kernel_main
    
    ; Si le kernel retourne, arrêter
    cli
.hang:
    hlt
    jmp .hang

section .rodata
gdt64:
    dq 0                                    ; Null descriptor
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)  ; Code segment
.data: equ $ - gdt64
    dq (1<<44) | (1<<47)                    ; Data segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64
