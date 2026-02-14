#!/bin/bash
# NexusOS Build Script
# Usage: ./build.sh [clean|all|iso|run|debug]

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
print_success() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[i]${NC} $1"
}

check_dependencies() {
    print_info "Checking dependencies..."
    
    local missing_deps=()
    
    command -v gcc >/dev/null 2>&1 || missing_deps+=("gcc")
    command -v nasm >/dev/null 2>&1 || missing_deps+=("nasm")
    command -v ld >/dev/null 2>&1 || missing_deps+=("ld")
    command -v grub-mkrescue >/dev/null 2>&1 || missing_deps+=("grub-mkrescue")
    command -v xorriso >/dev/null 2>&1 || missing_deps+=("xorriso")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        print_error "Missing dependencies: ${missing_deps[*]}"
        echo ""
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install build-essential nasm grub-pc-bin xorriso"
        echo "  Fedora: sudo dnf install gcc nasm grub2-tools xorriso"
        echo "  Arch: sudo pacman -S base-devel nasm grub xorriso"
        exit 1
    fi
    
    print_success "All dependencies found"
}

build_kernel() {
    print_info "Building NexusOS kernel..."
    make all
    print_success "Kernel built successfully"
}

build_iso() {
    print_info "Creating ISO image..."
    make iso
    print_success "ISO created: nexus.iso"
}

clean_build() {
    print_info "Cleaning build files..."
    make clean
    print_success "Clean completed"
}

run_qemu() {
    print_info "Starting QEMU..."
    
    if [ ! -f "nexus.iso" ]; then
        print_error "ISO file not found. Building..."
        build_iso
    fi
    
    # Check if QEMU is installed
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        print_error "QEMU not installed"
        echo "Install with:"
        echo "  Ubuntu/Debian: sudo apt-get install qemu-system-x86"
        echo "  Fedora: sudo dnf install qemu-system-x86"
        echo "  Arch: sudo pacman -S qemu"
        exit 1
    fi
    
    qemu-system-x86_64 -cdrom nexus.iso -m 512M -serial stdio
}

run_debug() {
    print_info "Starting QEMU in debug mode..."
    
    if [ ! -f "nexus.iso" ]; then
        print_error "ISO file not found. Building..."
        build_iso
    fi
    
    print_info "QEMU listening on port 1234"
    print_info "In another terminal, run: gdb build/nexus.bin"
    print_info "Then in GDB: target remote localhost:1234"
    
    qemu-system-x86_64 -cdrom nexus.iso -m 512M -serial stdio -s -S
}

show_help() {
    cat << EOF
NexusOS Build Script

Usage: ./build.sh [command]

Commands:
    all      - Build the kernel (default)
    iso      - Create bootable ISO image
    run      - Build and run in QEMU
    debug    - Build and run in QEMU with GDB server
    clean    - Clean build files
    help     - Show this help message

Examples:
    ./build.sh           # Build kernel
    ./build.sh iso       # Build and create ISO
    ./build.sh run       # Build, create ISO, and run in QEMU
    ./build.sh debug     # Build and run with debugging

EOF
}

# Main
case "${1:-all}" in
    check)
        check_dependencies
        ;;
    all)
        check_dependencies
        build_kernel
        ;;
    iso)
        check_dependencies
        build_kernel
        build_iso
        ;;
    run)
        check_dependencies
        build_kernel
        build_iso
        run_qemu
        ;;
    debug)
        check_dependencies
        build_kernel
        build_iso
        run_debug
        ;;
    clean)
        clean_build
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        print_error "Unknown command: $1"
        show_help
        exit 1
        ;;
esac
