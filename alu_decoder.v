// This is the ALU Decoder class for the Multi-Cycle RISC-V Processor
// It generates ALU control signal based on alu_op, funct3, and funct7
// This is the second level of decoding
module alu_decoder (
    input wire [1:0] alu_op,       // ALU operation type from FSM
    input wire [2:0] funct3,       // funct3 field from instruction
    input wire funct7_5,           // bit 5 of funct7 (distinguishes ADD/SUB, SRL/SRA)
    output reg [3:0] alu_control   // ALU control signal
);

    // ALU control encoding:
    // 0000 = ADD
    // 0001 = SUB
    // 0010 = SLL (shift left logical)
    // 0011 = SLT (set less than signed)
    // 0100 = SLTU (set less than unsigned)
    // 0101 = XOR
    // 0110 = SRL (shift right logical)
    // 0111 = SRA (shift right arithmetic)
    // 1000 = OR
    // 1001 = AND

    always @(*) begin
        case (alu_op)
            // alu_op = 00: ADD (for lw, sw, PC+4)
            2'b00: begin
                alu_control = 4'b0000;  // ADD
            end
            
            // alu_op = 01: SUB (for beq)
            2'b01: begin
                alu_control = 4'b0001;  // SUB
            end
            
            // alu_op = 10: R-type and I-type operations
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // ADD or SUB (R-type) / ADDI (I-type)
                        // funct7[5] distinguishes ADD from SUB in R-type
                        if (funct7_5)
                            alu_control = 4'b0001;  // SUB
                        else
                            alu_control = 4'b0000;  // ADD/ADDI
                    end
                    3'b001: alu_control = 4'b0010;  // SLL/SLLI
                    3'b010: alu_control = 4'b0011;  // SLT/SLTI
                    3'b011: alu_control = 4'b0100;  // SLTU/SLTIU
                    3'b100: alu_control = 4'b0101;  // XOR/XORI
                    3'b101: begin
                        // SRL or SRA / SRLI or SRAI
                        // funct7[5] distinguishes logical from arithmetic shift
                        if (funct7_5)
                            alu_control = 4'b0111;  // SRA/SRAI
                        else
                            alu_control = 4'b0110;  // SRL/SRLI
                    end
                    3'b110: alu_control = 4'b1000;  // OR/ORI
                    3'b111: alu_control = 4'b1001;  // AND/ANDI
                    default: alu_control = 4'b0000; // Default to ADD
                endcase
            end
            
            // Default: ADD
            default: begin
                alu_control = 4'b0000;
            end
        endcase
    end

endmodule