# RISC-V Processor in Verilog
To compile, run: iverilog -o sim testbench.v riscv_processor.v pc.v adder.v mux2.v mux4.v instruction_memory.v register_file.v sign_extender.v alu.v data_memory.v controller.v

To run the program, run: vvp sim
