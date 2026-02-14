# NexusOS - Système d'exploitation 64 bits

![Build Status](https://github.com/yourusername/nexusos/workflows/Build%20NexusOS/badge.svg)

**NexusOS** est un système d'exploitation 64 bits complet et fonctionnel pour l'architecture x86_64, écrit en C, C++ et assembleur. Il est conçu pour être éducatif, modulaire et extensible.

## ✨ Caractéristiques

### Kernel
- ✅ **Kernel 64 bits complet** avec support UEFI et BIOS
- ✅ **Gestion de la mémoire avancée** : pagination, mémoire virtuelle, allocateur heap
- ✅ **Multitâche** avec planificateur de processus round-robin
- ✅ **Gestion des interruptions** (IDT) avec support PIC
- ✅ **Gestion des processus et threads**

### Drivers
- ✅ **Clavier** PS/2 avec buffer circulaire
- ✅ **Affichage vidéo** VGA mode texte
- ✅ **Timer** PIT programmable
- ✅ **PCI** énumération et configuration basique

### Système de fichiers
- ✅ **VFS (Virtual File System)** avec support lecture/écriture
- ✅ Système de fichiers en mémoire (RAM disk)

### Interface utilisateur
- ✅ **Shell intégré** avec commandes système
- ✅ Support des couleurs et formatage
- ✅ Gestion des entrées utilisateur

## 🚀 Installation et compilation

### Prérequis

Sur **Ubuntu/Debian** :
```bash
sudo apt-get update
sudo apt-get install build-essential nasm grub-pc-bin xorriso mtools qemu-system-x86
```

Sur **Arch Linux** :
```bash
sudo pacman -S base-devel nasm grub xorriso mtools qemu
```

Sur **macOS** (avec Homebrew) :
```bash
brew install nasm x86_64-elf-gcc xorriso qemu
```

### Compilation

```bash
# Cloner le projet
git clone https://github.com/yourusername/nexusos.git
cd nexusos

# Compiler le kernel
make all

# Créer l'image ISO bootable
make iso
```

## 🖥️ Exécution

### Avec QEMU (recommandé)

```bash
# Mode BIOS
make run

# Mode UEFI
make run-uefi

# Avec options personnalisées
qemu-system-x86_64 -cdrom nexus.iso -m 512M -serial stdio
```

### Avec VirtualBox

1. Créer une nouvelle machine virtuelle 64 bits
2. Sélectionner `nexus.iso` comme CD-ROM bootable
3. Allouer au moins 512 MB de RAM
4. Démarrer la machine

### Sur matériel réel

⚠️ **Attention** : Tester sur du matériel réel peut être risqué !

1. Graver `nexus.iso` sur une clé USB :
   ```bash
   sudo dd if=nexus.iso of=/dev/sdX bs=4M status=progress
   ```
2. Démarrer depuis la clé USB

## 📚 Structure du projet

```
NexusOS/
├── boot/                   # Configuration bootloader
│   └── grub/              # Configuration GRUB
├── kernel/                # Code du noyau
│   ├── arch/              # Code spécifique à l'architecture
│   │   └── x86_64/       # Support x86_64
│   ├── core/             # Composants principaux du kernel
│   ├── drivers/          # Drivers matériels
│   │   ├── keyboard/
│   │   ├── video/
│   │   ├── timer/
│   │   └── pci/
│   ├── fs/               # Système de fichiers
│   ├── mm/               # Gestion mémoire
│   └── include/          # Headers
├── libc/                 # Bibliothèque C standard (partielle)
├── userland/             # Programmes utilisateur
│   └── shell/           # Shell interactif
├── build/               # Fichiers de build (généré)
├── .github/             # Workflows CI/CD
└── Makefile             # Script de build principal
```

## 🎮 Utilisation du shell

Une fois NexusOS démarré, vous aurez accès à un shell interactif :

```bash
nexus$ help           # Afficher l'aide
nexus$ ls             # Lister les fichiers
nexus$ cat welcome.txt # Afficher un fichier
nexus$ mem            # Informations mémoire
nexus$ time           # Temps de fonctionnement
nexus$ clear          # Effacer l'écran
nexus$ reboot         # Redémarrer
nexus$ halt           # Arrêter le système
```

## 🛠️ Développement et extension

### Ajouter un nouveau driver

1. Créer un dossier dans `kernel/drivers/`
2. Implémenter les fonctions d'initialisation et de gestion
3. Ajouter le header dans `kernel/include/`
4. Appeler l'initialisation dans `kernel_main()`

Exemple :
```c
// kernel/drivers/mydriver/mydriver.c
#include "mydriver.h"

void mydriver_init(void) {
    // Initialisation du driver
}

// kernel/include/mydriver.h
#ifndef KERNEL_MYDRIVER_H
#define KERNEL_MYDRIVER_H

void mydriver_init(void);

#endif
```

### Ajouter une nouvelle commande shell

Éditer `userland/shell/shell.c` :

```c
static void cmd_mycommand(void) {
    video_print("Ma nouvelle commande!\n");
}

// Dans process_command()
else if (strcmp_shell(command_buffer, "mycommand") == 0) {
    cmd_mycommand();
}
```

### Modifier la gestion mémoire

Le gestionnaire de mémoire se trouve dans `kernel/mm/memory.c`. Il utilise actuellement :
- Un **bitmap** pour la gestion des pages physiques
- Un **bump allocator** pour le heap kernel

Pour un système de production, vous pouvez implémenter :
- Un allocateur slab
- Un gestionnaire buddy
- Un garbage collector

## 🧪 Tests

### Tests unitaires (à venir)

```bash
make test
```

### Tests d'intégration

Le workflow GitHub Actions compile automatiquement le système à chaque commit et génère l'ISO.

### Débogage

Pour déboguer avec GDB :

```bash
# Terminal 1
qemu-system-x86_64 -cdrom nexus.iso -s -S

# Terminal 2
gdb build/nexus.bin
(gdb) target remote localhost:1234
(gdb) continue
```

## 📖 Documentation technique

### Architecture mémoire

```
0x0000000000000000 - 0x0000000000100000 : Mémoire basse (1 MB)
0x0000000000100000 - 0x0000000008000000 : Kernel space (127 MB)
0xFFFF800000000000 - 0xFFFF808000000000 : Kernel heap (128 MB)
```

### Interruptions

- **0-31** : Exceptions CPU
- **32-47** : IRQs matériels (PIC)
- **48-255** : Interruptions logicielles (disponibles)

### Registres importants

- **CR0** : Contrôle du processeur (pagination, protection)
- **CR3** : Base de la table des pages (PML4)
- **CR4** : Extensions (PAE, PSE)

## 🤝 Contribution

Les contributions sont les bienvenues ! Pour contribuer :

1. Fork le projet
2. Créer une branche (`git checkout -b feature/amazing-feature`)
3. Commit les changements (`git commit -m 'Add amazing feature'`)
4. Push vers la branche (`git push origin feature/amazing-feature`)
5. Ouvrir une Pull Request

### Guidelines de code

- Utiliser des noms de variables descriptifs
- Commenter le code complexe
- Suivre le style de code existant
- Tester toutes les modifications

## 📋 Roadmap

### Version 1.x
- [x] Boot en 64 bits
- [x] Gestion mémoire de base
- [x] Drivers essentiels
- [x] Shell interactif
- [ ] Support ACPI
- [ ] Networking (TCP/IP stack)

### Version 2.x
- [ ] Interface graphique (GUI)
- [ ] Support USB
- [ ] Système de fichiers ext2/FAT32
- [ ] Multi-core support (SMP)

### Version 3.x
- [ ] Support des applications utilisateur
- [ ] Permissions et sécurité
- [ ] Son (AC97/HDA)
- [ ] Package manager

## ⚖️ Licence

Ce projet est sous licence **MIT**. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- [OSDev Wiki](https://wiki.osdev.org/) - Ressource inestimable
- [Intel Software Developer Manuals](https://software.intel.com/content/www/us/en/develop/articles/intel-sdm.html)
- [AMD64 Architecture Programmer's Manual](https://www.amd.com/en/support/tech-docs)
- La communauté OSDev

## 📧 Contact

- Créateur : [Votre Nom]
- Email : your.email@example.com
- GitHub : [@yourusername](https://github.com/yourusername)

## ⭐ Support

Si ce projet vous a aidé, n'hésitez pas à lui donner une étoile ! ⭐

---

**NexusOS** - Un système d'exploitation éducatif pour apprendre et expérimenter avec le développement OS bas niveau.
