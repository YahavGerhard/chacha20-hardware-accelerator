# ChaCha20 Hardware Accelerator on Zynq SoC

![System Architecture](block_design.png)

## Overview
This repository showcases a custom-designed **ChaCha20 cryptography hardware accelerator**, implemented on a Xilinx Zynq SoC. The primary focus of this project is to design an efficient, high-throughput FPGA IP that offloads heavy stream cipher computations from the CPU directly into dedicated hardware.

## System Architecture
The system architecture revolves around maximizing data throughput using the SoC's hardware resources:
* **PL (Programmable Logic / FPGA):** The core of the project. It contains the custom ChaCha20 Verilog IP and a Xilinx AXI Direct Memory Access (DMA) block. The DMA acts as a high-speed engine entirely within the FPGA, fetching plaintext from memory and streaming it directly to the crypto engine.
* **PS (Processing System / ARM):** Used strictly for hardware initialization, memory allocation, and verification via a C-based debugging script running on Embedded Linux.

## AXI4 Interfaces
To ensure seamless integration and high bandwidth, the custom IP utilizes standard AXI4 interfaces:
* **AXI4-Lite (Control Path):** Used by the CPU to safely configure the hardware, setting the 256-bit Key, Nonce, and control signals (Run/Reset) into the IP's registers.
* **AXI4-Stream (Datapath):** A zero-latency, address-less streaming interface connecting the DMA directly to the ChaCha20 IP for continuous, high-speed data flow.

## Hardware Implementation (Verilog)
At the heart of this project is the custom Verilog RTL implementing the ChaCha20 algorithm:
* **FSM-Based Control:** A Finite State Machine strictly manages the initialization phase and the 20-round cryptographic computations.
* **Hardware Parallelism:** Utilizing the ARX (Add-Rotate-XOR) architecture of ChaCha20, the mathematical operations are physically wired for parallel execution, vastly outperforming software-based sequential execution.
* **Datapath:** The mathematically generated keystream undergoes a bitwise XOR operation with the incoming AXI-Stream plaintext on-the-fly, outputting valid ciphertext immediately.

## Verification
1. **Simulation:** The Verilog core was verified using a Vivado Testbench to ensure algorithmic accuracy against standard ChaCha20 vectors and to validate AXI-Stream handshakes.
2. **Hardware Validation:** Tested on physical hardware. A C script utilizes static test vectors (pre-defined Key, Nonce, and Constants) to verify the hardware implementation against official ChaCha20 reference outputs. The script handles DMA transfers and proves the hardware's real-time stability during on-board debugging.

## Repository Structure
* [RTL](./RTL) - Custom Verilog source files for the ChaCha20 IP.
* [Vivado](./block_design.png) - Block design and system architecture.
* [Hardware_Validation](./Hardware_Validation) - C scripts used for hardware validation and on-board debugging via Linux.

---
*A hardware-focused portfolio project demonstrating FPGA design, custom IP creation, and AXI architecture.*
