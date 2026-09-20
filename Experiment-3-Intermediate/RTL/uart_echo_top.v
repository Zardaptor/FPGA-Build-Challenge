module uart_echo_top #(
    parameter CLKS_PER_BIT = 160
)(
    input wire clk,
    input wire rst,
    input wire rx,
    output wire tx,
    output reg parity_err_led
);

wire [7:0] rx_data;
wire rx_valid;
wire parity_err;

wire tx_ready;
reg [7:0] tx_data;
reg tx_start;
reg pending_tx;

uart_rx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) rx_inst (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .parity_err(parity_err)
);

uart_tx #(
    .CLKS_PER_BIT(CLKS_PER_BIT)
) tx_inst (
    .clk(clk),
    .rst(rst),
    .tx_data(tx_data),
    .tx_start(tx_start),
    .tx(tx),
    .tx_ready(tx_ready)
);

// Echo logic with simple one-byte buffer and sticky error LED
always @(posedge clk) begin
    if (rst) begin
        tx_start <= 0;
        tx_data <= 0;
        parity_err_led <= 0;
        pending_tx <= 0;
    end else begin
        // Queue data for TX upon successful reception
        if (rx_valid) begin
            tx_data <= rx_data;
            pending_tx <= 1'b1;
        end
        
        // Push data to TX when ready
        if (pending_tx && tx_ready && !tx_start) begin
            tx_start <= 1'b1;
            pending_tx <= 1'b0;
        end else begin
            tx_start <= 1'b0;
        end
        
        // Sticky LED for parity errors
        if (rx_valid && parity_err) begin
            parity_err_led <= 1'b1;
        end
    end
end

endmodule
