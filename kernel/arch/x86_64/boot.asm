; NexusOS Bootloader - Multiboot2 compliant
; Architecture: x86_64 (64-bit)
; Supporte BIOS et UEFI

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
; On va mapper les premiers 4GB avec des huge pages (2MB)
align 4096
pml4_table:
    resb 4096
pdp_table:
    resb 4096
pd_tables:
    resb 4096 * 4  ; 4 tables PD pour 4GB (512 * 2MB * 4 = 4GB)

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
    
    ; Afficher 'OK' pour debug
    mov dword [0xb8000], 0x0f4b0f4f  ; 'OK' en blanc
    
    ; Vérifier le support du mode long
    call check_cpuid
    call check_long_mode
    
    ; Afficher '64' pour debug
    mov dword [0xb8004], 0x0f340f36  ; '64' en blanc
    
    ; Configurer les tables de pagination (4GB)
    call setup_page_tables
    
    ; Afficher 'PG' pour debug
    mov dword [0xb8008], 0x0f470f50  ; 'PG' en blanc
    
    ; Activer la pagination
    call enable_paging
    
    ; Afficher 'EN' pour debug
    mov dword [0xb800c], 0x0f4e0f45  ; 'EN' en blanc
    
    ; Charger le GDT 64-bit
    lgdt [gdt64.pointer]
    
    ; Passer en mode long avec un far jump
    jmp gdt64.code:long_mode_start

check_cpuid:
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
    mov dword [0xb8000], 0x4f434f4e  ; 'NC' en rouge
    hlt
    jmp $

check_long_mode:
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
    mov dword [0xb8000], 0x4f4c0f4e  ; 'NL' en rouge
    hlt
    jmp $

setup_page_tables:
    ; Nettoyer toutes les tables
    mov edi, pml4_table
    mov ecx, 6144  ; (1 + 1 + 4) * 1024 pages
    xor eax, eax
    rep stosd
    
    ; PML4[0] -> PDP
    mov eax, pdp_table
    or eax, 0b11        ; Present + writable
    mov [pml4_table], eax
    
    ; PDP[0..3] -> PD[0..3] (4 entrées pour 4GB)
    mov ecx, 4          ; 4 tables PD
    mov edi, pdp_table
    mov eax, pd_tables
    or eax, 0b11
.setup_pdp:
    mov [edi], eax
    add eax, 0x1000     ; Prochaine table PD
    add edi, 8
    loop .setup_pdp
    
    ; Remplir les 4 tables PD avec des huge pages (2MB chacune)
    ; Total: 4 tables * 512 entrées * 2MB = 4GB
    mov edi, pd_tables
    mov eax, 0x00000083  ; Page 0, present + writable + huge page
    mov ecx, 2048        ; 4 tables * 512 entrées
.map_pd:
    mov [edi], eax
    add eax, 0x200000   ; Prochaine huge page de 2MB
    add edi, 8
    loop .map_pd
    
    ret

enable_paging:
    ; Charger PML4 dans CR3
    mov eax, pml4_table
    mov cr3, eax
    
    ; Activer PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5      ; PAE
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
    ; Afficher 'LM' pour debug (mode long activé)
    mov rax, 0x0f4d0f4c  ; 'LM' en blanc
    mov [0xb8010], rax
    
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
    
    ; Afficher 'GO' pour debug
    mov rax, 0x0f4f0f47  ; 'GO' en blanc
    mov [0xb8014], rax
    
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
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)     ; Code segment (64-bit)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47)                          ; Data segment
.pointer:
    dw $ - gdt64 - 1
    dq gdt64