# RV-MC: Multi-Cycle RISC-V Processor

Multi-cycle implementation of RV32I base integer instruction set in Verilog.

## Features

* **24 RISC-V Instructions**: ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU, ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW, SW, BEQ, JAL, LUI
* **Multi-Cycle Execution**: Instructions complete in 3-5 cycles depending on type
* **Unified Memory**: Single memory serves both instructions and data
* **FSM Controller**: 12-state finite state machine manages execution flow
* **State Registers**: Intermediate values stored between cycles

## Architecture

Multi-cycle design where each instruction executes over multiple clock cycles:

* **Shorter Clock Period**: Only needs to accommodate slowest stage (not entire instruction)
* **Resource Reuse**: Single ALU used across different stages
* **Variable CPI**: LUI=3, R/I/SW/BEQ/JAL=4, LW=5 cycles
* **State Registers**: instr_reg, data_reg, rd1_reg, rd2_reg, alu_reg hold intermediate values

## Instruction Execution Stages

| Instruction | Cycles | Stages |
|-------------|--------|--------|
| LW          | 5      | Fetch → Decode → Addr Calc → Mem Read → Write Back |
| SW          | 4      | Fetch → Decode → Addr Calc → Mem Write |
| R-type      | 4      | Fetch → Decode → Execute → Write Back |
| I-type      | 4      | Fetch → Decode → Execute → Write Back |
| BEQ         | 4      | Fetch → Decode → Target Calc → Compare |
| JAL         | 4      | Fetch → Decode → Target Calc → Write Back |
| LUI         | 3      | Fetch → Decode → Write Back |

## Module Structure
```
rv_mc.v                    # Top-level module
├── pc_mc.v                # Program counter with enable
├── mem.v                  # Unified instruction/data memory
├── generic_register.v     # State registers
├── mux2.v / mux4.v        # Multiplexers
├── register_file.v        # 32 registers
├── sign_extender_debug.v  # Immediate generation
├── alu.v                  # Arithmetic/logic unit
└── controller_mc.v        # Multi-cycle controller
    ├── fsm.v              # Finite state machine
    ├── alu_decoder.v      # ALU control decoder
    └── instr_decoder.v    # Sign extender selector
```

## Usage

**Compile:**
```bash
iverilog -o sim testbench_mc.v rv_mc.v controller_mc.v fsm.v alu_decoder.v instr_decoder.v mem.v generic_register.v pc_mc.v alu.v register_file.v sign_extender.v mux2.v mux4.v
```

**Run:**
```bash
vvp sim
```

**View Waveforms:**
```bash
gtkwave riscv_processor_mc.vcd
```

## Key Differences from Single-Cycle

| Aspect | Single-Cycle | Multi-Cycle |
|--------|--------------|-------------|
| **CPI** | 1 | 3-5 (average ~4) |
| **Memory** | Separate inst/data | Unified |
| **ALU Usage** | 3 adders needed | 1 ALU reused |
| **Control** | Combinational | FSM-based |


Multi-cycle enables higher clock frequency but requires more cycles per instruction.

## Testing

Test suite validates all 24 instructions with 38 comprehensive tests including:
- Arithmetic operations with positive and negative immediates
- Logical operations and shifts
- Memory load/store operations
- Branch and jump instructions

