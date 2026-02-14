#include "memory.h"
#include "video.h"

// Gestion de la mémoire physique (bitmap simple)
#define MEMORY_SIZE (128 * 1024 * 1024)  // 128 MB
#define BITMAP_SIZE (MEMORY_SIZE / PAGE_SIZE / 8)

static uint8_t memory_bitmap[BITMAP_SIZE];
static size_t total_pages = MEMORY_SIZE / PAGE_SIZE;
static size_t free_pages = 0;

// Heap simple (bump allocator)
static uint8_t* heap_start = (uint8_t*)KERNEL_HEAP_START;
static uint8_t* heap_current = (uint8_t*)KERNEL_HEAP_START;
static uint8_t* heap_end = (uint8_t*)(KERNEL_HEAP_START + KERNEL_HEAP_SIZE);

// Structure pour les blocs alloués
struct alloc_header {
    size_t size;
    uint32_t magic;
} PACKED;

#define ALLOC_MAGIC 0xDEADBEEF

static void bitmap_set(size_t bit) {
    memory_bitmap[bit / 8] |= (1 << (bit % 8));
}

static void bitmap_clear(size_t bit) {
    memory_bitmap[bit / 8] &= ~(1 << (bit % 8));
}

static bool bitmap_test(size_t bit) {
    return (memory_bitmap[bit / 8] & (1 << (bit % 8))) != 0;
}

void memory_init(void) {
    // Initialiser le bitmap (tout est libre)
    for (size_t i = 0; i < BITMAP_SIZE; i++) {
        memory_bitmap[i] = 0;
    }
    
    // Les premières pages sont réservées pour le kernel
    for (size_t i = 0; i < 256; i++) { // 1 MB réservé
        bitmap_set(i);
    }
    
    free_pages = total_pages - 256;
    
    video_printf("Memory initialized: %u MB total, %u MB free\n",
                 (unsigned)(total_pages * PAGE_SIZE / 1024 / 1024),
                 (unsigned)(free_pages * PAGE_SIZE / 1024 / 1024));
}

void* pmm_alloc_page(void) {
    for (size_t i = 0; i < total_pages; i++) {
        if (!bitmap_test(i)) {
            bitmap_set(i);
            free_pages--;
            return (void*)(i * PAGE_SIZE);
        }
    }
    return NULL;
}

void pmm_free_page(void* page) {
    size_t index = (size_t)page / PAGE_SIZE;
    if (index < total_pages && bitmap_test(index)) {
        bitmap_clear(index);
        free_pages++;
    }
}

void* pmm_alloc_pages(size_t count) {
    size_t consecutive = 0;
    size_t start = 0;
    
    for (size_t i = 0; i < total_pages; i++) {
        if (!bitmap_test(i)) {
            if (consecutive == 0) {
                start = i;
            }
            consecutive++;
            
            if (consecutive == count) {
                for (size_t j = 0; j < count; j++) {
                    bitmap_set(start + j);
                }
                free_pages -= count;
                return (void*)(start * PAGE_SIZE);
            }
        } else {
            consecutive = 0;
        }
    }
    
    return NULL;
}

void pmm_free_pages(void* pages, size_t count) {
    size_t start = (size_t)pages / PAGE_SIZE;
    for (size_t i = 0; i < count; i++) {
        if (start + i < total_pages) {
            bitmap_clear(start + i);
            free_pages++;
        }
    }
}

void* kmalloc(size_t size) {
    if (size == 0) return NULL;
    
    size_t total_size = size + sizeof(struct alloc_header);
    total_size = ALIGN_UP(total_size, 16);
    
    if (heap_current + total_size >= heap_end) {
        return NULL; // Out of memory
    }
    
    struct alloc_header* header = (struct alloc_header*)heap_current;
    header->size = size;
    header->magic = ALLOC_MAGIC;
    
    void* ptr = heap_current + sizeof(struct alloc_header);
    heap_current += total_size;
    
    return ptr;
}

void* kmalloc_aligned(size_t size, size_t align) {
    if (size == 0 || align == 0) return NULL;
    
    uintptr_t current = (uintptr_t)heap_current;
    uintptr_t aligned = ALIGN_UP(current + sizeof(struct alloc_header), align);
    size_t padding = aligned - current - sizeof(struct alloc_header);
    
    size_t total_size = padding + size + sizeof(struct alloc_header);
    
    if (heap_current + total_size >= heap_end) {
        return NULL;
    }
    
    heap_current += padding;
    
    struct alloc_header* header = (struct alloc_header*)heap_current;
    header->size = size;
    header->magic = ALLOC_MAGIC;
    
    void* ptr = heap_current + sizeof(struct alloc_header);
    heap_current += sizeof(struct alloc_header) + size;
    
    return ptr;
}

void kfree(void* ptr) {
    // Note: Ce gestionnaire de mémoire simple ne libère pas vraiment la mémoire
    // Pour un vrai OS, il faudrait implémenter un allocateur plus sophistiqué
    if (!ptr) return;
    
    struct alloc_header* header = (struct alloc_header*)((uint8_t*)ptr - sizeof(struct alloc_header));
    if (header->magic != ALLOC_MAGIC) {
        video_print("[WARN] Invalid free detected!\n");
        return;
    }
}

size_t memory_get_total(void) {
    return total_pages * PAGE_SIZE;
}

size_t memory_get_free(void) {
    return free_pages * PAGE_SIZE;
}

size_t memory_get_used(void) {
    return (total_pages - free_pages) * PAGE_SIZE;
}
