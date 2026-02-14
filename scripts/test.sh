#!/bin/bash
# NexusOS Automated Test Script

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TESTS_PASSED=0
TESTS_FAILED=0

print_test() {
    echo -e "${YELLOW}[TEST]${NC} $1"
}

print_pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    ((TESTS_PASSED++))
}

print_fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    ((TESTS_FAILED++))
}

# Test 1: Build system
test_build() {
    print_test "Testing build system..."
    
    if make clean >/dev/null 2>&1 && make all >/dev/null 2>&1; then
        print_pass "Build system works"
    else
        print_fail "Build system failed"
        return 1
    fi
}

# Test 2: Kernel binary
test_kernel_binary() {
    print_test "Testing kernel binary..."
    
    if [ -f "build/nexus.bin" ]; then
        # Check if it's an ELF file
        if file build/nexus.bin | grep -q "ELF"; then
            print_pass "Kernel binary is valid ELF"
        else
            print_fail "Kernel binary is not ELF"
            return 1
        fi
    else
        print_fail "Kernel binary not found"
        return 1
    fi
}

# Test 3: ISO creation
test_iso_creation() {
    print_test "Testing ISO creation..."
    
    if make iso >/dev/null 2>&1; then
        if [ -f "nexus.iso" ]; then
            print_pass "ISO creation successful"
        else
            print_fail "ISO file not created"
            return 1
        fi
    else
        print_fail "ISO creation failed"
        return 1
    fi
}

# Test 4: QEMU boot test
test_qemu_boot() {
    print_test "Testing QEMU boot (30 seconds timeout)..."
    
    if ! command -v qemu-system-x86_64 >/dev/null 2>&1; then
        print_fail "QEMU not installed, skipping boot test"
        return 0
    fi
    
    # Run QEMU in background with timeout
    timeout 30s qemu-system-x86_64 \
        -cdrom nexus.iso \
        -m 512M \
        -nographic \
        -serial file:qemu_output.log \
        >/dev/null 2>&1 &
    
    QEMU_PID=$!
    sleep 5
    
    # Check if QEMU is still running (it should be)
    if ps -p $QEMU_PID > /dev/null 2>&1; then
        kill $QEMU_PID 2>/dev/null || true
        wait $QEMU_PID 2>/dev/null || true
        
        # Check boot output
        if [ -f "qemu_output.log" ]; then
            if grep -q "NexusOS" qemu_output.log && \
               grep -q "Boot sequence completed" qemu_output.log; then
                print_pass "QEMU boot successful"
                rm -f qemu_output.log
            else
                print_fail "QEMU boot did not complete properly"
                cat qemu_output.log
                rm -f qemu_output.log
                return 1
            fi
        else
            print_fail "No QEMU output captured"
            return 1
        fi
    else
        print_fail "QEMU crashed or exited early"
        return 1
    fi
}

# Test 5: Memory layout
test_memory_layout() {
    print_test "Testing memory layout..."
    
    # Check linker script
    if [ -f "kernel/arch/x86_64/linker.ld" ]; then
        if grep -q "1M" kernel/arch/x86_64/linker.ld; then
            print_pass "Memory layout is correct"
        else
            print_fail "Invalid memory layout"
            return 1
        fi
    else
        print_fail "Linker script not found"
        return 1
    fi
}

# Test 6: Source code structure
test_source_structure() {
    print_test "Testing source code structure..."
    
    local required_dirs=(
        "kernel/arch/x86_64"
        "kernel/core"
        "kernel/drivers"
        "kernel/include"
        "kernel/mm"
        "kernel/fs"
        "userland/shell"
        "boot/grub"
    )
    
    local missing=0
    for dir in "${required_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            print_fail "Missing directory: $dir"
            missing=1
        fi
    done
    
    if [ $missing -eq 0 ]; then
        print_pass "Source structure is correct"
    else
        return 1
    fi
}

# Test 7: GRUB configuration
test_grub_config() {
    print_test "Testing GRUB configuration..."
    
    if [ -f "boot/grub/grub.cfg" ]; then
        if grep -q "multiboot2" boot/grub/grub.cfg && \
           grep -q "nexus.bin" boot/grub/grub.cfg; then
            print_pass "GRUB configuration is valid"
        else
            print_fail "Invalid GRUB configuration"
            return 1
        fi
    else
        print_fail "GRUB configuration not found"
        return 1
    fi
}

# Run all tests
echo "======================================"
echo "     NexusOS Automated Test Suite    "
echo "======================================"
echo ""

test_source_structure || true
test_grub_config || true
test_build || true
test_kernel_binary || true
test_memory_layout || true
test_iso_creation || true
test_qemu_boot || true

echo ""
echo "======================================"
echo "         Test Results Summary         "
echo "======================================"
echo -e "Tests passed: ${GREEN}${TESTS_PASSED}${NC}"
echo -e "Tests failed: ${RED}${TESTS_FAILED}${NC}"
echo "======================================"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed.${NC}"
    exit 1
fi
