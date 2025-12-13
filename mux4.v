// This is a simple 4 input multiplexer, that selects one of the four inputs based on a 2-bit select signal which is the sel wire
module mux4 #(
    parameter WIDTH = 32
)(
    input wire [WIDTH-1:0] d0,  // ALU result (most A&L operations) 
    input wire [WIDTH-1:0] d1,  // Memory read data (lw instruction)
    input wire [WIDTH-1:0] d2,  // PC+4 (jal instruction for return address)
    input wire [WIDTH-1:0] d3,  // Immediate (lui instruction)
    input wire [1:0] sel, // The output of the controller
    output reg [WIDTH-1:0] y  // Connects to the Write Data (WD) input in the register file, and its a reg because its used in the always block
);

    // Combinational logic using always block with case statement, to control the output
    always @(*) begin
        case(sel)
            2'b00: y = d0;  //   When sel = 00: output y = d0
            2'b01: y = d1;  //   When sel = 01: output y = d1
            2'b10: y = d2;  //   When sel = 10: output y = d2
            2'b11: y = d3;  //   When sel = 11: output y = d3
            default: y = d0;    // Safe default
        endcase
    end

endmodule

// Examples:
// add x3, x1, x2      Write ALU result, for arithmetic/logical operations      → sel=00
// lw x5, 0(x6)        Write memory data, for lw                                → sel=01
// jal x1, 100         Write PC+4, for jal (return address)                     → sel=10
// lui x5, 0x123       Write immediate, for lui                                 → sel=11