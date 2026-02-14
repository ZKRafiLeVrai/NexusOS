#ifndef KERNEL_INTERRUPTS_H
#define KERNEL_INTERRUPTS_H

#include "types.h"

// Structure d'une entrée IDT
struct idt_entry {
    uint16_t offset_low;
    uint16_t selector;
    uint8_t  ist;
    uint8_t  type_attr;
    uint16_t offset_mid;
    uint32_t offset_high;
    uint32_t zero;
} PACKED;

// Pointeur IDT
struct idt_ptr {
    uint16_t limit;
    uint64_t base;
} PACKED;

// Registres sauvegardés lors d'une interruption
struct interrupt_frame {
    uint64_t r15, r14, r13, r12, r11, r10, r9, r8;
    uint64_t rdi, rsi, rbp, rsp, rbx, rdx, rcx, rax;
    uint64_t int_no, err_code;
    uint64_t rip, cs, rflags, userrsp, ss;
} PACKED;

typedef void (*interrupt_handler_t)(struct interrupt_frame*);

#ifdef __cplusplus
extern "C" {
#endif

void interrupts_init(void);
void register_interrupt_handler(uint8_t n, interrupt_handler_t handler);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_INTERRUPTS_H
