//============================================================================
// Module: alu_32bit
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   32-bit Arithmetic Logic Unit supporting all RV32I operations.
//   Generates a zero flag used for branch decision logic.
//
//   ALU Operation Encoding (alu_op):
//     4'b0000 - ADD
//     4'b0001 - SUB
//     4'b0010 - AND
//     4'b0011 - OR
//     4'b0100 - XOR
//     4'b0101 - SLT  (Set Less Than, signed)
//     4'b0110 - SLL  (Shift Left Logical)
//     4'b0111 - SRL  (Shift Right Logical)
//     4'b1000 - SRA  (Shift Right Arithmetic)
//     4'b1001 - SLTU (Set Less Than, unsigned)
//
// Port List:
//   a         - Operand A (from register file rd1)
//   b         - Operand B (from register file rd2 or immediate)
//   alu_op    - Operation select (4-bit, from ALU control)
//   result    - 32-bit ALU result
//   zero      - Zero flag (result == 0), used for BEQ/BNE
//============================================================================

module alu_32bit (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_op,
    output reg  [31:0] result,
    output wire        zero
);

    // ALU operation parameters
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
            ALU_ADD:  result = a + b;
            ALU_SUB:  result = a - b;
            ALU_AND:  result = a & b;
            ALU_OR:   result = a | b;
            ALU_XOR:  result = a ^ b;
            ALU_SLT:  result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            ALU_SLL:  result = a << b[4:0];
            ALU_SRL:  result = a >> b[4:0];
            ALU_SRA:  result = $signed(a) >>> b[4:0];
            ALU_SLTU: result = (a < b) ? 32'd1 : 32'd0;
            default:  result = 32'd0;
        endcase
    end

    // Zero flag — active when result is zero
    assign zero = (result == 32'd0);

endmodule
