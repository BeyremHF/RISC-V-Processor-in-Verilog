// This is the instruction memory class, it is a read only memory that stores the program instructions. The CPU fetches instructions from here using the program counter address.
module instruction_memory (
    input wire [31:0] addr,    // This is the byte address input
    output wire [31:0] rd      // And this is the 32-bit instruction output
);

    // This is the memory array: 1024 words, each 32 bits wide (1024 × 32-bit = 4096 bytes = 4KB)
    reg [31:0] mem [0:1023];

    // Initialize all memory to 0 (NOP instruction)
    integer i;
    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            mem[i] = 32'h00000013;  // NOP (addi x0, x0, 0)
        end
    end
    
    // Word-addressed read: convert byte address to word address
    // addr[31:2] effectively divides by 4 (right shift by 2)
    assign rd = mem[addr[31:2]];

endmodule


// Address Conversion [31:2]:
//    - Takes bits 31 down to 2 of the address
//    - Ignores bits 1 and 0 (the two least significant bits)
//    - This is equivalent to dividing by 4
//    - Binary example:
//      * addr = 12 = 0b...001100
//      * addr[31:2] = 0b...0011 = 3
//      * So byte address 12 maps to word 3 