`timescale 1ns / 1ps
// ADXL362 3-Axis Accelerometer SPI Controller & Tilt Processor for Nexys A7-100T
// Runs strictly in single clk25 domain using a /6 clock-enable (4.167 MHz base, ~1.04 MHz SCLK).
// SPI timing sequence adapted from verified FPGADude ADXL362 SPI state machine (CPOL=0, CPHA=0).
module acl_tilt (
    input  wire       clk,         // 25 MHz
    input  wire       rst,
    input  wire       miso,
    output reg        sclk  = 1'b0,
    output reg        mosi  = 1'b0,
    output reg        csn   = 1'b1,
    input  wire       btn_zero,    // BTNR pulse: calibrate neutral zero point
    input  wire       btn_orient,  // BTNL pulse: cycle 4 board orientations
    output reg signed [7:0] raw_x = 8'sd0,
    output reg signed [7:0] raw_y = 8'sd0,
    output reg signed [2:0] tilt_dx = 3'sd0, // -2 .. +2 game pixels/frame
    output reg signed [2:0] tilt_dy = 3'sd0,
    output reg [1:0]  orient_mode = 2'd0
);
    // 4.167 MHz tick enable from 25 MHz
    reg [2:0] div6 = 3'd0;
    wire      ce_4m = (div6 == 3'd5);
    always @(posedge clk) begin
        if (rst) div6 <= 3'd0;
        else     div6 <= ce_4m ? 3'd0 : div6 + 3'd1;
    end

    // 1.04 MHz SCLK driven directly by sub_step (0:LOW+MOSI setup, 1:HIGH, 2:HIGH+MISO sample, 3:LOW)
    localparam [3:0]
        S_PWRUP    = 4'd0,
        S_WR_CMD   = 4'd1,
        S_WR_ADDR  = 4'd2,
        S_WR_DATA  = 4'd3,
        S_WAIT40   = 4'd4,
        S_RD_CMD   = 4'd5,
        S_RD_ADDR  = 4'd6,
        S_RD_BYTES = 4'd7,
        S_WAIT10   = 4'd8;

    reg [3:0]  state   = S_PWRUP;
    reg [17:0] wait_cnt = 18'd0;
    reg [2:0]  bit_idx  = 3'd7;
    reg [1:0]  sub_step = 2'd0; // 4 ticks per SPI clock period
    reg [2:0]  byte_idx = 3'd0; // 0=XL, 1=XH, 2=YL, 3=YH
    reg [7:0]  tx_byte  = 8'h00;
    reg [7:0]  rx_shift = 8'h00;
    reg [15:0] x_reg = 16'd0, y_reg = 16'd0;

    always @(posedge clk) begin
        if (rst) begin
            state    <= S_PWRUP;
            wait_cnt <= 18'd0;
            csn      <= 1'b1;
            sclk     <= 1'b0;
            mosi     <= 1'b0;
            sub_step <= 2'd0;
            bit_idx  <= 3'd7;
            byte_idx <= 3'd0;
            x_reg    <= 16'd0;
            y_reg    <= 16'd0;
            raw_x    <= 8'sd0;
            raw_y    <= 8'sd0;
        end else if (ce_4m) begin
            case (state)
                S_PWRUP: begin
                    csn <= 1'b1; sclk <= 1'b0;
                    if (wait_cnt >= 18'd25000) begin
                        wait_cnt <= 0;
                        csn      <= 1'b0;
                        tx_byte  <= 8'h0A; // Write instruction
                        bit_idx  <= 3'd7;
                        sub_step <= 2'd0;
                        state    <= S_WR_CMD;
                    end else wait_cnt <= wait_cnt + 18'd1;
                end

                S_WR_CMD, S_WR_ADDR, S_WR_DATA, S_RD_CMD, S_RD_ADDR: begin
                    case (sub_step)
                        2'd0: begin sclk <= 1'b0; mosi <= tx_byte[bit_idx]; end
                        2'd1: begin sclk <= 1'b1; end
                        2'd2: begin sclk <= 1'b1; end
                        2'd3: begin sclk <= 1'b0; end
                    endcase
                    sub_step <= sub_step + 2'd1;
                    if (sub_step == 2'd3) begin
                        if (bit_idx == 3'd0) begin
                            bit_idx <= 3'd7;
                            case (state)
                                S_WR_CMD:  begin tx_byte <= 8'h2D; state <= S_WR_ADDR; end
                                S_WR_ADDR: begin tx_byte <= 8'h02; state <= S_WR_DATA; end
                                S_WR_DATA: begin
                                    csn <= 1'b1; sclk <= 1'b0; wait_cnt <= 0;
                                    state <= S_WAIT40;
                                end
                                S_RD_CMD:  begin tx_byte <= 8'h0E; state <= S_RD_ADDR; end
                                S_RD_ADDR: begin byte_idx <= 3'd0; mosi <= 1'b0; state <= S_RD_BYTES; end
                                default:   state <= S_PWRUP;
                            endcase
                        end else begin
                            bit_idx <= bit_idx - 3'd1;
                        end
                    end
                end

                S_WAIT40: begin
                    csn <= 1'b1; sclk <= 1'b0;
                    if (wait_cnt >= 18'd165000) begin
                        wait_cnt <= 0;
                        csn      <= 1'b0;
                        tx_byte  <= 8'h0B; // Read instruction
                        bit_idx  <= 3'd7;
                        sub_step <= 2'd0;
                        state    <= S_RD_CMD;
                    end else wait_cnt <= wait_cnt + 18'd1;
                end

                S_RD_BYTES: begin
                    case (sub_step)
                        2'd0: begin sclk <= 1'b0; end
                        2'd1: begin sclk <= 1'b1; end
                        2'd2: begin sclk <= 1'b1; rx_shift[bit_idx] <= miso; end
                        2'd3: begin sclk <= 1'b0; end
                    endcase
                    sub_step <= sub_step + 2'd1;
                    if (sub_step == 2'd3) begin
                        if (bit_idx == 3'd0) begin
                            bit_idx <= 3'd7;
                            case (byte_idx)
                                3'd0: x_reg[7:0]  <= rx_shift;
                                3'd1: x_reg[15:8] <= rx_shift;
                                3'd2: y_reg[7:0]  <= rx_shift;
                                3'd3: y_reg[15:8] <= rx_shift;
                            endcase
                            if (byte_idx == 3'd3) begin
                                csn <= 1'b1; sclk <= 1'b0; wait_cnt <= 0;
                                state <= S_WAIT10;
                            end else begin
                                byte_idx <= byte_idx + 3'd1;
                            end
                        end else begin
                            bit_idx <= bit_idx - 3'd1;
                        end
                    end
                end

                S_WAIT10: begin
                    csn <= 1'b1; sclk <= 1'b0;
                    if (wait_cnt == 18'd1) begin
                        raw_x <= x_reg[11:4];
                        raw_y <= y_reg[11:4];
                    end
                    if (wait_cnt >= 18'd40000) begin
                        wait_cnt <= 0;
                        csn      <= 1'b0;
                        tx_byte  <= 8'h0B;
                        bit_idx  <= 3'd7;
                        sub_step <= 2'd0;
                        state    <= S_RD_CMD;
                    end else wait_cnt <= wait_cnt + 18'd1;
                end

                default: state <= S_PWRUP;
            endcase
        end
    end

    // ---- Calibration Zeroing & Fixed Axis Orientation (BTNL inversion removed) ----
    reg signed [7:0] zero_x = 8'sd0, zero_y = 8'sd0;
    always @(posedge clk) begin
        if (rst) begin
            zero_x      <= 8'sd0;
            zero_y      <= 8'sd0;
            orient_mode <= 2'd0;
        end else begin
            if (btn_zero) begin
                zero_x <= raw_x;
                zero_y <= raw_y;
            end
            orient_mode <= 2'd0;
        end
    end

    wire signed [8:0] cx = raw_x - zero_x;
    wire signed [8:0] cy = raw_y - zero_y;
    wire signed [8:0] map_x = -cy; // Fixed natural landscape X
    wire signed [8:0] map_y =  cx; // Fixed natural landscape Y

    // Deadzone (|v| < 6 -> 0), Mild (6..15 -> 1 px), Steep (>=16 -> 2 px)
    always @(posedge clk) begin
        if      (map_x >=  9'sd16) tilt_dx <=  3'sd2;
        else if (map_x >=  9'sd6)  tilt_dx <=  3'sd1;
        else if (map_x <= -9'sd16) tilt_dx <= -3'sd2;
        else if (map_x <= -9'sd6)  tilt_dx <= -3'sd1;
        else                       tilt_dx <=  3'sd0;

        if      (map_y >=  9'sd16) tilt_dy <=  3'sd2;
        else if (map_y >=  9'sd6)  tilt_dy <=  3'sd1;
        else if (map_y <= -9'sd16) tilt_dy <= -3'sd2;
        else if (map_y <= -9'sd6)  tilt_dy <= -3'sd1;
        else                       tilt_dy <=  3'sd0;
    end
endmodule
