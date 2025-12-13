// This is the class for the unified memory module for the MC processor
// It combines instruction memory and data memory into a single memory
// Address selection controlled by sel_mem_addr:
//   - sel_mem_addr=0: Use PC (instruction fetch)
//   - sel_mem_addr=1: Use ALU result (data memory access)
module mem (
    input wire clk,                    // Clock signal
    input wire we,                     // Write enable
    input wire [31:0] addr,            // Memory address (from PC or ALU)
    input wire [31:0] wd,              // Write data
    output wire [31:0] rd              // Read data
);

    // Memory parameters
    parameter MEM_DEPTH = 256;  // 256 words = 1KB of memory
    
    // Memory array: 256 words × 32 bits
    reg [31:0] RAM [0:MEM_DEPTH-1];
    
    // Convert byte address to word address (divide by 4)
    // RISC-V uses byte addressing, but our memory is word-addressed
    wire [31:0] word_addr;
    assign word_addr = addr >> 2;
    
    // Read operation (combinational)
    // Read happens immediately based on address
    assign rd = RAM[word_addr];
    
    // Write operation (synchronous)
    // Write only happens on clock edge when we=1
    always @(posedge clk) begin
        if (we) begin
            RAM[word_addr] <= wd;
        end
    end

endmodule