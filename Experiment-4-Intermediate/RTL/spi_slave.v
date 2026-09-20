module spi_slave (
    input  wire       clk,
    input  wire       rst,
    input  wire       cpol,
    input  wire       cpha,
    
    input  wire       sck,
    input  wire       mosi,
    output reg        miso,
    input  wire       cs,
    
    output reg  [7:0] data_out,
    output reg        data_valid,
    input  wire [7:0] data_in
);

    reg [2:0] sck_r;
    reg [2:0] cs_r;
    reg [1:0] mosi_r;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sck_r <= 3'b000;
            cs_r <= 3'b111;
            mosi_r <= 2'b00;
        end else begin
            sck_r <= {sck_r[1:0], sck};
            cs_r <= {cs_r[1:0], cs};
            mosi_r <= {mosi_r[0], mosi};
        end
    end
    
    wire sck_rise = (sck_r[2:1] == 2'b01);
    wire sck_fall = (sck_r[2:1] == 2'b10);
    wire cs_fall = (cs_r[2:1] == 2'b10);
    wire cs_rise = (cs_r[2:1] == 2'b01);
    wire cs_active = ~cs_r[1];
    
    wire sample_edge = (cpha == 0) ? 
                       (cpol == 0 ? sck_rise : sck_fall) : 
                       (cpol == 0 ? sck_fall : sck_rise);
                       
    wire drive_edge = (cpha == 0) ? 
                      (cpol == 0 ? sck_fall : sck_rise) : 
                      (cpol == 0 ? sck_rise : sck_fall);
                      
    reg [7:0] rx_shift;
    reg [7:0] tx_shift;
    reg [3:0] bit_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            miso <= 0;
            data_out <= 0;
            data_valid <= 0;
            rx_shift <= 0;
            tx_shift <= 0;
            bit_cnt <= 0;
        end else begin
            data_valid <= 0;
            if (cs_fall) begin
                tx_shift <= data_in;
                bit_cnt <= 0;
                if (cpha == 0) begin
                    miso <= data_in[7];
                end
            end else if (cs_active) begin
                if (sample_edge) begin
                    rx_shift <= {rx_shift[6:0], mosi_r[1]};
                    bit_cnt <= bit_cnt + 1;
                end
                if (drive_edge) begin
                    miso <= tx_shift[7 - bit_cnt[2:0]];
                end
            end else if (cs_rise) begin
                if (bit_cnt == 8) begin
                    data_out <= rx_shift;
                    data_valid <= 1;
                end
            end
        end
    end
endmodule
