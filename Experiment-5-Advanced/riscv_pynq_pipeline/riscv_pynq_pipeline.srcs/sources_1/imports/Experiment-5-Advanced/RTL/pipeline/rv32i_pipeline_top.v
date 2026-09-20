//============================================================================
// Module: rv32i_pipeline_top
// Project: AutoSense RV32I SoC — 5-Stage Pipelined Processor
// Author: Team Suraj | V-SPACE FPGA Build Challenge 2026
//
// Description:
//   5-stage pipelined RISC-V RV32I processor with data forwarding
//   and hazard detection. Each clock cycle, up to 5 instructions
//   can be in-flight simultaneously — one per stage.
//
//   Pipeline Stages:
//     IF  — Instruction Fetch: PC → Instruction Memory
//     ID  — Instruction Decode: Decode + Register Read + Imm Gen
//     EX  — Execute: ALU operation + Branch decision
//     MEM — Memory Access: Data memory load/store
//     WB  — Write Back: Write result to register file
//
//   Hazard Handling:
//     - RAW data hazards: Resolved by forwarding unit (EX→EX, MEM→EX)
//     - Load-use hazards: 1-cycle stall + forwarding
//     - Control hazards: 2-cycle flush on branch taken / jump
//
//   This design mirrors the ARM Cortex-M0+ pipeline in NXP's
//   LPC and MCX microcontroller families.
//
// Port List:
//   clk            - System clock
//   rst            - Active-high synchronous reset
//   debug_pc       - Current PC (for testbench)
//   debug_instr    - Current instruction in IF stage
//   debug_reg_a0   - Register x10 (a0) value
//   debug_cycle_count - Total cycles executed
//============================================================================

