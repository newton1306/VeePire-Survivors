`timescale 1ns / 1ps
// UART 115200 8N1 Dual USB Joystick Receiver (PC Twin-USB Bridge -> FPGA)
// Packet Format (3 bytes):
//   Byte 0: {1'b1, 1'b0, p1_dy_enc[2:0], p1_dx_enc[2:0]}  (enc 0..4 => -2..+2)
//   Byte 1: {1'b0, 1'b0, p2_dy_enc[2:0], p2_dx_enc[2:0]}  (enc 0..4 => -2..+2)
//   Byte 2: {1'b0, 1'b0, p2_btn[2:0], p1_btn[2:0]}        ({fire, dash, chrono})
module uart_joy_rx (
    input  wire       clk,         // 25 MHz
    input  wire       rst,
    input  wire       uart_rxd,    // Nexys A7 UART_TXD_IN (C4)
    output reg signed [2:0] j1_dx = 3'sd0,
    output reg signed [2:0] j1_dy = 3'sd0,
    output reg  [2:0] j1_btn      = 3'b0, // {fire, dash, chrono}
    output reg signed [2:0] j2_dx = 3'sd0,
    output reg signed [2:0] j2_dy = 3'sd0,
    output reg  [2:0] j2_btn      = 3'b0, // {fire, dash, chrono}
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

    // 3-Byte Packet Framing + 1-Second Watchdog
    reg [1:0]  pkt_state = 2'd0;
    reg [7:0]  b0_latch = 8'd0, b1_latch = 8'd0;
    reg [24:0] wdog_cnt = 25'd0;

    always @(posedge clk) begin
        if (rst) begin
            pkt_state   <= 2'd0;
            j1_dx       <= 3'sd0; j1_dy <= 3'sd0; j1_btn <= 3'b0;
            j2_dx       <= 3'sd0; j2_dy <= 3'sd0; j2_btn <= 3'b0;
            joy_link_ok <= 1'b0;
            wdog_cnt    <= 25'd0;
        end else begin
            if (wdog_cnt > 0) begin
                wdog_cnt <= wdog_cnt - 25'd1;
            end else begin
                joy_link_ok <= 1'b0;
                j1_dx <= 3'sd0; j1_dy <= 3'sd0; j1_btn <= 3'b0;
                j2_dx <= 3'sd0; j2_dy <= 3'sd0; j2_btn <= 3'b0;
            end

            if (rx_valid) begin
                if (rx_byte[7] == 1'b1) begin
                    b0_latch  <= rx_byte;
                    pkt_state <= 2'd1;
                end else if (pkt_state == 2'd1) begin
                    b1_latch  <= rx_byte;
                    pkt_state <= 2'd2;
                end else if (pkt_state == 2'd2) begin
                    j1_dx       <= dec_axis(b0_latch[2:0]);
                    j1_dy       <= dec_axis(b0_latch[5:3]);
                    j2_dx       <= dec_axis(b1_latch[2:0]);
                    j2_dy       <= dec_axis(b1_latch[5:3]);
                    j1_btn      <= rx_byte[2:0];
                    j2_btn      <= rx_byte[5:3];
                    joy_link_ok <= 1'b1;
                    wdog_cnt    <= 25'd25000000;
                    pkt_state   <= 2'd0;
                end else begin
                    pkt_state <= 2'd0;
                end
            end
        end
    end
endmodule
