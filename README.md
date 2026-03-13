# Fault-Tolerant RV32I SoC with SECDED Memory and AXI4-Lite

## Project Objective
To design, verify, and physically synthesize a 32-bit RISC-V processor specifically engineered for high-reliability environments. The system features a custom 5-stage pipeline, interfaces with memory via an industry-standard AXI4-Lite bus, and employs a custom memory controller capable of dynamically detecting and correcting radiation- or noise-induced memory bit flips using SECDED (Single Error Correction, Double Error Detection) Hamming codes.

## Technical Specifications & Toolchain

| Category | Specification / Tool |
| --- | --- |
| **Instruction Set Architecture** | RISC-V RV32I (Base Integer, 32-bit) |
| **Microarchitecture** | 5-Stage Pipeline (Fetch, Decode, Execute, Memory, Writeback) |
| **Bus Protocol** | AMBA AXI4-Lite (Master & Slave interfaces) |
| **Error Correction (ECC)** | SECDED Hamming Code (32-bit data + 7-bit parity) |
| **Hardware Description Language** | SystemVerilog (IEEE 1800-2017) |
| **Verification / Simulation** | Verilator or ModelSim / Questa, SystemVerilog Assertions (SVAs) |
| **Physical Design (ASIC Flow)** | OpenROAD / OpenLane, Yosys, OpenSTA |
| **Target Technology Node** | SkyWater 130nm Open-Source PDK |

## Architectural Scope & Deliverables

### A. The Core Datapath (RV32I)
* **Pipeline Logic:** Standard 5-stage data flow with inter-stage pipeline registers.
* **Hazard Management:** Full hardware forwarding unit to resolve Read-After-Write (RAW) data hazards without stalling, and a hazard detection unit to inject pipeline bubbles for load-use hazards and branch mispredictions.
* **ALU:** Support for addition, subtraction, bitwise operations, and logical/arithmetic shifts.

### B. The Interconnect (AXI4-Lite)
* **CPU Master Interface:** Converts standard RISC-V load/store instructions into AXI4-Lite read/write transactions, managing `VALID` and `READY` handshake signals.
* **Memory Slave Interface:** Receives AXI4-Lite transactions and translates them into SRAM read/write enables.

### C. The SECDED Memory Controller
* **Write Operation:** Calculates a 7-bit Hamming code for every 32-bit word and stores the combined 39-bit data packet in SRAM.
* **Read Operation:** Recalculates the syndrome upon data retrieval.
  * *Syndrome = 0:* Clean data, pass to CPU.
  * *Single-bit Error:* Identify the flipped bit, invert it to correct the data, pass to CPU.
  * *Double-bit Error:* Raise an unrecoverable fault flag.

### D. Design Verification (DV)
* **Protocol Checking:** Implement SVAs to ensure the AXI4-Lite handshake protocol is never violated (e.g., `VALID` must not drop until `READY` is asserted).
* **Fault Injection:** A specialized testbench that intentionally corrupts SRAM bits during runtime to verify the SECDED controller accurately flags and corrects data before it reaches the CPU pipeline.

## Directory Structure

* `src/`: Contains all purely synthesizable SystemVerilog design files (`.sv`).
* `tb/`: Contains testbenches, fault-injection environments, and SystemVerilog Assertions.
* `docs/`: Holds block diagrams, ISA references, and memory maps.
* `scripts/`: Stores Makefiles and simulation automation scripts (for tools like Verilator or ModelSim).
* `synth/`: Dedicated output folder for Yosys and OpenROAD generated files.

## Implementation Phasing (Milestones)

* **Phase 1: Core Datapath & Control**
  * Draft architectural block diagrams.
  * Implement and verify the 5-stage pipeline modules independently (Fetch, Decode, Execute, Memory, Writeback).
  * Integrate modules and verify basic instruction execution.

* **Phase 2: Hazard & Forwarding Logic**
  * Implement the forwarding unit and hazard detection.
  * Verify against a test program containing complex data dependencies.

* **Phase 3: SECDED Memory Controller**
  * Design the Hamming code generation and decoding logic.
  * Write the fault-injection testbench to prove single-bit correction logic.

* **Phase 4: AXI4-Lite Integration**
  * Wrap the CPU memory interface and the SECDED controller in AXI4-Lite protocols.
  * Perform full-system simulation to ensure proper handshaking and data transfer.

* **Phase 5: Physical Synthesis & PPA Analysis**
  * Push the verified SystemVerilog RTL through the OpenLane flow using the Sky130 PDK.
  * Extract final metrics: Gate count, critical path delay (maximum operating frequency), and power consumption.
  * Generate the final GDSII layout.
