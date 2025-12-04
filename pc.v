// The program counter by definition is the register that stores the address of the instruction to be executed. It updates on every clock cycle.
module pc (
    input wire clk,           // Clock signal
    input wire rst,           // Reset signal
    input wire [31:0] pc_next,    // Next PC value (input): assigned as "wire" because it is read only in the always block
    output reg [31:0] pc_current  // Current PC value (output): assigned as "reg" because it is used in the always block, and constantly updated
);
    // Initialize PC to 0
    // This prevents undefined (X) values before reset
    initial begin
        pc_current = 32'b0;
    end

    // Sequential logic: Update PC on clock edge : We will use non-blocking assignments "<=" so all assignments happen simultaniously at the clock edge
    always @(posedge clk or posedge rst) begin 
        if (rst)
            pc_current <= 32'b0;    // Resets to address 0 if the reset signal is 1
        else
            pc_current <= pc_next;   // Else, it updates to next value, that we get using the adder to increment the value by 4 bytes
    end

endmodule