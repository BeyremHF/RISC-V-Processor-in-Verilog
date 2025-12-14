// This is the register file class. It's task is to manage the 32 registers (x0-x31) used by the processor to store temporary values during computation
module register_file (
    input wire clk,              // Clock signal
    input wire rst,              // Reset signal
    input wire we,               // Write enable (1 = write, 0 = don't write)
    input wire [4:0] a1,         // Read address 1 (rs1)
    input wire [4:0] a2,         // Read address 2 (rs2)
    input wire [4:0] a3,         // Write address (rd)
    input wire [31:0] wd,        // Write data (32-bit value to write)
    output wire [31:0] rd1,      // Read data 1 (value from register a1)
    output wire [31:0] rd2       // Read data 2 (value from register a2)
    // As u can see, wires that contain data are 32 bits wide, and wires that contain addresses are 5 bits long (We need 5 bits to address 2^5 = 32 registers)
);

    // Register array: 32 registers, each 32 bits (updated in the always block on every clock cycle)
    reg [31:0] regs [0:31];
    
    // Loop variable for reset
    integer i;
    
    // COMBINATIONAL READS
    // x0 always returns 0 and cannot be overwritten (hardwired)
    assign rd1 = (a1 == 5'b0) ? 32'b0 : regs[a1];  
    assign rd2 = (a2 == 5'b0) ? 32'b0 : regs[a2];
    
    // SEQUENTIAL WRITE with RESET    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Initialize all registers to 0 on reset
            for (i = 0; i < 32; i = i + 1) begin
                regs[i] <= 32'b0;
            end
        end else begin
            // Normal write operation
            if (we && (a3 != 5'b0))  // Only write if: we = 1 AND address is not x0
                regs[a3] <= wd;
        end
    end

endmodule

// Initialization:
//    - Registers start with unknown values X (as seen in the lecture)
//    - Software should initialize registers before using them

// Reading and Writing same register:
//    - Read happens with OLD value (before clock edge)
//    - Write happens AT clock edge
//    - Next cycle will see the NEW value
//    - This is expected behavior in pipelined processors