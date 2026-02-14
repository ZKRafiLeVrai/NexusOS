#include "scheduler.h"
#include "memory.h"
#include "video.h"

static task_t* task_list = NULL;
static task_t* current_task = NULL;
static uint32_t next_task_id = 1;

static void strcpy_sched(char* dest, const char* src) {
    while ((*dest++ = *src++));
}

void scheduler_init(void) {
    // Créer la tâche idle (kernel)
    task_list = (task_t*)kmalloc(sizeof(task_t));
    task_list->id = 0;
    strcpy_sched(task_list->name, "kernel");
    task_list->state = TASK_RUNNING;
    task_list->stack = NULL;
    task_list->rsp = 0;
    task_list->rbp = 0;
    task_list->next = NULL;
    
    current_task = task_list;
    
    video_print("Task scheduler initialized\n");
}

task_t* task_create(const char* name, void (*entry)(void)) {
    task_t* task = (task_t*)kmalloc(sizeof(task_t));
    task->id = next_task_id++;
    strcpy_sched(task->name, name);
    task->state = TASK_READY;
    
    // Allouer une pile pour la tâche
    task->stack = (uint64_t*)kmalloc(STACK_SIZE);
    task->rsp = (uint64_t)(task->stack + STACK_SIZE / sizeof(uint64_t) - 16);
    task->rbp = task->rsp;
    
    // Initialiser la pile pour le contexte
    uint64_t* stack_ptr = (uint64_t*)task->rsp;
    stack_ptr[0] = (uint64_t)entry; // RIP
    stack_ptr[1] = 0x08;             // CS
    stack_ptr[2] = 0x202;            // RFLAGS (interrupts enabled)
    
    // Ajouter à la liste
    task->next = task_list;
    task_list = task;
    
    return task;
}

void task_exit(void) {
    if (current_task) {
        current_task->state = TASK_TERMINATED;
    }
    task_yield();
}

void task_yield(void) {
    // Planification simple: round-robin
    if (!current_task || !task_list) {
        return;
    }
    
    task_t* next = current_task->next;
    if (!next) {
        next = task_list;
    }
    
    // Trouver la prochaine tâche prête
    while (next && next->state != TASK_READY && next->state != TASK_RUNNING) {
        next = next->next;
        if (!next) {
            next = task_list;
        }
        if (next == current_task) {
            break; // Aucune autre tâche prête
        }
    }
    
    if (next && next != current_task) {
        task_t* old_task = current_task;
        if (old_task->state == TASK_RUNNING) {
            old_task->state = TASK_READY;
        }
        
        current_task = next;
        current_task->state = TASK_RUNNING;
        
        // Changement de contexte (simplifié - devrait être en ASM)
        // Pour ce système simple, on ne fait pas vraiment de changement de contexte
    }
}

task_t* scheduler_get_current(void) {
    return current_task;
}
