#ifndef KERNEL_VFS_H
#define KERNEL_VFS_H

#include "types.h"

#define VFS_MAX_PATH 256
#define VFS_MAX_FILES 128

typedef enum {
    VFS_FILE,
    VFS_DIRECTORY
} vfs_type_t;

struct vfs_node {
    char name[64];
    vfs_type_t type;
    size_t size;
    uint8_t* data;
    struct vfs_node* next;
};

typedef struct vfs_node vfs_node_t;

#ifdef __cplusplus
extern "C" {
#endif

void vfs_init(void);
vfs_node_t* vfs_open(const char* path);
int vfs_read(vfs_node_t* node, void* buffer, size_t size);
int vfs_write(vfs_node_t* node, const void* buffer, size_t size);
void vfs_close(vfs_node_t* node);
vfs_node_t* vfs_create(const char* path, vfs_type_t type);
int vfs_delete(const char* path);
vfs_node_t* vfs_list_root(void);

#ifdef __cplusplus
}
#endif

#endif // KERNEL_VFS_H
