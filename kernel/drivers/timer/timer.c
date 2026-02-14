#include "timer.h"
#include "io.h"
#include "interrupts.h"

#define PIT_FREQUENCY 1193182
#define PIT_COMMAND 0x43
#define PIT_CHANNEL0 0x40

static volatile uint64_t timer_ticks = 0;
static uint32_t timer_frequency = 0;

static void timer_handler(struct interrupt_frame* frame) {
    (void)frame;
    timer_ticks++;
}

void timer_init(uint32_t frequency) {
    timer_frequency = frequency;
    timer_ticks = 0;
    
    // Calculer le diviseur
    uint32_t divisor = PIT_FREQUENCY / frequency;
    
    // Configurer le PIT
    outb(PIT_COMMAND, 0x36); // Mode 3 (square wave), binary
    outb(PIT_CHANNEL0, divisor & 0xFF);
    outb(PIT_CHANNEL0, (divisor >> 8) & 0xFF);
    
    // Enregistrer le gestionnaire d'interruption (IRQ0 = INT 32)
    register_interrupt_handler(32, timer_handler);
}

uint64_t timer_get_ticks(void) {
    return timer_ticks;
}

void timer_sleep(uint32_t ms) {
    uint64_t target = timer_ticks + (ms * timer_frequency / 1000);
    while (timer_ticks < target) {
        asm volatile("hlt");
    }
}
