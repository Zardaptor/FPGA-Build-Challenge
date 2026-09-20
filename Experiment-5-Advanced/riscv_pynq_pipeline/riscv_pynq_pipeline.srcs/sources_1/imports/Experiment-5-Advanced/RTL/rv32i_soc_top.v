//============================================================================
// Module: rv32i_soc_top
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Board-level SoC wrapper for the Zybo Z7. Connects the RV32I
//   processor core to the physical I/O:
//     - BTN0 = Reset
//     - LEDs = Lower 4 bits of register x10 (a0) — program output
//     - System clock = 125 MHz
//
//   The processor runs the program from instruction memory and
//   displays the result on LEDs. For the Fibonacci program, the
//   LEDs will show the lower 4 bits of the final result (55 = 0x37,
//   lower 4 bits = 0b0111 = LEDs LD2:LD0 ON, LD3 OFF).
//
// Port List:
//   clk       - 125 MHz system clock (Zybo Z7 pin K17)
//   btn       - Push buttons [3:0] (BTN0=reset)
//   led       - LEDs [3:0]
//============================================================================

module rv32i_soc_top (
    input  wire       clk,
    input  wire [3:0] btn,
    output wire [3:0] led
);

    // Reset from BTN0 (active-high)
    wire rst = btn[0];

    // Processor debug outputs
    wire [31:0] debug_pc;
    wire [31:0] debug_instr;
    wire [31:0] debug_alu_result;
    wire [31:0] debug_reg_a0;

    // Instantiate RISC-V processor core
    rv32i_top u_cpu (
        .clk             (clk),
        .rst             (rst),
        .debug_pc        (debug_pc),
        .debug_instr     (debug_instr),
        .debug_alu_result(debug_alu_result),
        .debug_reg_a0    (debug_reg_a0)
    );

    // Display register a0 (x10) lower 4 bits on LEDs
    assign led = debug_reg_a0[3:0];

endmodule
