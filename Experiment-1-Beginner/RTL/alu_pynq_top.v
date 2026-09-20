module alu_pynq_top (
    input  wire clk,
    input  wire [3:0] btn,
    output wire [3:0] led,
    output wire led4_r,
    output wire led4_g,
    output wire led4_b,
    output wire led5_r
);
    wire rst = btn[0];

    // 1 Hz Clock Divider for Visual Demo
    reg [25:0] clk_cnt;
    reg slow_clk;
    always @(posedge clk) begin
        if (rst) begin
            clk_cnt <= 0;
            slow_clk <= 0;
        end else if (clk_cnt == 26'd62_499_999) begin
            clk_cnt <= 0;
            slow_clk <= ~slow_clk;
        end else begin
            clk_cnt <= clk_cnt + 1;
        end
    end

    // Auto-Tester State Machine
    reg [2:0] state;
    reg [7:0] a, b;
    reg [2:0] opcode;
    
    always @(posedge slow_clk or posedge rst) begin
        if (rst) begin
            state <= 0;
            a <= 0; b <= 0; opcode <= 0;
        end else begin
            state <= state + 1;
            case (state)
                // Cycle through math tests to trigger different NZCV flags
                3'd0: begin a <= 8'd10;  b <= 8'd5; opcode <= 3'd0; end // ADD: 15 (No flags)
                3'd1: begin a <= 8'd5;   b <= 8'd10; opcode <= 3'd1; end // SUB: -5 (Negative flag)
                3'd2: begin a <= 8'd255; b <= 8'd1; opcode <= 3'd0; end // ADD: 0  (Carry & Zero flag)
                3'd3: begin a <= 8'd4;   b <= 8'd2; opcode <= 3'd7; end // MUL: 8  (No flags)
                3'd4: begin a <= 8'd15;  b <= 8'd15; opcode <= 3'd2; end // AND: 15
                3'd5: begin a <= 8'd127; b <= 8'd2; opcode <= 3'd0; end // ADD: 129 (Overflow flag)
                default: begin a <= 8'd0; b <= 8'd0; opcode <= 3'd0; end
            endcase
        end
    end

    // Instantiate Advanced ALU
    wire [7:0] result;
    wire n, z, c, v;
    alu_advanced #( .WIDTH(8) ) u_alu (
        .a(a), .b(b), .opcode(opcode),
        .result(result),
        .N(n), .Z(z), .C(c), .V(v)
    );

    // Map NZCV Flags to the 4 main Green LEDs
    assign led[0] = n; // Negative
    assign led[1] = z; // Zero
    assign led[2] = c; // Carry
    assign led[3] = v; // Overflow

    // Map lower 4 bits of result to RGB LEDs
    assign led4_r = result[0];
    assign led4_g = result[1];
    assign led4_b = result[2];
    assign led5_r = result[3];

endmodule
