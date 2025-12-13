// This is the class for the controller, which decodes instructions (opcode, funct3, funct7 as input) and generates all control signals that coordinate the datapath components.
// It uses two-level decoding for clarity and maintainability
module controller (
    // Instruction fields
    input wire [6:0] opcode,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    
    // Control signals
    output reg rf_we,              // Register file write enable
    output reg [2:0] sel_ext,      // Sign extender select
    output reg sel_alu_src_b,      // ALU source B select (0=reg, 1=imm)
    output reg dmem_we,            // Data memory write enable
    output reg [1:0] sel_result,   // Result select (00=ALU, 01=MEM, 10=PC+4, 11=IMM)
    output reg [3:0] alu_control,  // ALU operation control
    output reg branch,             // Branch signal
    output reg jump                // Jump signal
);

    // Intermediate signal for two-level decoding
    reg [1:0] alu_op;
    
    // LEVEL 1 DECODING: opcode → control signals + alu_op
    // This implements Table 3 from the manual

    always @(*) begin
        // Default values (safe defaults to prevent latches)
        rf_we = 1'b0;
        sel_ext = 3'b000;
        sel_alu_src_b = 1'b0;
        dmem_we = 1'b0;
        sel_result = 2'b00;
        alu_op = 2'b00;
        branch = 1'b0;
        jump = 1'b0;
        
        case(opcode)
            // R-type: Arithmetic and Logical operations (register-register)
            7'b0110011: begin
                rf_we = 1'b1;           // Write result to register
                sel_alu_src_b = 1'b0;   // Use register for operand B
                sel_result = 2'b00;     // Write-back ALU result
                alu_op = 2'b01;         // R-type operations
                // sel_ext doesn't matter (no immediate)
            end
            
            // I-type: Arithmetic and Logical with immediate
            7'b0010011: begin
                rf_we = 1'b1;           // Write result to register
                sel_ext = 3'b000;       // I-type immediate format
                sel_alu_src_b = 1'b1;   // Use immediate for operand B
                sel_result = 2'b00;     // Write-back ALU result
                alu_op = 2'b10;         // I-type operations
            end
            
            // Load: lw (load word)
            7'b0000011: begin
                rf_we = 1'b1;           // Write loaded data to register
                sel_ext = 3'b000;       // I-type immediate (offset)
                sel_alu_src_b = 1'b1;   // Use immediate (offset)
                dmem_we = 1'b0;         // Don't write to memory
                sel_result = 2'b01;     // Write-back memory data
                alu_op = 2'b00;         // Use ADD for address calculation
            end
            
            // Store: sw (store word)
            7'b0100011: begin
                rf_we = 1'b0;           // Don't write to register
                sel_ext = 3'b001;       // S-type immediate format
                sel_alu_src_b = 1'b1;   // Use immediate (offset)
                dmem_we = 1'b1;         // Write to memory
                sel_result = 2'b00;     // Doesn't matter (no write-back)
                alu_op = 2'b00;         // Use ADD for address calculation
            end
            
            // Branch: beq (branch if equal)
            7'b1100011: begin
                rf_we = 1'b0;           // Don't write to register
                sel_ext = 3'b010;       // B-type immediate format
                sel_alu_src_b = 1'b0;   // Use register for comparison
                dmem_we = 1'b0;         // Don't write to memory
                sel_result = 2'b00;     // Doesn't matter (no write-back)
                branch = 1'b1;          // This is a branch instruction
                alu_op = 2'b01;         // Use SUB for comparison
            end
            
            // Jump: jal (jump and link)
            7'b1101111: begin
                rf_we = 1'b1;           // Write return address to register
                sel_ext = 3'b011;       // J-type immediate format
                sel_alu_src_b = 1'b0;   // Doesn't matter
                dmem_we = 1'b0;         // Don't write to memory
                sel_result = 2'b10;     // Write-back PC+4 (return address)
                jump = 1'b1;            // This is a jump instruction
                alu_op = 2'b00;         // Doesn't matter
            end
            
            // Upper immediate: lui (load upper immediate)
            7'b0110111: begin
                rf_we = 1'b1;           // Write immediate to register
                sel_ext = 3'b100;       // U-type immediate format
                sel_alu_src_b = 1'b0;   // Doesn't matter
                dmem_we = 1'b0;         // Don't write to memory
                sel_result = 2'b11;     // Write-back immediate value
                alu_op = 2'b00;         // Doesn't matter
            end
            
            // Default: keep default values
            default: begin
                // All signals already set to safe defaults
            end
        endcase
    end
    
    // LEVEL 2 DECODING: alu_op + funct3 + funct7 → alu_control

    always @(*) begin
        case(alu_op)
            // alu_op = 00: Load/Store (always ADD for address calculation)
            2'b00: begin
                alu_control = 4'b0000;  // ADD
            end
            
            // alu_op = 01: R-type operations
            2'b01: begin
                case(funct3)
                    3'b000: begin
                        // funct7[5] distinguishes ADD from SUB
                        if (funct7[5])
                            alu_control = 4'b0001;  // SUB
                        else
                            alu_control = 4'b0000;  // ADD
                    end
                    3'b001: alu_control = 4'b0010;  // SLL
                    3'b010: alu_control = 4'b0011;  // SLT
                    3'b011: alu_control = 4'b0100;  // SLTU
                    3'b100: alu_control = 4'b0101;  // XOR
                    3'b101: begin
                        // funct7[5] distinguishes SRL from SRA
                        if (funct7[5])
                            alu_control = 4'b0111;  // SRA
                        else
                            alu_control = 4'b0110;  // SRL
                    end
                    3'b110: alu_control = 4'b1000;  // OR
                    3'b111: alu_control = 4'b1001;  // AND
                    default: alu_control = 4'b0000; // Default to ADD
                endcase
            end
            
            // alu_op = 10: I-type operations
            2'b10: begin
                case(funct3)
                    3'b000: alu_control = 4'b0000;  // ADDI
                    3'b001: alu_control = 4'b0010;  // SLLI
                    3'b010: alu_control = 4'b0011;  // SLTI
                    3'b011: alu_control = 4'b0100;  // SLTIU
                    3'b100: alu_control = 4'b0101;  // XORI
                    3'b101: begin
                        // funct7[5] distinguishes SRLI from SRAI
                        if (funct7[5])
                            alu_control = 4'b0111;  // SRAI
                        else
                            alu_control = 4'b0110;  // SRLI
                    end
                    3'b110: alu_control = 4'b1000;  // ORI
                    3'b111: alu_control = 4'b1001;  // ANDI
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