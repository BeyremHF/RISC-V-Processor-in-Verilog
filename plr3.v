// Pipeline Register 3 (EX/MA)
// Separates Execute and Memory Access stages
module plr3 (
    input wire clk,
    input wire rst,
    
    // Data inputs from EX stage
    input wire [31:0] E_alu_o,      // ALU result
    input wire [31:0] E_dm_wd,      // Data memory write data (rd2)
    input wire [31:0] E_ext,        // Extended immediate (for LUI)
    input wire [4:0] E_rf_a3,       // Destination register address
    input wire [31:0] E_pc_p4,      // PC + 4 (for JAL)
    
    // Control inputs from EX stage
    input wire E_we_rf,             // Register file write enable
    input wire E_we_dm,             // Data memory write enable
    input wire [1:0] E_sel_result,  // Result select
    
    // Data outputs to MA stage
    output reg [31:0] M_alu_o,
    output reg [31:0] M_dm_wd,
    output reg [31:0] M_ext,        // Extended immediate (for LUI)
    output reg [4:0] M_rf_a3,
    output reg [31:0] M_pc_p4,
    
    // Control outputs to MA stage
    output reg M_we_rf,
    output reg M_we_dm,
    output reg [1:0] M_sel_result
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset - clear all outputs
        M_alu_o <= 32'b0;
        M_dm_wd <= 32'b0;
        M_ext <= 32'b0;
        M_rf_a3 <= 5'b0;
        M_pc_p4 <= 32'b0;
        M_we_rf <= 1'b0;
        M_we_dm <= 1'b0;
        M_sel_result <= 2'b0;
    end
    else begin
        // Normal operation - pipeline all signals
        M_alu_o <= E_alu_o;
        M_dm_wd <= E_dm_wd;
        M_ext <= E_ext;
        M_rf_a3 <= E_rf_a3;
        M_pc_p4 <= E_pc_p4;
        M_we_rf <= E_we_rf;
        M_we_dm <= E_we_dm;
        M_sel_result <= E_sel_result;
    end
end

endmodule