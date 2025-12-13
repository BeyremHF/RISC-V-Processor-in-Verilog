// This class is for the Instruction Decoder for the Multi-Cycle RISC-V Processor
// It generates the sel_ext signal based on opcode
// This determines what type of immediate value to extract
module instr_decoder (
    input wire [6:0] op,          // Opcode
    output reg [2:0] sel_ext      // Sign extender select
);

    // Opcode definitions
    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_ARITH = 7'b0010011;
    localparam OP_LW = 7'b0000011;
    localparam OP_SW = 7'b0100011;
    localparam OP_BEQ = 7'b1100011;
    localparam OP_JAL = 7'b1101111;
    localparam OP_LUI = 7'b0110111;
    
    // Sign extender select values
    // 000 = I-type (12-bit immediate)
    // 001 = S-type (store offset)
    // 010 = B-type (branch offset)
    // 011 = J-type (jump offset)
    // 100 = U-type (upper immediate)
    
    always @(*) begin
        case (op)
            OP_I_ARITH, OP_LW: sel_ext = 3'b000;  // I-type
            OP_SW:             sel_ext = 3'b001;  // S-type
            OP_BEQ:            sel_ext = 3'b010;  // B-type
            OP_JAL:            sel_ext = 3'b011;  // J-type
            OP_LUI:            sel_ext = 3'b100;  // U-type
            default:           sel_ext = 3'b000;  // Default to I-type
        endcase
    end

endmodule