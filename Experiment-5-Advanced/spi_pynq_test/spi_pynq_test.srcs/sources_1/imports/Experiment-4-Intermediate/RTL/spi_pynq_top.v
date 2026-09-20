module spi_pynq_top (
    input  wire       clk,      // 125 MHz
    input  wire [0:0] btn,      // btn[0] for rst
    output wire [3:0] led
);

    wire rst = btn[0];

    // 1 Hz tick generator (125 MHz clock)
    reg [26:0] counter_1hz;
    wire tick_1hz = (counter_1hz == 27'd124_999_999);
    
    always @(posedge clk) begin
        if (rst) begin
            counter_1hz <= 0;
        end else begin
            if (tick_1hz)
                counter_1hz <= 0;
            else
                counter_1hz <= counter_1hz + 1;
        end
    end

    // State machine to cycle through CPOL, CPHA, and slave_select
    reg [2:0] config_state;
    always @(posedge clk) begin
        if (rst) begin
            config_state <= 0;
        end else if (tick_1hz) begin
            config_state <= config_state + 1;
        end
    end

    wire cpol_sw = config_state[2];
    wire cpha_sw = config_state[1];
    wire slave_select_sw = config_state[0];

    // Dummy data to feed into switch_in
    wire [7:0] dummy_data = {5'b10101, config_state}; 

    // Trigger send_btn periodically (e.g., halfway through the 1 second period)
    reg send_btn_reg;
    always @(posedge clk) begin
        if (rst) begin
            send_btn_reg <= 0;
        end else begin
            if (counter_1hz == 27'd62_500_000)
                send_btn_reg <= 1'b1;
            else
                send_btn_reg <= 1'b0;
        end
    end

    wire [7:0] led_out;

    // Instantiate the loopback top
    spi_loopback_top u_spi_loopback (
        .clk             (clk),
        .rst             (rst),
        .switch_in       (dummy_data),
        .send_btn        (send_btn_reg),
        .cpol_sw         (cpol_sw),
        .cpha_sw         (cpha_sw),
        .slave_select_sw (slave_select_sw),
        .led_out         (led_out)
    );

    // Map output to board LEDs
    assign led = led_out[3:0];

endmodule
