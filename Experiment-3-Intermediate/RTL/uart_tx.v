module uart_tx #(
    parameter CLKS_PER_BIT = 160
)(
    input wire clk,
    input wire rst,
    input wire [7:0] tx_data,
    input wire tx_start,
    output reg tx,
    output reg tx_ready
);

localparam IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP = 4;
reg [2:0] state;
reg [15:0] clk_cnt;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg calc_parity;

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        tx <= 1'b1;
        tx_ready <= 1'b1;
        clk_cnt <= 0;
        bit_cnt <= 0;
        shift_reg <= 0;
        calc_parity <= 0;
    end else begin
        case (state)
            IDLE: begin
                tx <= 1'b1;
                tx_ready <= 1'b1;
                if (tx_start) begin
                    state <= START;
                    tx_ready <= 1'b0;
                    shift_reg <= tx_data;
                    calc_parity <= ^tx_data; // Even parity generation
                    clk_cnt <= 0;
                end
            end
            START: begin
                tx <= 1'b0; // Start bit
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 0;
                    state <= DATA;
                    bit_cnt <= 0;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            DATA: begin
                tx <= shift_reg[0]; // Send LSB first
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 0;
                    shift_reg <= {1'b0, shift_reg[7:1]};
                    if (bit_cnt == 7) begin
                        state <= PARITY;
                    end else begin
                        bit_cnt <= bit_cnt + 1;
                    end
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            PARITY: begin
                tx <= calc_parity; // Send calculated parity bit
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 0;
                    state <= STOP;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            STOP: begin
                tx <= 1'b1; // Stop bit
                if (clk_cnt == CLKS_PER_BIT - 1) begin
                    clk_cnt <= 0;
                    state <= IDLE;
                end else begin
                    clk_cnt <= clk_cnt + 1;
                end
            end
            default: state <= IDLE;
        endcase
    end
end
endmodule
