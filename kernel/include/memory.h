#ifndef KERNEL_MEMORY_H
#define KERNEL_MEMORY_H

#include "types.h"

#define PAGE_SIZE 4096
#define KERNEL_HEAP_START 0xFFFF800000000000ULL
#define KERNEL_HEAP_SIZE  (128 * 1024 * 1024) // 128 MB

// Flags de page
#define PAGE_PRESENT   (1ULL << 0)
#define PAGE_WRITE     (1ULL << 1)
#define PAGE_USER      (1ULL << 2)
#define PAGE_NOCACHE   (1ULL << 4)
#define PAGE_ACCESSED  (1ULL << 5)
#define PAGE_DIRTY     (1ULL << 6)
#define PAGE_HUGE      (1ULL << 7)
#define PAGE_GLOBAL    (1ULL << 8)

#ifdef __cplusplus
extern "C" {
#endif

// Initialisation
void memory_init(void);

// Allocation de pages physiques
void* pmm_alloc_page(void);
void  pmm_free_page(void* page);
void* pmm_alloc_pages(size_t count);
void  pmm_free_pages(void* pages, size_t count);

// Allocation de mémoire virtuelle (heap)
void* kmalloc(size_t size);
void* kmalloc_aligned(size_t size, size_t align);
void  kfree(void* ptr);

// Statistiques mémoire
size_t memory_get_total(void);
size_t memory_get_free(void);
size_t memory_get_used(void);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_MEMORY_H
