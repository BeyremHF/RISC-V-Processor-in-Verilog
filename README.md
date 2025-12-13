# RISC-V Processor in Verilog
Hardware implementations of RISC-V processors in Verilog for HDL Course.

## Branches
- **RV-SC**: Single-cycle RISC-V processor
- **RV-MC**: Multi-cycle RISC-V processor
- **RV-PL**: Pipelined RISC-V processor (coming soon)

## Current Implementations

### Single-Cycle (RV-SC)
Single-cycle processor supporting RV32I base integer instruction set:
- 24 instructions (R-type, I-type, S-type, B-type, J-type, U-type)
- Full datapath with PC, register file, ALU, and memory modules
- Comprehensive test suite
- CPI: 1 cycle per instruction

### Multi-Cycle (RV-MC)
Multi-cycle processor with FSM-based control:
- Same 24 RV32I instructions as single-cycle
- 12-state finite state machine controller
- Unified instruction/data memory architecture
- Variable CPI: 3-5 cycles per instruction
- Shorter clock period

## Usage

**Compile & run:**

Please see the specific commands for each branch.

## Documentation
See branch-specific documentation for detailed architecture and implementation notes.