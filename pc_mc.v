// This is the class for the program Counter, with Write Enable for the Multi-Cycle Processor
// Where PC should only update when we_pc=1 (not every cycle)
// Allowing the processor to execute one instruction over multiple cycles
module pc_mc (
    input wire clk,              // Clock signal
    input wire rst,              // Reset signal
    input wire en,               // Write enable - PC only updates when en=1
    input wire [31:0] pc_next,   // Next PC value
    output reg [31:0] pc_current // Current PC value
);
    
    // Sequential logic: Update PC on clock edge only when enabled
    always @(posedge clk or posedge rst) begin 
        if (rst)
            pc_current <= 32'b0;     // Reset to address 0
        else if (en)
            pc_current <= pc_next;   // Update only when enabled
        // If en=0, PC holds its current value
    end

endmodule