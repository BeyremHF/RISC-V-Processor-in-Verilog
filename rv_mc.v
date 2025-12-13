// Multi-Cycle RISC-V Processor - Top Module
// This processor executes one instruction over multiple clock cycles
// Different instructions take different number of cycles to complete
module rv_mc (
    input wire clk,     // Clock signal
    input wire rst      // Reset signal
);

    // ========== INTERNAL SIGNALS ==========
    
    // Program Counter signals
    wire [31:0] pc_current;         // Current PC value
    wire [31:0] pc_next;            // Next PC value (from mux)
    wire [31:0] pc_plus4;           // PC + 4 (stored separately for JAL)
    wire [31:0] old_pc;             // PC before current instruction (for JAL)
    
    // Instruction and its fields
    wire [31:0] instruction;        // Current instruction from IR
    wire [31:0] mem_instr;          // Instruction from memory
    wire [6:0] op;                  // Opcode
    wire [4:0] rs1, rs2, rd;        // Register addresses
    wire [2:0] funct3;              // funct3 field
    wire funct7_5;                  // bit 5 of funct7
    
    // Sign extender
    wire [31:0] imm_ext;            // Extended immediate
    
    // Register file
    wire [31:0] reg_rd1, reg_rd2;   // Register outputs
    wire [31:0] rd1, rd2;           // Registered register outputs
    wire [31:0] write_data;         // Data to write to register
    
    // ALU signals
    wire [31:0] alu_src_a;          // ALU input A (from mux)
    wire [31:0] alu_src_b;          // ALU input B (from mux)
    wire [31:0] alu_out;            // ALU output (combinational)
    wire [31:0] alu_result;         // ALU output (registered)
    wire alu_zero;                  // Zero flag from ALU
    
    // Memory signals
    wire [31:0] mem_addr;           // Memory address (from mux)
    wire [31:0] mem_read;           // Data read from memory
    wire [31:0] data;               // Registered memory data
    
    // Control signals
    wire we_pc;                     // PC write enable
    wire we_ir;                     // Instruction register write enable
    wire we_rf;                     // Register file write enable
    wire we_mem;                    // Memory write enable
    wire sel_mem_addr;              // Memory address select (0=PC, 1=ALU)
    wire [1:0] sel_alu_src_a;       // ALU source A select
    wire [1:0] sel_alu_src_b;       // ALU source B select
    wire [1:0] sel_result;          // Result select
    wire [3:0] alu_control;         // ALU control
    wire [2:0] sel_ext;             // Sign extender select
    wire sel_pc_src;                // PC source select (from FSM)
    
    // ========== INSTRUCTION FIELD EXTRACTION ==========
    assign op = instruction[6:0];
    assign rd = instruction[11:7];
    assign funct3 = instruction[14:12];
    assign rs1 = instruction[19:15];
    assign rs2 = instruction[24:20];
    assign funct7_5 = instruction[30];  // bit 5 of funct7 (bit 30 of instruction)
    
    // ========== STATE REGISTERS (Multi-Cycle Architecture) ==========
    // These registers hold intermediate values between clock cycles
    // This allows one instruction to execute over multiple cycles
    
    // PC Register with enable
    pc_mc pc_reg (
        .clk(clk),
        .rst(rst),
        .en(we_pc),
        .pc_next(pc_next),
        .pc_current(pc_current)
    );
    
    // Old PC Register - stores PC value before fetch for JAL
    // This captures PC of current instruction (needed for JAL to save return address)
    register old_pc_reg (
        .clk(clk),
        .rst(rst),
        .en(we_ir),              // Update when fetching new instruction
        .d(pc_current),
        .q(old_pc)
    );
    
    // Instruction Register
    register instr_reg (
        .clk(clk),
        .rst(rst),
        .en(we_ir),
        .d(mem_read),            // Load instruction from memory
        .q(instruction)
    );
    
    // Data Register (stores data read from memory)
    register data_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),               // Always enabled
        .d(mem_read),
        .q(data)
    );
    
    // Register File Output Registers
    register rd1_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),               // Always enabled
        .d(reg_rd1),
        .q(rd1)
    );
    
    register rd2_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),               // Always enabled
        .d(reg_rd2),
        .q(rd2)
    );
    
    // ALU Result Register
    register alu_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),               // Always enabled
        .d(alu_out),
        .q(alu_result)
    );
    
    // PC+4 Register (for JAL return address)
    register pc_plus4_reg (
        .clk(clk),
        .rst(rst),
        .en(we_ir),              // Update when fetching new instruction
        .d(alu_out),             // Computed in fetch stage
        .q(pc_plus4)
    );
    
    // ========== DATAPATH COMPONENTS ==========
    
    // Memory Address Multiplexer
    // sel_mem_addr=0: Use PC (instruction fetch)
    // sel_mem_addr=1: Use ALU result (data memory access)
    mux2 mem_addr_mux (
        .d0(pc_current),
        .d1(alu_result),
        .sel(sel_mem_addr),
        .y(mem_addr)
    );
    
    // Unified Memory
    mem MEM (
        .clk(clk),
        .we(we_mem),
        .addr(mem_addr),
        .wd(rd2),                // Write data from rs2
        .rd(mem_read)
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
        .we(we_rf),
        .a1(rs1),
        .a2(rs2),
        .a3(rd),
        .wd(write_data),
        .rd1(reg_rd1),
        .rd2(reg_rd2)
    );
    
    // ALU Source A Multiplexer (4-to-1)
    // 00: PC (for PC+4 in fetch)
    // 01: old_pc (for JAL - PC of current instruction)
    // 10: rd1 (registered register data)
    // 11: unused
    mux4 alu_src_a_mux (
        .d0(pc_current),
        .d1(old_pc),
        .d2(rd1),
        .d3(32'b0),
        .sel(sel_alu_src_a),
        .y(alu_src_a)
    );
    
    // ALU Source B Multiplexer (4-to-1)
    // 00: rd2 (registered register data)
    // 01: imm_ext (immediate value)
    // 10: 4 (for PC+4)
    // 11: unused
    mux4 alu_src_b_mux (
        .d0(rd2),
        .d1(imm_ext),
        .d2(32'd4),
        .d3(32'b0),
        .sel(sel_alu_src_b),
        .y(alu_src_b)
    );
    
    // ALU
    alu alu_inst (
        .a(alu_src_a),
        .b(alu_src_b),
        .alu_control(alu_control),
        .result(alu_out),
        .zero(alu_zero)
    );
    
    // Result Multiplexer (4-to-1) - for register file write-back
    // 00: alu_result (registered ALU output)
    // 01: data (registered memory data)
    // 10: pc_plus4 (for JAL return address)
    // 11: imm_ext (for LUI)
    mux4 result_mux (
        .d0(alu_result),
        .d1(data),
        .d2(pc_plus4),
        .d3(imm_ext),
        .sel(sel_result),
        .y(write_data)
    );
    
    // PC Update Multiplexer
    // sel_pc_src from FSM determines which value to use:
    // 0: alu_out (direct ALU output, for PC+4 in fetch)
    // 1: alu_result (registered ALU result, for branch/jump targets from S2)
    mux2 pc_next_mux (
        .d0(alu_out),        // Use direct ALU output (PC+4)
        .d1(alu_result),     // Use registered ALU result (branch/jump target)
        .sel(sel_pc_src),
        .y(pc_next)
    );
    
    // Multi-Cycle Controller
    controller_mc ctrl (
        .clk(clk),
        .rst(rst),
        .op(op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .zero(alu_zero),
        .we_pc(we_pc),
        .we_ir(we_ir),
        .we_rf(we_rf),
        .we_mem(we_mem),
        .sel_mem_addr(sel_mem_addr),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .sel_result(sel_result),
        .alu_control(alu_control),
        .sel_ext(sel_ext),
        .sel_pc_src(sel_pc_src)
    );

endmodule