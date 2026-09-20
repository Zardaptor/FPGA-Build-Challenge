//============================================================================
// Module: program_counter
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Program Counter (PC) register. On each clock cycle, the PC is updated
//   to pc_next. On reset, PC is initialized to 0x00000000.
//   Outputs the current PC value for instruction fetch.
//
// Port List:
//   clk       - System clock (125 MHz on Zybo Z7)
//   rst       - Active-high synchronous reset
//   pc_next   - Next PC value (from branch/jump mux)
//   pc        - Current PC value (to instruction memory)
//============================================================================

module program_counter (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] pc_next,
    output reg  [31:0] pc
);

    always @(posedge clk) begin
        if (rst)
            pc <= 32'h0000_0000;
        else
            pc <= pc_next;
    end

endmodule
