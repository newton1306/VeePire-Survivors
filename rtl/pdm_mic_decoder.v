`timescale 1ns / 1ps
// ============================================================================
// ADMP421 Omnidirectional MEMS Microphone PDM Decoder for Digilent Nexys A7
// Generates 2.5 MHz M_CLK from 25 MHz system clock
// PDM Decimation & Acoustic Amplitude Envelope Follower
// Detects "KMUTT Shout / Voice Roar" when player yells or blows into mic
// ============================================================================

module pdm_mic_decoder (
    input  wire        clk,        // 25 MHz clock
    input  wire        rst,
    // Physical Nexys A7 Microphone Pins
    output reg         M_CLK = 1'b0,
    input  wire        M_DATA,
    output wire        M_LRSEL,
    // Sound Amplitude & Roar Detection
    output reg  [5:0]  sound_level = 6'd0, // Current acoustic loudness 0..63
    output reg         mic_roar    = 1'b0  // Pulse/Flag for Screen Shockwave attack!
);

    assign M_LRSEL = 1'b0; // Left channel (standard mono)

    // Generate 2.50 MHz M_CLK from 25 MHz: divide by 10 (toggle every 5 ticks)
    reg [2:0] clk_div = 3'd0;
    reg       m_clk_rise = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            clk_div    <= 3'd0;
            M_CLK      <= 1'b0;
            m_clk_rise <= 1'b0;
        end else if (clk_div == 3'd4) begin
            clk_div    <= 3'd0;
            M_CLK      <= ~M_CLK;
            m_clk_rise <= ~M_CLK; // High on rising edge of M_CLK
        end else begin
            clk_div    <= clk_div + 3'd1;
            m_clk_rise <= 1'b0;
        end
    end

    // Double-flop synchronizer for asynchronous M_DATA
    reg m_data_meta = 1'b0;
    reg m_data_sync = 1'b0;

    always @(posedge clk) begin
        m_data_meta <= M_DATA;
        m_data_sync <= m_data_meta;
    end

    // Decimation Window: 128 samples (~51 microseconds @ 2.5 MHz)
    reg [6:0] sample_cnt = 7'd0;
    reg [7:0] ones_accum = 8'd0;
    reg [5:0] raw_dev    = 6'd0;

    // Loudness hold timer (~1/3 second = 8,000,000 cycles @ 25 MHz)
    reg [23:0] roar_hold_t = 24'd0;

    always @(posedge clk) begin
        if (rst) begin
            sample_cnt  <= 7'd0;
            ones_accum  <= 8'd0;
            sound_level <= 6'd0;
            mic_roar    <= 1'b0;
            roar_hold_t <= 24'd0;
        end else begin
            if (m_clk_rise) begin
                if (m_data_sync) ones_accum <= ones_accum + 8'd1;

                if (sample_cnt == 7'd127) begin
                    sample_cnt <= 7'd0;
                    // Center of 128 samples is 64. Calculate absolute deviation from 64:
                    raw_dev = (ones_accum >= 8'd64) ? (ones_accum[6:0] - 7'd64) : (7'd64 - ones_accum[6:0]);
                    sound_level <= raw_dev;
                    ones_accum <= 8'd0;

                    // Trigger Voice Roar if deviation exceeds threshold 30 (Loud shout or close blow)
                    if (raw_dev >= 6'd28) begin
                        roar_hold_t <= 24'd8000000; // Hold roar high for ~320ms
                    end
                end else begin
                    sample_cnt <= sample_cnt + 7'd1;
                end
            end

            // Decrement roar hold timer
            if (roar_hold_t > 0) begin
                roar_hold_t <= roar_hold_t - 24'd1;
                mic_roar    <= 1'b1;
            end else begin
                mic_roar    <= 1'b0;
            end
        end
    end

endmodule
