//============================================================================
// Module: forwarding_unit
// Project: AutoSense RV32I SoC — 5-Stage Pipelined Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Data forwarding (bypass) unit for the 5-stage pipeline. Resolves
//   Read-After-Write (RAW) data hazards WITHOUT stalling, by forwarding
//   results from EX/MEM or MEM/WB stages back to the ALU inputs in
//   the EX stage.
//
//   This is the SAME technique used in ARM Cortex-A/R cores inside
//   NXP's i.MX and S32 automotive processors.
//
//   Forwarding Priority:
//     EX/MEM forwarding takes priority over MEM/WB forwarding.
//     This handles the case where two consecutive instructions
//     write to the same register:
//       ADD x1, x2, x3   (in MEM stage)
//       SUB x1, x4, x5   (in EX stage)  ← this result is newer
//       AND x6, x1, x7   (in ID stage)  ← needs x1 from EX, not MEM
//
//   Forward Select Encoding:
//     2'b00 — No forwarding (use register file value)
//     2'b01 — Forward from MEM/WB stage (1 cycle old result)
//     2'b10 — Forward from EX/MEM stage (0 cycle old result, highest priority)
//
// Port List:
//   ex_mem_reg_write - EX/MEM stage register write enable
//   mem_wb_reg_write - MEM/WB stage register write enable
//   ex_mem_rd        - EX/MEM stage destination register
//   mem_wb_rd        - MEM/WB stage destination register
//   id_ex_rs1        - ID/EX stage source register 1
//   id_ex_rs2        - ID/EX stage source register 2
//   forward_a        - Forwarding mux select for ALU input A
//   forward_b        - Forwarding mux select for ALU input B
//============================================================================

module forwarding_unit (
    input  wire        ex_mem_reg_write,
    input  wire        mem_wb_reg_write,
    input  wire [4:0]  ex_mem_rd,
    input  wire [4:0]  mem_wb_rd,
    input  wire [4:0]  id_ex_rs1,
    input  wire [4:0]  id_ex_rs2,
    output reg  [1:0]  forward_a,
    output reg  [1:0]  forward_b
);

    // Forwarding logic for ALU input A (rs1 path)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && 
            (ex_mem_rd == id_ex_rs1)) begin
            // EX/MEM forwarding — highest priority
            forward_a = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && 
                 (mem_wb_rd == id_ex_rs1)) begin
            // MEM/WB forwarding — lower priority
            forward_a = 2'b01;
        end
        else begin
            // No forwarding needed — use register file value
            forward_a = 2'b00;
        end
    end

    // Forwarding logic for ALU input B (rs2 path)
    always @(*) begin
        if (ex_mem_reg_write && (ex_mem_rd != 5'd0) && 
            (ex_mem_rd == id_ex_rs2)) begin
            // EX/MEM forwarding — highest priority
            forward_b = 2'b10;
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'd0) && 
                 (mem_wb_rd == id_ex_rs2)) begin
            // MEM/WB forwarding — lower priority
            forward_b = 2'b01;
        end
        else begin
            // No forwarding needed — use register file value
            forward_b = 2'b00;
        end
    end

endmodule
