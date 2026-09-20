//============================================================================
// Module: imm_gen
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Immediate Generator for RV32I instruction formats. Extracts and
//   sign-extends the immediate value from the instruction based on
//   the instruction type (I, S, B, U, J).
//
//   RISC-V has 6 instruction formats. The immediate bits are scattered
//   across the instruction word for each format — this module
//   reassembles them into a sign-extended 32-bit value.
//
//   Format Encoding (determined by opcode[6:0]):
//     I-type: LW, ADDI, ANDI, ORI, XORI, SLTI, JALR
//     S-type: SW
//     B-type: BEQ, BNE
//     U-type: LUI, AUIPC
//     J-type: JAL
//
// Port List:
//   instr     - Full 32-bit instruction
//   imm       - Sign-extended 32-bit immediate output
//============================================================================

module imm_gen (
    input  wire [31:0] instr,
    output reg  [31:0] imm
);

    // Opcode field
    wire [6:0] opcode = instr[6:0];

    // Opcode definitions
    localparam OP_LOAD   = 7'b0000011;  // LW (I-type)
    localparam OP_IMM    = 7'b0010011;  // ADDI, ANDI, etc. (I-type)
    localparam OP_STORE  = 7'b0100011;  // SW (S-type)
    localparam OP_BRANCH = 7'b1100011;  // BEQ, BNE (B-type)
    localparam OP_LUI    = 7'b0110111;  // LUI (U-type)
    localparam OP_AUIPC  = 7'b0010111;  // AUIPC (U-type)
    localparam OP_JAL    = 7'b1101111;  // JAL (J-type)
    localparam OP_JALR   = 7'b1100111;  // JALR (I-type)

    always @(*) begin
        case (opcode)
            // I-type: imm[11:0] = instr[31:20]
            OP_LOAD,
            OP_IMM,
            OP_JALR: begin
                imm = {{20{instr[31]}}, instr[31:20]};
            end

            // S-type: imm[11:5|4:0] = instr[31:25|11:7]
            OP_STORE: begin
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            end

            // B-type: imm[12|10:5|4:1|11] = instr[31|30:25|11:8|7]
            // Note: imm[0] is always 0 (half-word aligned)
            OP_BRANCH: begin
                imm = {{19{instr[31]}}, instr[31], instr[7], 
                        instr[30:25], instr[11:8], 1'b0};
            end

            // U-type: imm[31:12] = instr[31:12], lower 12 bits = 0
            OP_LUI,
            OP_AUIPC: begin
                imm = {instr[31:12], 12'b0};
            end

            // J-type: imm[20|10:1|11|19:12] = instr[31|30:21|20|19:12]
            // Note: imm[0] is always 0 (half-word aligned)
            OP_JAL: begin
                imm = {{11{instr[31]}}, instr[31], instr[19:12], 
                        instr[20], instr[30:21], 1'b0};
            end

            default: begin
                imm = 32'd0;
            end
        endcase
    end

endmodule
