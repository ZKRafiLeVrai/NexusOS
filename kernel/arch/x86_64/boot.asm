; NexusOS Bootloader - Multiboot2 compliant
; Architecture: x86_64 (64-bit)
; Maps ALL of lower 4GB for UEFI compatibility

section .multiboot
align 8
multiboot_header_start:
    dd 0xE85250D6                ; Magic
    dd 0                         ; Architecture (i386)
    dd multiboot_header_end - multiboot_header_start
    dd -(0xE85250D6 + 0 + (multiboot_header_end - multiboot_header_start))
    
    ; Framebuffer tag
    align 8
    dw 5, 0                      ; type, flags
    dd 20                        ; size
    dd 1024, 768, 32             ; width, height, depth
    
    ; End tag
    align 8
    dw 0, 0, 8                   ; type, flags, size
multiboot_header_end:

section .bss
align 16
stack_bottom:
    resb 16384
stack_top:

; Page tables - map first 4GB with huge pages
align 4096
pml4_table:
    resb 4096
pdp_table:
    resb 4096
pd_tables:
    resb 4096 * 4                ; 4 PD tables for 4GB

section .note.GNU-stack noalloc noexec nowrite progbits

section .text
bits 32
global kernel_entry
extern kernel_main

kernel_entry:
    cli
    mov edi, ebx
    mov esi, eax
    mov esp, stack_top
    
    call check_cpuid
    call check_long_mode
    call setup_page_tables
    call enable_paging
    
    lgdt [gdt64.pointer]
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
    je .error
    ret
.error:
    mov dword [0xb8000], 0x4f434f4e
    hlt
    jmp $

check_long_mode:
    mov eax, 0x80000000
    cpuid
    cmp eax, 0x80000001
    jb .error
    mov eax, 0x80000001
    cpuid
    test edx, 1 << 29
    jz .error
    ret
.error:
    mov dword [0xb8000], 0x4f4c4f4e
    hlt
    jmp $

setup_page_tables:
    ; Zero all tables
    mov edi, pml4_table
    mov ecx, 6144
    xor eax, eax
    rep stosd
    
    ; PML4[0] -> PDP
    mov eax, pdp_table
    or eax, 0x03
    mov [pml4_table], eax
    
    ; PDP[0-3] -> PD[0-3]
    mov ecx, 4
    mov edi, pdp_table
    mov eax, pd_tables
    or eax, 0x03
.setup_pdp:
    mov [edi], eax
    add eax, 0x1000
    add edi, 8
    loop .setup_pdp
    
    ; Fill 4 PD tables with 2MB huge pages
    ; This maps 4GB: 4 tables * 512 entries * 2MB = 4GB
    mov edi, pd_tables
    mov eax, 0x83                ; present + writable + huge
    mov ecx, 2048                ; 4 * 512 entries
.map_pd:
    mov [edi], eax
    add eax, 0x200000
    add edi, 8
    loop .map_pd
    ret

enable_paging:
    ; Load PML4
    mov eax, pml4_table
    mov cr3, eax
    
    ; Enable PAE
    mov eax, cr4
    or eax, 1 << 5
    mov cr4, eax
    
    ; Enable Long Mode
    mov ecx, 0xC0000080
    rdmsr
    or eax, 1 << 8
    wrmsr
    
    ; Enable paging
    mov eax, cr0
    or eax, 1 << 31
    mov cr0, eax
    ret

bits 64
long_mode_start:
    ; Load segments
    mov ax, gdt64.data
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Set stack
    mov rsp, stack_top
    xor rbp, rbp
    
    ; Clear all registers
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
    
    ; Call kernel
    call kernel_main
    
    ; Halt if kernel returns
    cli
.hang:
    hlt
    jmp .hang

section .rodata
align 16
gdt64:
    dq 0
.code: equ $ - gdt64
    dq (1<<43) | (1<<44) | (1<<47) | (1<<53)
.data: equ $ - gdt64
    dq (1<<44) | (1<<47)
.pointer:
    dw $ - gdt64 - 1
    dq gdt64