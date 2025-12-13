// This is the class for the multi-cycle controller
// it assembles three components:
// 1. FSM - generates most control signals based on state
// 2. ALU Decoder - generates alu_control from alu_op, funct3, funct7
// 3. Instruction Decoder - generates sel_ext from opcode
module controller_mc (
    // Inputs
    input wire clk,                    // Clock signal
    input wire rst,                    // Reset signal
    input wire [6:0] op,               // Opcode
    input wire [2:0] funct3,           // funct3 field
    input wire funct7_5,               // bit 5 of funct7
    input wire zero,                   // Zero flag from ALU
    
    // Outputs
    output wire we_pc,                 // PC write enable
    output wire we_ir,                 // Instruction register write enable
    output wire we_rf,                 // Register file write enable
    output wire we_mem,                // Memory write enable
    output wire sel_mem_addr,          // Memory address select
    output wire [1:0] sel_alu_src_a,   // ALU source A select
    output wire [1:0] sel_alu_src_b,   // ALU source B select
    output wire [1:0] sel_result,      // Result select
    output wire [3:0] alu_control,     // ALU control
    output wire [2:0] sel_ext,         // Sign extender select
    output wire sel_pc_src             // PC source select
);

    // Internal signals
    wire [1:0] alu_op;      // From FSM to ALU decoder
    wire pc_update;         // From FSM
    wire branch;            // From FSM
    
    // FSM instance
    fsm fsm_inst (
        .clk(clk),
        .rst(rst),
        .op(op),
        .zero(zero),
        .we_ir(we_ir),
        .we_rf(we_rf),
        .we_mem(we_mem),
        .sel_mem_addr(sel_mem_addr),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .sel_result(sel_result),
        .alu_op(alu_op),
        .pc_update(pc_update),
        .branch(branch),
        .sel_pc_src(sel_pc_src)
    );
    
    // ALU Decoder instance
    alu_decoder alu_dec (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7_5(funct7_5),
        .alu_control(alu_control)
    );
    
    // Instruction Decoder instance
    instr_decoder instr_dec (
        .op(op),
        .sel_ext(sel_ext)
    );
    
    // PC write enable logic
    // PC updates when:
    // 1. pc_update=1 AND branch=0 (unconditional, like in fetch or JAL)
    // 2. pc_update=1 AND branch=1 AND zero=1 (conditional branch taken)
    assign we_pc = pc_update & (~branch | zero);

endmodule