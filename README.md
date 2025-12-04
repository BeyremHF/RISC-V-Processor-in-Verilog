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

```bash
# Compile and run testbench
iverilog -o riscv_tb riscv_processor_tb.v riscv_processor.v
vvp riscv_tb
```

## Documentation

See branch-specific documentation for detailed architecture and implementation notes.
