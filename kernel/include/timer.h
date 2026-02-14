#ifndef KERNEL_TIMER_H
#define KERNEL_TIMER_H

#include "types.h"

#ifdef __cplusplus
extern "C" {
#endif

void timer_init(uint32_t frequency);
uint64_t timer_get_ticks(void);
void timer_sleep(uint32_t ms);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_TIMER_H
