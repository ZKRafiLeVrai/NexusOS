#ifndef KERNEL_TYPES_H
#define KERNEL_TYPES_H

// Types de base
typedef unsigned char      uint8_t;
typedef unsigned short     uint16_t;
typedef unsigned int       uint32_t;
typedef unsigned long long uint64_t;

typedef signed char        int8_t;
typedef signed short       int16_t;
typedef signed int         int32_t;
typedef signed long long   int64_t;

typedef uint64_t           size_t;
typedef int64_t            ssize_t;
typedef uint64_t           uintptr_t;
typedef int64_t            intptr_t;

// Valeurs booléennes
typedef int                bool;
#define true               1
#define false              0

// NULL
#define NULL               ((void*)0)

// Attributs de fonction
#define PACKED             __attribute__((packed))
#define ALIGNED(x)         __attribute__((aligned(x)))
#define NORETURN           __attribute__((noreturn))
#define UNUSED             __attribute__((unused))

// Utilitaires
#define ARRAY_SIZE(x)      (sizeof(x) / sizeof((x)[0]))
#define MIN(a, b)          ((a) < (b) ? (a) : (b))
#define MAX(a, b)          ((a) > (b) ? (a) : (b))

// Alignement
#define ALIGN_UP(x, align)   (((x) + (align) - 1) & ~((align) - 1))
#define ALIGN_DOWN(x, align) ((x) & ~((align) - 1))
#define IS_ALIGNED(x, align) (((x) & ((align) - 1)) == 0)

// Macros de bit
#define BIT(n)             (1ULL << (n))
#define BITMASK(n)         (BIT(n) - 1)

#endif // KERNEL_TYPES_H
