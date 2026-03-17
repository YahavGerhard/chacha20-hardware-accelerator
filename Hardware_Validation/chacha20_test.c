#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <unistd.h>
#include <stdint.h>
#include <string.h>

#define CHACHA_BASE   0xA0020000
#define DMA_TX_BASE   0xA0000000
#define DMA_RX_BASE   0xA0010000

int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    int tfd = open("/dev/udmabuf-tx", O_RDWR | O_SYNC);
    int rfd = open("/dev/udmabuf-rx", O_RDWR | O_SYNC);

    if (fd < 0 || tfd < 0 || rfd < 0) return -1;

    // Mapping AXI-Lite Control Interfaces
    volatile uint32_t *chacha = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, CHACHA_BASE);
    volatile uint32_t *dma_tx = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, DMA_TX_BASE);
    volatile uint32_t *dma_rx = mmap(NULL, 4096, PROT_READ|PROT_WRITE, MAP_SHARED, fd, DMA_RX_BASE);
    
    // Mapping UDMABUF for safe DMA transfers (32-bit aligned)
    volatile uint32_t *tx_buf = mmap(NULL, 16384, PROT_READ|PROT_WRITE, MAP_SHARED, tfd, 0);
    volatile uint32_t *rx_buf = mmap(NULL, 16384, PROT_READ|PROT_WRITE, MAP_SHARED, rfd, 0);

    // Local shadow buffers
    uint8_t local_tx[64] = {0}; 
    uint8_t local_rx[64] = {0};

    printf("\n--- STEP 1: INITIALIZING HARDWARE ---\n");
    // Writing constants and Key to hardware registers
    chacha[1] = 0x03020100; chacha[2] = 0x07060504; chacha[0] = 1;
    usleep(1000);

    // --- ENCRYPTION PHASE ---
    printf("--- STEP 2: ENCRYPTING ---\n");
    
    // Plaintext (64 bytes / 512 bits)
    snprintf((char*)local_tx, 64, "ChaCha20 hardware accelerator running at full 512-bit capacity!"); 
    printf("Original: %s\n", local_tx);

    // Aligned 32-bit copy to hardware buffer
    uint32_t *local_tx_32 = (uint32_t*)local_tx;
    for(int i = 0; i < 16; i++) {
        tx_buf[i] = local_tx_32[i]; 
    }

    // DMA Reset
    dma_tx[0] = 4; dma_rx[12] = 4; 
    usleep(10000); 

    // Trigger DMA Transfer
    dma_rx[12] = 1; dma_rx[18] = 0x1BA44000; dma_rx[22] = 64; 
    dma_tx[0] = 1;  dma_tx[6] = 0x1BA40000;  dma_tx[10] = 64; 
    
    usleep(10000); // Wait for processing

    // Read ciphertext back to local shadow buffer
    uint32_t *local_rx_32 = (uint32_t*)local_rx;
    for(int i = 0; i < 16; i++) {
        local_rx_32[i] = rx_buf[i];
    }

    printf("Encrypted HEX: %02X %02X %02X %02X\n", local_rx[0], local_rx[1], local_rx[2], local_rx[3]);

    // --- DECRYPTION PHASE ---
    printf("--- STEP 3: DECRYPTING ---\n");
    
    // Feed ciphertext back to hardware input
    for(int i = 0; i < 16; i++) {
        tx_buf[i] = rx_buf[i]; 
    }

    dma_tx[0] = 4; dma_rx[12] = 4; 
    usleep(10000); 

    dma_rx[12] = 1; dma_rx[18] = 0x1BA44000; dma_rx[22] = 64; 
    dma_tx[0] = 1;  dma_tx[6] = 0x1BA40000;  dma_tx[10] = 64; 
    
    usleep(10000);
    
    for(int i = 0; i < 16; i++) {
        local_rx_32[i] = rx_buf[i];
    }

    printf("Decrypted result: %s\n", local_rx);

    chacha[0] = 0;
    return 0;
}