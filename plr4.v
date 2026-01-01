// Pipeline Register 4 (MA/WB)
// Separates Memory Access and Write Back stages
module plr4 (
    input wire clk,
    input wire rst,
    
    // Data inputs from MA stage
    input wire [31:0] M_alu_o,      // ALU result
    input wire [31:0] M_dm_rd,      // Data memory read data
    input wire [31:0] M_ext,        // Extended immediate (for LUI)
    input wire [4:0] M_rf_a3,       // Destination register address
    input wire [31:0] M_pc_p4,      // PC + 4 (for JAL)
    
    // Control inputs from MA stage
    input wire M_we_rf,             // Register file write enable
    input wire [1:0] M_sel_result,  // Result select
    
    // Data outputs to WB stage
    output reg [31:0] W_alu_o,
    output reg [31:0] W_dm_rd,
    output reg [31:0] W_ext,        // Extended immediate (for LUI)
    output reg [4:0] W_rf_a3,
    output reg [31:0] W_pc_p4,
    
    // Control outputs to WB stage
    output reg W_we_rf,
    output reg [1:0] W_sel_result
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        // Reset - clear all outputs
        W_alu_o <= 32'b0;
        W_dm_rd <= 32'b0;
        W_ext <= 32'b0;
        W_rf_a3 <= 5'b0;
        W_pc_p4 <= 32'b0;
        W_we_rf <= 1'b0;
        W_sel_result <= 2'b0;
    end
    else begin
        // Normal operation - pipeline all signals
        W_alu_o <= M_alu_o;
        W_dm_rd <= M_dm_rd;
        W_ext <= M_ext;
        W_rf_a3 <= M_rf_a3;
        W_pc_p4 <= M_pc_p4;
        W_we_rf <= M_we_rf;
        W_sel_result <= M_sel_result;
    end
end

endmodule