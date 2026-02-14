#ifndef KERNEL_KEYBOARD_H
#define KERNEL_KEYBOARD_H

#include "types.h"

#define KEYBOARD_BUFFER_SIZE 256

#ifdef __cplusplus
extern "C" {
#endif

void keyboard_init(void);
char keyboard_getchar(void);
bool keyboard_haschar(void);
void keyboard_wait_key(void);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_KEYBOARD_H
