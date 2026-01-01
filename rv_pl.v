// RISC-V Pipelined Processor - Top Level Module
// 5-Stage Pipeline: IF → ID → EX → MA → WB
// Implements hazard detection and forwarding

module rv_pl (
    input wire clk,      // Clock signal
    input wire rst_n     // Active-low reset
);

// Reset signal (convert active-low to active-high)
wire rst;
assign rst = ~rst_n;

// ============================================================================
// STAGE 1: IF (Instruction Fetch)
// ============================================================================

// IF Stage Signals
wire [31:0] F_pc;           // Current PC
wire [31:0] F_pc_p4;        // PC + 4
wire [31:0] F_instr;        // Fetched instruction
wire [31:0] pc_next;        // Next PC value
wire PC_en;                 // PC enable (from hazard unit)

// PC Register
pc_pl PC (
    .clk(clk),
    .rst(rst),
    .en(PC_en),
    .pc_next(pc_next),
    .pc_current(F_pc)
);

// PC + 4 Adder
adder PC_PLUS_4 (
    .a(F_pc),
    .b(32'd4),
    .sum(F_pc_p4)
);

// Instruction Memory
instruction_memory IMEM (
    .addr(F_pc),
    .rd(F_instr)
);

// ============================================================================
// Pipeline Register 1: IF/ID
// ============================================================================

wire [31:0] D_instr, D_pc, D_pc_p4;
wire PLR1_en, PLR1_clr;

plr1 PLR1 (
    .clk(clk),
    .rst(rst),
    .en(PLR1_en),
    .clr(PLR1_clr),
    .F_instr(F_instr),
    .F_pc(F_pc),
    .F_pc_p4(F_pc_p4),
    .D_instr(D_instr),
    .D_pc(D_pc),
    .D_pc_p4(D_pc_p4)
);

// ============================================================================
// STAGE 2: ID (Instruction Decode)
// ============================================================================

// Instruction fields
wire [6:0] D_opcode;
wire [4:0] D_rf_a1, D_rf_a2, D_rf_a3;
wire [2:0] D_funct3;
wire [6:0] D_funct7;

assign D_opcode = D_instr[6:0];
assign D_rf_a1 = D_instr[19:15];  // rs1
assign D_rf_a2 = D_instr[24:20];  // rs2
assign D_rf_a3 = D_instr[11:7];   // rd
assign D_funct3 = D_instr[14:12];
assign D_funct7 = D_instr[31:25];  // Full funct7 field

// Register File
wire [31:0] D_rf_rd1, D_rf_rd2;
wire [31:0] W_result;           // Write-back data (from WB stage)
wire [4:0] W_rf_a3;             // Write-back address (from WB stage)
wire W_we_rf;                   // Write enable (from WB stage)

register_file_pl RF (
    .clk(clk),
    .rst(rst),
    .we(W_we_rf),
    .a1(D_rf_a1),
    .a2(D_rf_a2),
    .a3(W_rf_a3),
    .wd(W_result),
    .rd1(D_rf_rd1),
    .rd2(D_rf_rd2)
);

// Sign Extender
wire [31:0] D_ext;
wire [2:0] D_sel_ext;

sign_extender SIGN_EXT (
    .instr(D_instr[31:7]),
    .sel_ext(D_sel_ext),
    .imm_ext(D_ext)
);

// Controller (generates all control signals)
wire D_we_rf, D_we_dm, D_branch, D_jump;
wire [1:0] D_sel_result;
wire D_sel_alu_src_b;
wire [3:0] D_alu_control;

controller CONTROLLER (
    .opcode(D_opcode),
    .funct3(D_funct3),
    .funct7(D_funct7),
    .rf_we(D_we_rf),
    .dmem_we(D_we_dm),
    .sel_result(D_sel_result),
    .alu_control(D_alu_control),
    .sel_alu_src_b(D_sel_alu_src_b),
    .sel_ext(D_sel_ext),
    .branch(D_branch),
    .jump(D_jump)
);

// ============================================================================
// Pipeline Register 2: ID/EX
// ============================================================================

wire [31:0] E_pc, E_pc_p4, E_ext, E_rf_rd1, E_rf_rd2;
wire [4:0] E_rf_a1, E_rf_a2, E_rf_a3;
wire [6:0] E_opcode;
wire E_we_rf, E_we_dm, E_branch, E_jump;
wire [1:0] E_sel_result;
wire [3:0] E_alu_control;
wire E_sel_alu_src_b;
wire PLR2_clr;

plr2 PLR2 (
    .clk(clk),
    .rst(rst),
    .clr(PLR2_clr),
    .D_pc(D_pc),
    .D_pc_p4(D_pc_p4),
    .D_ext(D_ext),
    .D_rf_rd1(D_rf_rd1),
    .D_rf_rd2(D_rf_rd2),
    .D_rf_a1(D_rf_a1),
    .D_rf_a2(D_rf_a2),
    .D_rf_a3(D_rf_a3),
    .D_opcode(D_opcode),
    .D_we_rf(D_we_rf),
    .D_we_dm(D_we_dm),
    .D_sel_result(D_sel_result),
    .D_alu_control(D_alu_control),
    .D_sel_alu_src_b(D_sel_alu_src_b),
    .D_branch(D_branch),
    .D_jump(D_jump),
    .E_pc(E_pc),
    .E_pc_p4(E_pc_p4),
    .E_ext(E_ext),
    .E_rf_rd1(E_rf_rd1),
    .E_rf_rd2(E_rf_rd2),
    .E_rf_a1(E_rf_a1),
    .E_rf_a2(E_rf_a2),
    .E_rf_a3(E_rf_a3),
    .E_opcode(E_opcode),
    .E_we_rf(E_we_rf),
    .E_we_dm(E_we_dm),
    .E_sel_result(E_sel_result),
    .E_alu_control(E_alu_control),
    .E_sel_alu_src_b(E_sel_alu_src_b),
    .E_branch(E_branch),
    .E_jump(E_jump)
);

// ============================================================================
// STAGE 3: EX (Execute)
// ============================================================================

// Data Forwarding MUXes
wire [31:0] E_alu_src_a, E_alu_src_b_forwarded;
wire [1:0] E_forward_alu_op1, E_forward_alu_op2;
wire [31:0] M_alu_o;          // From MA stage (for forwarding)
wire [31:0] W_alu_o;          // From WB stage (for forwarding)

// Forward MUX for ALU operand A (rs1)
mux3 FORWARD_MUX_A (
    .d0(E_rf_rd1),            // Normal value from pipeline
    .d1(M_alu_o),             // Forward from MA stage
    .d2(W_alu_o),             // Forward from WB stage
    .sel(E_forward_alu_op1),
    .y(E_alu_src_a)
);

// Forward MUX for ALU operand B (rs2 before immediate selection)
wire [31:0] E_alu_src_b_temp;
mux3 FORWARD_MUX_B (
    .d0(E_rf_rd2),            // Normal value from pipeline
    .d1(M_alu_o),             // Forward from MA stage
    .d2(W_alu_o),             // Forward from WB stage
    .sel(E_forward_alu_op2),
    .y(E_alu_src_b_temp)
);

// ALU Source B MUX (immediate or forwarded register value)
mux2 ALU_SRC_B_MUX (
    .d0(E_alu_src_b_temp),
    .d1(E_ext),
    .sel(E_sel_alu_src_b),
    .y(E_alu_src_b_forwarded)
);

// ALU
wire [31:0] E_alu_o;
wire E_zero;

alu ALU (
    .a(E_alu_src_a),
    .b(E_alu_src_b_forwarded),
    .alu_control(E_alu_control),
    .result(E_alu_o),
    .zero(E_zero)
);

// Branch Target Adder
wire [31:0] E_target_pc;
adder BRANCH_TARGET_ADDER (
    .a(E_pc),
    .b(E_ext),
    .sum(E_target_pc)
);

// Data memory write data (always rd2, potentially forwarded)
wire [31:0] E_dm_wd;
assign E_dm_wd = E_alu_src_b_temp;

// PC Source MUX (PC+4 or branch/jump target)
wire pc_src;
assign pc_src = (E_branch & E_zero) | E_jump;

mux2 PC_SRC_MUX (
    .d0(F_pc_p4),
    .d1(E_target_pc),
    .sel(pc_src),
    .y(pc_next)
);

// ============================================================================
// Pipeline Register 3: EX/MA
// ============================================================================

wire [31:0] M_dm_wd, M_pc_p4, M_ext;
wire [4:0] M_rf_a3;
wire M_we_rf, M_we_dm;
wire [1:0] M_sel_result;

plr3 PLR3 (
    .clk(clk),
    .rst(rst),
    .E_alu_o(E_alu_o),
    .E_dm_wd(E_dm_wd),
    .E_ext(E_ext),
    .E_rf_a3(E_rf_a3),
    .E_pc_p4(E_pc_p4),
    .E_we_rf(E_we_rf),
    .E_we_dm(E_we_dm),
    .E_sel_result(E_sel_result),
    .M_alu_o(M_alu_o),
    .M_dm_wd(M_dm_wd),
    .M_ext(M_ext),
    .M_rf_a3(M_rf_a3),
    .M_pc_p4(M_pc_p4),
    .M_we_rf(M_we_rf),
    .M_we_dm(M_we_dm),
    .M_sel_result(M_sel_result)
);

// ============================================================================
// STAGE 4: MA (Memory Access)
// ============================================================================

// Data Memory
wire [31:0] M_dm_rd;

data_memory DMEM (
    .clk(clk),
    .we(M_we_dm),
    .addr(M_alu_o),
    .wd(M_dm_wd),
    .rd(M_dm_rd)
);

// ============================================================================
// Pipeline Register 4: MA/WB
// ============================================================================

wire [31:0] W_dm_rd, W_pc_p4, W_ext;
wire [1:0] W_sel_result;

plr4 PLR4 (
    .clk(clk),
    .rst(rst),
    .M_alu_o(M_alu_o),
    .M_dm_rd(M_dm_rd),
    .M_ext(M_ext),
    .M_rf_a3(M_rf_a3),
    .M_pc_p4(M_pc_p4),
    .M_we_rf(M_we_rf),
    .M_sel_result(M_sel_result),
    .W_alu_o(W_alu_o),
    .W_dm_rd(W_dm_rd),
    .W_ext(W_ext),
    .W_rf_a3(W_rf_a3),
    .W_pc_p4(W_pc_p4),
    .W_we_rf(W_we_rf),
    .W_sel_result(W_sel_result)
);

// ============================================================================
// STAGE 5: WB (Write Back)
// ============================================================================

// Result MUX (select what to write back to register file)
mux4 RESULT_MUX (
    .d0(W_alu_o),
    .d1(W_dm_rd),
    .d2(W_pc_p4),
    .d3(W_ext),      // LUI: extended immediate
    .sel(W_sel_result),
    .y(W_result)
);

// ============================================================================
// HAZARD UNIT
// ============================================================================

hazard_unit HAZARD_UNIT (
    .D_rf_a1(D_rf_a1),
    .D_rf_a2(D_rf_a2),
    .E_rf_a1(E_rf_a1),
    .E_rf_a2(E_rf_a2),
    .E_rf_a3(E_rf_a3),
    .M_rf_a3(M_rf_a3),
    .W_rf_a3(W_rf_a3),
    .E_we_rf(E_we_rf),
    .M_we_rf(M_we_rf),
    .W_we_rf(W_we_rf),
    .E_opcode(E_opcode),
    .E_branch(E_branch),
    .E_jump(E_jump),
    .E_zero(E_zero),
    .E_forward_alu_op1(E_forward_alu_op1),
    .E_forward_alu_op2(E_forward_alu_op2),
    .PC_en(PC_en),
    .PLR1_en(PLR1_en),
    .PLR1_clr(PLR1_clr),
    .PLR2_clr(PLR2_clr)
);

endmodule