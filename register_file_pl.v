// Register File for Pipeline - Writes on NEGATIVE edge
// Modified to write on negedge to allow same-cycle read after write
// This solves part of the RAW hazard (1-cycle gap)
module register_file_pl (
    input wire clk,              // Clock signal
    input wire rst,              // Reset signal
    input wire we,               // Write enable (1 = write, 0 = don't write)
    input wire [4:0] a1,         // Read address 1 (rs1)
    input wire [4:0] a2,         // Read address 2 (rs2)
    input wire [4:0] a3,         // Write address (rd)
    input wire [31:0] wd,        // Write data (32-bit value to write)
    output wire [31:0] rd1,      // Read data 1 (value from register a1)
    output wire [31:0] rd2       // Read data 2 (value from register a2)
);

    // Register array: 32 registers, each 32 bits
    reg [31:0] regs [0:31];

    // COMBINATIONAL READS
    // x0 always returns 0 and cannot be overwritten (hardwired)
    assign rd1 = (a1 == 5'b0) ? 32'b0 : regs[a1];  
    assign rd2 = (a2 == 5'b0) ? 32'b0 : regs[a2];
    
    // SEQUENTIAL WRITE on NEGATIVE EDGE with RESET
    // Key change: @(negedge clk) instead of @(posedge clk)
    // This allows an instruction at cycle N to write, and instruction at cycle N+1
    // to read the updated value in the same clock cycle
    integer i;
    always @(negedge clk or posedge rst) begin
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

// Pipeline Timing:
//    - Reads happen on posedge (ID stage reads registers)
//    - Writes happen on negedge (WB stage writes back)
//    - Within same cycle: posedge read happens first, then negedge write
//    - This means instruction N can write at negedge of cycle K,
//      and instruction N+1 can read that value at posedge of cycle K+1