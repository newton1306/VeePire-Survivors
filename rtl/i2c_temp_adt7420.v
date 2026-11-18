`timescale 1ns / 1ps
// ============================================================================
// ADT7420 I2C Temperature Sensor Controller for Digilent Nexys A7-100T
// Address: 7'b1001011 (0x4B)
// Reads 16-bit/13-bit Temperature Register every ~100ms
// Outputs integer Celsius, 1-decimal BCD, and Fever mode trigger (> 30°C)
// ============================================================================

module i2c_temp_adt7420 (
    input  wire        clk,        // 25 MHz or 100 MHz clock
    input  wire        rst,
    // Physical I2C Pins to ADT7420
    output wire        TMP_SCL,
    inout  wire        TMP_SDA,
    // Output Status & Measurements
    output reg  [7:0]  temp_c = 8'd27,     // Integer Celsius (e.g. 28)
    output reg  [3:0]  temp_frac = 4'd5,   // 0.1 C fraction (e.g. 5 for 28.5 C)
    output reg  [15:0] temp_bcd = 16'h0275,// [15:12]=0, [11:8]=Tens, [7:4]=Units, [3:0]=Frac
    output reg         temp_fever = 1'b0   // High when temp >= 30 C (Finger touch overclock!)
);

    // Clock divider for I2C SCL (~100 kHz from 25 MHz)
    // 25 MHz / 250 = 100 kHz. Quarter cycle = 62.5 ticks (~62 ticks)
    localparam [7:0] QUARTER = 8'd62;

    reg [7:0] q_cnt = 8'd0;
    reg       q_pulse = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            q_cnt   <= 8'd0;
            q_pulse <= 1'b0;
        end else if (q_cnt >= QUARTER - 1) begin
            q_cnt   <= 8'd0;
            q_pulse <= 1'b1;
        end else begin
            q_cnt   <= q_cnt + 8'd1;
            q_pulse <= 1'b0;
        end
    end

    // I2C Open-Drain Drive
    reg scl_o = 1'b1;
    reg sda_o = 1'b1;
    wire sda_i = TMP_SDA;

    assign TMP_SCL = scl_o;
    assign TMP_SDA = sda_o ? 1'bz : 1'b0;

    // Refresh timer: poll temp every ~100 ms (2,500,000 cycles @ 25 MHz)
    reg [21:0] poll_cnt = 22'd0;
    reg        poll_start = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            poll_cnt   <= 22'd0;
            poll_start <= 1'b0;
        end else if (poll_cnt >= 22'd2500000) begin
            poll_cnt   <= 22'd0;
            poll_start <= 1'b1;
        end else begin
            poll_cnt   <= poll_cnt + 22'd1;
            poll_start <= 1'b0;
        end
    end

    // FSM States
    localparam [4:0]
        S_IDLE     = 5'd0,
        S_START    = 5'd1,
        S_WR_ADDR  = 5'd2,
        S_ACK1     = 5'd3,
        S_RD_MSB   = 5'd4,
        S_ACK_M    = 5'd5,
        S_RD_LSB   = 5'd6,
        S_NACK_M   = 5'd7,
        S_STOP     = 5'd8,
        S_UPDATE   = 5'd9;

    reg [4:0]  state = S_IDLE;
    reg [1:0]  sub   = 2'd0;
    reg [3:0]  bit_idx = 4'd7;
    reg [7:0]  tx_byte = 8'h00;
    reg [7:0]  rx_msb  = 8'h00;
    reg [7:0]  rx_lsb  = 8'h00;
    reg [15:0] raw_temp = 16'h0000;

    always @(posedge clk) begin
        if (rst) begin
            state      <= S_IDLE;
            sub        <= 2'd0;
            scl_o      <= 1'b1;
            sda_o      <= 1'b1;
            temp_c     <= 8'd27;
            temp_frac  <= 4'd5;
            temp_bcd   <= 16'h0275;
            temp_fever <= 1'b0;
        end else if (q_pulse) begin
            case (state)
                S_IDLE: begin
                    scl_o <= 1'b1;
                    sda_o <= 1'b1;
                    sub   <= 2'd0;
                    if (poll_start) begin
                        state <= S_START;
                    end
                end

                S_START: begin
                    // Generate I2C START: SDA drops while SCL is HIGH
                    case (sub)
                        2'd0: begin scl_o <= 1'b1; sda_o <= 1'b1; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sda_o <= 1'b0; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b0; sda_o <= 1'b0; sub <= 2'd3; end
                        2'd3: begin
                            tx_byte <= {7'b1001011, 1'b1}; // Address 0x4B + READ bit
                            bit_idx <= 4'd7;
                            sub     <= 2'd0;
                            state   <= S_WR_ADDR;
                        end
                    endcase
                end

                S_WR_ADDR: begin
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= tx_byte[bit_idx]; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o <= 1'b0;
                            sub   <= 2'd0;
                            if (bit_idx == 4'd0) begin
                                state <= S_ACK1;
                            end else begin
                                bit_idx <= bit_idx - 4'd1;
                            end
                        end
                    endcase
                end

                S_ACK1: begin
                    // Read slave ACK
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b1; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o   <= 1'b0;
                            sub     <= 2'd0;
                            bit_idx <= 4'd7;
                            state   <= S_RD_MSB;
                        end
                    endcase
                end

                S_RD_MSB: begin
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b1; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; rx_msb[bit_idx] <= sda_i; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o <= 1'b0;
                            sub   <= 2'd0;
                            if (bit_idx == 4'd0) begin
                                state <= S_ACK_M;
                            end else begin
                                bit_idx <= bit_idx - 4'd1;
                            end
                        end
                    endcase
                end

                S_ACK_M: begin
                    // Master ACK (pull SDA low to ask for byte 2)
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b0; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o   <= 1'b0;
                            sda_o   <= 1'b1;
                            sub     <= 2'd0;
                            bit_idx <= 4'd7;
                            state   <= S_RD_LSB;
                        end
                    endcase
                end

                S_RD_LSB: begin
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b1; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; rx_lsb[bit_idx] <= sda_i; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o <= 1'b0;
                            sub   <= 2'd0;
                            if (bit_idx == 4'd0) begin
                                state <= S_NACK_M;
                            end else begin
                                bit_idx <= bit_idx - 4'd1;
                            end
                        end
                    endcase
                end

                S_NACK_M: begin
                    // Master NACK (keep SDA high to signal end of read)
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b1; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            scl_o <= 1'b0;
                            sda_o <= 1'b0;
                            sub   <= 2'd0;
                            state <= S_STOP;
                        end
                    endcase
                end

                S_STOP: begin
                    // Generate I2C STOP: SDA rises while SCL is HIGH
                    case (sub)
                        2'd0: begin scl_o <= 1'b0; sda_o <= 1'b0; sub <= 2'd1; end
                        2'd1: begin scl_o <= 1'b1; sda_o <= 1'b0; sub <= 2'd2; end
                        2'd2: begin scl_o <= 1'b1; sda_o <= 1'b1; sub <= 2'd3; end
                        2'd3: begin
                            sub   <= 2'd0;
                            state <= S_UPDATE;
                        end
                    endcase
                end

                S_UPDATE: begin
                    // Calculate temperature
                    // If reading all 1s (0xFFFF), bus was unacknowledged -> keep default
                    if ({rx_msb, rx_lsb} != 16'hFFFF && {rx_msb, rx_lsb} != 16'h0000) begin
                        raw_temp = {rx_msb, rx_lsb};
                        // 13-bit temp in raw_temp[15:3].
                        // Upper 8 bits [15:7] is temperature in Celsius
                        temp_c <= raw_temp[14:7];
                        // 4-bit fraction [6:3] in 0.0625 C steps. (frac * 10) / 16 gives 1 decimal digit
                        temp_frac <= (raw_temp[6:3] * 4'd10) >> 4;
                        // Fever Trigger: Finger Touch Heating > 30 C!
                        temp_fever <= (raw_temp[14:7] >= 8'd30);

                        // BCD Encoding
                        temp_bcd[3:0]   <= (raw_temp[6:3] * 4'd10) >> 4;
                        temp_bcd[7:4]   <= raw_temp[14:7] % 8'd10;
                        temp_bcd[11:8]  <= (raw_temp[14:7] / 8'd10) % 8'd10;
                        temp_bcd[15:12] <= 4'd0;
                    end
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
