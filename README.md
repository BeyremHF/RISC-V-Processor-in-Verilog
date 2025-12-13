# RISC-V Processor in Verilog
Hardware implementations of RISC-V processors in Verilog for HDL Course.

## Branches
- **RV-SC**: Single-cycle RISC-V processor
- **RV-MC**: Multi-cycle RISC-V processor (coming soon)
- **RV-PL**: Pipelined RISC-V processor (coming soon)

## Current Implementation (RV-SC)
Single-cycle processor supporting RV32I base integer instruction set:
- 24 instructions (R-type, I-type, S-type, B-type, J-type, U-type)
- Full datapath with PC, register file, ALU, and memory modules
- Comprehensive test suite with 100% pass rate

## Usage

**Compile:**
```bash
iverilog -o sim testbench.v riscv_processor.v pc.v adder.v mux2.v mux4.v instruction_memory.v register_file.v sign_extender.v alu.v data_memory.v controller.v
```

**Run:**
```bash
vvp sim
```

## Documentation
See branch-specific documentation for detailed architecture and implementation notes.