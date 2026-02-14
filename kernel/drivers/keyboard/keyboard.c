#include "keyboard.h"
#include "io.h"
#include "interrupts.h"

#define KEYBOARD_DATA_PORT 0x60
#define KEYBOARD_STATUS_PORT 0x64

static char keyboard_buffer[KEYBOARD_BUFFER_SIZE];
static volatile size_t kbd_read_pos = 0;
static volatile size_t kbd_write_pos = 0;
static volatile bool shift_pressed = false;
static volatile bool ctrl_pressed = false;

// Scancode vers ASCII (layout US)
static const char scancode_to_ascii[] = {
    0,  27, '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', '-', '=', '\b',
    '\t', 'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p', '[', ']', '\n',
    0, 'a', 's', 'd', 'f', 'g', 'h', 'j', 'k', 'l', ';', '\'', '`',
    0, '\\', 'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/', 0,
    '*', 0, ' '
};

static const char scancode_to_ascii_shift[] = {
    0,  27, '!', '@', '#', '$', '%', '^', '&', '*', '(', ')', '_', '+', '\b',
    '\t', 'Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P', '{', '}', '\n',
    0, 'A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L', ':', '"', '~',
    0, '|', 'Z', 'X', 'C', 'V', 'B', 'N', 'M', '<', '>', '?', 0,
    '*', 0, ' '
};

static void keyboard_handler(struct interrupt_frame* frame) {
    (void)frame;
    
    uint8_t scancode = inb(KEYBOARD_DATA_PORT);
    
    // Gérer les touches spéciales
    if (scancode == 0x2A || scancode == 0x36) { // Shift pressed
        shift_pressed = true;
        return;
    }
    if (scancode == 0xAA || scancode == 0xB6) { // Shift released
        shift_pressed = false;
        return;
    }
    if (scancode == 0x1D) { // Ctrl pressed
        ctrl_pressed = true;
        return;
    }
    if (scancode == 0x9D) { // Ctrl released
        ctrl_pressed = false;
        return;
    }
    
    // Ignorer les scancodes de release
    if (scancode & 0x80) {
        return;
    }
    
    // Convertir le scancode en caractère
    char c = 0;
    if (scancode < sizeof(scancode_to_ascii)) {
        c = shift_pressed ? scancode_to_ascii_shift[scancode] : scancode_to_ascii[scancode];
    }
    
    if (c != 0) {
        // Ajouter au buffer circulaire
        size_t next_pos = (kbd_write_pos + 1) % KEYBOARD_BUFFER_SIZE;
        if (next_pos != kbd_read_pos) {
            keyboard_buffer[kbd_write_pos] = c;
            kbd_write_pos = next_pos;
        }
    }
}

void keyboard_init(void) {
    kbd_read_pos = 0;
    kbd_write_pos = 0;
    shift_pressed = false;
    ctrl_pressed = false;
    
    // Enregistrer le gestionnaire d'interruption (IRQ1 = INT 33)
    register_interrupt_handler(33, keyboard_handler);
}

bool keyboard_haschar(void) {
    return kbd_read_pos != kbd_write_pos;
}

char keyboard_getchar(void) {
    while (!keyboard_haschar()) {
        asm volatile("hlt");
    }
    
    char c = keyboard_buffer[kbd_read_pos];
    kbd_read_pos = (kbd_read_pos + 1) % KEYBOARD_BUFFER_SIZE;
    return c;
}

void keyboard_wait_key(void) {
    while (!keyboard_haschar()) {
        asm volatile("hlt");
    }
}
