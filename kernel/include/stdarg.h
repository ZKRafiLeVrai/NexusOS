#ifndef KERNEL_STDARG_H
#define KERNEL_STDARG_H

// Variable arguments support for kernel
// Compatible with GCC/Clang built-ins

#ifdef __GNUC__
// GCC/Clang built-in macros
typedef __builtin_va_list va_list;
#define va_start(ap, last) __builtin_va_start(ap, last)
#define va_arg(ap, type) __builtin_va_arg(ap, type)
#define va_end(ap) __builtin_va_end(ap)
#define va_copy(dest, src) __builtin_va_copy(dest, src)
#else
// Fallback for IntelliSense (won't be used during actual compilation)
typedef char* va_list;
#define va_start(ap, last) ((void)0)
#define va_arg(ap, type) (*(type*)0)
#define va_end(ap) ((void)0)
#define va_copy(dest, src) ((void)0)
#endif

#endif // KERNEL_STDARG_H