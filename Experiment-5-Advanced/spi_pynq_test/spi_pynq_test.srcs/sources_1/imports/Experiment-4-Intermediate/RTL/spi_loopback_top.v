module spi_loopback_top (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] switch_in,
    input  wire       send_btn,
    input  wire       cpol_sw,
    input  wire       cpha_sw,
    input  wire       slave_select_sw,
    output wire [7:0] led_out
);

    reg [2:0] btn_r;
    always @(posedge clk or posedge rst) begin
        if (rst) btn_r <= 0;
        else btn_r <= {btn_r[1:0], send_btn};
    end
    wire start = (btn_r[2:1] == 2'b01);

    wire sck, mosi, miso, cs;
    wire [7:0] master_data_out;
    wire master_valid;
    wire master_busy;

    spi_master master_inst (
        .clk(clk),
        .rst(rst),
        .cpol(cpol_sw),
        .cpha(cpha_sw),
        .start(start),
        .data_in(switch_in),
        .busy(master_busy),
        .data_out(master_data_out),
        .data_valid(master_valid),
        .sck(sck),
        .mosi(mosi),
        .miso(miso),
        .cs(cs)
    );

    wire cs0 = (slave_select_sw == 0) ? cs : 1'b1;
    wire cs1 = (slave_select_sw == 1) ? cs : 1'b1;

    wire miso0, miso1;
    wire [7:0] slave0_data_out, slave1_data_out;
    wire slave0_valid, slave1_valid;

    spi_slave slave0_inst (
        .clk(clk),
        .rst(rst),
        .cpol(cpol_sw),
        .cpha(cpha_sw),
        .sck(sck),
        .mosi(mosi),
        .miso(miso0),
        .cs(cs0),
        .data_out(slave0_data_out),
        .data_valid(slave0_valid),
        .data_in(~switch_in)
    );

    spi_slave slave1_inst (
        .clk(clk),
        .rst(rst),
        .cpol(cpol_sw),
        .cpha(cpha_sw),
        .sck(sck),
        .mosi(mosi),
        .miso(miso1),
        .cs(cs1),
        .data_out(slave1_data_out),
        .data_valid(slave1_valid),
        .data_in(~switch_in)
    );

    assign miso = (slave_select_sw == 0) ? miso0 : miso1;

    reg [7:0] led_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            led_reg <= 0;
        end else begin
            if (slave_select_sw == 0 && slave0_valid) begin
                led_reg <= slave0_data_out;
            end else if (slave_select_sw == 1 && slave1_valid) begin
                led_reg <= slave1_data_out;
            end
        end
    end
    assign led_out = led_reg;

endmodule
