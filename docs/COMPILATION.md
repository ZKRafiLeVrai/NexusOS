# Guide de compilation NexusOS

## Configuration de l'environnement

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y \
    build-essential \
    nasm \
    grub-pc-bin \
    grub-common \
    xorriso \
    mtools \
    qemu-system-x86

# Optionnel: pour le débogage
sudo apt-get install -y gdb
```

### Fedora/RHEL
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install nasm grub2-tools xorriso mtools qemu-system-x86 gdb
```

### Arch Linux
```bash
sudo pacman -S base-devel nasm grub xorriso mtools qemu gdb
```

### macOS
```bash
brew install nasm x86_64-elf-gcc xorriso qemu

# Note: Sur macOS, vous devrez peut-être compiler un cross-compiler
# Voir: https://wiki.osdev.org/GCC_Cross-Compiler
```

## Compilation

### Méthode 1: Makefile (recommandé)

```bash
# Compiler le kernel
make all

# Créer l'ISO
make iso

# Nettoyer
make clean

# Compiler et exécuter
make run
```

### Méthode 2: Compilation manuelle

```bash
# Créer les dossiers
mkdir -p build/kernel/{arch/x86_64,core,mm,drivers,fs}
mkdir -p build/userland/shell
mkdir -p boot/iso/boot/grub

# Compiler le bootloader
nasm -f elf64 kernel/arch/x86_64/boot.asm -o build/kernel/arch/x86_64/boot.o
nasm -f elf64 kernel/arch/x86_64/interrupt_handlers.asm -o build/kernel/arch/x86_64/interrupt_handlers.o

# Compiler le kernel C/C++
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/core/kernel.cpp -o build/kernel/core/kernel.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/core/interrupts.cpp -o build/kernel/core/interrupts.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/mm/memory.c -o build/kernel/mm/memory.o -Ikernel/include

# Compiler les drivers
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/drivers/video/video.c -o build/kernel/drivers/video/video.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/drivers/keyboard/keyboard.c -o build/kernel/drivers/keyboard/keyboard.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/drivers/timer/timer.c -o build/kernel/drivers/timer/timer.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/drivers/pci/pci.c -o build/kernel/drivers/pci/pci.o -Ikernel/include

# Compiler le VFS et le scheduler
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/fs/vfs.c -o build/kernel/fs/vfs.o -Ikernel/include
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c kernel/core/scheduler.c -o build/kernel/core/scheduler.o -Ikernel/include

# Compiler le shell
gcc -m64 -ffreestanding -O2 -Wall -Wextra -c userland/shell/shell.c -o build/userland/shell/shell.o -Ikernel/include

# Linker
ld -nostdlib -n -T kernel/arch/x86_64/linker.ld -o build/nexus.bin \
    build/kernel/arch/x86_64/boot.o \
    build/kernel/arch/x86_64/interrupt_handlers.o \
    build/kernel/core/kernel.o \
    build/kernel/core/interrupts.o \
    build/kernel/mm/memory.o \
    build/kernel/drivers/video/video.o \
    build/kernel/drivers/keyboard/keyboard.o \
    build/kernel/drivers/timer/timer.o \
    build/kernel/drivers/pci/pci.o \
    build/kernel/fs/vfs.o \
    build/kernel/core/scheduler.o \
    build/userland/shell/shell.o

# Créer l'ISO
mkdir -p boot/iso/nexus
cp build/nexus.bin boot/iso/nexus/
cp boot/grub/grub.cfg boot/iso/boot/grub/
grub-mkrescue -o nexus.iso boot/iso
```

## Résolution des problèmes

### Erreur: "grub-mkrescue: command not found"
```bash
# Sur Ubuntu/Debian
sudo apt-get install grub-pc-bin grub-common

# Sur Fedora
sudo dnf install grub2-tools
```

### Erreur: "xorriso: command not found"
```bash
sudo apt-get install xorriso
```

### Le kernel ne boot pas
1. Vérifiez que GRUB est configuré correctement
2. Assurez-vous que le fichier est en format Multiboot2
3. Vérifiez les logs avec: `qemu-system-x86_64 -cdrom nexus.iso -serial stdio`

### Erreur de compilation C++
Si vous obtenez des erreurs liées à C++, assurez-vous d'utiliser les flags:
```
-fno-exceptions -fno-rtti -nostdlib
```

## Tests

### Test rapide avec QEMU
```bash
qemu-system-x86_64 -cdrom nexus.iso
```

### Test avec options de débogage
```bash
qemu-system-x86_64 \
    -cdrom nexus.iso \
    -m 512M \
    -serial stdio \
    -no-reboot \
    -d int,cpu_reset
```

### Débogage avec GDB
```bash
# Terminal 1
qemu-system-x86_64 -cdrom nexus.iso -s -S -serial stdio

# Terminal 2
gdb build/nexus.bin
(gdb) target remote localhost:1234
(gdb) break kernel_main
(gdb) continue
```

## Optimisations

### Build de production
```bash
make CFLAGS="-O2 -DNDEBUG"
```

### Build de debug
```bash
make CFLAGS="-O0 -g -DDEBUG"
```

## Plateformes supportées

### Testé sur:
- ✅ QEMU (x86_64)
- ✅ VirtualBox 6.x
- ✅ VMware Workstation
- ⚠️ Matériel réel (expérimental)

### Non testé:
- ❌ Hyper-V
- ❌ KVM (devrait fonctionner)
- ❌ Bochs (devrait fonctionner)
