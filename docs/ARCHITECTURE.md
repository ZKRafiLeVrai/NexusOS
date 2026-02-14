# Architecture Technique de NexusOS

## Vue d'ensemble

NexusOS est un système d'exploitation monolithique 64 bits pour x86_64, conçu avec une architecture modulaire et extensible.

## Architecture générale

```
┌─────────────────────────────────────────┐
│         Applications Utilisateur         │
├─────────────────────────────────────────┤
│              Shell / Init                │
├─────────────────────────────────────────┤
│      Système de Fichiers Virtuel        │
├─────────────────────────────────────────┤
│          Noyau (Kernel Core)            │
│  ┌──────────┬──────────┬──────────┐    │
│  │  Memory  │  Sched   │   IPC    │    │
│  │  Manager │          │          │    │
│  └──────────┴──────────┴──────────┘    │
├─────────────────────────────────────────┤
│            Gestionnaires                 │
│   ┌─────────┬─────────┬──────────┐     │
│   │ Interr. │  Timer  │   PCI    │     │
│   └─────────┴─────────┴──────────┘     │
├─────────────────────────────────────────┤
│              Drivers                     │
│   ┌─────────┬─────────┬──────────┐     │
│   │Keyboard │  Video  │ Storage  │     │
│   └─────────┴─────────┴──────────┘     │
├─────────────────────────────────────────┤
│      Couche d'abstraction matériel      │
│         (HAL - x86_64 specific)         │
└─────────────────────────────────────────┘
```

## Composants principaux

### 1. Bootloader et initialisation

#### boot.asm
- Point d'entrée du système
- Configuration Multiboot2
- Passage du mode 32-bit au mode 64-bit (Long Mode)
- Configuration de la pagination initiale
- Chargement de la GDT 64-bit

**Séquence de boot :**
```
1. GRUB charge le kernel
2. Vérification CPUID et Long Mode
3. Configuration PML4/PDP/PD (tables de pages)
4. Activation PAE (CR4)
5. Activation Long Mode (EFER MSR)
6. Activation pagination (CR0)
7. Saut vers le code 64-bit
8. Appel kernel_main()
```

### 2. Gestion de la mémoire

#### Architecture de pagination

```
Virtual Address (64-bit)
┌────────┬────────┬────────┬────────┬────────────┐
│  PML4  │  PDP   │   PD   │   PT   │   Offset   │
│ 9 bits │ 9 bits │ 9 bits │ 9 bits │  12 bits   │
└────────┴────────┴────────┴────────┴────────────┘
   [47:39]  [38:30]  [29:21]  [20:12]   [11:0]
```

**Layout mémoire :**
```
0x0000000000000000 - 0x0000000000100000 : Mémoire basse (1 MB)
0x0000000000100000 - 0x0000000008000000 : Kernel (jusqu'à 127 MB)
0xFFFF800000000000 - 0xFFFF808000000000 : Kernel heap (128 MB)
```

#### Gestionnaire de mémoire physique (PMM)

- **Type** : Bitmap allocator
- **Granularité** : 4 KB (pages)
- **Opérations** :
  - `pmm_alloc_page()` : Alloue une page
  - `pmm_free_page()` : Libère une page
  - `pmm_alloc_pages()` : Alloue N pages contiguës

#### Gestionnaire de mémoire virtuelle (Heap)

- **Type** : Bump allocator (simple)
- **Fonctions** :
  - `kmalloc(size)` : Allocation simple
  - `kmalloc_aligned(size, align)` : Allocation alignée
  - `kfree(ptr)` : Libération (actuellement no-op)

**Note** : Pour un système de production, remplacer par un allocateur slab ou buddy.

### 3. Gestion des interruptions

#### IDT (Interrupt Descriptor Table)

- **Taille** : 256 entrées
- **Type** : Interrupt gates 64-bit
- **Mapping** :
  - 0-31 : Exceptions CPU
  - 32-47 : IRQs matériels (PIC)
  - 48-255 : Interruptions software

#### PIC (Programmable Interrupt Controller)

- **Configuration** : Cascadé (Master + Slave)
- **Remap** : IRQ0-7 → INT32-39, IRQ8-15 → INT40-47
- **EOI** : End Of Interrupt automatique

**Flow d'une interruption :**
```
1. Interruption matérielle/software
2. CPU sauvegarde contexte (RIP, RFLAGS, etc.)
3. Appel ISR stub (interrupt_handlers.asm)
4. Sauvegarde registres (RAX-R15)
5. Appel handler C (interrupt_handler_common)
6. Handler spécifique (si enregistré)
7. Envoi EOI au PIC
8. Restauration registres
9. IRETQ
```

### 4. Planificateur de tâches

#### Structure task_t

