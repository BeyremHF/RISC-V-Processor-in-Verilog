// Hazard Detection and Forwarding Unit
// Detects and resolves three types of hazards:
// 1. RAW (Read After Write) - solved by data forwarding
// 2. LW (Load-Use) - solved by stalling + flushing
// 3. Control (Branch/Jump) - solved by flushing on branch/jump taken

module hazard_unit (
    // Register addresses for hazard detection
    input wire [4:0] D_rf_a1,      // ID stage rs1 (source register 1)
    input wire [4:0] D_rf_a2,      // ID stage rs2 (source register 2)
    input wire [4:0] E_rf_a1,      // EX stage rs1 (for forwarding detection)
    input wire [4:0] E_rf_a2,      // EX stage rs2 (for forwarding detection)
    input wire [4:0] E_rf_a3,      // EX stage rd (destination register)
    input wire [4:0] M_rf_a3,      // MA stage rd
    input wire [4:0] W_rf_a3,      // WB stage rd
    
    // Write enable signals
    input wire E_we_rf,            // EX stage will write to register file
    input wire M_we_rf,            // MA stage will write to register file
    input wire W_we_rf,            // WB stage will write to register file
    
    // Instruction type detection
    input wire [6:0] E_opcode,     // EX stage opcode (to detect LW)
    input wire E_branch,           // EX stage branch signal
    input wire E_jump,             // EX stage jump signal
    input wire E_zero,             // ALU zero flag (branch condition)
    
    // Control outputs
    output reg [1:0] E_forward_alu_op1,  // Forwarding select for ALU operand A
    output reg [1:0] E_forward_alu_op2,  // Forwarding select for ALU operand B
    output reg PC_en,                     // PC enable (0 = stall, 1 = normal)
    output reg PLR1_en,                   // PLR1 enable (0 = stall, 1 = normal)
    output reg PLR1_clr,                  // PLR1 clear (1 = flush, 0 = normal)
    output reg PLR2_clr                   // PLR2 clear (1 = flush, 0 = normal)
);

// Opcode definitions
localparam OP_LW = 7'b0000011;

// ============================================================================
// 1. RAW HAZARD - DATA FORWARDING
// ============================================================================
// Forward ALU result from later stages to resolve data dependencies

always @(*) begin
    // Forward ALU operand 1 (rs1)
    // Priority: MA stage > WB stage > no forwarding
    if ((E_rf_a1 == M_rf_a3) && M_we_rf && (M_rf_a3 != 5'b0)) begin
        // Forward from MA stage (most recent)
        E_forward_alu_op1 = 2'b01;
    end
    else if ((E_rf_a1 == W_rf_a3) && W_we_rf && (W_rf_a3 != 5'b0)) begin
        // Forward from WB stage
        E_forward_alu_op1 = 2'b10;
    end
    else begin
        // No forwarding needed
        E_forward_alu_op1 = 2'b00;
    end
    
    // Forward ALU operand 2 (rs2)
    // Priority: MA stage > WB stage > no forwarding
    if ((E_rf_a2 == M_rf_a3) && M_we_rf && (M_rf_a3 != 5'b0)) begin
        // Forward from MA stage (most recent)
        E_forward_alu_op2 = 2'b01;
    end
    else if ((E_rf_a2 == W_rf_a3) && W_we_rf && (W_rf_a3 != 5'b0)) begin
        // Forward from WB stage
        E_forward_alu_op2 = 2'b10;
    end
    else begin
        // No forwarding needed
        E_forward_alu_op2 = 2'b00;
    end
end

// ============================================================================
// 2. LW HAZARD + 3. CONTROL HAZARD - COMBINED
// ============================================================================
// MUST be in ONE always block to avoid multiple drivers!

always @(*) begin
    // Default values - normal operation
    PC_en = 1'b1;
    PLR1_en = 1'b1;
    PLR1_clr = 1'b0;
    PLR2_clr = 1'b0;
    
    // ========================================================================
    // LW Hazard Detection (PRIORITY 1 - happens first)
    // ========================================================================
    // When LW is in EX and next instruction (in ID) needs the loaded value
    if ((E_opcode == OP_LW) && E_we_rf && 
        ((D_rf_a1 == E_rf_a3) || (D_rf_a2 == E_rf_a3)) && (E_rf_a3 != 5'b0)) begin
        // LW hazard detected - STALL pipeline
        PC_en = 1'b0;       // Stall PC (don't fetch new instruction)
        PLR1_en = 1'b0;     // Stall PLR1 (keep current instruction in ID)
        PLR2_clr = 1'b1;    // Flush PLR2 (insert NOP/bubble in EX stage)
    end
    
    // ========================================================================
    // Control Hazard Detection (PRIORITY 2 - overrides LW if both happen)
    // ========================================================================
    // When branch is taken OR jump occurs, flush the pipeline
    if ((E_branch && E_zero) || E_jump) begin
        // Branch/Jump taken - FLUSH 2 instructions that were fetched after branch
        PLR1_clr = 1'b1;    // Flush IF/ID (instruction immediately after branch)
        PLR2_clr = 1'b1;    // Flush ID/EX (instruction 2nd after branch)
        PC_en = 1'b1;       // Don't stall PC (let new target address load)
        PLR1_en = 1'b1;     // Don't stall PLR1
    end
end

endmodule