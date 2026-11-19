`timescale 1ns / 1ps
// UART 115200 8N1 Dual USB Joystick + Wireless Keyboard Receiver (PC Bridge -> FPGA)
// Packet Format (5 bytes):
//   Byte 0: {1'b1, j1_shoot, p1_dy_enc[2:0], p1_dx_enc[2:0]}  (enc 0..4 => -2..+2)
//   Byte 1: {1'b0, j2_shoot, p2_dy_enc[2:0], p2_dx_enc[2:0]}  (enc 0..4 => -2..+2)
//   Byte 2: {1'b0, joy_start, p2_btn[2:0], p1_btn[2:0]}       ({fire, dash, nova})
//   Byte 3: {1'b0, kb_shoot, kb_dy_enc[2:0], kb_dx_enc[2:0]}
//   Byte 4: {1'b0, kb_quiz_hit, (kb_quiz_hit ? kb_quiz_sel[1:0] : {kb_esc, kb_start}), joy_select, kb_btn[2:0]}
module uart_joy_rx (
    input  wire       clk,         // 25 MHz
    input  wire       rst,
    input  wire       uart_rxd,    // Nexys A7 UART_TXD_IN (C4)
    output reg signed [2:0] j1_dx = 3'sd0,
    output reg signed [2:0] j1_dy = 3'sd0,
    output reg  [2:0] j1_btn      = 3'b0, // {fire, dash, nova}
    output reg signed [2:0] j2_dx = 3'sd0,
    output reg signed [2:0] j2_dy = 3'sd0,
    output reg  [2:0] j2_btn      = 3'b0, // {fire, dash, nova}
    output reg        j1_shoot    = 1'b0, // Btn 1 (Top Green)
    output reg        j2_shoot    = 1'b0,
    output reg        joy_pause   = 1'b0, // Joystick Start button
    output reg        joy_select  = 1'b0, // Joystick Select button
    output reg signed [2:0] uart_kb_dx = 3'sd0,
    output reg signed [2:0] uart_kb_dy = 3'sd0,
    output reg  [2:0] uart_kb_btn = 3'b0, // {atk, dash, nova}
    output reg        uart_kb_shoot = 1'b0,
    output reg        uart_kb_start = 1'b0,
    output reg        uart_kb_esc   = 1'b0,
    output reg  [1:0] uart_kb_quiz_sel = 2'd0,
    output reg        uart_kb_quiz_hit = 1'b0,
    output reg        joy_link_ok = 1'b0
);
    localparam integer CLKS_PER_BIT = 217; // 25,000,000 / 115,200 = 217.01

    // 2-FF input synchronizer
    reg rx_s0 = 1'b1, rx_s1 = 1'b1;
    always @(posedge clk) begin
        rx_s0 <= uart_rxd;
        rx_s1 <= rx_s0;
    end

    // UART 8N1 Receiver FSM
    localparam [1:0] U_IDLE=2'd0, U_START=2'd1, U_DATA=2'd2, U_STOP=2'd3;
    reg [1:0] u_state   = U_IDLE;
    reg [7:0] clk_cnt   = 8'd0;
    reg [2:0] bit_idx   = 3'd0;
    reg [7:0] rx_shift  = 8'd0;
    reg [7:0] rx_byte   = 8'd0;
    reg       rx_valid  = 1'b0;

    always @(posedge clk) begin
        rx_valid <= 1'b0;
        if (rst) begin
            u_state <= U_IDLE;
            clk_cnt <= 8'd0;
            bit_idx <= 3'd0;
        end else begin
            case (u_state)
                U_IDLE: begin
                    clk_cnt <= 8'd0;
                    bit_idx <= 3'd0;
                    if (!rx_s1) u_state <= U_START;
                end
                U_START: begin
                    if (clk_cnt >= (CLKS_PER_BIT / 2)) begin
                        if (!rx_s1) begin
                            clk_cnt <= 8'd0;
                            u_state <= U_DATA;
                        end else begin
                            u_state <= U_IDLE;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end
                U_DATA: begin
                    if (clk_cnt >= CLKS_PER_BIT - 1) begin
                        clk_cnt           <= 8'd0;
                        rx_shift[bit_idx] <= rx_s1;
                        if (bit_idx == 3'd7) begin
                            bit_idx <= 3'd0;
                            u_state <= U_STOP;
                        end else begin
                            bit_idx <= bit_idx + 3'd1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end
                U_STOP: begin
                    if (clk_cnt >= CLKS_PER_BIT - 1) begin
                        u_state <= U_IDLE;
                        if (rx_s1) begin
                            rx_byte  <= rx_shift;
                            rx_valid <= 1'b1;
                        end
                    end else begin
                        clk_cnt <= clk_cnt + 8'd1;
                    end
                end
            endcase
        end
    end

    function automatic signed [2:0] dec_axis;
        input [2:0] enc;
        begin
            case (enc)
                3'd0:    dec_axis = -3'sd2;
                3'd1:    dec_axis = -3'sd1;
                3'd2:    dec_axis =  3'sd0;
                3'd3:    dec_axis =  3'sd1;
                3'd4:    dec_axis =  3'sd2;
                default: dec_axis =  3'sd0;
            endcase
        end
    endfunction

    // 5-Byte Packet Framing + 1-Second Watchdog
    reg [2:0]  pkt_state = 3'd0;
    reg [7:0]  b0_latch = 8'd0, b1_latch = 8'd0, b2_latch = 8'd0, b3_latch = 8'd0;
    reg [24:0] wdog_cnt = 25'd0;

    always @(posedge clk) begin
        if (rst) begin
            pkt_state        <= 3'd0;
            j1_dx            <= 3'sd0; j1_dy <= 3'sd0; j1_btn <= 3'b0;
            j2_dx            <= 3'sd0; j2_dy <= 3'sd0; j2_btn <= 3'b0;
            j1_shoot         <= 1'b0;  j2_shoot <= 1'b0;
            joy_pause        <= 1'b0;  joy_select <= 1'b0;
            uart_kb_dx       <= 3'sd0; uart_kb_dy <= 3'sd0; uart_kb_btn <= 3'b0;
            uart_kb_shoot    <= 1'b0;  uart_kb_start <= 1'b0; uart_kb_esc <= 1'b0;
            uart_kb_quiz_sel <= 2'd0;  uart_kb_quiz_hit <= 1'b0;
            joy_link_ok      <= 1'b0;
            wdog_cnt         <= 25'd0;
        end else begin
            if (wdog_cnt > 0) begin
                wdog_cnt <= wdog_cnt - 25'd1;
            end else begin
                joy_link_ok      <= 1'b0;
                j1_dx <= 3'sd0; j1_dy <= 3'sd0; j1_btn <= 3'b0;
                j2_dx <= 3'sd0; j2_dy <= 3'sd0; j2_btn <= 3'b0;
                j1_shoot <= 1'b0; j2_shoot <= 1'b0;
                joy_pause <= 1'b0; joy_select <= 1'b0;
                uart_kb_dx <= 3'sd0; uart_kb_dy <= 3'sd0; uart_kb_btn <= 3'b0;
                uart_kb_shoot <= 1'b0; uart_kb_start <= 1'b0; uart_kb_esc <= 1'b0;
                uart_kb_quiz_hit <= 1'b0;
            end

            if (rx_valid) begin
                if (rx_byte[7] == 1'b1) begin
                    b0_latch  <= rx_byte;
                    pkt_state <= 3'd1;
                end else if (pkt_state == 3'd1) begin
                    b1_latch  <= rx_byte;
                    pkt_state <= 3'd2;
                end else if (pkt_state == 3'd2) begin
                    b2_latch  <= rx_byte;
                    pkt_state <= 3'd3;
                end else if (pkt_state == 3'd3) begin
                    b3_latch  <= rx_byte;
                    pkt_state <= 3'd4;
                end else if (pkt_state == 3'd4) begin
                    j1_dx            <= dec_axis(b0_latch[2:0]);
                    j1_dy            <= dec_axis(b0_latch[5:3]);
                    j1_shoot         <= b0_latch[6];
                    j2_dx            <= dec_axis(b1_latch[2:0]);
                    j2_dy            <= dec_axis(b1_latch[5:3]);
                    j2_shoot         <= b1_latch[6];
                    j1_btn           <= b2_latch[2:0];
                    j2_btn           <= b2_latch[5:3];
                    joy_pause        <= b2_latch[6];
                    uart_kb_dx       <= dec_axis(b3_latch[2:0]);
                    uart_kb_dy       <= dec_axis(b3_latch[5:3]);
                    uart_kb_shoot    <= b3_latch[6];
                    uart_kb_btn      <= rx_byte[2:0];
                    joy_select       <= rx_byte[3];
                    uart_kb_quiz_sel <= rx_byte[5:4];
                    uart_kb_quiz_hit <= rx_byte[6];
                    uart_kb_start    <= !rx_byte[6] ? rx_byte[4] : 1'b0;
                    uart_kb_esc      <= !rx_byte[6] ? rx_byte[5] : 1'b0;
                    joy_link_ok      <= 1'b1;
                    wdog_cnt         <= 25'd25000000;
                    pkt_state        <= 3'd0;
                end else begin
                    pkt_state <= 3'd0;
                end
            end
        end
    end
endmodule
