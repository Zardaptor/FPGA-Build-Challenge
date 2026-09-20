//============================================================================
// Module: data_memory
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Data memory (RAM) for load/store instructions. Supports word-aligned
//   reads and writes. Synchronous write, asynchronous read (for single-
//   cycle operation — data available in the same cycle).
//
//   Memory depth: 256 words (1 KB). In a real NXP SoC, this maps to
//   the tightly-coupled SRAM in the S32 real-time processing cores.
//
// Port List:
//   clk       - System clock
//   mem_read  - Read enable (from control unit, LW)
//   mem_write - Write enable (from control unit, SW)
//   addr      - Byte address (word-aligned)
//   wdata     - Write data (32-bit, from register rs2)
//   rdata     - Read data (32-bit, to register file write-back)
//============================================================================

module data_memory (
    input  wire        clk,
    input  wire        mem_read,
    input  wire        mem_write,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    output wire [31:0] rdata
);

    parameter MEM_DEPTH = 256;  // 256 words = 1 KB

    // Memory array
    reg [31:0] mem [0:MEM_DEPTH-1];

    // Initialize memory to zero
    integer i;
    initial begin
        for (i = 0; i < MEM_DEPTH; i = i + 1)
            mem[i] = 32'd0;
    end

    // Synchronous write
    always @(posedge clk) begin
        if (mem_write)
            mem[addr[31:2]] <= wdata;  // Word-aligned write
    end

    // Asynchronous read (data available same cycle for single-cycle CPU)
    assign rdata = (mem_read) ? mem[addr[31:2]] : 32'd0;

endmodule
