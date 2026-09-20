//============================================================================
// Testbench: tb_rv32i_top
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Self-checking testbench for the RV32I processor. Runs the Fibonacci
//   test program and verifies:
//     1. Final register x10 (a0) = 89
//     2. Correct Fibonacci sequence in data memory
//     3. Prints instruction-by-instruction execution trace
//     4. Reports PASS/FAIL with test count
//
//   This testbench demonstrates verification skills valued by NXP:
//     - Self-checking (no manual waveform inspection needed)
//     - Execution trace (debug visibility)
//     - Memory content verification
//     - Automated pass/fail reporting
//============================================================================

`timescale 1ns / 1ps

module tb_rv32i_top;

    //========================================================================
    // Signals
    //========================================================================
    reg         clk;
    reg         rst;
    wire [31:0] debug_pc;
    wire [31:0] debug_instr;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_reg_a0;

    //========================================================================
    // DUT Instantiation
    //========================================================================
    rv32i_top uut (
        .clk             (clk),
        .rst             (rst),
        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result),
        .debug_reg_a0    (debug_reg_a0)
    );

    //========================================================================
    // Clock Generation — 125 MHz (8 ns period)
    //========================================================================
    initial clk = 0;
    always #4 clk = ~clk;  // 4 ns half-period = 8 ns period = 125 MHz

    //========================================================================
    // Test Counters
    //========================================================================
    integer pass_count = 0;
    integer fail_count = 0;
    integer test_num   = 0;

    //========================================================================
    // Helper Task: Check a value and report PASS/FAIL
    //========================================================================
    task check;
        input [255:0] test_name;  // padded string
        input [31:0]  actual;
        input [31:0]  expected;
        begin
            test_num = test_num + 1;
            if (actual === expected) begin
                $display("[PASS] Test %0d: %0s = %0d (0x%08h)",
                         test_num, test_name, actual, actual);
                pass_count = pass_count + 1;
            end else begin
                $display("[FAIL] Test %0d: %0s = %0d (0x%08h), expected %0d (0x%08h)",
                         test_num, test_name, actual, actual, expected, expected);
                fail_count = fail_count + 1;
            end
        end
    endtask

    //========================================================================
    // Instruction Decoder — for readable execution trace
    //========================================================================
    task decode_and_print;
        input [31:0] pc;
        input [31:0] instr;
        reg [6:0] opcode;
        reg [4:0] rd, rs1, rs2;
        reg [2:0] funct3;
        begin
            opcode = instr[6:0];
            rd     = instr[11:7];
            funct3 = instr[14:12];
            rs1    = instr[19:15];
            rs2    = instr[24:20];

            case (opcode)
                7'b0010011: $display("  PC=0x%03h: ADDI  x%0d, x%0d, %0d",
                               pc, rd, rs1, $signed(instr[31:20]));
                7'b0110011: begin
                    if (instr[30])
                        $display("  PC=0x%03h: SUB   x%0d, x%0d, x%0d", pc, rd, rs1, rs2);
                    else
                        $display("  PC=0x%03h: ADD   x%0d, x%0d, x%0d", pc, rd, rs1, rs2);
                end
                7'b0100011: $display("  PC=0x%03h: SW    x%0d, %0d(x%0d)",
                               pc, rs2, $signed({instr[31:25], instr[11:7]}), rs1);
                7'b1100011: begin
                    if (funct3 == 3'b000)
                        $display("  PC=0x%03h: BEQ   x%0d, x%0d", pc, rs1, rs2);
                    else
                        $display("  PC=0x%03h: BNE   x%0d, x%0d", pc, rs1, rs2);
                end
                7'b1101111: $display("  PC=0x%03h: JAL   x%0d", pc, rd);
                7'b0110111: $display("  PC=0x%03h: LUI   x%0d, 0x%05h", pc, rd, instr[31:12]);
                default:    $display("  PC=0x%03h: ???   (0x%08h)", pc, instr);
            endcase
        end
    endtask

    //========================================================================
    // Main Test Sequence
    //========================================================================
    initial begin
        // Waveform dump for viewer (GTKWave / Vivado)
        $dumpfile("rv32i_tb.vcd");
        $dumpvars(0, tb_rv32i_top);

        $display("");
        $display("================================================================");
        $display("  RISC-V RV32I Processor — Testbench");
        $display("  V-SPACE FPGA Build Challenge 2026 | Team Suraj");
        $display("================================================================");
        $display("");

        // ---- Reset Phase ----
        $display("--- Phase 1: Reset ---");
        rst = 1;
        repeat(5) @(posedge clk);
        rst = 0;
        $display("  Reset deasserted. Processor running...");
        $display("");

        // ---- Execution Phase ----
        $display("--- Phase 2: Execution Trace ---");

        // Run for enough cycles:
        // 5 setup instructions + 10 iterations × 7 instructions + 2 final = 77 instructions
        // Add margin: run 100 cycles
        repeat(100) begin
            @(posedge clk);
            #1;  // Small delay for signal settling
            // Only print if instruction is not 0 (uninitialized memory)
            if (debug_instr !== 32'h0 && debug_pc < 32'h38) begin
                decode_and_print(debug_pc, debug_instr);
            end
        end

        $display("");
        $display("--- Phase 3: Verification ---");
        $display("");

        // ---- Verify Register x10 (a0) = 89 ----
        $display(">> Register File Check:");
        check("x10 (a0) final value", debug_reg_a0, 32'd89);

        // Also check other registers via hierarchical access
        check("x1 (F_n-2 final)", uut.u_regfile.registers[1], 32'd55);
        check("x2 (F_n-1 final)", uut.u_regfile.registers[2], 32'd89);
        check("x3 (loop limit)",  uut.u_regfile.registers[3], 32'd10);
        check("x4 (loop counter)",uut.u_regfile.registers[4], 32'd10);
        check("x6 (last Fib)",    uut.u_regfile.registers[6], 32'd89);

        $display("");

        // ---- Verify Data Memory (Fibonacci sequence) ----
        $display(">> Data Memory Check (Fibonacci sequence at 0x100):");
        // Memory word address = byte_address / 4
        // 0x100 = 256 bytes = word 64
        check("mem[0x100] = F(1)", uut.u_dmem.mem[64],  32'd1);
        check("mem[0x104] = F(2)", uut.u_dmem.mem[65],  32'd2);
        check("mem[0x108] = F(3)", uut.u_dmem.mem[66],  32'd3);
        check("mem[0x10C] = F(4)", uut.u_dmem.mem[67],  32'd5);
        check("mem[0x110] = F(5)", uut.u_dmem.mem[68],  32'd8);
        check("mem[0x114] = F(6)", uut.u_dmem.mem[69],  32'd13);
        check("mem[0x118] = F(7)", uut.u_dmem.mem[70],  32'd21);
        check("mem[0x11C] = F(8)", uut.u_dmem.mem[71],  32'd34);
        check("mem[0x120] = F(9)", uut.u_dmem.mem[72],  32'd55);
        check("mem[0x124] = F(10)",uut.u_dmem.mem[73],  32'd89);

        // ---- Final Report ----
        $display("");
        $display("================================================================");
        if (fail_count == 0) begin
            $display("  RESULT: ALL %0d TESTS PASSED", pass_count);
        end else begin
            $display("  RESULT: %0d PASSED, %0d FAILED (out of %0d)",
                     pass_count, fail_count, test_num);
        end
        $display("================================================================");
        $display("");

        $finish;
    end

    //========================================================================
    // Timeout Watchdog — prevent infinite simulation
    //========================================================================
    initial begin
        #10000;  // 10 us = 1250 clock cycles at 125 MHz
        $display("");
        $display("[ERROR] Simulation timed out after 10 us!");
        $display("  PC stuck at 0x%08h", debug_pc);
        $display("");
        $finish;
    end

endmodule
