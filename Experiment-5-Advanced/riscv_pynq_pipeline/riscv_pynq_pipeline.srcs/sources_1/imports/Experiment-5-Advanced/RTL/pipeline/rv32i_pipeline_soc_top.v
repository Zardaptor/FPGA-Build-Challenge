//============================================================================
// Module: rv32i_pipeline_soc_top
// Project: AutoSense RV32I SoC — 5-Stage Pipelined Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Board-level SoC wrapper for the pipelined RV32I processor.
//   Connects to Zybo Zynq-7000 board I/O:
//     - BTN0 = Reset (active-high)
//     - LEDs[3:0] = Lower 4 bits of register a0 (x10)
//     - System clock = 125 MHz
//============================================================================

module rv32i_pipeline_soc_top (
    input  wire       clk,
    input  wire [3:0] btn,
    output wire [3:0] led
);

    wire rst = btn[0];

    wire [31:0] debug_pc;
    wire [31:0] debug_instr;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_reg_a0;
    wire [31:0] debug_cycle_count;

    rv32i_pipeline_top u_cpu (
        .clk              (clk),
        .rst              (rst),
        .debug_pc         (debug_pc),
        .debug_instr      (debug_instr),
        .debug_alu_result (debug_alu_result),
        .debug_reg_a0     (debug_reg_a0),
        .debug_cycle_count(debug_cycle_count)
    );

    // Display register a0 (x10) lower 4 bits on LEDs
    assign led = debug_reg_a0[3:0];

endmodule
