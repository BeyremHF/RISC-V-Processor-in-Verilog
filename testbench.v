`timescale 1ns/1ps

module testbench;

    // Signals
    reg clk;
    reg rst_n;  // Active-low reset for pipeline
    
    // Test statistics
    integer passed_tests;
    integer failed_tests;
    integer total_tests;
    
    // Instantiate the pipelined processor
    rv_pl dut (
        .clk(clk),
        .rst_n(rst_n)
    );
    
    // Clock generation (50MHz = 20ns period)
    initial begin
        // VCD dump for waveform viewing
        $dumpfile("dump.vcd");
        $dumpvars(0, testbench);

        clk = 0;
        forever #10 clk = ~clk;
    end
    
    // Helper task to check register value
    task check_register;
        input [4:0] reg_num;
        input [31:0] expected;
        input [200*8:0] test_name;
        begin
            total_tests = total_tests + 1;
            if (dut.RF.regs[reg_num] === expected) begin
                $display("✓ PASS: %0s", test_name);
                $display("  x%0d = 0x%08h", reg_num, dut.RF.regs[reg_num]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("✗ FAIL: %0s", test_name);
                $display("  Expected: x%0d = 0x%08h", reg_num, expected);
                $display("  Got:      x%0d = 0x%08h", reg_num, dut.RF.regs[reg_num]);
                failed_tests = failed_tests + 1;
            end
        end
    endtask
    
    // Helper task to check memory value
    task check_memory;
        input [31:0] addr;
        input [31:0] expected;
        input [200*8:0] test_name;
        begin
            total_tests = total_tests + 1;
            if (dut.DMEM.mem[addr[31:2]] === expected) begin
                $display("✓ PASS: %0s", test_name);
                $display("  mem[%0d] = 0x%08h", addr, dut.DMEM.mem[addr[31:2]]);
                passed_tests = passed_tests + 1;
            end else begin
                $display("✗ FAIL: %0s", test_name);
                $display("  Expected: mem[%0d] = 0x%08h", addr, expected);
                $display("  Got:      mem[%0d] = 0x%08h", addr, dut.DMEM.mem[addr[31:2]]);
                failed_tests = failed_tests + 1;
            end
        end
    endtask
    
    // Test procedure
    initial begin
        // Initialize counters
        passed_tests = 0;
        failed_tests = 0;
        total_tests = 0;
        
        // Setup waveform dumping
        $dumpfile("riscv_pipeline.vcd");
        $dumpvars(0, testbench);
        
        // Load program
        $readmemh("program.hex", dut.IMEM.mem);
        
        $display("\n================================================================================");
        $display("RISC-V PIPELINED PROCESSOR COMPREHENSIVE TEST SUITE");
        $display("================================================================================\n");
        
        // Reset sequence - active-low reset
        rst_n = 0;  // Assert reset
        #15;
        rst_n = 1;  // Deassert reset
        #15;
        
        // Run for enough cycles to complete all instructions
        // Pipeline has 5 stages, so first instruction completes at cycle 5
        // 38 instructions + pipeline fill + branches/jumps = ~50 cycles
        // Add extra margin for safety
        #1000;
        
        $display("\n================================================================================");
        $display("TEST RESULTS");
        $display("================================================================================\n");
        
        // GROUP 1: I-TYPE ARITHMETIC (ADDI)
        $display("--- GROUP 1: I-TYPE ARITHMETIC (ADDI) ---");
        check_register(1, 32'h0000000f, "TEST 1: addi x1, x0, 15");
        check_register(2, 32'h0000000a, "TEST 2: addi x2, x0, 10");
        check_register(3, 32'hfffffffb, "TEST 3: addi x3, x0, -5");
        check_register(4, 32'hfffffff8, "TEST 4: addi x4, x0, -8");
        check_register(5, 32'h00000001, "TEST 5: addi x5, x0, 1");
        $display("");
        
        // GROUP 2: U-TYPE (LUI)
        $display("--- GROUP 2: U-TYPE (LUI) ---");
        check_register(6, 32'h12345000, "TEST 6: lui x6, 0x12345");
        $display("");
        
        // GROUP 3: R-TYPE ARITHMETIC
        $display("--- GROUP 3: R-TYPE ARITHMETIC ---");
        check_register(7, 32'h00000019, "TEST 7: add x7, x1, x2 (15+10=25)");
        check_register(8, 32'h00000005, "TEST 8: sub x8, x1, x2 (15-10=5)");
        check_register(9, 32'h0000000a, "TEST 9: add x9, x1, x3 (15+(-5)=10)");
        check_register(10, 32'h00000014, "TEST 10: sub x10, x1, x3 (15-(-5)=20)");
        check_register(11, 32'hfffffff6, "TEST 11: add x11, x3, x3 (-5+(-5)=-10)");
        $display("");
        
        // GROUP 4: R-TYPE LOGICAL
        $display("--- GROUP 4: R-TYPE LOGICAL ---");
        check_register(12, 32'h00000005, "TEST 12: xor x12, x1, x2 (15 XOR 10)");
        check_register(13, 32'h0000000f, "TEST 13: or x13, x1, x2 (15 OR 10)");
        check_register(14, 32'h0000000a, "TEST 14: and x14, x1, x2 (15 AND 10)");
        $display("");
        
        // GROUP 5: R-TYPE SHIFTS
        $display("--- GROUP 5: R-TYPE SHIFTS ---");
        check_register(15, 32'h00000002, "TEST 15: addi x15, x0, 2");
        check_register(16, 32'h00000028, "TEST 16: sll x16, x2, x15 (10<<2=40)");
        check_register(17, 32'h0000000a, "TEST 17: srl x17, x16, x15 (40>>2=10)");
        $display("");
        
        // GROUP 6: ARITHMETIC SHIFT
        $display("--- GROUP 6: ARITHMETIC SHIFT ---");
        check_register(18, 32'hfffffffc, "TEST 18: sra x18, x4, x5 (-8>>>1=-4)");
        $display("");
        
        // GROUP 7: COMPARISONS
        $display("--- GROUP 7: R-TYPE COMPARISONS ---");
        check_register(19, 32'h00000001, "TEST 19: slt x19, x2, x1 (10<15=1)");
        check_register(20, 32'h00000000, "TEST 20: slt x20, x1, x2 (15<10=0)");
        $display("");
        
        // GROUP 8: I-TYPE ARITHMETIC
        $display("--- GROUP 8: I-TYPE ARITHMETIC ---");
        check_register(21, 32'h00000014, "TEST 21: addi x21, x1, 5 (15+5=20)");
        check_register(22, 32'h00000007, "TEST 22: addi x22, x2, -3 (10-3=7)");
        check_register(23, 32'h00000001, "TEST 23: slti x23, x2, 20 (10<20=1)");
        check_register(24, 32'h00000000, "TEST 24: slti x24, x1, 10 (15<10=0)");
        $display("");
        
        // GROUP 9: I-TYPE LOGICAL
        $display("--- GROUP 9: I-TYPE LOGICAL ---");
        check_register(25, 32'h00000005, "TEST 25: xori x25, x1, 10 (15 XOR 10)");
        check_register(26, 32'h0000000f, "TEST 26: ori x26, x2, 5 (10 OR 5)");
        check_register(27, 32'h0000000a, "TEST 27: andi x27, x1, 10 (15 AND 10)");
        $display("");
        
        // GROUP 10: I-TYPE SHIFTS
        $display("--- GROUP 10: I-TYPE SHIFTS ---");
        check_register(28, 32'h00000028, "TEST 28: slli x28, x2, 2 (10<<2=40)");
        check_register(29, 32'h00000014, "TEST 29: srli x29, x28, 1 (40>>1=20)");
        check_register(30, 32'hfffffffd, "TEST 30: srai x30, x3, 1 (-5>>>1=-3)");
        $display("");
        
        // GROUP 11: MEMORY OPERATIONS
        $display("--- GROUP 11: MEMORY OPERATIONS ---");
        check_memory(0, 32'h00000019, "TEST 31: sw x7, 0(x0) - store 25");
        check_memory(4, 32'h00000005, "TEST 32: sw x8, 4(x0) - store 5");
        check_memory(8, 32'h0000000a, "TEST 33: sw x9, 8(x0) - store 10");
        check_memory(12, 32'h00000014, "TEST 34: sw x10, 12(x0) - store 20");
        check_register(31, 32'h00000019, "TEST 35: lw x31, 0(x0) - load 25");
        $display("");
        
        // GROUP 12: BRANCH
        $display("--- GROUP 12: BRANCH TEST ---");
        check_register(1, 32'h0000000f, "TEST 36: BEQ taken - x1 unchanged (not 99)");
        check_register(2, 32'h0000000a, "TEST 37: BEQ taken - x2 unchanged (not 99)");
        $display("");
        
        // GROUP 13: JUMP
        $display("--- GROUP 13: JUMP TEST ---");
        check_register(3, 32'hfffffffb, "TEST 38: JAL - x3 unchanged (not 99)");
        $display("");
        
        // FINAL SUMMARY
        $display("================================================================================");
        $display("FINAL TEST SUMMARY");
        $display("================================================================================");
        $display("Total Tests:  %0d", total_tests);
        $display("Passed:       %0d", passed_tests);
        $display("Failed:       %0d", failed_tests);
        $display("Success Rate: %0d%%", (passed_tests * 100) / total_tests);
        $display("================================================================================");
        
        if (failed_tests == 0) begin
            $display("\n✓✓✓ PERFECT SCORE - ALL TESTS PASSED! ✓✓✓\n");
        end else begin
            $display("\n⚠️  SOME TESTS FAILED ⚠️");
            $display("Please check the failed tests above.\n");
        end
        
        // Display register dump for verification
        $display("\n================================================================================");
        $display("REGISTER FILE DUMP");
        $display("================================================================================");
        $display("x0  = 0x%08h  |  x16 = 0x%08h", dut.RF.regs[0], dut.RF.regs[16]);
        $display("x1  = 0x%08h  |  x17 = 0x%08h", dut.RF.regs[1], dut.RF.regs[17]);
        $display("x2  = 0x%08h  |  x18 = 0x%08h", dut.RF.regs[2], dut.RF.regs[18]);
        $display("x3  = 0x%08h  |  x19 = 0x%08h", dut.RF.regs[3], dut.RF.regs[19]);
        $display("x4  = 0x%08h  |  x20 = 0x%08h", dut.RF.regs[4], dut.RF.regs[20]);
        $display("x5  = 0x%08h  |  x21 = 0x%08h", dut.RF.regs[5], dut.RF.regs[21]);
        $display("x6  = 0x%08h  |  x22 = 0x%08h", dut.RF.regs[6], dut.RF.regs[22]);
        $display("x7  = 0x%08h  |  x23 = 0x%08h", dut.RF.regs[7], dut.RF.regs[23]);
        $display("x8  = 0x%08h  |  x24 = 0x%08h", dut.RF.regs[8], dut.RF.regs[24]);
        $display("x9  = 0x%08h  |  x25 = 0x%08h", dut.RF.regs[9], dut.RF.regs[25]);
        $display("x10 = 0x%08h  |  x26 = 0x%08h", dut.RF.regs[10], dut.RF.regs[26]);
        $display("x11 = 0x%08h  |  x27 = 0x%08h", dut.RF.regs[11], dut.RF.regs[27]);
        $display("x12 = 0x%08h  |  x28 = 0x%08h", dut.RF.regs[12], dut.RF.regs[28]);
        $display("x13 = 0x%08h  |  x29 = 0x%08h", dut.RF.regs[13], dut.RF.regs[29]);
        $display("x14 = 0x%08h  |  x30 = 0x%08h", dut.RF.regs[14], dut.RF.regs[30]);
        $display("x15 = 0x%08h  |  x31 = 0x%08h", dut.RF.regs[15], dut.RF.regs[31]);
        $display("================================================================================\n");
        
        $finish;
    end

endmodule