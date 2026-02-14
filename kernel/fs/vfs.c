#include "vfs.h"
#include "memory.h"
#include "video.h"

// Fonctions de manipulation de chaînes
static size_t strlen(const char* str) {
    size_t len = 0;
    while (str[len]) len++;
    return len;
}

static int strcmp(const char* s1, const char* s2) {
    while (*s1 && (*s1 == *s2)) {
        s1++;
        s2++;
    }
    return *(const unsigned char*)s1 - *(const unsigned char*)s2;
}

static void strcpy(char* dest, const char* src) {
    while ((*dest++ = *src++));
}

static void memcpy_vfs(void* dest, const void* src, size_t n) {
    uint8_t* d = (uint8_t*)dest;
    const uint8_t* s = (const uint8_t*)src;
    for (size_t i = 0; i < n; i++) {
        d[i] = s[i];
    }
}

static vfs_node_t* root_node = NULL;

void vfs_init(void) {
    // Créer le répertoire racine
    root_node = (vfs_node_t*)kmalloc(sizeof(vfs_node_t));
    strcpy(root_node->name, "/");
    root_node->type = VFS_DIRECTORY;
    root_node->size = 0;
    root_node->data = NULL;
    root_node->next = NULL;
    
    // Créer quelques fichiers de démonstration
    vfs_node_t* welcome = (vfs_node_t*)kmalloc(sizeof(vfs_node_t));
    strcpy(welcome->name, "welcome.txt");
    welcome->type = VFS_FILE;
    const char* content = "Welcome to NexusOS!\nThis is a simple virtual file system.\n";
    welcome->size = strlen(content);
    welcome->data = (uint8_t*)kmalloc(welcome->size);
    memcpy_vfs(welcome->data, content, welcome->size);
    welcome->next = NULL;
    root_node->next = welcome;
    
    video_print("Virtual file system initialized\n");
}

vfs_node_t* vfs_list_root(void) {
    return root_node;
}

vfs_node_t* vfs_open(const char* path) {
    if (!path || path[0] != '/') {
        return NULL;
    }
    
    // Chercher le fichier
    vfs_node_t* current = root_node->next;
    while (current) {
        if (strcmp(current->name, path + 1) == 0) {
            return current;
        }
        current = current->next;
    }
    
    return NULL;
}

int vfs_read(vfs_node_t* node, void* buffer, size_t size) {
    if (!node || node->type != VFS_FILE) {
        return -1;
    }
    
    size_t to_read = (size < node->size) ? size : node->size;
    memcpy_vfs(buffer, node->data, to_read);
    return (int)to_read;
}

int vfs_write(vfs_node_t* node, const void* buffer, size_t size) {
    if (!node || node->type != VFS_FILE) {
        return -1;
    }
    
    // Allouer de la nouvelle mémoire si nécessaire
    if (size > node->size) {
        kfree(node->data);
        node->data = (uint8_t*)kmalloc(size);
    }
    
    memcpy_vfs(node->data, buffer, size);
    node->size = size;
    return (int)size;
}

void vfs_close(vfs_node_t* node) {
    // Dans ce système simple, pas besoin de faire quoi que ce soit
    (void)node;
}

vfs_node_t* vfs_create(const char* path, vfs_type_t type) {
    if (!path || path[0] != '/') {
        return NULL;
    }
    
    // Vérifier si le fichier existe déjà
    if (vfs_open(path)) {
        return NULL;
    }
    
    // Créer un nouveau nœud
    vfs_node_t* new_node = (vfs_node_t*)kmalloc(sizeof(vfs_node_t));
    strcpy(new_node->name, path + 1);
    new_node->type = type;
    new_node->size = 0;
    new_node->data = NULL;
    new_node->next = root_node->next;
    root_node->next = new_node;
    
    return new_node;
}

int vfs_delete(const char* path) {
    if (!path || path[0] != '/') {
        return -1;
    }
    
    vfs_node_t* prev = root_node;
    vfs_node_t* current = root_node->next;
    
    while (current) {
        if (strcmp(current->name, path + 1) == 0) {
            prev->next = current->next;
            kfree(current->data);
            kfree(current);
            return 0;
        }
        prev = current;
        current = current->next;
    }
    
    return -1;
}
