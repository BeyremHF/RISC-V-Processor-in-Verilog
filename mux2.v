module mux2 #(
    parameter WIDTH = 32    // Using the same parameterized width approach as the adder, again, in our case its 32 bits
)(
    input wire [WIDTH-1:0] d0,    // Input wire 0
    input wire [WIDTH-1:0] d1,    // Input wire 1
    input wire sel,               // Select signal, this tells us which sort of instruction we are dealing with, 
                                  // either one with immediate values (sel = 1 then PC + immediate), 
                                  // or without (sel = 0 then PC + 4, to calculate the next address)
    output wire [WIDTH-1:0] y     // Output y
);

    // Combinational logic
    assign y = sel ? d1 : d0; // use d1 or d2 based on the value of sel (1 or 0)

endmodule