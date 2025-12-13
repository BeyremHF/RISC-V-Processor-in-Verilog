/* The adder simply adds two 32 bit addresses (width), 
    it's used to calculate the next instruction address 
    (either PC + 4 or PC + immediate for jump instructions for example) for the program counter.
*/

module adder #(
    parameter WIDTH = 32    // Parameterized width for each CPU (in our case the width is 32 bits = 4 bytes)
)(
    input wire [WIDTH-1:0] a,     // First 32 bit input a
    input wire [WIDTH-1:0] b,     // Second 32 bit input b
    output wire [WIDTH-1:0] sum   // Output 32 bits sum = a + b
);

    // Combinational logic: Continuous assignment (no clock involved)
    assign sum = a + b;

endmodule