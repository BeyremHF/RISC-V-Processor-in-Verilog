// This is the Generic 32-bit register with write enable
// Used for multi-cycle state registers: instr_reg, data_reg, rd1_reg, rd2_reg, alu_reg
// Unlike PC which always updates, these registers only update when their enable signal is high
module register (
    input wire clk,              // Clock signal
    input wire rst,              // Reset signal
    input wire en,               // Write enable - register only updates when en=1
    input wire [31:0] d,         // Data input
    output reg [31:0] q          // Data output
);
    
    // Sequential logic: Update register on clock edge only when enabled
    always @(posedge clk or posedge rst) begin 
        if (rst)
            q <= 32'b0;          // Reset to 0
        else if (en)
            q <= d;              // Update only when enabled
        // If en=0, q holds its previous value
    end

endmodule