#include "pci.h"
#include "io.h"
#include "video.h"

#define PCI_CONFIG_ADDRESS 0xCF8
#define PCI_CONFIG_DATA 0xCFC

static const char* pci_class_names[] = {
    "Unclassified",
    "Mass Storage Controller",
    "Network Controller",
    "Display Controller",
    "Multimedia Controller",
    "Memory Controller",
    "Bridge Device",
    "Simple Communication Controller",
    "Base System Peripheral",
    "Input Device",
    "Docking Station",
    "Processor",
    "Serial Bus Controller",
    "Wireless Controller",
    "Intelligent I/O Controller",
    "Satellite Communication Controller",
    "Encryption/Decryption Controller",
    "Data Acquisition Controller"
};

uint32_t pci_read_config(uint8_t bus, uint8_t device, uint8_t function, uint8_t offset) {
    uint32_t address = (uint32_t)((bus << 16) | (device << 11) | 
                                  (function << 8) | (offset & 0xFC) | 0x80000000);
    
    outl(PCI_CONFIG_ADDRESS, address);
    return inl(PCI_CONFIG_DATA);
}

void pci_write_config(uint8_t bus, uint8_t device, uint8_t function, uint8_t offset, uint32_t value) {
    uint32_t address = (uint32_t)((bus << 16) | (device << 11) | 
                                  (function << 8) | (offset & 0xFC) | 0x80000000);
    
    outl(PCI_CONFIG_ADDRESS, address);
    outl(PCI_CONFIG_DATA, value);
}

static void pci_scan_device(uint8_t bus, uint8_t device) {
    uint32_t vendor_device = pci_read_config(bus, device, 0, 0);
    uint16_t vendor_id = vendor_device & 0xFFFF;
    uint16_t device_id = (vendor_device >> 16) & 0xFFFF;
    
    if (vendor_id == 0xFFFF) {
        return; // Device doesn't exist
    }
    
    uint32_t class_info = pci_read_config(bus, device, 0, 0x08);
    uint8_t class_code = (class_info >> 24) & 0xFF;
    uint8_t subclass = (class_info >> 16) & 0xFF;
    
    const char* class_name = "Unknown";
    if (class_code < sizeof(pci_class_names) / sizeof(pci_class_names[0])) {
        class_name = pci_class_names[class_code];
    }
    
    video_printf("  [%u:%u] Vendor: %x, Device: %x, Class: %s (%x:%x)\n",
                 bus, device, vendor_id, device_id, class_name, class_code, subclass);
}

void pci_init(void) {
    video_print("Scanning PCI devices:\n");
    
    int devices_found = 0;
    
    // Scanner le bus 0 (simplifié)
    for (uint8_t device = 0; device < 32; device++) {
        uint32_t vendor_device = pci_read_config(0, device, 0, 0);
        uint16_t vendor_id = vendor_device & 0xFFFF;
        
        if (vendor_id != 0xFFFF) {
            pci_scan_device(0, device);
            devices_found++;
        }
    }
    
    if (devices_found == 0) {
        video_print("  No PCI devices found.\n");
    }
}
