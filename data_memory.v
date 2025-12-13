// This is the class for the data memory. Which is a read/write memory, used to store program data like variable, arrays,... 
// It is used by lw and sw instructions
module data_memory (
    input wire clk,              // Clock signal for synchronous writes
    input wire we,               // Write enable (1 = write and 0 = don't write)
    input wire [31:0] addr,      // Byte address 32-bit byte address
    input wire [31:0] wd,        // Write data (32-bit value to store)
    output wire [31:0] rd        // Read data (32-bit value loaded from memory)
);

    // Memory array: 1024 words, each 32 bits (4KB)
    reg [31:0] mem [0:1023];

    // Initialize all memory to 0
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'b0;
        end
    end
    
    // COMBINATIONAL READ
    // Convert byte address to word address by dropping lower 2 bits to divide by 4 (like instruction memory)
    assign rd = mem[addr[31:2]];
    
    // SEQUENTIAL WRITE
    // Write to memory on clock edge if write enable is high
    always @(posedge clk) begin
        if (we)
            mem[addr[31:2]] <= wd;
    end

endmodule