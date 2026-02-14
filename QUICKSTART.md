# 🚀 Quick Start Guide - NexusOS

Get NexusOS running in 5 minutes!

## Prerequisites

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install -y build-essential nasm grub-pc-bin xorriso qemu-system-x86
```

### Fedora
```bash
sudo dnf groupinstall "Development Tools"
sudo dnf install nasm grub2-tools xorriso qemu-system-x86
```

### Arch Linux
```bash
sudo pacman -S base-devel nasm grub xorriso qemu
```

## Build and Run

### Method 1: Using the build script (recommended)
```bash
chmod +x build.sh
./build.sh run
```

### Method 2: Using Make
```bash
# Build the kernel
make all

# Create ISO image
make iso

# Run in QEMU
make run
```

### Method 3: Step by step
```bash
# Build
make all

# Create ISO
make iso

# Run manually
qemu-system-x86_64 -cdrom nexus.iso -m 512M
```

## First Boot

When NexusOS boots, you'll see:
1. GRUB menu (select "NexusOS 64-bit")
2. Boot messages
3. NexusOS shell prompt

## Try These Commands

```bash
nexus$ help          # Show available commands
nexus$ ls            # List files
nexus$ cat welcome.txt  # Read a file
nexus$ mem           # Show memory info
nexus$ time          # Show uptime
nexus$ clear         # Clear screen
```

## Testing on VirtualBox

1. Create a new VM:
   - Type: Linux, Version: Other Linux (64-bit)
   - RAM: 512 MB or more
   - No hard disk needed

2. Settings → Storage → Add CD → Select `nexus.iso`

3. Start the VM

## Troubleshooting

### Build fails?
```bash
# Check dependencies
./build.sh check
```

### QEMU doesn't start?
```bash
# Install QEMU
sudo apt-get install qemu-system-x86
```

### Want to debug?
```bash
# Terminal 1: Start QEMU with GDB server
./build.sh debug

# Terminal 2: Connect with GDB
gdb build/nexus.bin
(gdb) target remote localhost:1234
(gdb) continue
```

## Next Steps

- Read the [full README](README.md)
- Check the [architecture documentation](docs/ARCHITECTURE.md)
- Learn how to [contribute](CONTRIBUTING.md)
- Browse the [FAQ](docs/FAQ.md)

## Need Help?

- Open an issue on GitHub
- Check the documentation
- Visit the OSDev wiki

---

**Congratulations! You're now running NexusOS! 🎉**
