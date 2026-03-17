# ChaCha20 Hardware Accelerator on Zynq SoC

![System Architecture](block_design.png)

## Overview
This project showcases a custom-designed **ChaCha20 cryptographic hardware accelerator**, implemented on a Xilinx Zynq UltraScale+ SoC. The primary objective was to develop a robust encryption system capable of processing large data streams with high security and minimal latency, leveraging dedicated FPGA logic to outperform software-based implementations.

## System Architecture & SoC Integration
The design integrates multiple hardware components to ensure reliable data movement and processing:
* **Custom ChaCha20 IP (PL):** A high-speed Verilog core implementing the stream cipher.
* **AXI DMA Controller:** Acts as the high-speed data mover. It utilizes **AXI4-Memory Map (AXI-MM)** to fetch data from the DDR memory and **AXI4-Stream** to push it into the crypto core.
* **Infrastructure Blocks:** Includes AXI Interconnects for bus arbitration and Processor System Reset modules to ensure synchronized hardware startup.
* **Processing System (PS):** An ARM-based processor running **Embedded Linux**, responsible for system orchestration and hardware validation.

## Technical Specifications
* **Protocol Standard:** RFC 7539 (The official Internet Engineering Task Force standard for ChaCha20).
* **Data Capacity:** Optimized for 512-bit block processing (64 bytes) per iteration, suitable for high-bandwidth streams.
* **Hardware Addressing:** * DMA Control: `0xA0000000` / `0xA0010000`
  * Crypto Control: `0xA0020000`

## AXI4 Interfaces
* **AXI4-Lite:** Control path for configuring the 256-bit Key, 96-bit Nonce, and 32-bit initial counter.
* **AXI4-Stream:** High-throughput data path for plaintext/ciphertext streaming.
* **AXI4-MM (Memory Map):** Used by the DMA to interface directly with the SoC's DDR memory.

## Hardware Implementation (Verilog)
* **Parallel Architecture:** Mathematical operations (Add-Rotate-XOR) are physically wired for parallel execution.
* **Real-time Processing:** The keystream is XORed with the incoming data stream in real-time, ensuring zero-latency encryption as data flows through the pipeline.

## Verification & On-Board Validation
The system was validated on a physical Zynq SoC. The validation process ensures "Bit-Perfect" accuracy:
* **Test Configuration:** Validated using a standard 256-bit Key and 96-bit Nonce.
* **Full Cycle:** The script encrypts a 64-byte payload and then decrypts the result. By applying the symmetric XOR property, the original data is perfectly recovered.
* **udmabuf (User DMA Buffer):** Used to allocate a contiguous memory region in the kernel. This acts as a "shared window," allowing safe and synchronized data exchange between the Linux userspace application and the FPGA hardware.

## Project Structure
* [RTL](./RTL) - Custom Verilog source files (English comments).
* [Vivado](./block_design.png) - System block design.
* [Hardware_Validation](./Hardware_Validation) - C validation scripts.
