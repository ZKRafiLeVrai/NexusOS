# NexusOS 64-bit Operating System - Main Makefile

# Architecture et compilateur
ARCH := x86_64
CC := gcc
CXX := g++
AS := nasm
LD := ld

# Répertoires
KERNEL_DIR := kernel
BOOT_DIR := boot
BUILD_DIR := build
ISO_DIR := boot/iso
USERLAND_DIR := userland

# Flags de compilation
CFLAGS := -m64 -ffreestanding -O2 -Wall -Wextra -fno-exceptions \
          -nostdlib -nostdinc -fno-builtin -fno-stack-protector \
          -mno-red-zone -fno-pie -fno-pic \
          -I$(KERNEL_DIR)/include
CXXFLAGS := $(CFLAGS) -fno-rtti -fno-use-cxa-atexit
ASFLAGS := -f elf64
LDFLAGS := -nostdlib -n -T $(KERNEL_DIR)/arch/x86_64/linker.ld

# Fichiers sources
KERNEL_C_SOURCES := $(shell find $(KERNEL_DIR) -name '*.c' 2>/dev/null || true)
KERNEL_CXX_SOURCES := $(shell find $(KERNEL_DIR) -name '*.cpp' 2>/dev/null || true)
KERNEL_ASM_SOURCES := $(shell find $(KERNEL_DIR) -name '*.asm' 2>/dev/null || true)
USERLAND_C_SOURCES := $(shell find $(USERLAND_DIR) -name '*.c' 2>/dev/null || true)

# Fichiers objets
KERNEL_C_OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(KERNEL_C_SOURCES))
KERNEL_CXX_OBJECTS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(KERNEL_CXX_SOURCES))
KERNEL_ASM_OBJECTS := $(patsubst %.asm,$(BUILD_DIR)/%.o,$(KERNEL_ASM_SOURCES))
USERLAND_C_OBJECTS := $(patsubst %.c,$(BUILD_DIR)/%.o,$(USERLAND_C_SOURCES))

ALL_OBJECTS := $(KERNEL_C_OBJECTS) $(KERNEL_CXX_OBJECTS) $(KERNEL_ASM_OBJECTS) $(USERLAND_C_OBJECTS)

# Cible principale
KERNEL_BIN := $(BUILD_DIR)/nexus.bin

.PHONY: all clean iso run run-uefi

all: $(KERNEL_BIN)

# Compilation du noyau
$(KERNEL_BIN): $(ALL_OBJECTS)
	@echo "Linking kernel..."
	@mkdir -p $(dir $@)
	$(LD) $(LDFLAGS) -o $@ $^
	@echo "Kernel built successfully: $@"

# Règles de compilation
$(BUILD_DIR)/%.o: %.c
	@echo "Compiling C: $<"
	@mkdir -p $(dir $@)
	$(CC) $(CFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.cpp
	@echo "Compiling C++: $<"
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

$(BUILD_DIR)/%.o: %.asm
	@echo "Assembling: $<"
	@mkdir -p $(dir $@)
	$(AS) $(ASFLAGS) $< -o $@

# Création de l'image ISO
iso: $(KERNEL_BIN)
	@echo "Creating ISO image..."
	@mkdir -p $(ISO_DIR)/boot/grub
	@mkdir -p $(ISO_DIR)/nexus
	@cp $(KERNEL_BIN) $(ISO_DIR)/nexus/nexus.bin
	@cp $(BOOT_DIR)/grub/grub.cfg $(ISO_DIR)/boot/grub/
	grub-mkrescue -o nexus.iso $(ISO_DIR)
	@echo "ISO created: nexus.iso"

# Exécution avec QEMU (BIOS)
run: iso
	qemu-system-x86_64 -cdrom nexus.iso -m 512M -serial stdio

# Exécution avec QEMU (UEFI)
run-uefi: iso
	qemu-system-x86_64 -cdrom nexus.iso -m 512M -serial stdio -bios /usr/share/ovmf/OVMF.fd

# Nettoyage
clean:
	rm -rf $(BUILD_DIR)
	rm -f nexus.iso
	@echo "Clean completed"

# Aide
help:
	@echo "NexusOS Build System"
	@echo "===================="
	@echo "make all      - Build the kernel"
	@echo "make iso      - Create bootable ISO image"
	@echo "make run      - Run in QEMU (BIOS mode)"
	@echo "make run-uefi - Run in QEMU (UEFI mode)"
	@echo "make clean    - Clean build files"