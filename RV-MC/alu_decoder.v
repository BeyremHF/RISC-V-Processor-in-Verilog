// This is the ALU Decoder class for the Multi-Cycle RISC-V Processor
// It generates ALU control signal based on alu_op, funct3, and funct7
// This is the second level of decoding
module alu_decoder (
    input wire [1:0] alu_op,       // ALU operation type from FSM
    input wire [2:0] funct3,       // funct3 field from instruction
    input wire funct7_5,           // bit 5 of funct7
    output reg [3:0] alu_control   // ALU control signal
);

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
            
            // alu_op = 10: R-type operations (check funct7[5])
            2'b10: begin
                case (funct3)
                    3'b000: begin
                        // ADD or SUB based on funct7[5]
                        if (funct7_5)
                            alu_control = 4'b0001;  // SUB
                        else
                            alu_control = 4'b0000;  // ADD
                    end
                    3'b001: alu_control = 4'b0010;  // SLL
                    3'b010: alu_control = 4'b0011;  // SLT
                    3'b011: alu_control = 4'b0100;  // SLTU
                    3'b100: alu_control = 4'b0101;  // XOR
                    3'b101: begin
                        // SRL or SRA based on funct7[5]
                        if (funct7_5)
                            alu_control = 4'b0111;  // SRA
                        else
                            alu_control = 4'b0110;  // SRL
                    end
                    3'b110: alu_control = 4'b1000;  // OR
                    3'b111: alu_control = 4'b1001;  // AND
                    default: alu_control = 4'b0000;
                endcase
            end
            
            // alu_op = 11: I-type operations (ignore funct7[5] except for shifts)
            2'b11: begin
                case (funct3)
                    3'b000: alu_control = 4'b0000;  // ADDI (always ADD)
                    3'b001: alu_control = 4'b0010;  // SLLI
                    3'b010: alu_control = 4'b0011;  // SLTI
                    3'b011: alu_control = 4'b0100;  // SLTIU
                    3'b100: alu_control = 4'b0101;  // XORI
                    3'b101: 
                    begin
                    
                        if (funct7_5)
                            alu_control = 4'b0111;  // SRAI
                        else
                            alu_control = 4'b0110;  // SRLI
                    end
                    3'b110: alu_control = 4'b1000;  // ORI
                    3'b111: alu_control = 4'b1001;  // ANDI
                    default: alu_control = 4'b0000;
                endcase
            end
            
            default: alu_control = 4'b0000;
        endcase
    end

endmodule