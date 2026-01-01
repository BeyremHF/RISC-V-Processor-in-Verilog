# RV-PL: Pipelined RISC-V Processor
5-stage pipelined implementation of RV32I base integer instruction set in Verilog.

## Features
* **24 RISC-V Instructions**: ADD, SUB, XOR, OR, AND, SLL, SRL, SRA, SLT, SLTU, ADDI, XORI, ORI, ANDI, SLLI, SRLI, SRAI, SLTI, SLTIU, LW, SW, BEQ, JAL, LUI
* **5-Stage Pipeline**: IF → ID → EX → MA → WB with concurrent instruction execution
* **Hazard Resolution**: Data forwarding, pipeline stalling, and flushing
* **Separate Memories**: Independent instruction and data memories
* **CPI ≈ 1.2-1.5**: Near-ideal throughput with automatic hazard handling

## Architecture
Classic 5-stage RISC pipeline with comprehensive hazard detection:
* **Pipeline Stages**: Instruction Fetch, Instruction Decode, Execute, Memory Access, Write Back
* **Data Forwarding**: Automatic forwarding from MA/WB stages to EX stage
* **Hazard Detection**: Handles RAW, load-use, and control hazards
* **Register File**: Writes on negative clock edge for same-cycle availability
* **Pipeline Registers**: PLR1-4 separate and synchronize each stage

## Pipeline Stages
| Stage | Function | Components |
|-------|----------|------------|
| **IF** | Fetch instruction from memory | PC, instruction memory, PC+4 adder |
| **ID** | Decode instruction, read registers | Register file, controller, sign extender |
| **EX** | Execute operation, calculate targets | ALU, forwarding MUXes, branch adder |
| **MA** | Access data memory | Data memory |
| **WB** | Write result back to register | Result MUX |

## Hazard Handling
| Hazard Type | Detection | Resolution | Penalty |
|-------------|-----------|------------|---------|
| **RAW** | Compare register addresses | Data forwarding from MA/WB | 0 cycles |
| **Load-Use** | LW in EX, dependency in ID | Stall + flush | 1 cycle |
| **Control** | Branch/jump taken | Flush IF/ID stages | 2 cycles |

## Module Structure
```
rv_pl.v                    # Top-level pipelined processor
├── pc_pl.v                # Program counter with enable
├── instruction_memory.v   # Instruction memory
├── data_memory.v          # Data memory
├── plr1.v - plr4.v        # Pipeline registers (IF/ID, ID/EX, EX/MA, MA/WB)
├── hazard_unit.v          # Hazard detection and forwarding control
├── mux2.v / mux3.v / mux4.v  # Multiplexers
├── register_file_pl.v     # 32 registers (negedge write)
├── sign_extender.v        # Immediate generation
├── alu.v                  # Arithmetic/logic unit
└── controller.v           # Single-cycle controller
    ├── alu_decoder.v      # ALU control decoder
    └── instr_decoder.v    # Main instruction decoder
```

## Usage
**Compile:**
```bash
iverilog -g2012 -o sim *.v
```

**Run:**
```bash
vvp sim
```

**View Waveforms:**
```bash
gtkwave dump.vcd
```

## Key Differences from Multi-Cycle
| Aspect | Multi-Cycle | Pipelined |
|--------|-------------|-----------|
| **CPI** | 3-5 (avg ~4.0) | 1.2-1.5 |
| **Memory** | Unified | Separate inst/data |
| **Throughput** | 1 instruction every 4 cycles | ~1 instruction per cycle |
| **Control** | FSM (12 states) | Hazard unit + forwarding |
| **Registers** | 5 state registers | 4 pipeline registers |
| **Complexity** | Simpler control | Hazard detection required |

Pipeline achieves ~3x higher throughput than multi-cycle with automatic hazard handling.

## Testing
Test suite validates all 24 instructions with 38 comprehensive tests including:
- Arithmetic operations with positive and negative immediates
- Logical operations and shifts
- Memory load/store operations with hazard scenarios
- Branch and jump instructions with pipeline flushing
- Data forwarding and stall insertion verification

**Result:** 38/38 tests passed (100%)