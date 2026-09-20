//============================================================================
// Module: alu_control
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   ALU Control unit. Takes the 2-bit alu_op from the main control unit
//   along with funct3 and funct7[5] fields to produce the final 4-bit
//   ALU operation select.
//
//   This two-level decode (control_unit → alu_control → ALU) mirrors
//   how real SoC designs separate instruction decode from execution
//   control — a pattern you'll see in NXP's processor implementations.
//
//   alu_op encoding from control_unit:
//     00 = Load/Store (always ADD for address calculation)
//     01 = Branch (SUB for comparison)
//     10 = R-type (use funct3 + funct7[5] to determine operation)
//     11 = I-type (use funct3, treat as R-type but no SUB from funct7)
//
// Port List:
//   alu_op    - 2-bit operation type from control unit
//   funct3    - 3-bit function field from instruction [14:12]
//   funct7_5  - Bit 5 of funct7 field (instruction[30])
//   opcode_5  - Bit 5 of opcode (instruction[5]), distinguishes R/I
//   alu_ctrl  - 4-bit ALU operation select output
//============================================================================

module alu_control (
    input  wire [1:0] alu_op,
    input  wire [2:0] funct3,
    input  wire       funct7_5,   // instruction[30]
    input  wire       opcode_5,   // instruction[5] — 1 for R-type, 0 for I-type
    output reg  [3:0] alu_ctrl
);

    // ALU operation encodings (must match alu_32bit)
    localparam ALU_ADD  = 4'b0000;
    localparam ALU_SUB  = 4'b0001;
    localparam ALU_AND  = 4'b0010;
    localparam ALU_OR   = 4'b0011;
    localparam ALU_XOR  = 4'b0100;
    localparam ALU_SLT  = 4'b0101;
    localparam ALU_SLL  = 4'b0110;
    localparam ALU_SRL  = 4'b0111;
    localparam ALU_SRA  = 4'b1000;
    localparam ALU_SLTU = 4'b1001;

    always @(*) begin
        case (alu_op)
            2'b00: begin
                // Load/Store — always ADD (base + offset)
                alu_ctrl = ALU_ADD;
            end

            2'b01: begin
                // Branch — SUB for comparison (zero flag decides branch)
                alu_ctrl = ALU_SUB;
            end

            2'b10: begin
                // R-type — decode from funct3 + funct7[5]
                case (funct3)
                    3'b000: alu_ctrl = (funct7_5) ? ALU_SUB : ALU_ADD;  // ADD/SUB
                    3'b001: alu_ctrl = ALU_SLL;                          // SLL
                    3'b010: alu_ctrl = ALU_SLT;                          // SLT
                    3'b011: alu_ctrl = ALU_SLTU;                         // SLTU
                    3'b100: alu_ctrl = ALU_XOR;                          // XOR
                    3'b101: alu_ctrl = (funct7_5) ? ALU_SRA : ALU_SRL;  // SRL/SRA
                    3'b110: alu_ctrl = ALU_OR;                           // OR
                    3'b111: alu_ctrl = ALU_AND;                          // AND
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            2'b11: begin
                // I-type — similar to R-type but funct7_5 only matters
                // for SRAI (funct3=101). For ADDI, funct7_5 could be set
                // as part of the immediate, so we must not use it for SUB.
                case (funct3)
                    3'b000: alu_ctrl = ALU_ADD;                          // ADDI (always ADD)
                    3'b001: alu_ctrl = ALU_SLL;                          // SLLI
                    3'b010: alu_ctrl = ALU_SLT;                          // SLTI
                    3'b011: alu_ctrl = ALU_SLTU;                         // SLTIU
                    3'b100: alu_ctrl = ALU_XOR;                          // XORI
                    3'b101: alu_ctrl = (funct7_5) ? ALU_SRA : ALU_SRL;  // SRLI/SRAI
                    3'b110: alu_ctrl = ALU_OR;                           // ORI
                    3'b111: alu_ctrl = ALU_AND;                          // ANDI
                    default: alu_ctrl = ALU_ADD;
                endcase
            end

            default: alu_ctrl = ALU_ADD;
        endcase
    end

endmodule
