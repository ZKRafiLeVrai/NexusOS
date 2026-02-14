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
pt_table:
    resb 4096

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
bits 32
global kernel_entry
extern kernel_main

kernel_entry:
    ; Désactiver les interruptions
    cli
    
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
    
    ; Passer en mode long avec un far jump
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
    mov dword [0xb8000], 0x4f434f4e  ; 'NC' en blanc sur rouge
    hlt
    jmp $

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
    mov dword [0xb8000], 0x4f4c4f4e  ; 'NL' en blanc sur rouge
    hlt
    jmp $

setup_page_tables:
    ; Nettoyer toutes les tables
    mov edi, pml4_table
    mov ecx, 4096  ; 4 * 4096 / 4
    xor eax, eax
    rep stosd
    
    ; PML4[0] -> PDP (identity mapping low memory)
    mov eax, pdp_table
    or eax, 0b11        ; Present + writable
    mov [pml4_table], eax
    
    ; PDP[0] -> PD
    mov eax, pd_table
    or eax, 0b11
    mov [pdp_table], eax
    
    ; PD[0] -> PT (map first 2MB using 4KB pages for better control)
    mov eax, pt_table
    or eax, 0b11
    mov [pd_table], eax
    
    ; Remplir PT avec les 512 premières pages (2MB total)
    mov edi, pt_table
    mov eax, 0x00000003  ; Page 0, present + writable
    mov ecx, 512         ; 512 pages de 4KB = 2MB
.map_pt:
    mov [edi], eax
    add eax, 0x1000     ; Prochaine page de 4KB
    add edi, 8
    loop .map_pt
    
    ; Mapper aussi les 6MB suivants avec huge pages pour le reste du kernel
    mov eax, 0x200000   ; 2MB
    or eax, 0b10000011  ; Present + writable + huge page
    mov [pd_table + 8], eax
    
    mov eax, 0x400000   ; 4MB
    or eax, 0b10000011
    mov [pd_table + 16], eax
    
    mov eax, 0x600000   ; 6MB
    or eax, 0b10000011
    mov [pd_table + 24], eax
    
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
    or eax, 1 << 8      ; LME (Long Mode Enable)
    or eax, 1 << 11     ; NXE (No-Execute Enable)
    wrmsr
    
    ; Activer la pagination
    mov eax, cr0
    or eax, 1 << 31     ; PG (Paging)
    or eax, 1 << 16     ; WP (Write Protect)
    mov cr0, eax
    
    ret

bits 64
long_mode_start:
    ; Charger les segments de données
    mov ax, gdt64.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Définir la pile en mode 64-bit
    mov rsp, stack_top
    
    ; Nettoyer les registres
    xor rbp, rbp
    xor rax, rax
    xor rbx, rbx
    xor rcx, rcx
    xor rdx, rdx
    xor rsi, rsi
    xor rdi, rdi
    xor r8, r8
    xor r9, r9
    xor r10, r10
    xor r11, r11
    xor r12, r12
    xor r13, r13
    xor r14, r14
    xor r15, r15
    
    ; Appeler le kernel C/C++
    call kernel_main
    
    ; Si le kernel retourne, arrêter
    cli
.hang:
    hlt
    jmp .hang

section .rodata
gdt64:
    dq 0                                          ; Null descriptor
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)     ; Code segment (64-bit, executable, present, long mode)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47)                          ; Data segment (present, writable)
.pointer:
    dw $ - gdt64 - 1
    dq gdt64