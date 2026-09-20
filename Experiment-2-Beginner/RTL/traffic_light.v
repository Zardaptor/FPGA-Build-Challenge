module traffic_light #(
    parameter CLK_FREQ = 125_000_000,
    parameter DEBOUNCE_MAX = 16'hFFFF
)(
    input clk,
    input rst,
    input pedestrian_btn,
    input emergency_override,
    output reg red,
    output reg yellow,
    output reg green
);

    // FSM States
    localparam S_RED     = 2'b00;
    localparam S_YELLOW1 = 2'b01;
    localparam S_GREEN   = 2'b10;
    localparam S_YELLOW2 = 2'b11;

    reg [1:0] state, next_state;

    // Debounce the pedestrian button
    reg btn_sync_1, btn_sync_2;
    reg [15:0] debounce_cnt;
    reg btn_debounced;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            btn_sync_1 <= 1'b0;
            btn_sync_2 <= 1'b0;
            debounce_cnt <= 16'd0;
            btn_debounced <= 1'b0;
        end else begin
            btn_sync_1 <= pedestrian_btn;
            btn_sync_2 <= btn_sync_1;
            
            if (btn_sync_2 == btn_debounced) begin
                debounce_cnt <= 16'd0;
            end else begin
                debounce_cnt <= debounce_cnt + 1'b1;
                if (debounce_cnt == DEBOUNCE_MAX) begin
                    btn_debounced <= btn_sync_2;
                    debounce_cnt <= 16'd0;
                end
            end
        end
    end

    // Edge detector for debounced button
    reg btn_debounced_d;
    wire btn_press = btn_debounced && !btn_debounced_d;

    always @(posedge clk or posedge rst) begin
        if (rst) btn_debounced_d <= 1'b0;
        else btn_debounced_d <= btn_debounced;
    end

    // Clock divider for 1Hz tick
    reg [31:0] clk_cnt;
    wire tick = (clk_cnt == CLK_FREQ - 1);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 32'd0;
        end else begin
            if (tick) begin
                clk_cnt <= 32'd0;
            end else begin
                clk_cnt <= clk_cnt + 1'b1;
            end
        end
    end

    // Timer for states (in seconds)
    reg [2:0] sec_cnt;
    reg reset_sec_cnt;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            sec_cnt <= 3'd0;
        end else begin
            if (reset_sec_cnt) begin
                sec_cnt <= 3'd0;
            end else if (tick) begin
                sec_cnt <= sec_cnt + 1'b1;
            end
        end
    end

    // FSM sequential logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_RED;
        end else begin
            state <= next_state;
        end
    end

    // Pedestrian request latch
    reg ped_request;
    reg clear_ped_request;
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ped_request <= 1'b0;
        end else if (btn_press) begin
            ped_request <= 1'b1;
        end else if (clear_ped_request) begin
            ped_request <= 1'b0;
        end
    end

    // FSM combinational logic
    always @(*) begin
        // Default values
        next_state = state;
        reset_sec_cnt = 1'b0;
        red = 1'b0;
        yellow = 1'b0;
        green = 1'b0;
        clear_ped_request = 1'b0;

        case (state)
            S_RED: begin
                red = 1'b1;
                if (emergency_override) begin
                    next_state = S_YELLOW1;
                    reset_sec_cnt = 1'b1;
                end else if (sec_cnt >= 3'd4 && tick) begin // 5 seconds
                    next_state = S_YELLOW1;
                    reset_sec_cnt = 1'b1;
                    if (ped_request) clear_ped_request = 1'b1;
                end
            end
            
            S_YELLOW1: begin
                yellow = 1'b1;
                if (sec_cnt >= 3'd0 && tick) begin // 1 second
                    next_state = S_GREEN;
                    reset_sec_cnt = 1'b1;
                end
            end
            
            S_GREEN: begin
                green = 1'b1;
                if (emergency_override) begin
                    // Hold in GREEN
                    reset_sec_cnt = 1'b1;
                end else if (ped_request) begin
                    // Safely transition to RED
                    next_state = S_YELLOW2;
                    reset_sec_cnt = 1'b1;
                end else if (sec_cnt >= 3'd4 && tick) begin // 5 seconds
                    next_state = S_YELLOW2;
                    reset_sec_cnt = 1'b1;
                end
            end
            
            S_YELLOW2: begin
                yellow = 1'b1;
                if (sec_cnt >= 3'd0 && tick) begin // 1 second
                    next_state = S_RED;
                    reset_sec_cnt = 1'b1;
                end
            end
            
            default: begin
                next_state = S_RED;
            end
        endcase
    end

endmodule
