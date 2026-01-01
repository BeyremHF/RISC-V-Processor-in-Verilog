// Pipeline Register 2 (ID/EX)
// Separates Instruction Decode and Execute stages
// Pipelines both data and control signals
module plr2 (
    input wire clk,
    input wire rst,
    input wire clr,             // Clear signal (for flushing)
    
    // Data inputs from ID stage
    input wire [31:0] D_pc,
    input wire [31:0] D_pc_p4,
    input wire [31:0] D_ext,        // Sign-extended immediate
    input wire [31:0] D_rf_rd1,     // Register file read data 1
    input wire [31:0] D_rf_rd2,     // Register file read data 2
    input wire [4:0] D_rf_a1,       // Source register 1 address (rs1)
    input wire [4:0] D_rf_a2,       // Source register 2 address (rs2)
    input wire [4:0] D_rf_a3,       // Destination register address
    input wire [6:0] D_opcode,      // Opcode (for hazard detection)
    
    // Control inputs from ID stage
    input wire D_we_rf,             // Register file write enable
    input wire D_we_dm,             // Data memory write enable
    input wire [1:0] D_sel_result,  // Result select (ALU, memory, PC+4, imm)
    input wire [3:0] D_alu_control, // ALU control
    input wire D_sel_alu_src_b,     // ALU source B select (rd2 or imm)
    input wire D_branch,            // Branch signal
    input wire D_jump,              // Jump signal
    
    // Data outputs to EX stage
    output reg [31:0] E_pc,
    output reg [31:0] E_pc_p4,
    output reg [31:0] E_ext,
    output reg [31:0] E_rf_rd1,
    output reg [31:0] E_rf_rd2,
    output reg [4:0] E_rf_a1,       // Source register 1 address (rs1)
    output reg [4:0] E_rf_a2,       // Source register 2 address (rs2)
    output reg [4:0] E_rf_a3,
    output reg [6:0] E_opcode,
    
    // Control outputs to EX stage
    output reg E_we_rf,
    output reg E_we_dm,
    output reg [1:0] E_sel_result,
    output reg [3:0] E_alu_control,
    output reg E_sel_alu_src_b,
    output reg E_branch,
    output reg E_jump
);

always @(posedge clk or posedge rst) begin
    if (rst || clr) begin
        // Reset or flush - clear all outputs (insert bubble/NOP)
        // Data signals
        E_pc <= 32'b0;
        E_pc_p4 <= 32'b0;
        E_ext <= 32'b0;
        E_rf_rd1 <= 32'b0;
        E_rf_rd2 <= 32'b0;
        E_rf_a1 <= 5'b0;
        E_rf_a2 <= 5'b0;
        E_rf_a3 <= 5'b0;
        E_opcode <= 7'b0;
        
        // Control signals - all disabled
        E_we_rf <= 1'b0;
        E_we_dm <= 1'b0;
        E_sel_result <= 2'b0;
        E_alu_control <= 4'b0;
        E_sel_alu_src_b <= 1'b0;
        E_branch <= 1'b0;
        E_jump <= 1'b0;
    end
    else begin
        // Normal operation - pipeline all signals
        // Data signals
        E_pc <= D_pc;
        E_pc_p4 <= D_pc_p4;
        E_ext <= D_ext;
        E_rf_rd1 <= D_rf_rd1;
        E_rf_rd2 <= D_rf_rd2;
        E_rf_a1 <= D_rf_a1;
        E_rf_a2 <= D_rf_a2;
        E_rf_a3 <= D_rf_a3;
        E_opcode <= D_opcode;
        
        // Control signals
        E_we_rf <= D_we_rf;
        E_we_dm <= D_we_dm;
        E_sel_result <= D_sel_result;
        E_alu_control <= D_alu_control;
        E_sel_alu_src_b <= D_sel_alu_src_b;
        E_branch <= D_branch;
        E_jump <= D_jump;
    end
end

endmodule