```c
struct task {
    uint32_t id;           // ID unique
    char name[32];         // Nom de la tâche
    task_state_t state;    // État (RUNNING, READY, etc.)
    uint64_t* stack;       // Pile de la tâche
    uint64_t rsp;          // Stack pointer
    uint64_t rbp;          // Base pointer
    struct task* next;     // Liste chaînée
};
```

#### Algorithme

- **Type** : Round-robin coopératif
- **Préemption** : Non (pour l'instant)
- **Changement de contexte** : Simplifié (pas de sauvegarde complète)

**Pour un vrai multitâche, implémenter :**
- Timer-based preemption
- Sauvegarde/restauration complète du contexte
- Priorités de tâches
- Quantum time slicing

### 5. Système de fichiers

#### VFS (Virtual File System)

**Structure :**
```c
struct vfs_node {
    char name[64];        // Nom du fichier
    vfs_type_t type;      // FILE ou DIRECTORY
    size_t size;          // Taille
    uint8_t* data;        // Données
    struct vfs_node* next;// Liste chaînée
};
```

**Implémentation actuelle :**
- Système de fichiers en RAM (RAM disk)
- Structure simple en liste chaînée
- Pas de hiérarchie de répertoires (flat)
- Lecture/écriture basique

**Extensions futures :**
- Support ext2/FAT32
- Hiérarchie de répertoires
- Permissions et propriétés
- Cache de fichiers

### 6. Drivers

#### Driver Vidéo (VGA Text Mode)

- **Mode** : 80x25 caractères
- **Mémoire** : 0xB8000
- **Format** : 16 bits (8 bits caractère + 8 bits couleur)
- **Fonctionnalités** :
  - Affichage couleur
  - Scrolling automatique
  - Printf-like formatting

#### Driver Clavier (PS/2)

- **Port** : 0x60 (data), 0x64 (status)
- **Interruption** : IRQ1 (INT 33)
- **Buffer** : Circulaire 256 bytes
- **Scancodes** : Set 1 (US layout)
- **Support** : Shift, Control, alphanumériques

#### Driver Timer (PIT)

- **Fréquence** : Configurable (défaut 100 Hz)
- **Interruption** : IRQ0 (INT 32)
- **Fonctionnalités** :
  - Compteur de ticks
  - Sleep fonction

#### Driver PCI

- **Ports** : 0xCF8 (address), 0xCFC (data)
- **Fonctionnalités** :
  - Énumération des périphériques
  - Lecture/écriture configuration space
  - Détection classe/sous-classe

## Flux d'exécution

### Démarrage complet

```
1. BIOS/UEFI → GRUB
2. GRUB → Charge kernel en mémoire
3. GRUB → Passe contrôle à kernel_entry (boot.asm)
4. kernel_entry → Active mode 64-bit
5. kernel_entry → Configure pagination
6. kernel_entry → Appelle kernel_main()
7. kernel_main() → Initialise composants:
   a. Video
   b. Memory manager
   c. Interrupts (IDT + PIC)
   d. Timer
   e. Keyboard
   f. PCI
   g. Scheduler
   h. VFS
8. kernel_main() → Active interruptions (STI)
9. kernel_main() → Démarre shell
10. Shell → Boucle événements utilisateur
```

## Extensions possibles

### Court terme
- [ ] Support ACPI (détection matériel avancé)
- [ ] APIC/IOAPIC (remplacer PIC)
- [ ] Vrai allocateur mémoire (slab/buddy)
- [ ] Changement de contexte complet
- [ ] Préemption timer-based

### Moyen terme
- [ ] Support multiprocesseur (SMP)
- [ ] Système de fichiers réel (ext2/FAT32)
- [ ] Driver ATA/SATA (disque dur)
- [ ] Networking (carte réseau, stack TCP/IP)
- [ ] Support USB

### Long terme
- [ ] Interface graphique (mode VESA/GOP)
- [ ] Sound driver (AC97/HDA)
- [ ] Loadable kernel modules
- [ ] ELF loader (exécutables)
- [ ] Sécurité et permissions

## Performance

### Optimisations actuelles
- Bump allocator (O(1) allocation)
- Bitmap PMM (O(n) recherche, optimisable)
- Buffer circulaire clavier

### Bottlenecks identifiés
- Recherche page libre : O(n)
- VFS lookup : O(n) liste chaînée
- Pas de cache

### Améliorations possibles
- Hash table pour VFS
- Free list pour PMM
- Cache de pages fréquentes

## Sécurité

### Actuellement
- Aucune isolation utilisateur/kernel
- Pas de vérification des accès mémoire
- Pas de permissions fichiers

### À implémenter
- Ring 3 (mode utilisateur)
- System calls (interruption 0x80)
- Memory protection (page permissions)
- Sandbox processus

## Références

- Intel 64 and IA-32 Architectures Software Developer Manual
- AMD64 Architecture Programmer's Manual
- OSDev Wiki
- Multiboot2 Specification
