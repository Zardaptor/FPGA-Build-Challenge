//============================================================================
// Module: rv32i_top
// Project: RISC-V RV32I Single-Cycle Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   Top-level datapath for the single-cycle RV32I processor.
//   Connects all sub-modules: PC, instruction memory, register file,
//   ALU, control unit, ALU control, immediate generator, data memory.
//
//   This is a complete processor core — the kind of IP block that
//   NXP designs as part of their Quintauris RISC-V initiative.
//
//   Supported Instructions:
//     R-type: ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA, SLTU
//     I-type: ADDI, ANDI, ORI, XORI, SLTI, SLTIU, SLLI, SRLI, SRAI, LW, JALR
//     S-type: SW
//     B-type: BEQ, BNE
//     U-type: LUI, AUIPC
//     J-type: JAL
//
// Datapath Flow:
//   PC → Instruction Memory → Decode → Register File → ALU → Data Memory
//              ↓                              ↓
//        Control Unit                   Write-back Mux
//              ↓                              ↓
//        ALU Control                   Register File (WB)
//
// Port List:
//   clk       - System clock
//   rst       - Active-high synchronous reset
//   (debug outputs for testbench observation)
//============================================================================

module rv32i_top (
    input  wire        clk,
    input  wire        rst,
    // Debug outputs — exposed for testbench and FPGA verification
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instr,
    output wire [31:0] debug_alu_result,
    output wire [31:0] debug_reg_a0       // Register x10 (a0) — program output
);

    //========================================================================
    // Internal Wires
    //========================================================================

    // PC signals
    wire [31:0] pc_current;
    wire [31:0] pc_plus4;
    wire [31:0] pc_next;
    wire [31:0] pc_branch_target;
    wire [31:0] pc_jump_target;

    // Instruction
    wire [31:0] instr;

    // Control signals
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire        alu_src;
    wire [1:0]  mem_to_reg;
    wire        branch;
    wire        jump;
    wire [1:0]  alu_op;

    // Register file signals
    wire [31:0] reg_rd1;
    wire [31:0] reg_rd2;
    wire [31:0] reg_write_data;

    // ALU signals
    wire [31:0] alu_input_b;
    wire [31:0] alu_result;
    wire        alu_zero;
    wire [3:0]  alu_ctrl;

    // Immediate
    wire [31:0] imm;

    // Data memory
    wire [31:0] mem_rdata;

    // Branch decision
    wire        branch_taken;
    wire        funct3_0;  // funct3[0] distinguishes BEQ(0) from BNE(1)

    //========================================================================
    // Instruction Field Extraction
    //========================================================================
    wire [6:0] opcode  = instr[6:0];
    wire [4:0] rd_addr = instr[11:7];
    wire [2:0] funct3  = instr[14:12];
    wire [4:0] rs1     = instr[19:15];
    wire [4:0] rs2     = instr[24:20];
    wire       funct7_5 = instr[30];

    //========================================================================
    // Module Instantiations
    //========================================================================

    // --- Program Counter ---
    program_counter u_pc (
        .clk     (clk),
        .rst     (rst),
        .pc_next (pc_next),
        .pc      (pc_current)
    );

    // PC + 4 (next sequential instruction)
    assign pc_plus4 = pc_current + 32'd4;

    // --- Instruction Memory ---
    instruction_memory u_imem (
        .addr  (pc_current),
        .instr (instr)
    );

    // --- Control Unit ---
    control_unit u_ctrl (
        .opcode    (opcode),
        .reg_write (reg_write),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .alu_src   (alu_src),
        .mem_to_reg(mem_to_reg),
        .branch    (branch),
        .jump      (jump),
        .alu_op    (alu_op)
    );

    // --- Register File ---
    register_file u_regfile (
        .clk (clk),
        .rst (rst),
        .we  (reg_write),
        .rs1 (rs1),
        .rs2 (rs2),
        .rd  (rd_addr),
        .wd  (reg_write_data),
        .rd1 (reg_rd1),
        .rd2 (reg_rd2)
    );

    // --- Immediate Generator ---
    imm_gen u_immgen (
        .instr (instr),
        .imm   (imm)
    );

    // --- ALU Source Mux ---
    // Select between register (R-type) and immediate (I-type, loads, stores)
    assign alu_input_b = (alu_src) ? imm : reg_rd2;

    // --- ALU Control ---
    alu_control u_alu_ctrl (
        .alu_op   (alu_op),
        .funct3   (funct3),
        .funct7_5 (funct7_5),
        .opcode_5 (opcode[5]),
        .alu_ctrl (alu_ctrl)
    );

    // --- ALU ---
    alu_32bit u_alu (
        .a      (reg_rd1),
        .b      (alu_input_b),
        .alu_op (alu_ctrl),
        .result (alu_result),
        .zero   (alu_zero)
    );

    // --- Data Memory ---
    data_memory u_dmem (
        .clk       (clk),
        .mem_read  (mem_read),
        .mem_write (mem_write),
        .addr      (alu_result),
        .wdata     (reg_rd2),
        .rdata     (mem_rdata)
    );

    //========================================================================
    // Write-Back Mux
    //========================================================================
    // Select what data gets written back to the register file:
    //   00 = ALU result   (R-type, I-type ALU, LUI)
    //   01 = Memory data  (LW)
    //   10 = PC + 4       (JAL, JALR — return address)
    assign reg_write_data = (mem_to_reg == 2'b01) ? mem_rdata :
                            (mem_to_reg == 2'b10) ? pc_plus4 :
                                                    alu_result;

    //========================================================================
    // Branch / Jump Logic
    //========================================================================
    assign funct3_0 = funct3[0];

    // Branch taken logic:
    //   BEQ (funct3[0]=0): branch if zero flag is SET
    //   BNE (funct3[0]=1): branch if zero flag is CLEAR
    assign branch_taken = branch & (alu_zero ^ funct3_0);

    // Branch target: PC + immediate (B-type immediate is already shifted)
    assign pc_branch_target = pc_current + imm;

    // Jump target: PC + immediate (JAL) — for JALR, it's rs1 + imm via ALU
    assign pc_jump_target = (opcode == 7'b1100111) ? alu_result :  // JALR: rs1 + imm
                                                     pc_current + imm;  // JAL: PC + imm

    // Next PC Mux
    //   Priority: Jump > Branch > PC+4
    assign pc_next = (jump)         ? pc_jump_target :
                     (branch_taken) ? pc_branch_target :
                                     pc_plus4;

    //========================================================================
    // Debug Outputs
    //========================================================================
    assign debug_pc         = pc_current;
    assign debug_instr      = instr;
    assign debug_alu_result = alu_result;

    // Expose register x10 (a0) for program output verification
    // We read it through the register file's rs1 port when not in use,
    // but for cleanliness, we directly access the register array
    // Note: This works because register_file exposes registers as a reg array
    // For synthesis, we add a dedicated read port:
    assign debug_reg_a0 = u_regfile.registers[10];

endmodule
