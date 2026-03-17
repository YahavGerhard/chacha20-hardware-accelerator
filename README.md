# ChaCha20 Hardware Accelerator on Zynq SoC

![System Architecture](block_design.png)

## Overview
This repository showcases a custom-designed **ChaCha20 cryptography hardware accelerator**, implemented on a Xilinx Zynq SoC. The primary focus of this project is to design an efficient, high-throughput FPGA IP that offloads heavy stream cipher computations from the CPU directly into dedicated hardware.

## System Architecture
The system architecture revolves around maximizing data throughput using the SoC's hardware resources:
* **PL (Programmable Logic / FPGA):** The core of the project. It contains the custom ChaCha20 Verilog IP and a Xilinx AXI Direct Memory Access (DMA) block. The DMA acts as a high-speed engine entirely within the FPGA, fetching plaintext from memory and streaming it directly to the crypto engine.
* **PS (Processing System / ARM):** Used strictly for hardware initialization, memory allocation, and verification via a C-based debugging script running on Embedded Linux.

## Technical Specifications & Constraints
* **Data Width:** Optimized for 512-bit block processing (64 bytes) per iteration.
* **Memory Alignment:** The DMA engine requires 32-bit aligned memory addresses for stable burst transfers.
* **Hardware Addressing:**
  * **DMA TX:** `0xA0000000`
  * **DMA RX:** `0xA0010000`
  * **ChaCha20 IP Control:** `0xA0020000`

## AXI4 Interfaces
To ensure seamless integration and high bandwidth, the custom IP utilizes standard AXI4 interfaces:
* **AXI4-Lite (Control Path):** Used by the CPU to safely configure the hardware, setting the 256-bit Key, Nonce, and control signals (Run/Reset) into the IP's registers.
* **AXI4-Stream (Datapath):** A zero-latency interface connecting the DMA directly to the ChaCha20 IP for continuous, high-speed data flow.

## Hardware Implementation (Verilog)
At the heart of this project is the custom Verilog RTL implementing the ChaCha20 algorithm:
* **FSM-Based Control:** A Finite State Machine strictly manages the initialization phase and the 20-round cryptographic computations.
* **Hardware Parallelism:** Utilizing the ARX (Add-Rotate-XOR) architecture, mathematical operations are physically wired for parallel execution.
* **Datapath:** The keystream undergoes a **real-time** bitwise XOR operation with the incoming AXI-Stream plaintext, outputting ciphertext immediately with minimal latency.

## Verification & On-Board Validation
The system was validated on a physical Zynq SoC using a C-based validation script. The process demonstrates a full cryptographic cycle (Encryption & Decryption):

### 1. Encryption Phase:
* **Input Plaintext:** `"ChaCha20 hardware accelerator running at full 512-bit capacity!"`
* **Keystream Generation:** The hardware engine generates a unique 512-bit keystream based on the provided 256-bit Key and Nonce.
* **Real-time XOR:** The IP performs a bitwise XOR between the plaintext and the keystream.
* **Ciphertext (Output):** The resulting encrypted stream is captured via DMA. For the given input and test key, the initial bytes of the ciphertext appear as: `D2 4A 7B 1F...` (verified against RFC 7539 reference).

### 2. Decryption & Recovery:
* **Decipher Process:** Due to the symmetric nature of the stream cipher, the generated Ciphertext is fed back into the hardware accelerator.
* **XOR Reversibility:** Applying a second XOR operation with the exact same keystream in real-time perfectly recovers the original message.
* **Result:** The final output is verified to be identical to the original input string, proving the arithmetic and timing integrity of the FPGA implementation.

### 3. Methodology:
* **Static Test Vectors:** Used fixed 256-bit Keys and 64-byte payloads for deterministic, bit-perfect verification.
* **Shadow Buffering:** Implementation of `udmabuf` (userspace DMA buffers) ensures safe and synchronized memory sharing between Linux and the FPGA hardware.

## Repository Structure
* [RTL](./RTL) - Custom Verilog source files for the ChaCha20 IP.
* [Vivado](./block_design.png) - Block design and system architecture.
* [Hardware_Validation](./Hardware_Validation) - C scripts used for hardware validation and on-board debugging.

---
*A hardware-focused portfolio project demonstrating FPGA design, custom IP creation, and AXI architecture.*
