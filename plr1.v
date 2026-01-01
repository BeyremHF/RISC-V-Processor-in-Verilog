// Pipeline Register 1 (IF/ID)
// Separates Instruction Fetch and Instruction Decode stages
module plr1 (
    input wire clk,
    input wire rst,
    input wire en,              // Enable signal (for stalling)
    input wire clr,             // Clear signal (for flushing)
    
    // Inputs from IF stage
    input wire [31:0] F_instr,  // Fetched instruction
    input wire [31:0] F_pc,     // PC of current instruction
    input wire [31:0] F_pc_p4,  // PC + 4
    
    // Outputs to ID stage
    output reg [31:0] D_instr,  // Instruction to decode
    output reg [31:0] D_pc,     // PC for branch target calculation
    output reg [31:0] D_pc_p4   // PC + 4 for JAL return address
);

always @(posedge clk or posedge rst) begin
    if (rst || clr) begin
        // Reset or flush - clear all outputs (insert bubble/NOP)
        D_instr <= 32'b0;
        D_pc <= 32'b0;
        D_pc_p4 <= 32'b0;
    end
    else if (en) begin
        // Normal operation - load new values
        D_instr <= F_instr;
        D_pc <= F_pc;
        D_pc_p4 <= F_pc_p4;
    end
    // else: stall - hold current values (en = 0)
end

endmodule