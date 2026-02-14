#include "types.h"
#include "video.h"
#include "memory.h"
#include "interrupts.h"
#include "scheduler.h"
#include "vfs.h"
#include "keyboard.h"
#include "timer.h"
#include "pci.h"
#include "shell.h"

// Logo NexusOS
static const char* logo[] = {
    "  _   _                     ___  ____  ",
    " | \\ | | _____  ___   _ ___|_ \\ / ___| ",
    " |  \\| |/ _ \\ \\/ / | | / __|| |\\___ \\ ",
    " | |\\  |  __/>  <| |_| \\__ \\| | ___) |",
    " |_| \\_|\\___/_/\\_\\\\__,_|___/|_||____/ ",
    "",
    " NexusOS v1.0 - 64-bit Operating System",
    " Copyright (c) 2025 - Licensed under MIT",
    ""
};

extern "C" void kernel_main(void) {
    // Initialiser l'affichage vidéo
    video_init();
    video_clear();
    
    // Afficher le logo
    for (size_t i = 0; i < sizeof(logo) / sizeof(logo[0]); i++) {
        video_print(logo[i]);
        video_print("\n");
    }
    
    video_print("\n[BOOT] Initializing NexusOS...\n");
    
    // Initialiser le gestionnaire de mémoire
    video_print("[BOOT] Initializing memory manager...\n");
    memory_init();
    
    // Initialiser les interruptions
    video_print("[BOOT] Initializing interrupts (IDT)...\n");
    interrupts_init();
    
    // Initialiser le timer
    video_print("[BOOT] Initializing PIT timer...\n");
    timer_init(100); // 100 Hz
    
    // Initialiser le clavier
    video_print("[BOOT] Initializing keyboard driver...\n");
    keyboard_init();
    
    // Initialiser le bus PCI
    video_print("[BOOT] Scanning PCI bus...\n");
    pci_init();
    
    // Initialiser le planificateur de tâches
    video_print("[BOOT] Initializing task scheduler...\n");
    scheduler_init();
    
    // Initialiser le système de fichiers
    video_print("[BOOT] Initializing virtual file system...\n");
    vfs_init();
    
    // Activer les interruptions
    video_print("[BOOT] Enabling interrupts...\n");
    asm volatile("sti");
    
    video_print("[BOOT] Boot sequence completed successfully!\n");
    video_print("\n");
    
    // Démarrer le shell
    video_print("Starting NexusOS shell...\n\n");
    shell_run();
    
    // Si le shell se termine, arrêter
    video_print("\nKernel halted.\n");
    while (1) {
        asm volatile("hlt");
    }
}
