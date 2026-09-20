module uart_rx #(
    parameter CLKS_PER_BIT = 160
)(
    input wire clk,
    input wire rst,
    input wire rx,
    output reg [7:0] rx_data,
    output reg rx_valid,
    output reg parity_err
);

localparam OVERSAMPLE_TICKS = CLKS_PER_BIT / 16;
reg [15:0] tick_cnt;
reg tick;

// Generate oversampling tick (16x baud rate)
always @(posedge clk) begin
    if (rst) begin
        tick_cnt <= 0;
        tick <= 0;
    end else begin
        if (tick_cnt >= OVERSAMPLE_TICKS - 1) begin
            tick_cnt <= 0;
            tick <= 1;
        end else begin
            tick_cnt <= tick_cnt + 1;
            tick <= 0;
        end
    end
end

// Double flop synchronizer for rx
reg rx_sync1, rx_sync2;
always @(posedge clk) begin
    if (rst) begin
        rx_sync1 <= 1'b1;
        rx_sync2 <= 1'b1;
    end else begin
        rx_sync1 <= rx;
        rx_sync2 <= rx_sync1;
    end
end

localparam IDLE = 0, START = 1, DATA = 2, PARITY = 3, STOP = 4;
reg [2:0] state;
reg [3:0] os_cnt;
reg [2:0] bit_cnt;
reg [7:0] shift_reg;
reg calc_parity;

always @(posedge clk) begin
    if (rst) begin
        state <= IDLE;
        os_cnt <= 0;
        bit_cnt <= 0;
        rx_valid <= 0;
        parity_err <= 0;
        rx_data <= 0;
        shift_reg <= 0;
        calc_parity <= 0;
    end else begin
        rx_valid <= 0; // default to 0, pulses for 1 cycle when valid
        
        if (tick) begin
            case (state)
                IDLE: begin
                    if (rx_sync2 == 0) begin
                        state <= START;
                        os_cnt <= 1;
                    end
                end
                START: begin
                    // Sample middle of start bit
                    if (os_cnt == 7) begin
                        if (rx_sync2 == 0) begin
                            os_cnt <= os_cnt + 1;
                        end else begin
                            state <= IDLE; // False start
                        end
                    end else if (os_cnt == 15) begin
                        state <= DATA;
                        os_cnt <= 0;
                        bit_cnt <= 0;
                        calc_parity <= 0; // Even parity
                    end else begin
                        os_cnt <= os_cnt + 1;
                    end
                end
                DATA: begin
                    if (os_cnt == 7) begin
                        shift_reg <= {rx_sync2, shift_reg[7:1]};
                        calc_parity <= calc_parity ^ rx_sync2;
                        os_cnt <= os_cnt + 1;
                    end else if (os_cnt == 15) begin
                        os_cnt <= 0;
                        if (bit_cnt == 7) begin
                            state <= PARITY;
                        end else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end else begin
                        os_cnt <= os_cnt + 1;
                    end
                end
                PARITY: begin
                    if (os_cnt == 7) begin
                        // Check parity against received bit
                        parity_err <= (calc_parity != rx_sync2);
                        os_cnt <= os_cnt + 1;
                    end else if (os_cnt == 15) begin
                        state <= STOP;
                        os_cnt <= 0;
                    end else begin
                        os_cnt <= os_cnt + 1;
                    end
                end
                STOP: begin
                    if (os_cnt == 15) begin
                        state <= IDLE;
                        rx_valid <= 1;
                        rx_data <= shift_reg;
                    end else begin
                        os_cnt <= os_cnt + 1;
                    end
                end
                default: state <= IDLE;
            endcase
        end
    end
end
endmodule
