# Changelog

All notable changes to NexusOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-02-14

### Added
- Initial release of NexusOS
- 64-bit kernel with Multiboot2 support
- Memory management system:
  - Physical memory manager (bitmap allocator)
  - Virtual memory with pagination
  - Kernel heap allocator
- Interrupt handling:
  - IDT (Interrupt Descriptor Table) setup
  - PIC remapping
  - Exception handlers
  - IRQ handlers
- Drivers:
  - VGA text mode video driver
  - PS/2 keyboard driver
  - PIT timer driver
  - Basic PCI enumeration
- Task scheduler (round-robin)
- Virtual File System (VFS):
  - RAM disk implementation
  - Basic file operations (read, write, create, delete)
- Interactive shell with commands:
  - help, clear, ls, cat, mem, time, echo, reboot, halt
- Boot system:
  - GRUB configuration
  - Boot sequence from 32-bit to 64-bit mode
  - Long mode activation
- Build system:
  - Makefile for compilation
  - CMake support (alternative)
  - Automated build script
  - GitHub Actions workflow
- Documentation:
  - README with complete setup instructions
  - ARCHITECTURE documentation
  - COMPILATION guide
  - CONTRIBUTING guide
  - FAQ
  - LICENSE (MIT)

### Known Issues
- No preemptive multitasking
- Simple bump allocator doesn't free memory
- No user/kernel space separation
- Limited driver support
- No networking support
- No GUI

### Technical Details
- Language: C, C++, Assembly (NASM)
- Architecture: x86_64
- Bootloader: GRUB2 (Multiboot2)
- Memory: 128 MB supported
- Page size: 4 KB

## [Unreleased]

### Planned
- ACPI support
- APIC/IOAPIC (replace PIC)
- Better memory allocator (slab/buddy)
- Preemptive multitasking
- ELF executable loader
- System calls
- User/kernel separation (Ring 3)
- ext2/FAT32 filesystem support
- Network stack (TCP/IP)
- USB support
- Sound driver
- GUI (graphical interface)

---

For more details, see the [GitHub releases page](https://github.com/yourusername/nexusos/releases).
