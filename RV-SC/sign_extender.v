// This is the sign extender class, its task is to extract immediate values from instructions and extend them to 32 bits.
// Different instruction types store immediates in different bit positions.
module sign_extender (
    input wire [31:7] instr,      // Instruction bits (immediate fields are in here) [31:7]
    input wire [2:0] sel_ext,     // Extension format select 
    output reg [31:0] imm_ext     // 32-bit extended immediate output
);

    always @(*) begin
        case(sel_ext)
            // I-type: imm[11:0] = instr[31:20]
            3'b000: begin
                // Sign bit is instr[31]
                // Replicate it 20 times to fill upper bits
                imm_ext = {{20{instr[31]}}, instr[31:20]};
            end
            
            // S-type: imm[11:5] = instr[31:25], imm[4:0] = instr[11:7]
            3'b001: begin
                // Sign bit is instr[31]
                // Need to concatenate two separate fields
                imm_ext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end
            
            // B-type: imm[12|10:5|4:1|11] with implicit 0 at bit 0
            3'b010: begin
                // Sign bit is instr[31] (bit 12 of immediate)
                // Rearrange: [31][7][30:25][11:8][0]
                imm_ext = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            end
            
            // J-type: imm[20|10:1|11|19:12] with implicit 0 at bit 0
            3'b011: begin
                // Sign bit is instr[31] (bit 20 of immediate)
                // Rearrange: [31][19:12][20][30:21][0]
                imm_ext = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
            end
            
            // U-type: imm[31:12], lower 12 bits are 0
            3'b100: begin
                // No sign extension needed, just place in upper 20 bits
                imm_ext = {instr[31:12], 12'b0};
            end
            
            // Default: return 0 (for safety)
            default: begin
                imm_ext = 32'b0;
            end
        endcase
    end

endmodule


// IMMEDIATE FORMATS (from Figure 1 in manual):
//   I-type: 12 bits [31:20]
//   S-type: 12 bits [31:25|11:7]
//   B-type: 13 bits [31|7|30:25|11:8] with bit 0 implicit 0
//   J-type: 21 bits [31|19:12|20|30:21] with bit 0 implicit 0
//   U-type: 20 bits [31:12]