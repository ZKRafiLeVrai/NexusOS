# NexusOS - Structure du Projet

```
NexusOS/
│
├── .github/
│   └── workflows/
│       └── build.yml              # GitHub Actions CI/CD
│
├── boot/
│   ├── grub/
│   │   └── grub.cfg              # Configuration GRUB
│   └── iso/                      # Répertoire ISO (généré)
│
├── build/                        # Fichiers compilés (généré)
│
├── docs/
│   ├── ARCHITECTURE.md           # Documentation architecture technique
│   ├── COMPILATION.md            # Guide de compilation détaillé
│   └── FAQ.md                    # Questions fréquentes
│
├── kernel/
│   ├── arch/
│   │   └── x86_64/
│   │       ├── boot.asm          # Bootloader et passage en 64-bit
│   │       ├── interrupt_handlers.asm  # Stubs d'interruption
│   │       └── linker.ld         # Script de linkage
│   │
│   ├── core/
│   │   ├── kernel.cpp            # Point d'entrée principal du kernel
│   │   ├── interrupts.cpp        # Gestion des interruptions (IDT)
│   │   └── scheduler.c           # Planificateur de tâches
│   │
│   ├── drivers/
│   │   ├── keyboard/
│   │   │   └── keyboard.c        # Driver clavier PS/2
│   │   ├── pci/
│   │   │   └── pci.c             # Driver PCI
│   │   ├── timer/
│   │   │   └── timer.c           # Driver timer (PIT)
│   │   └── video/
│   │       └── video.c           # Driver vidéo VGA
│   │
│   ├── fs/
│   │   └── vfs.c                 # Système de fichiers virtuel
│   │
│   ├── include/
│   │   ├── interrupts.h          # Interface interruptions
│   │   ├── io.h                  # Fonctions I/O (inb, outb)
│   │   ├── keyboard.h            # Interface clavier
│   │   ├── memory.h              # Interface gestion mémoire
│   │   ├── pci.h                 # Interface PCI
│   │   ├── scheduler.h           # Interface scheduler
│   │   ├── shell.h               # Interface shell
│   │   ├── timer.h               # Interface timer
│   │   ├── types.h               # Types de base
│   │   ├── vfs.h                 # Interface VFS
│   │   └── video.h               # Interface vidéo
│   │
│   └── mm/
│       └── memory.c              # Gestionnaire de mémoire
│
├── libc/                         # Bibliothèque C (à développer)
│   ├── include/
│   └── src/
│
├── scripts/
│   └── test.sh                   # Script de tests automatisés
│
├── userland/
│   └── shell/
│       └── shell.c               # Shell interactif utilisateur
│
├── .gitignore                    # Fichiers à ignorer par git
├── build.sh                      # Script de build principal
├── CHANGELOG.md                  # Historique des versions
├── CMakeLists.txt                # Configuration CMake (alternative)
├── CONTRIBUTING.md               # Guide de contribution
├── LICENSE                       # Licence MIT
├── Makefile                      # Makefile principal
├── QUICKSTART.md                 # Guide de démarrage rapide
└── README.md                     # Documentation principale

```

## Statistiques du Projet

### Fichiers Source
- **Assembleur (ASM)** : 2 fichiers (~200 lignes)
- **C** : 9 fichiers (~1200 lignes)
- **C++** : 2 fichiers (~100 lignes)
- **Headers** : 11 fichiers

### Configuration et Documentation
- **Build** : Makefile + CMakeLists.txt + build.sh
- **CI/CD** : GitHub Actions workflow
- **Documentation** : 7 fichiers Markdown
- **Tests** : Script de test automatisé

### Total
- **~40 fichiers** au total
- **~1500+ lignes de code**
- Architecture complète et modulaire

## Composants par Catégorie

### Boot et Initialisation
- `boot.asm` - Bootloader Multiboot2
- `kernel.cpp` - Initialisation du kernel

### Gestion Mémoire
- `memory.c` - PMM + heap allocator
- Tables de pagination (dans boot.asm)

### Interruptions et Timing
- `interrupts.cpp` - IDT et handlers
- `interrupt_handlers.asm` - Stubs ASM
- `timer.c` - PIT timer

### Drivers
- `video.c` - Affichage VGA
- `keyboard.c` - Clavier PS/2
- `pci.c` - Énumération PCI

### Système de Fichiers
- `vfs.c` - VFS avec RAM disk

### Interface Utilisateur
- `shell.c` - Shell interactif complet

### Build et Tests
- `Makefile` - Build principal
- `CMakeLists.txt` - Build alternatif
- `build.sh` - Script automatisé
- `test.sh` - Tests automatisés

## Points d'Extension

### Faciles
- Ajouter des commandes shell
- Créer de nouveaux fichiers dans le VFS
- Modifier les couleurs d'affichage

### Moyens
- Ajouter un nouveau driver
- Implémenter un meilleur allocateur
- Ajouter support pour d'autres layouts clavier

### Avancés
- Support multiprocesseur (SMP)
- Vrai système de fichiers (ext2/FAT32)
- Networking (stack TCP/IP)
- Interface graphique

## Prochains Développements

1. **Court terme**
   - Support ACPI
   - Meilleur allocateur mémoire
   - Multitâche préemptif

2. **Moyen terme**
   - Driver de stockage (ATA/SATA)
   - Système de fichiers réel
   - Support USB

3. **Long terme**
   - GUI avec mode graphique
   - Support réseau complet
   - Applications utilisateur
