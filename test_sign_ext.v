`timescale 1ns/1ps

module test_sign_ext;
    reg [31:0] instr;
    reg [2:0] sel;
    wire [31:0] imm;
    
    sign_extender dut (
        .instr_full(instr),
        .sel_ext(sel),
        .imm_ext(imm)
    );
    
    initial begin
        // Test I-type with -5
        instr = 32'hffb00193;  // addi x3, x0, -5
        sel = 3'b000;          // I-type
        #10;
        $display("Instruction: %h", instr);
        $display("Bits [31:20]: %b", instr[31:20]);
        $display("Bit 31: %b", instr[31]);
        $display("Extended immediate: %h", imm);
        $display("Expected: ffffffb");
        
        if (imm == 32'hfffffffb)
            $display("PASS: Sign extension correct!");
        else
            $display("FAIL: Sign extension wrong!");
        
        $finish;
    end
endmodule