module rv32i_pipeline_top (
    input  wire        clk,
    input  wire        rst,
    // Debug outputs
    output wire [31:0] debug_pc,
    output wire [31:0] debug_instr,
    output wire [31:0] debug_alu_result,
    output wire [31:0] debug_reg_a0,
    output wire [31:0] debug_cycle_count
);

    //========================================================================
    // Performance Counter — counts total clock cycles
    //========================================================================
    reg [31:0] cycle_counter;
    always @(posedge clk) begin
        if (rst)
            cycle_counter <= 32'd0;
        else
            cycle_counter <= cycle_counter + 32'd1;
    end
    assign debug_cycle_count = cycle_counter;

    //========================================================================
    // Hazard Control Signals
    //========================================================================
    wire stall_if, stall_id;
    wire flush_id, flush_ex;
    wire branch_taken;
    wire jump_taken_ex;    // jump signal from EX stage
    wire [31:0] pc_branch_target;

    //========================================================================
    //  STAGE 1: INSTRUCTION FETCH (IF)
    //========================================================================
    
    reg  [31:0] pc;
    wire [31:0] pc_plus4_if;
    wire [31:0] pc_next;
    wire [31:0] instr_if;

    // PC + 4
    assign pc_plus4_if = pc + 32'd4;

    // Next PC logic
    //   Branch/jump target from EX stage has priority
    //   Then normal PC+4, unless stalled
    assign pc_next = (branch_taken || jump_taken_ex) ? pc_branch_target :
                                                       pc_plus4_if;

    // PC register with stall support
    always @(posedge clk) begin
        if (rst)
            pc <= 32'd0;
        else if (!stall_if)
            pc <= pc_next;
        // If stall_if, PC holds its value
    end

    // Instruction Memory (shared with single-cycle design)
    instruction_memory u_imem (
        .addr  (pc),
        .instr (instr_if)
    );

    //========================================================================
    //  IF/ID PIPELINE REGISTER
    //========================================================================
    
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc_plus4;
    reg [31:0] if_id_instr;

    always @(posedge clk) begin
        if (rst || flush_id) begin
            // Flush: insert NOP (addi x0, x0, 0 = 0x00000013)
            if_id_pc       <= 32'd0;
            if_id_pc_plus4 <= 32'd0;
            if_id_instr    <= 32'h0000_0013;  // NOP
        end
        else if (!stall_id) begin
            if_id_pc       <= pc;
            if_id_pc_plus4 <= pc_plus4_if;
            if_id_instr    <= instr_if;
        end
        // If stall_id, register holds its value
    end

    //========================================================================
    //  STAGE 2: INSTRUCTION DECODE (ID)
    //========================================================================
    
    // Instruction field extraction
    wire [6:0]  opcode_id   = if_id_instr[6:0];
    wire [4:0]  rd_id       = if_id_instr[11:7];
    wire [2:0]  funct3_id   = if_id_instr[14:12];
    wire [4:0]  rs1_id      = if_id_instr[19:15];
    wire [4:0]  rs2_id      = if_id_instr[24:20];
    wire        funct7_5_id = if_id_instr[30];

    // Control Unit
    wire        reg_write_id;
    wire        mem_read_id;
    wire        mem_write_id;
    wire        alu_src_id;
    wire [1:0]  mem_to_reg_id;
    wire        branch_id;
    wire        jump_id;
    wire [1:0]  alu_op_id;

    control_unit u_ctrl (
        .opcode    (opcode_id),
        .reg_write (reg_write_id),
        .mem_read  (mem_read_id),
        .mem_write (mem_write_id),
        .alu_src   (alu_src_id),
        .mem_to_reg(mem_to_reg_id),
        .branch    (branch_id),
        .jump      (jump_id),
        .alu_op    (alu_op_id)
    );

    // Register File — write in WB stage, read in ID stage
    wire        reg_write_wb;
    wire [4:0]  rd_wb;
    wire [31:0] write_data_wb;
    wire [31:0] reg_rd1_id;
    wire [31:0] reg_rd2_id;

    register_file u_regfile (
        .clk (clk),
        .rst (rst),
        .we  (reg_write_wb),
        .rs1 (rs1_id),
        .rs2 (rs2_id),
        .rd  (rd_wb),
        .wd  (write_data_wb),
        .rd1 (reg_rd1_id),
        .rd2 (reg_rd2_id),
        .a0_out (debug_reg_a0)
    );

    // Immediate Generator
    wire [31:0] imm_id;

    imm_gen u_immgen (
        .instr (if_id_instr),
        .imm   (imm_id)
    );

    //========================================================================
    //  ID/EX PIPELINE REGISTER
    //========================================================================
    
    // Data signals
    reg [31:0] id_ex_pc;
    reg [31:0] id_ex_pc_plus4;
    reg [31:0] id_ex_rd1;
    reg [31:0] id_ex_rd2;
    reg [31:0] id_ex_imm;
    reg [4:0]  id_ex_rs1;
    reg [4:0]  id_ex_rs2;
    reg [4:0]  id_ex_rd;
    reg [2:0]  id_ex_funct3;
    reg        id_ex_funct7_5;
    reg [6:0]  id_ex_opcode;

    // Control signals
    reg        id_ex_reg_write;
    reg        id_ex_mem_read;
    reg        id_ex_mem_write;
    reg        id_ex_alu_src;
    reg [1:0]  id_ex_mem_to_reg;
    reg        id_ex_branch;
    reg        id_ex_jump;
    reg [1:0]  id_ex_alu_op;

    always @(posedge clk) begin
        if (rst || flush_ex) begin
            // Flush: zero all control signals (creates a bubble/NOP)
            id_ex_pc         <= 32'd0;
            id_ex_pc_plus4   <= 32'd0;
            id_ex_rd1        <= 32'd0;
            id_ex_rd2        <= 32'd0;
            id_ex_imm        <= 32'd0;
            id_ex_rs1        <= 5'd0;
            id_ex_rs2        <= 5'd0;
            id_ex_rd         <= 5'd0;
            id_ex_funct3     <= 3'd0;
            id_ex_funct7_5   <= 1'b0;
            id_ex_opcode     <= 7'd0;
            // Control — all deasserted = NOP
            id_ex_reg_write  <= 1'b0;
            id_ex_mem_read   <= 1'b0;
            id_ex_mem_write  <= 1'b0;
            id_ex_alu_src    <= 1'b0;
            id_ex_mem_to_reg <= 2'b00;
            id_ex_branch     <= 1'b0;
            id_ex_jump       <= 1'b0;
            id_ex_alu_op     <= 2'b00;
        end
        else begin
            id_ex_pc         <= if_id_pc;
            id_ex_pc_plus4   <= if_id_pc_plus4;
            id_ex_rd1        <= reg_rd1_id;
            id_ex_rd2        <= reg_rd2_id;
            id_ex_imm        <= imm_id;
            id_ex_rs1        <= rs1_id;
            id_ex_rs2        <= rs2_id;
            id_ex_rd         <= rd_id;
            id_ex_funct3     <= funct3_id;
            id_ex_funct7_5   <= funct7_5_id;
            id_ex_opcode     <= opcode_id;
            // Control signals
            id_ex_reg_write  <= reg_write_id;
            id_ex_mem_read   <= mem_read_id;
            id_ex_mem_write  <= mem_write_id;
            id_ex_alu_src    <= alu_src_id;
            id_ex_mem_to_reg <= mem_to_reg_id;
            id_ex_branch     <= branch_id;
            id_ex_jump       <= jump_id;
            id_ex_alu_op     <= alu_op_id;
        end
    end

    //========================================================================
    //  STAGE 3: EXECUTE (EX)
    //========================================================================
    
    // Forwarding Unit
    wire [1:0]  forward_a;
    wire [1:0]  forward_b;
    wire        ex_mem_reg_write;
    wire [4:0]  ex_mem_rd_wire;

    forwarding_unit u_fwd (
        .ex_mem_reg_write (ex_mem_reg_write),
        .mem_wb_reg_write (reg_write_wb),
        .ex_mem_rd        (ex_mem_rd_wire),
        .mem_wb_rd        (rd_wb),
        .id_ex_rs1        (id_ex_rs1),
        .id_ex_rs2        (id_ex_rs2),
        .forward_a        (forward_a),
        .forward_b        (forward_b)
    );

    // Forwarded ALU input muxes
    wire [31:0] ex_mem_alu_result_wire;
    wire [31:0] alu_src_a;
    wire [31:0] alu_src_b_reg;  // forwarded register value (before ALU src mux)
    wire [31:0] alu_src_b;      // final ALU input B

    // Forward mux for operand A
    assign alu_src_a = (forward_a == 2'b10) ? ex_mem_alu_result_wire :  // EX/MEM forward
                       (forward_a == 2'b01) ? write_data_wb :            // MEM/WB forward
                                              id_ex_rd1;                 // No forward

    // Forward mux for operand B (register value, before ALU source select)
    assign alu_src_b_reg = (forward_b == 2'b10) ? ex_mem_alu_result_wire :
                           (forward_b == 2'b01) ? write_data_wb :
                                                  id_ex_rd2;

    // ALU source B: forwarded register value OR immediate
    assign alu_src_b = (id_ex_alu_src) ? id_ex_imm : alu_src_b_reg;

    // ALU Control
    wire [3:0] alu_ctrl;

    alu_control u_alu_ctrl (
        .alu_op   (id_ex_alu_op),
        .funct3   (id_ex_funct3),
        .funct7_5 (id_ex_funct7_5),
        .opcode_5 (id_ex_opcode[5]),
        .alu_ctrl (alu_ctrl)
    );

    // ALU
    wire [31:0] alu_result_ex;
    wire        alu_zero_ex;

    alu_32bit u_alu (
        .a      (alu_src_a),
        .b      (alu_src_b),
        .alu_op (alu_ctrl),
        .result (alu_result_ex),
        .zero   (alu_zero_ex)
    );

    // Branch decision (in EX stage)
    //   BEQ (funct3[0]=0): branch if zero flag SET
    //   BNE (funct3[0]=1): branch if zero flag CLEAR
    assign branch_taken = id_ex_branch & (alu_zero_ex ^ id_ex_funct3[0]);

    // Jump target calculation
    wire [31:0] jump_target_ex;
    assign jump_target_ex = (id_ex_opcode == 7'b1100111) ? alu_result_ex :   // JALR: rs1+imm
                                                           id_ex_pc + id_ex_imm; // JAL: PC+imm

    // Branch/jump target
    assign pc_branch_target = id_ex_branch ? (id_ex_pc + id_ex_imm) : jump_target_ex;
    assign jump_taken_ex = id_ex_jump;

    //========================================================================
    //  EX/MEM PIPELINE REGISTER
    //========================================================================
    
    reg [31:0] ex_mem_pc_plus4;
    reg [31:0] ex_mem_alu_result;
    reg [31:0] ex_mem_rd2;          // Store data (forwarded)
    reg [4:0]  ex_mem_rd;
    // Control
    reg        ex_mem_reg_write_r;
    reg        ex_mem_mem_read;
    reg        ex_mem_mem_write;
    reg [1:0]  ex_mem_mem_to_reg;

    always @(posedge clk) begin
        if (rst) begin
            ex_mem_pc_plus4    <= 32'd0;
            ex_mem_alu_result  <= 32'd0;
            ex_mem_rd2         <= 32'd0;
            ex_mem_rd          <= 5'd0;
            ex_mem_reg_write_r <= 1'b0;
            ex_mem_mem_read    <= 1'b0;
            ex_mem_mem_write   <= 1'b0;
            ex_mem_mem_to_reg  <= 2'b00;
        end
        else begin
            ex_mem_pc_plus4    <= id_ex_pc_plus4;
            ex_mem_alu_result  <= alu_result_ex;
            ex_mem_rd2         <= alu_src_b_reg;  // Use forwarded value for store data
            ex_mem_rd          <= id_ex_rd;
            ex_mem_reg_write_r <= id_ex_reg_write;
            ex_mem_mem_read    <= id_ex_mem_read;
            ex_mem_mem_write   <= id_ex_mem_write;
            ex_mem_mem_to_reg  <= id_ex_mem_to_reg;
        end
    end

    // Wire aliases for forwarding unit
    assign ex_mem_reg_write     = ex_mem_reg_write_r;
    assign ex_mem_rd_wire       = ex_mem_rd;
    assign ex_mem_alu_result_wire = ex_mem_alu_result;

    //========================================================================
    //  STAGE 4: MEMORY ACCESS (MEM)
    //========================================================================
    
    wire [31:0] mem_rdata;

    data_memory u_dmem (
        .clk       (clk),
        .mem_read  (ex_mem_mem_read),
        .mem_write (ex_mem_mem_write),
        .addr      (ex_mem_alu_result),
        .wdata     (ex_mem_rd2),
        .rdata     (mem_rdata)
    );

    //========================================================================
    //  MEM/WB PIPELINE REGISTER
    //========================================================================
    
    reg [31:0] mem_wb_pc_plus4;
    reg [31:0] mem_wb_alu_result;
    reg [31:0] mem_wb_mem_rdata;
    reg [4:0]  mem_wb_rd;
    reg        mem_wb_reg_write;
    reg [1:0]  mem_wb_mem_to_reg;

    always @(posedge clk) begin
        if (rst) begin
            mem_wb_pc_plus4   <= 32'd0;
            mem_wb_alu_result <= 32'd0;
            mem_wb_mem_rdata  <= 32'd0;
            mem_wb_rd         <= 5'd0;
            mem_wb_reg_write  <= 1'b0;
            mem_wb_mem_to_reg <= 2'b00;
        end
        else begin
            mem_wb_pc_plus4   <= ex_mem_pc_plus4;
            mem_wb_alu_result <= ex_mem_alu_result;
            mem_wb_mem_rdata  <= mem_rdata;
            mem_wb_rd         <= ex_mem_rd;
            mem_wb_reg_write  <= ex_mem_reg_write_r;
            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;
        end
    end

    //========================================================================
    //  STAGE 5: WRITE BACK (WB)
    //========================================================================
    
    // Write-back mux: ALU result, Memory data, or PC+4
    assign write_data_wb = (mem_wb_mem_to_reg == 2'b01) ? mem_wb_mem_rdata :
                           (mem_wb_mem_to_reg == 2'b10) ? mem_wb_pc_plus4 :
                                                          mem_wb_alu_result;

    // Write-back control (directly to register file)
    assign reg_write_wb = mem_wb_reg_write;
    assign rd_wb        = mem_wb_rd;

    //========================================================================
    //  HAZARD DETECTION UNIT
    //========================================================================
    
    hazard_unit u_hazard (
        .id_ex_mem_read (id_ex_mem_read),
        .id_ex_rd       (id_ex_rd),
        .if_id_rs1      (rs1_id),
        .if_id_rs2      (rs2_id),
        .branch_taken   (branch_taken),
        .jump_taken     (jump_taken_ex),
        .stall_if       (stall_if),
        .stall_id       (stall_id),
        .flush_id       (flush_id),
        .flush_ex       (flush_ex)
    );

    //========================================================================
    //  DEBUG OUTPUTS
    //========================================================================
    
    assign debug_pc         = pc;
    assign debug_instr      = instr_if;
    assign debug_alu_result = alu_result_ex;
    // assign debug_reg_a0 removed (now connected directly to port)

endmodule
