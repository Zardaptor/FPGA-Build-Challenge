import os

srcs_dir = r"c:\Users\suraj\Desktop\Projects\FPGA\FPGA-Build-Challenge-Suraj\Experiment-5-Advanced\riscv_pynq_pipeline\riscv_pynq_pipeline.srcs"

for root, dirs, files in os.walk(srcs_dir):
    if "instruction_memory.v" in files:
        with open(os.path.join(root, "instruction_memory.v"), "w") as f:
            f.write('''module instruction_memory(
    input wire [31:0] addr,
    output reg [31:0] instr
);
    wire [31:0] word_addr = addr >> 2;
    always @(*) begin
        case (word_addr)
            32'd0: instr = 32'h00000293; // addi x5, x0, 0
            32'd1: instr = 32'h00100093; // addi x1, x0, 1
            32'd2: instr = 32'h00000113; // addi x2, x0, 0
            32'd3: instr = 32'h00a00193; // addi x3, x0, 10
            32'd4: instr = 32'h00000213; // addi x4, x0, 0
            32'd5: instr = 32'h00208333; // add x6, x1, x2
            32'd6: instr = 32'h0062a023; // sw x6, 0(x5)
            32'd7: instr = 32'h00008533; // add x10, x0, x1
            32'd8: instr = 32'h002080b3; // add x1, x0, x2
            32'd9: instr = 32'h00608133; // add x2, x0, x6
            32'd10: instr = 32'h00428293; // addi x5, x5, 4
            32'd11: instr = 32'h00120213; // addi x4, x4, 1
            32'd12: instr = 32'hfe3214e3; // bne x4, x3, -24
            32'd13: instr = 32'h0000006f; // jal x0, 0
            default: instr = 32'h00000013; // nop
        endcase
    end
endmodule
''')
    if "register_file.v" in files:
        with open(os.path.join(root, "register_file.v"), "w") as f:
            f.write('''module register_file (
    input  wire        clk,
    input  wire        rst,
    input  wire        we,
    input  wire [4:0]  rs1,
    input  wire [4:0]  rs2,
    input  wire [4:0]  rd,
    input  wire [31:0] wd,
    output wire [31:0] rd1,
    output wire [31:0] rd2,
    output wire [31:0] a0_out
);
    reg [31:0] registers [31:0];
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'd0;
        end else if (we && (rd != 5'd0)) begin
            registers[rd] <= wd;
        end
    end
    assign rd1 = (rs1 == 5'd0) ? 32'd0 : registers[rs1];
    assign rd2 = (rs2 == 5'd0) ? 32'd0 : registers[rs2];
    assign a0_out = registers[10];
endmodule
''')
    if "rv32i_pipeline_top.v" in files:
        top_file = os.path.join(root, "rv32i_pipeline_top.v")
        with open(top_file, "r") as f:
            content = f.read()
        content = content.replace(".rd2 (reg_rd2_id)", ".rd2 (reg_rd2_id),\n        .a0_out (debug_reg_a0)")
        content = content.replace("assign debug_reg_a0     = u_regfile.registers[10];", "// assign debug_reg_a0 removed (now connected directly to port)")
        with open(top_file, "w") as f:
            f.write(content)

print("Fixed Vivado copies successfully!")
