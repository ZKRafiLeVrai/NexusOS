#ifndef KERNEL_SCHEDULER_H
#define KERNEL_SCHEDULER_H

#include "types.h"

#define MAX_TASKS 64
#define STACK_SIZE 4096

typedef enum {
    TASK_RUNNING,
    TASK_READY,
    TASK_BLOCKED,
    TASK_TERMINATED
} task_state_t;

struct task {
    uint32_t id;
    char name[32];
    task_state_t state;
    uint64_t* stack;
    uint64_t rsp;
    uint64_t rbp;
    struct task* next;
};

typedef struct task task_t;

#ifdef __cplusplus
extern "C" {
#endif

void scheduler_init(void);
task_t* task_create(const char* name, void (*entry)(void));
void task_exit(void);
void task_yield(void);
task_t* scheduler_get_current(void);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_SCHEDULER_H
