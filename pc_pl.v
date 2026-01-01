// Program Counter with Enable for Pipeline
// Modified to support stalling during LW hazards
module pc_pl (
    input wire clk,                 // Clock signal
    input wire rst,                 // Reset signal  
    input wire en,                  // Enable signal (for stalling)
    input wire [31:0] pc_next,      // Next PC value
    output reg [31:0] pc_current    // Current PC value
);

    // Sequential logic: Update PC on clock edge
    // Only updates when en = 1, otherwise holds current value (stall)
    always @(posedge clk or posedge rst) begin 
        if (rst)
            pc_current <= 32'b0;        // Reset to address 0
        else if (en)
            pc_current <= pc_next;      // Update PC when enabled
        // else: hold current value (stall when en = 0)
    end

endmodule