#include "interrupts.h"
#include "io.h"
#include "video.h"

#define IDT_ENTRIES 256

static struct idt_entry idt[IDT_ENTRIES];
static struct idt_ptr idtp;
static interrupt_handler_t interrupt_handlers[IDT_ENTRIES];

// Fonctions ASM externes (définies dans interrupt_handlers.asm)
extern void* isr_stub_table[];

// Remapper le PIC
static void pic_remap(void) {
    // Sauvegarder les masques
    uint8_t a1 = inb(0x21);
    uint8_t a2 = inb(0xA1);
    
    // Initialiser le PIC maître
    outb(0x20, 0x11);
    io_wait();
    outb(0xA0, 0x11);
    io_wait();
    
    // Offset des vecteurs
    outb(0x21, 0x20); // IRQ 0-7 -> INT 32-39
    io_wait();
    outb(0xA1, 0x28); // IRQ 8-15 -> INT 40-47
    io_wait();
    
    // Configuration du mode en cascade
    outb(0x21, 0x04);
    io_wait();
    outb(0xA1, 0x02);
    io_wait();
    
    // Mode 8086
    outb(0x21, 0x01);
    io_wait();
    outb(0xA1, 0x01);
    io_wait();
    
    // Restaurer les masques
    outb(0x21, a1);
    outb(0xA1, a2);
}

static void idt_set_gate(uint8_t num, void* handler, uint8_t flags) {
    uint64_t base = (uint64_t)handler;
    
    idt[num].offset_low = base & 0xFFFF;
    idt[num].selector = 0x08; // Code segment
    idt[num].ist = 0;
    idt[num].type_attr = flags;
    idt[num].offset_mid = (base >> 16) & 0xFFFF;
    idt[num].offset_high = (base >> 32) & 0xFFFFFFFF;
    idt[num].zero = 0;
}

void interrupts_init(void) {
    // Initialiser les handlers à NULL
    for (int i = 0; i < IDT_ENTRIES; i++) {
        interrupt_handlers[i] = NULL;
    }
    
    // Remapper le PIC
    pic_remap();
    
    // Installer les ISR
    for (int i = 0; i < IDT_ENTRIES; i++) {
        idt_set_gate(i, isr_stub_table[i], 0x8E);
    }
    
    // Charger l'IDT
    idtp.limit = sizeof(idt) - 1;
    idtp.base = (uint64_t)&idt;
    
    asm volatile("lidt %0" : : "m"(idtp));
}

void register_interrupt_handler(uint8_t n, interrupt_handler_t handler) {
    interrupt_handlers[n] = handler;
}

// Gestionnaire commun des interruptions
extern "C" void interrupt_handler_common(struct interrupt_frame* frame) {
    if (interrupt_handlers[frame->int_no]) {
        interrupt_handlers[frame->int_no](frame);
    }
    
    // Envoyer EOI au PIC si nécessaire
    if (frame->int_no >= 32 && frame->int_no < 48) {
        if (frame->int_no >= 40) {
            outb(0xA0, 0x20); // EOI au PIC esclave
        }
        outb(0x20, 0x20); // EOI au PIC maître
    }
}
