//============================================================================
// Module: hazard_unit
// Project: AutoSense RV32I SoC — 5-Stage Pipelined Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Hazard detection unit for the 5-stage pipeline. Handles two types
//   of hazards:
//
//   1. LOAD-USE HAZARD (Data Hazard):
//      When a LOAD instruction (LW) is immediately followed by an
//      instruction that uses the loaded value, the forwarding unit
//      CANNOT resolve this because the data isn't available until
//      the MEM stage. We must STALL the pipeline for 1 cycle.
//
//      Example:
//        LW  x1, 0(x5)    ← data available after MEM stage
//        ADD x2, x1, x3   ← needs x1 NOW in EX stage — TOO EARLY!
//        Solution: Insert 1 bubble (stall IF and ID, flush EX)
//
//   2. CONTROL HAZARD (Branch/Jump):
//      When a branch is TAKEN or a jump occurs, the instructions
//      already fetched into IF and ID stages are wrong. We must
//      FLUSH them (convert to NOPs).
//
//      Example:
//        BEQ x1, x2, target  ← branch decided in EX stage
//        ADD x3, x4, x5      ← already in ID — WRONG if branch taken
//        SUB x6, x7, x8      ← already in IF — WRONG if branch taken
//        Solution: Flush IF/ID and ID/EX registers
//
// Port List:
//   id_ex_mem_read - ID/EX stage memory read signal (indicates LOAD)
//   id_ex_rd       - ID/EX stage destination register (LOAD target)
//   if_id_rs1      - IF/ID stage source register 1
//   if_id_rs2      - IF/ID stage source register 2
//   branch_taken   - Branch is taken (from EX stage)
//   jump           - Jump instruction detected (from ID/EX control)
//   stall_if       - Stall the IF stage (hold PC, hold IF/ID register)
//   stall_id       - Stall the ID stage (hold ID/EX register)  
//   flush_id       - Flush IF/ID register (on branch/jump)
//   flush_ex       - Flush ID/EX register (on load-use stall or branch)
//============================================================================

module hazard_unit (
    // Load-use hazard detection inputs
    input  wire       id_ex_mem_read,
    input  wire [4:0] id_ex_rd,
    input  wire [4:0] if_id_rs1,
    input  wire [4:0] if_id_rs2,
    
    // Control hazard inputs
    input  wire       branch_taken,
    input  wire       jump_taken,
    
    // Stall outputs
    output wire       stall_if,
    output wire       stall_id,
    
    // Flush outputs
    output wire       flush_id,
    output wire       flush_ex
);

    // Load-use hazard: LOAD in EX stage, dependent instruction in ID stage
    wire load_use_hazard;
    assign load_use_hazard = id_ex_mem_read && (id_ex_rd != 5'd0) &&
                             ((id_ex_rd == if_id_rs1) || (id_ex_rd == if_id_rs2));

    // Stall signals — freeze the pipeline front-end for 1 cycle
    // Only stall for load-use hazards (branches cause flushes, not stalls)
    assign stall_if = load_use_hazard;
    assign stall_id = load_use_hazard;

    // Flush signals
    // Flush ID stage (IF/ID register) on branch taken or jump
    // Flush EX stage (ID/EX register) on load-use stall OR branch/jump
    assign flush_id = branch_taken || jump_taken;
    assign flush_ex = load_use_hazard || branch_taken || jump_taken;

endmodule
