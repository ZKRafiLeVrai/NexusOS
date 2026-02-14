#include "shell.h"
#include "video.h"
#include "keyboard.h"
#include "memory.h"
#include "vfs.h"
#include "timer.h"

#define SHELL_BUFFER_SIZE 256

static char command_buffer[SHELL_BUFFER_SIZE];
static size_t buffer_pos = 0;

// Fonctions utilitaires
static size_t strlen_shell(const char* str) {
    size_t len = 0;
    while (str[len]) len++;
    return len;
}

static int strcmp_shell(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

static int strncmp_shell(const char* s1, const char* s2, size_t n) {
    for (size_t i = 0; i < n; i++) {
        if (s1[i] != s2[i] || s1[i] == '\0') {
            return s1[i] - s2[i];
        }
    }
    return 0;
}

static void print_prompt(void) {
    video_set_color(VGA_COLOR_LIGHT_GREEN, VGA_COLOR_BLACK);
    video_print("nexus");
    video_set_color(VGA_COLOR_WHITE, VGA_COLOR_BLACK);
    video_print("$ ");
}

static void cmd_help(void) {
    video_print("NexusOS Shell - Available commands:\n");
    video_print("  help       - Display this help message\n");
    video_print("  clear      - Clear the screen\n");
    video_print("  ls         - List files in root directory\n");
    video_print("  cat <file> - Display file contents\n");
    video_print("  mem        - Display memory information\n");
    video_print("  time       - Display system uptime\n");
    video_print("  echo <msg> - Echo a message\n");
    video_print("  reboot     - Reboot the system\n");
    video_print("  halt       - Halt the system\n");
}

static void cmd_clear(void) {
    video_clear();
}

static void cmd_ls(void) {
    vfs_node_t* root = vfs_list_root();
    if (!root) {
        video_print("Error: Cannot access file system\n");
        return;
    }
    
    vfs_node_t* current = root->next;
    if (!current) {
        video_print("(empty directory)\n");
        return;
    }
    
    while (current) {
        video_print(current->name);
        if (current->type == VFS_DIRECTORY) {
            video_print("/");
        }
        video_printf(" (%u bytes)\n", (unsigned)current->size);
        current = current->next;
    }
}

static void cmd_cat(const char* filename) {
    if (!filename || strlen_shell(filename) == 0) {
        video_print("Usage: cat <filename>\n");
        return;
    }
    
    char path[VFS_MAX_PATH];
    path[0] = '/';
    size_t i = 0;
    while (filename[i] && i < VFS_MAX_PATH - 2) {
        path[i + 1] = filename[i];
        i++;
    }
    path[i + 1] = '\0';
    
    vfs_node_t* file = vfs_open(path);
    if (!file) {
        video_print("Error: File not found\n");
        return;
    }
    
    if (file->type != VFS_FILE) {
        video_print("Error: Not a file\n");
        return;
    }
    
    char* buffer = (char*)kmalloc(file->size + 1);
    int bytes_read = vfs_read(file, buffer, file->size);
    if (bytes_read > 0) {
        buffer[bytes_read] = '\0';
        video_print(buffer);
        if (buffer[bytes_read - 1] != '\n') {
            video_print("\n");
        }
    }
    kfree(buffer);
    vfs_close(file);
}

static void cmd_mem(void) {
    size_t total = memory_get_total();
    size_t used = memory_get_used();
    size_t free = memory_get_free();
    
    video_printf("Memory Information:\n");
    video_printf("  Total: %u MB\n", (unsigned)(total / 1024 / 1024));
    video_printf("  Used:  %u MB\n", (unsigned)(used / 1024 / 1024));
    video_printf("  Free:  %u MB\n", (unsigned)(free / 1024 / 1024));
}

static void cmd_time(void) {
    uint64_t ticks = timer_get_ticks();
    uint64_t seconds = ticks / 100; // 100 Hz timer
    uint64_t minutes = seconds / 60;
    uint64_t hours = minutes / 60;
    
    video_printf("System uptime: %u:%02u:%02u\n",
                 (unsigned)hours,
                 (unsigned)(minutes % 60),
                 (unsigned)(seconds % 60));
}

static void cmd_echo(const char* message) {
    if (message && strlen_shell(message) > 0) {
        video_print(message);
        video_print("\n");
    }
}

static void cmd_reboot(void) {
    video_print("Rebooting...\n");
    // Triple fault to reboot
    asm volatile("cli");
    uint8_t good = 0x02;
    while (good & 0x02) {
        good = inb(0x64);
    }
    outb(0x64, 0xFE);
    asm volatile("hlt");
}

static void cmd_halt(void) {
    video_print("System halted. You may now power off.\n");
    asm volatile("cli; hlt");
}

static void process_command(void) {
    // Null-terminate the command
    command_buffer[buffer_pos] = '\0';
    
    if (buffer_pos == 0) {
        return;
    }
    
    // Parse command
    if (strcmp_shell(command_buffer, "help") == 0) {
        cmd_help();
    } else if (strcmp_shell(command_buffer, "clear") == 0) {
        cmd_clear();
    } else if (strcmp_shell(command_buffer, "ls") == 0) {
        cmd_ls();
    } else if (strncmp_shell(command_buffer, "cat ", 4) == 0) {
        cmd_cat(command_buffer + 4);
    } else if (strcmp_shell(command_buffer, "mem") == 0) {
        cmd_mem();
    } else if (strcmp_shell(command_buffer, "time") == 0) {
        cmd_time();
    } else if (strncmp_shell(command_buffer, "echo ", 5) == 0) {
        cmd_echo(command_buffer + 5);
    } else if (strcmp_shell(command_buffer, "reboot") == 0) {
        cmd_reboot();
    } else if (strcmp_shell(command_buffer, "halt") == 0) {
        cmd_halt();
    } else {
        video_print("Unknown command: ");
        video_print(command_buffer);
        video_print("\nType 'help' for available commands.\n");
    }
    
    // Clear buffer
    buffer_pos = 0;
}

void shell_run(void) {
    video_print("Type 'help' for a list of commands.\n\n");
    print_prompt();
    
    while (1) {
        char c = keyboard_getchar();
        
        if (c == '\n') {
            video_putchar('\n');
            process_command();
            print_prompt();
        } else if (c == '\b') {
            if (buffer_pos > 0) {
                buffer_pos--;
                video_print("\b \b");
            }
        } else if (buffer_pos < SHELL_BUFFER_SIZE - 1) {
            command_buffer[buffer_pos++] = c;
            video_putchar(c);
        }
    }
}
