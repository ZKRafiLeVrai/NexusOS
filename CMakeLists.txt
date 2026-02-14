cmake_minimum_required(VERSION 3.16)
project(NexusOS C CXX ASM_NASM)

# Configuration du compilateur
set(CMAKE_C_COMPILER gcc)
set(CMAKE_CXX_COMPILER g++)
set(CMAKE_ASM_NASM_COMPILER nasm)

# Flags de compilation
set(CMAKE_C_FLAGS "-m64 -ffreestanding -O2 -Wall -Wextra -fno-exceptions -fno-rtti -nostdlib -nostdinc -fno-builtin -fno-stack-protector -mno-red-zone -mcmodel=kernel")
set(CMAKE_CXX_FLAGS "${CMAKE_C_FLAGS} -fno-use-cxa-atexit")
set(CMAKE_ASM_NASM_FLAGS "-f elf64")

# Désactiver la bibliothèque standard
set(CMAKE_C_STANDARD_LIBRARIES "")
set(CMAKE_CXX_STANDARD_LIBRARIES "")

# Répertoires d'inclusion
include_directories(
    ${CMAKE_SOURCE_DIR}/kernel/include
    ${CMAKE_SOURCE_DIR}/libc/include
)

# Fichiers sources ASM
set(ASM_SOURCES
    kernel/arch/x86_64/boot.asm
    kernel/arch/x86_64/interrupt_handlers.asm
)

# Fichiers sources C
set(C_SOURCES
    kernel/mm/memory.c
    kernel/drivers/video/video.c
    kernel/drivers/keyboard/keyboard.c
    kernel/drivers/timer/timer.c
    kernel/drivers/pci/pci.c
    kernel/fs/vfs.c
    kernel/core/scheduler.c
    userland/shell/shell.c
)

# Fichiers sources C++
set(CXX_SOURCES
    kernel/core/kernel.cpp
    kernel/core/interrupts.cpp
)

# Créer les objets ASM
foreach(asm_file ${ASM_SOURCES})
    get_filename_component(asm_name ${asm_file} NAME_WE)
    add_custom_command(
        OUTPUT ${CMAKE_BINARY_DIR}/${asm_name}.o
        COMMAND ${CMAKE_ASM_NASM_COMPILER} ${CMAKE_ASM_NASM_FLAGS} 
                ${CMAKE_SOURCE_DIR}/${asm_file} 
                -o ${CMAKE_BINARY_DIR}/${asm_name}.o
        DEPENDS ${CMAKE_SOURCE_DIR}/${asm_file}
    )
    list(APPEND ASM_OBJECTS ${CMAKE_BINARY_DIR}/${asm_name}.o)
endforeach()

# Créer le kernel
add_executable(nexus.bin
    ${C_SOURCES}
    ${CXX_SOURCES}
    ${ASM_OBJECTS}
)

# Flags de linkage
set_target_properties(nexus.bin PROPERTIES
    LINK_FLAGS "-nostdlib -n -T ${CMAKE_SOURCE_DIR}/kernel/arch/x86_64/linker.ld"
)

# Target pour créer l'ISO
add_custom_target(iso
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/boot/iso/nexus
    COMMAND ${CMAKE_COMMAND} -E make_directory ${CMAKE_SOURCE_DIR}/boot/iso/boot/grub
    COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:nexus.bin> ${CMAKE_SOURCE_DIR}/boot/iso/nexus/
    COMMAND ${CMAKE_COMMAND} -E copy ${CMAKE_SOURCE_DIR}/boot/grub/grub.cfg ${CMAKE_SOURCE_DIR}/boot/iso/boot/grub/
    COMMAND grub-mkrescue -o ${CMAKE_SOURCE_DIR}/nexus.iso ${CMAKE_SOURCE_DIR}/boot/iso
    DEPENDS nexus.bin
    COMMENT "Creating ISO image..."
)

# Target pour exécuter avec QEMU
add_custom_target(run
    COMMAND qemu-system-x86_64 -cdrom ${CMAKE_SOURCE_DIR}/nexus.iso -m 512M -serial stdio
    DEPENDS iso
    COMMENT "Running NexusOS in QEMU..."
)

# Installation
install(TARGETS nexus.bin DESTINATION bin)
install(FILES ${CMAKE_SOURCE_DIR}/nexus.iso DESTINATION . OPTIONAL)
