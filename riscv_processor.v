// This is the complete single-cycle (One instruction completes per clock cycle) RISC-V processor that integrates all components.
module riscv_processor (
    input wire clk, // System clock
    input wire rst  // Reset signal
);

    // INTERNAL SIGNALS
    
    // Program Counter signals
    wire [31:0] pc_current;     // Current PC value
    wire [31:0] pc_next;        // Next PC value
    wire [31:0] pc_plus4;       // PC + 4
    wire [31:0] pc_target;      // PC + immediate (for branch/jump)
    
    // Instruction and its fields
    wire [31:0] instruction;    // 32-bit instruction from memory
    wire [6:0] opcode;          // Instruction opcode
    wire [4:0] rs1, rs2, rd;    // Register addresses
    wire [2:0] funct3;          // Function field 3
    wire [6:0] funct7;          // Function field 7
    
    // Sign extender
    wire [31:0] imm_ext;        // Extended immediate value
    
    // Register file
    wire [31:0] reg_rd1;        // Register read data 1 (rs1)
    wire [31:0] reg_rd2;        // Register read data 2 (rs2)
    wire [31:0] write_back_data; // Data to write back to register
    
    // ALU
    wire [31:0] alu_src_b;      // ALU operand B (from mux)
    wire [31:0] alu_result;     // ALU result
    wire alu_zero;              // ALU zero flag (not used in Part 1)
    
    // Data memory
    wire [31:0] mem_read_data;  // Data read from memory
    
    // Control signals (from controller)
    wire rf_we;                 // Register file write enable
    wire [2:0] sel_ext;         // Sign extender select
    wire sel_alu_src_b;         // ALU source B select
    wire dmem_we;               // Data memory write enable
    wire [1:0] sel_result;      // Result select
    wire [3:0] alu_control;     // ALU control
    wire branch;                // Branch signal
    wire jump;                  // Jump signal
    wire pc_src;                // PC source select
    
    // INSTRUCTION FIELD EXTRACTION
    
    assign opcode = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7 = instruction[31:25];
    
    // PROGRAM COUNTER LOGIC
    // PC can be: PC+4 (sequential), or PC+immediate (branch/jump)
    // Branch: Only taken if beq AND zero flag is set (rs1 == rs2)
    // Jump: Always taken
    assign pc_src = (branch & alu_zero) | jump;  // Select PC+imm if branch taken or jump
    
    // MODULE INSTANTIATIONS
    
    // Program Counter
    pc pc_inst (
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pc_current(pc_current)
    );
    
    // PC + 4 Adder (calculates next sequential instruction address)
    adder pc_plus4_adder (
        .a(pc_current),
        .b(32'd4),
        .sum(pc_plus4)
    );
    
    // PC + immediate Adder (for branch and jump targets)
    adder pc_target_adder (
        .a(pc_current),
        .b(imm_ext),
        .sum(pc_target)
    );
    
    // PC source multiplexer (choose between PC+4 and PC+immediate)
    mux2 pc_src_mux (
        .d0(pc_plus4),
        .d1(pc_target),
        .sel(pc_src),
        .y(pc_next)
    );
    
    // Instruction Memory
    instruction_memory imem (
        .addr(pc_current),
        .rd(instruction)
    );
    
    // Sign Extender
    sign_extender sign_ext (
        .instr(instruction[31:7]),
        .sel_ext(sel_ext),
        .imm_ext(imm_ext)
    );
    
    // Register File
    register_file reg_file (
        .clk(clk),
        .rst(rst), 
        .we(rf_we),
        .a1(rs1),
        .a2(rs2),
        .a3(rd),
        .wd(write_back_data),
        .rd1(reg_rd1),
        .rd2(reg_rd2)
    );
    
    // Multiplexer: Select ALU operand B (register or immediate)
    mux2 alu_src_b_mux (
        .d0(reg_rd2),           // From register file (rs2)
        .d1(imm_ext),           // From sign extender (immediate)
        .sel(sel_alu_src_b),
        .y(alu_src_b)
    );
    
    // ALU (Arithmetic Logic Unit)
    alu alu_inst (
        .a(reg_rd1),            // Operand A from register rs1
        .b(alu_src_b),          // Operand B from mux
        .alu_control(alu_control),
        .result(alu_result),
        .zero(alu_zero)         // Not used in Part 1
    );
    
    // Data Memory
    data_memory dmem (
        .clk(clk),
        .we(dmem_we),
        .addr(alu_result),      // Address from ALU
        .wd(reg_rd2),           // Write data from register rs2
        .rd(mem_read_data)
    );
    
    // Multiplexer: Select write-back data (ALU result, memory data, PC+4, or immediate)
    mux4 result_mux (
        .d0(alu_result),        // ALU result
        .d1(mem_read_data),     // Memory data (for lw)
        .d2(pc_plus4),          // PC+4 (for jal - return address)
        .d3(imm_ext),           // Immediate (for lui)
        .sel(sel_result),
        .y(write_back_data)
    );
    
    // Controller (Decoder)
    controller ctrl (
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .rf_we(rf_we),
        .sel_ext(sel_ext),
        .sel_alu_src_b(sel_alu_src_b),
        .dmem_we(dmem_we),
        .sel_result(sel_result),
        .alu_control(alu_control),
        .branch(branch),
        .jump(jump)
    );

endmodule
