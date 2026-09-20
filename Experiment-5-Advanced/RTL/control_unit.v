//============================================================================
// Module: control_unit
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Main control unit (instruction decoder). Generates all control
//   signals based on the opcode field of the instruction. This is
//   the "brain" of the processor — analogous to the control logic
//   in NXP's S32 real-time processors.
//
//   Control Signals:
//     reg_write  - Enable write to register file
//     mem_read   - Enable read from data memory (LW)
//     mem_write  - Enable write to data memory (SW)
//     alu_src    - Select ALU input B: 0=register, 1=immediate
//     mem_to_reg - Select write-back data: 00=ALU, 01=memory, 10=PC+4
//     branch     - Instruction is a branch (BEQ/BNE)
//     jump       - Instruction is JAL
//     alu_op     - ALU operation type (passed to ALU control)
//
// Port List:
//   opcode     - Instruction opcode field [6:0]
//   reg_write  - Register file write enable
//   mem_read   - Data memory read enable
//   mem_write  - Data memory write enable
//   alu_src    - ALU source B select (0=reg, 1=imm)
//   mem_to_reg - Write-back mux select (2-bit)
//   branch     - Branch instruction flag
//   jump       - Jump instruction flag (JAL)
//   alu_op     - ALU operation type (2-bit, decoded further by alu_control)
//============================================================================

module control_unit (
    input  wire [6:0] opcode,
    output reg        reg_write,
    output reg        mem_read,
    output reg        mem_write,
    output reg        alu_src,
    output reg  [1:0] mem_to_reg,  // 00=ALU, 01=Mem, 10=PC+4
    output reg        branch,
    output reg        jump,
    output reg  [1:0] alu_op       // 00=add(LW/SW), 01=branch, 10=R-type, 11=I-type
);

    // Opcode definitions
    localparam OP_RTYPE  = 7'b0110011;  // R-type: ADD, SUB, AND, OR, XOR, SLT
    localparam OP_IMM    = 7'b0010011;  // I-type ALU: ADDI, ANDI, ORI, etc.
    localparam OP_LOAD   = 7'b0000011;  // LW
    localparam OP_STORE  = 7'b0100011;  // SW
    localparam OP_BRANCH = 7'b1100011;  // BEQ, BNE
    localparam OP_JAL    = 7'b1101111;  // JAL
    localparam OP_JALR   = 7'b1100111;  // JALR
    localparam OP_LUI    = 7'b0110111;  // LUI
    localparam OP_AUIPC  = 7'b0010111;  // AUIPC

    always @(*) begin
        // Default: all signals deasserted (NOP-safe)
        reg_write  = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        alu_src    = 1'b0;
        mem_to_reg = 2'b00;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_op     = 2'b00;

        case (opcode)
            OP_RTYPE: begin     // R-type (ADD, SUB, AND, OR, XOR, SLT)
                reg_write  = 1'b1;
                alu_src    = 1'b0;  // operand B from register
                mem_to_reg = 2'b00; // write-back from ALU
                alu_op     = 2'b10; // R-type ALU operation
            end

            OP_IMM: begin       // I-type ALU (ADDI, ANDI, ORI, XORI, SLTI)
                reg_write  = 1'b1;
                alu_src    = 1'b1;  // operand B from immediate
                mem_to_reg = 2'b00; // write-back from ALU
                alu_op     = 2'b11; // I-type ALU operation
            end

            OP_LOAD: begin      // LW
                reg_write  = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;  // base + offset
                mem_to_reg = 2'b01; // write-back from memory
                alu_op     = 2'b00; // ALU does ADD for address calc
            end

            OP_STORE: begin     // SW
                mem_write  = 1'b1;
                alu_src    = 1'b1;  // base + offset
                alu_op     = 2'b00; // ALU does ADD for address calc
            end

            OP_BRANCH: begin    // BEQ, BNE
                branch     = 1'b1;
                alu_src    = 1'b0;  // compare two registers
                alu_op     = 2'b01; // branch comparison (SUB)
            end

            OP_JAL: begin       // JAL
                reg_write  = 1'b1;
                jump       = 1'b1;
                mem_to_reg = 2'b10; // write-back PC+4 (return address)
            end

            OP_JALR: begin      // JALR
                reg_write  = 1'b1;
                alu_src    = 1'b1;  // rs1 + imm
                jump       = 1'b1;
                mem_to_reg = 2'b10; // write-back PC+4
                alu_op     = 2'b00; // ADD for target address
            end

            OP_LUI: begin       // LUI
                reg_write  = 1'b1;
                alu_src    = 1'b1;  // immediate passthrough
                mem_to_reg = 2'b00; // write-back from ALU
                alu_op     = 2'b11; // I-type (ALU control will handle LUI)
            end

            OP_AUIPC: begin     // AUIPC
                reg_write  = 1'b1;
                alu_src    = 1'b1;
                mem_to_reg = 2'b00;
                alu_op     = 2'b00; // ADD (PC + imm, handled in datapath)
            end

            default: begin
                // Unknown opcode — all signals stay at default (NOP)
            end
        endcase
    end

endmodule
