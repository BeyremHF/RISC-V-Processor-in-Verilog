# RV-SC: Single-Cycle RISC-V Processor

Single-cycle implementation of RV32I base integer instruction set in Verilog.

## Features

- **24 RISC-V Instructions**: ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU, ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW, SW, BEQ, JAL, LUI
- **Complete Datapath**: PC, instruction memory, register file, ALU, data memory, control unit
- **Full Control Logic**: Main controller and ALU decoder with all control signals
  
## Architecture

Single-cycle design where each instruction completes in one clock cycle:
- PC increments by 4 or jumps to target address
- Instruction fetch, decode, execute, memory access, and write-back occur in parallel
- No pipeline registers or hazard handling required

## Module Structure
```
riscv_processor.v          # Top-level module
├── pc.v                   # Program counter
├── adder.v                # PC+4 and branch target adders
├── mux2.v / mux4.v        # Multiplexers
├── instruction_memory.v   # ROM with test program
├── register_file.v        # 32 registers
├── sign_extender.v        # Immediate generation
├── alu.v                  # Arithmetic/logic unit
├── data_memory.v          # RAM
└── controller.v           # Control unit
```

## Usage

**Compile:**
```bash
iverilog -o sim testbench.v riscv_processor.v pc.v adder.v mux2.v mux4.v instruction_memory.v register_file.v sign_extender.v alu.v data_memory.v controller.v
```

**Run:**
```bash
vvp sim
```

**View Waveforms:**
```bash
gtkwave dump.vcd
```
