// This is the Finite State Machine class for the Multi-Cycle RISC-V Processor
// The FSM controls the execution of instructions across multiple clock cycles
// Each instruction type follows a different path through the state machine
module fsm (
    input wire clk,                    // Clock signal
    input wire rst,                    // Reset signal
    input wire [6:0] op,               // Opcode from instruction
    input wire zero,                   // Zero flag from ALU (for branch)
    
    // Control outputs
    output reg we_ir,                  // Instruction register write enable
    output reg we_rf,                  // Register file write enable
    output reg we_mem,                 // Memory write enable
    output reg sel_mem_addr,           // Memory address select (0=PC, 1=ALU)
    output reg [1:0] sel_alu_src_a,    // ALU source A select (00=PC, 01=old_pc, 10=rd1)
    output reg [1:0] sel_alu_src_b,    // ALU source B select (00=rd2, 01=imm, 10=4)
    output reg [1:0] sel_result,       // Result select (00=alu_reg, 01=data, 10=pc_plus4, 11=imm)
    output reg [1:0] alu_op,           // ALU operation type for ALU decoder
    output reg pc_update,              // PC update signal (for conditional branch)
    output reg branch,                 // Branch signal
    output reg sel_pc_src              // PC source select (0=alu_out, 1=alu_result)
);

    // State encoding using localparam
    localparam S0_FETCH    = 4'd0;   // Fetch instruction, compute PC+4
    localparam S1_DECODE   = 4'd1;   // Decode instruction, read registers
    localparam S2_EXE_ADDR = 4'd2;   // Execute: compute memory address (LW/SW) or branch target (BEQ/JAL)
    localparam S3_MEM_RD   = 4'd3;   // Memory read (LW)
    localparam S4_WB_MEM   = 4'd4;   // Write back memory data (LW)
    localparam S5_MEM_WR   = 4'd5;   // Memory write (SW)
    localparam S6_EXE_R    = 4'd6;   // Execute R-type operation
    localparam S7_WB_ALU   = 4'd7;   // Write back ALU result (R-type, I-type)
    localparam S8_BEQ      = 4'd8;   // Branch comparison
    localparam S9_EXE_I    = 4'd9;   // Execute I-type operation
    localparam S10_JAL     = 4'd10;  // JAL write back
    localparam S11_LUI     = 4'd11;  // Execute LUI (added for LUI support)
    
    // Opcode definitions
    localparam OP_R_TYPE = 7'b0110011;
    localparam OP_I_ARITH = 7'b0010011;
    localparam OP_LW = 7'b0000011;
    localparam OP_SW = 7'b0100011;
    localparam OP_BEQ = 7'b1100011;
    localparam OP_JAL = 7'b1101111;
    localparam OP_LUI = 7'b0110111;
    
    // State register
    reg [3:0] current_state, next_state;
    
    // State register update
    always @(posedge clk or posedge rst) begin
        if (rst)
            current_state <= S0_FETCH;
        else
            current_state <= next_state;
    end
    
    // Next state logic (combinational)
    always @(*) begin
        // Default: stay in current state
        next_state = current_state;
        
        case (current_state)
            S0_FETCH: begin
                // After fetch, always go to decode
                next_state = S1_DECODE;
            end
            
            S1_DECODE: begin
                // Decode and branch based on opcode
                case (op)
                    OP_LW, OP_SW:   next_state = S2_EXE_ADDR;  // Load/Store need address calculation
                    OP_R_TYPE:      next_state = S6_EXE_R;     // R-type execute
                    OP_I_ARITH:     next_state = S9_EXE_I;     // I-type execute
                    OP_BEQ:         next_state = S2_EXE_ADDR;  // Branch needs target address calc first
                    OP_JAL:         next_state = S2_EXE_ADDR;  // Jump needs target address calc first
                    OP_LUI:         next_state = S11_LUI;      // Load Upper Immediate
                    default:        next_state = S0_FETCH;     // Unknown: restart
                endcase
            end
            
            S2_EXE_ADDR: begin
                // After address calculation, check instruction type
                case (op)
                    OP_LW:  next_state = S3_MEM_RD;   // Load: go to memory read
                    OP_SW:  next_state = S5_MEM_WR;   // Store: go to memory write
                    OP_BEQ: next_state = S8_BEQ;      // Branch: go to comparison
                    OP_JAL: next_state = S10_JAL;     // Jump: go to write back
                    default: next_state = S0_FETCH;
                endcase
            end
            
            S3_MEM_RD: begin
                // After memory read, go to write back
                next_state = S4_WB_MEM;
            end
            
            S4_WB_MEM: begin
                // After write back, fetch next instruction
                next_state = S0_FETCH;
            end
            
            S5_MEM_WR: begin
                // After memory write, fetch next instruction
                next_state = S0_FETCH;
            end
            
            S6_EXE_R: begin
                // After R-type execution, go to ALU write back
                next_state = S7_WB_ALU;
            end
            
            S7_WB_ALU: begin
                // After ALU write back, fetch next instruction
                next_state = S0_FETCH;
            end
            
            S8_BEQ: begin
                // After branch decision, fetch next instruction
                next_state = S0_FETCH;
            end
            
            S9_EXE_I: begin
                // After I-type execution, go to ALU write back
                next_state = S7_WB_ALU;
            end
            
            S10_JAL: begin
                // After JAL, fetch next instruction
                next_state = S0_FETCH;
            end
            
            S11_LUI: begin
                // After LUI, fetch next instruction
                next_state = S0_FETCH;
            end
            
            default: begin
                next_state = S0_FETCH;
            end
        endcase
    end
    
    // Output logic (combinational) - Moore FSM
    // Outputs depend only on current state
    always @(*) begin
        // Default values for all outputs (prevents latches)
        we_ir = 1'b0;
        we_rf = 1'b0;
        we_mem = 1'b0;
        sel_mem_addr = 1'b0;
        sel_alu_src_a = 2'b00;
        sel_alu_src_b = 2'b00;
        sel_result = 2'b00;
        alu_op = 2'b00;
        pc_update = 1'b0;
        branch = 1'b0;
        sel_pc_src = 1'b0;        // Default: use alu_out (for PC+4)
        
        case (current_state)
            S0_FETCH: begin
                // Fetch instruction from memory at PC address
                // Also compute PC+4 using ALU
                sel_mem_addr = 1'b0;      // Use PC for memory address
                we_ir = 1'b1;             // Write instruction to IR
                sel_alu_src_a = 2'b00;    // ALU A = PC
                sel_alu_src_b = 2'b10;    // ALU B = 4
                alu_op = 2'b00;           // ALU operation = ADD
                sel_result = 2'b10;       // Result = ALU output (PC+4)
                pc_update = 1'b1;         // Update PC with PC+4
            end
            
            S1_DECODE: begin
                // Read registers (happens automatically)
                // Sign extend immediate (happens automatically)
                // No control signals needed, just let data propagate
            end
            
            S2_EXE_ADDR: begin
                // Compute address: base + offset (for LW/SW) or PC + imm (for BEQ/JAL)
                // For LW/SW: rd1 + imm
                // For BEQ/JAL: old_pc + imm
                if (op == OP_LW || op == OP_SW) begin
                    sel_alu_src_a = 2'b10;    // rd1 for LW/SW
                end else begin
                    sel_alu_src_a = 2'b01;    // old_pc for BEQ/JAL
                end
                sel_alu_src_b = 2'b01;        // ALU B = imm
                alu_op = 2'b00;               // ALU operation = ADD
            end
            
            S3_MEM_RD: begin
                // Read from memory at computed address
                sel_result = 2'b00;       // Result = alu_reg (address)
                sel_mem_addr = 1'b1;      // Use ALU result for memory address
            end
            
            S4_WB_MEM: begin
                // Write memory data to register file
                sel_result = 2'b01;       // Result = data (from memory)
                we_rf = 1'b1;             // Write to register file
            end
            
            S5_MEM_WR: begin
                // Write to memory at computed address
                sel_result = 2'b00;       // Result = alu_reg (address)
                sel_mem_addr = 1'b1;      // Use ALU result for memory address
                we_mem = 1'b1;            // Write to memory
            end
            
            S6_EXE_R: begin
                // Execute R-type operation: rd1 op rd2
                sel_alu_src_a = 2'b10;    // ALU A = rd1
                sel_alu_src_b = 2'b00;    // ALU B = rd2
                alu_op = 2'b10;           // ALU operation determined by funct3/funct7
            end
            
            S7_WB_ALU: begin
                // Write ALU result to register file
                sel_result = 2'b00;       // Result = alu_reg
                we_rf = 1'b1;             // Write to register file
            end
            
            S8_BEQ: begin
                // Branch comparison: compare rd1 and rd2
                // Branch target (PC+imm) already computed in S2_EXE_ADDR and stored in alu_reg
                sel_alu_src_a = 2'b10;    // ALU A = rd1
                sel_alu_src_b = 2'b00;    // ALU B = rd2
                alu_op = 2'b01;           // ALU operation = SUB (for comparison)
                sel_result = 2'b00;       // Result = alu_reg (not used for PC)
                branch = 1'b1;            // This is a branch
                pc_update = 1'b1;         // May update PC if branch taken (zero=1)
                sel_pc_src = 1'b1;        // Use alu_result (branch target from S2)
            end
            
            S9_EXE_I: begin
                // Execute I-type operation: rd1 op imm
                sel_alu_src_a = 2'b10;    // ALU A = rd1
                sel_alu_src_b = 2'b01;    // ALU B = imm
                alu_op = 2'b11;           // I-type: ignore funct7[5] except for shifts
            end
            
            S10_JAL: begin
                // JAL: Write PC+4 to register, update PC to target
                // Target address (PC+imm) computed in S2 and stored in alu_reg
                // PC+4 is in pc_plus4_reg
                sel_result = 2'b10;       // Result = pc_plus4 (for register write-back)
                we_rf = 1'b1;             // Write PC+4 to register file
                pc_update = 1'b1;         // Update PC to jump target (from alu_reg)
                sel_pc_src = 1'b1;        // Use alu_result (jump target from S2)
            end
            
            S11_LUI: begin
                // Load Upper Immediate: rd = imm
                sel_result = 2'b11;       // Result = imm
                we_rf = 1'b1;             // Write to register file
            end
            
            default: begin
                // Keep default values
            end
        endcase
    end

endmodule