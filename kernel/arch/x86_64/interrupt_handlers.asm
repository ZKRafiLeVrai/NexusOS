; NexusOS - Interrupt Service Routine Stubs
bits 64

extern interrupt_handler_common

; Macro pour ISR sans code d'erreur
%macro ISR_NOERRCODE 1
global isr%1
isr%1:
    push qword 0           ; Code d'erreur factice
    push qword %1          ; Numéro d'interruption
    jmp isr_common_stub
%endmacro

; Macro pour ISR avec code d'erreur
%macro ISR_ERRCODE 1
global isr%1
isr%1:
    push qword %1          ; Numéro d'interruption
    jmp isr_common_stub
%endmacro

; Exceptions CPU (0-31)
ISR_NOERRCODE 0    ; Division par zéro
ISR_NOERRCODE 1    ; Debug
ISR_NOERRCODE 2    ; NMI
ISR_NOERRCODE 3    ; Breakpoint
ISR_NOERRCODE 4    ; Overflow
ISR_NOERRCODE 5    ; Bound range exceeded
ISR_NOERRCODE 6    ; Invalid opcode
ISR_NOERRCODE 7    ; Device not available
ISR_ERRCODE   8    ; Double fault
ISR_NOERRCODE 9    ; Coprocessor segment overrun
ISR_ERRCODE   10   ; Invalid TSS
ISR_ERRCODE   11   ; Segment not present
ISR_ERRCODE   12   ; Stack-segment fault
ISR_ERRCODE   13   ; General protection fault
ISR_ERRCODE   14   ; Page fault
ISR_NOERRCODE 15   ; Reserved
ISR_NOERRCODE 16   ; x87 FPU error
ISR_ERRCODE   17   ; Alignment check
ISR_NOERRCODE 18   ; Machine check
ISR_NOERRCODE 19   ; SIMD exception
ISR_NOERRCODE 20   ; Virtualization exception
ISR_NOERRCODE 21   ; Reserved
ISR_NOERRCODE 22   ; Reserved
ISR_NOERRCODE 23   ; Reserved
ISR_NOERRCODE 24   ; Reserved
ISR_NOERRCODE 25   ; Reserved
ISR_NOERRCODE 26   ; Reserved
ISR_NOERRCODE 27   ; Reserved
ISR_NOERRCODE 28   ; Reserved
ISR_NOERRCODE 29   ; Reserved
ISR_ERRCODE   30   ; Security exception
ISR_NOERRCODE 31   ; Reserved

; IRQs (32-47)
%assign i 32
%rep 16
    ISR_NOERRCODE i
    %assign i i+1
%endrep

; ISRs supplémentaires (48-255)
%assign i 48
%rep 208
    ISR_NOERRCODE i
    %assign i i+1
%endrep

; Stub commun
isr_common_stub:
    ; Sauvegarder tous les registres
    push rax
    push rcx
    push rdx
    push rbx
    push rsp
    push rbp
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    push r12
    push r13
    push r14
    push r15
    
    ; Appeler le gestionnaire C
    mov rdi, rsp
    call interrupt_handler_common
    
    ; Restaurer les registres
    pop r15
    pop r14
    pop r13
    pop r12
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rbp
    add rsp, 8  ; Ignorer le RSP sauvegardé
    pop rbx
    pop rdx
    pop rcx
    pop rax
    
    ; Nettoyer le code d'erreur et le numéro d'interruption
    add rsp, 16
    
    ; Retour de l'interruption
    iretq

; Table des pointeurs ISR
section .data
global isr_stub_table
isr_stub_table:
%assign i 0
%rep 256
    dq isr%+i
    %assign i i+1
%endrep
