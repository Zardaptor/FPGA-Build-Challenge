module spi_master (
    input  wire       clk,
    input  wire       rst,
    input  wire       cpol,
    input  wire       cpha,
    input  wire       start,
    input  wire [7:0] data_in,
    output reg        busy,
    output reg  [7:0] data_out,
    output reg        data_valid,
    output reg        sck,
    output reg        mosi,
    input  wire       miso,
    output reg        cs
);

    localparam IDLE = 1'b0, ACTIVE = 1'b1;
    reg state;
    reg [4:0] bit_cnt;
    reg [7:0] tx_shift;
    reg [7:0] rx_shift;
    
    reg [2:0] clk_div;
    wire tick = (clk_div == 0);
    always @(posedge clk or posedge rst) begin
        if (rst) clk_div <= 0;
        else clk_div <= clk_div + 1;
    end
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            data_valid <= 0;
            sck <= 0;
            mosi <= 0;
            cs <= 1;
            bit_cnt <= 0;
            data_out <= 0;
            tx_shift <= 0;
            rx_shift <= 0;
        end else begin
            data_valid <= 0;
            case (state)
                IDLE: begin
                    sck <= cpol;
                    cs <= 1;
                    if (start) begin
                        state <= ACTIVE;
                        busy <= 1;
                        tx_shift <= data_in;
                        cs <= 0;
                        bit_cnt <= 0;
                        if (cpha == 0) begin
                            mosi <= data_in[7];
                        end
                    end
                end
                
                ACTIVE: begin
                    if (tick) begin
                        if (bit_cnt < 16) begin
                            if (cpha == 0) begin
                                if (bit_cnt[0] == 0) begin // Leading edge (Sample)
                                    sck <= ~cpol;
                                    rx_shift <= {rx_shift[6:0], miso};
                                end else begin // Trailing edge (Drive)
                                    sck <= cpol;
                                    if (bit_cnt < 15)
                                        mosi <= tx_shift[7 - (bit_cnt[4:1] + 1)];
                                end
                            end else begin // cpha == 1
                                if (bit_cnt[0] == 0) begin // Leading edge (Drive)
                                    sck <= ~cpol;
                                    mosi <= tx_shift[7 - bit_cnt[4:1]];
                                end else begin // Trailing edge (Sample)
                                    sck <= cpol;
                                    rx_shift <= {rx_shift[6:0], miso};
                                end
                            end
                            bit_cnt <= bit_cnt + 1;
                        end else begin
                            sck <= cpol;
                            cs <= 1;
                            busy <= 0;
                            data_out <= rx_shift;
                            data_valid <= 1;
                            state <= IDLE;
                        end
                    end
                end
            endcase
        end
    end
endmodule
