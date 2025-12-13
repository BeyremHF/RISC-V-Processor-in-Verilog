// This is the arithmetic and logical unit. 
module alu (
    input wire [31:0] a,           // Operand A (usually from rs1)
    input wire [31:0] b,           // Operand B (from rs2 or immediate)
    input wire [3:0] alu_control,  // Operation select (4 bits)
    output reg [31:0] result,      // Result output (32 bits)
    output wire zero               // Zero flag: 1 if result is zero, 0 otherwise (for branches later)
);

    // Zero flag: true if result is zero
    assign zero = (result == 32'b0);
    
    // ALU operations
    always @(*) begin
        case(alu_control)
            4'b0000: result = a + b;                    // ADD
            4'b0001: result = a - b;                    // SUB
            4'b0010: result = a << b[4:0];              // SLL (shift left logical)
            4'b0011: result = ($signed(a) < $signed(b)) ? 32'b1 : 32'b0;  // SLT (Set Less Than)
            4'b0100: result = (a < b) ? 32'b1 : 32'b0;  // SLTU (Set Less Than Unsigned)
            4'b0101: result = a ^ b;                    // XOR
            4'b0110: result = a >> b[4:0];              // SRL (shift right logical)
            4'b0111: result = $signed(a) >>> b[4:0];    // SRA (shift right arithmetic)
            4'b1000: result = a | b;                    // OR
            4'b1001: result = a & b;                    // AND
            default: result = 32'b0;                    // Safe default
        endcase
    end

endmodule

//   0000: ADD  - Addition (a + b)
//   0001: SUB  - Subtraction (a - b)
//   0010: SLL  - Shift Left Logical
//   0011: SLT  - Set Less Than (signed)
//   0100: SLTU - Set Less Than Unsigned
//   0101: XOR  - Bitwise XOR
//   0110: SRL  - Shift Right Logical
//   0111: SRA  - Shift Right Arithmetic
//   1000: OR   - Bitwise OR
//   1001: AND  - Bitwise AND