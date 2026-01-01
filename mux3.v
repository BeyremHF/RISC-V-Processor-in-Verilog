// 3-input MUX for data forwarding in pipeline
// Used to select between normal pipeline value and forwarded values from MA/WB stages
module mux3 #(parameter WIDTH = 32) (
    input wire [WIDTH-1:0] d0,      // Normal pipeline value (from pipeline register)
    input wire [WIDTH-1:0] d1,      // Forwarded value from MA stage
    input wire [WIDTH-1:0] d2,      // Forwarded value from WB stage
    input wire [1:0] sel,           // Select signal from hazard unit
    output reg [WIDTH-1:0] y        // Output
);

always @(*) begin
    case (sel)
        2'b00: y = d0;  // No forwarding - use normal pipeline value
        2'b01: y = d1;  // Forward from MA stage
        2'b10: y = d2;  // Forward from WB stage
        default: y = d0;
    endcase
end

endmodule