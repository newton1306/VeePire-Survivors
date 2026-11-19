`timescale 1ns / 1ps
// ============================================================================
// PS/2 Keyboard Controller for Digilent Nexys A7-100T USB Host Port
// Decodes PS/2 Set 2 Scancodes from standard USB Keyboards
// Full Direct Control: WASD, Space, Enter, Keys 1-4 for Quiz Answers
// ============================================================================

module ps2_keyboard (
    input  wire        clk,        // 25 MHz system clock
    input  wire        rst,
    // Physical Nexys A7 PS/2 Pins (from PIC24 USB Host)
    input  wire        PS2_CLK,
    input  wire        PS2_DATA,
    // Movement & Combat Controls
    output reg         kb_up       = 1'b0,
    output reg         kb_down     = 1'b0,
    output reg         kb_left     = 1'b0,
    output reg         kb_right    = 1'b0,
    output reg         kb_attack   = 1'b0,
    output reg         kb_skill    = 1'b0,
    output reg         kb_nova     = 1'b0,
    output reg         kb_shoot    = 1'b0,
    output reg         kb_start    = 1'b0,
    output reg         kb_esc      = 1'b0,
    // Quiz Door Number Selection (Keys 1..4)
    output reg  [1:0]  kb_quiz_sel = 2'd0,
    output reg         kb_quiz_hit = 1'b0
);

    // Filter & Synchronize PS2_CLK and PS2_DATA (debounce ~8 samples @ 25 MHz)
    reg [7:0] clk_filter = 8'hFF;
    reg [7:0] dat_filter = 8'hFF;
    reg ps2_clk_clean = 1'b1;
    reg ps2_dat_clean = 1'b1;
    reg ps2_clk_prev  = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            clk_filter    <= 8'hFF;
            dat_filter    <= 8'hFF;
            ps2_clk_clean <= 1'b1;
            ps2_dat_clean <= 1'b1;
            ps2_clk_prev  <= 1'b1;
        end else begin
            clk_filter <= {clk_filter[6:0], PS2_CLK};
            dat_filter <= {dat_filter[6:0], PS2_DATA};

            if (clk_filter == 8'h00) ps2_clk_clean <= 1'b0;
            else if (clk_filter == 8'hFF) ps2_clk_clean <= 1'b1;

            if (dat_filter == 8'h00) ps2_dat_clean <= 1'b0;
            else if (dat_filter == 8'hFF) ps2_dat_clean <= 1'b1;

            ps2_clk_prev <= ps2_clk_clean;
        end
    end

    wire ps2_fall = (ps2_clk_prev && !ps2_clk_clean);

    // Frame Receiver (11 bits: Start, 8 Data, Parity, Stop)
    reg [3:0]  bit_count = 4'd0;
    reg [10:0] shift_reg = 11'd0;
    reg [7:0]  scancode  = 8'h00;
    reg        code_valid = 1'b0;

    // Timeout counter to reset frame if line hangs (> 5 ms = 125,000 cycles)
    reg [17:0] timeout_cnt = 18'd0;

    always @(posedge clk) begin
        if (rst) begin
            bit_count   <= 4'd0;
            shift_reg   <= 11'd0;
            scancode    <= 8'h00;
            code_valid  <= 1'b0;
            timeout_cnt <= 18'd0;
        end else begin
            code_valid <= 1'b0;

            if (ps2_fall) begin
                timeout_cnt <= 18'd0;
                shift_reg   <= {ps2_dat_clean, shift_reg[10:1]};

                if (bit_count == 4'd10) begin
                    bit_count <= 4'd0;
                    // Check start=0 (shifted 10 times from bit 10 -> bit 1) and stop=1 (current ps2_dat_clean)
                    if (shift_reg[1] == 1'b0 && ps2_dat_clean == 1'b1) begin
                        scancode   <= shift_reg[9:2];
                        code_valid <= 1'b1;
                    end
                end else begin
                    bit_count <= bit_count + 4'd1;
                end
            end else begin
                if (bit_count != 4'd0) begin
                    if (timeout_cnt >= 18'd125000) begin
                        bit_count   <= 4'd0;
                        timeout_cnt <= 18'd0;
                    end else begin
                        timeout_cnt <= timeout_cnt + 18'd1;
                    end
                end
            end
        end
    end

    // Scancode Decoder
    // F0 prefix indicates key release (break)
    reg is_break = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            is_break    <= 1'b0;
            kb_up       <= 1'b0;
            kb_down     <= 1'b0;
            kb_left     <= 1'b0;
            kb_right    <= 1'b0;
            kb_attack   <= 1'b0;
            kb_skill    <= 1'b0;
            kb_nova     <= 1'b0;
            kb_shoot    <= 1'b0;
            kb_start    <= 1'b0;
            kb_esc      <= 1'b0;
            kb_quiz_sel <= 2'd0;
            kb_quiz_hit <= 1'b0;
        end else begin
            kb_quiz_hit <= 1'b0; // 1-cycle strobe

            if (code_valid) begin
                if (scancode == 8'hF0) begin
                    is_break <= 1'b1;
                end else if (scancode == 8'hE0) begin
                    // Extended key prefix, ignore for simple keys
                end else begin
                    case (scancode)
                        // 'W' or Up Arrow (8'h75)
                        8'h1D, 8'h75: kb_up     <= ~is_break;
                        // 'S' or Down Arrow (8'h72)
                        8'h1B, 8'h72: kb_down   <= ~is_break;
                        // 'A' or Left Arrow (8'h6B)
                        8'h1C, 8'h6B: kb_left   <= ~is_break;
                        // 'D' or Right Arrow (8'h74)
                        8'h23, 8'h74: kb_right  <= ~is_break;
                        // Spacebar or 'J' (Attack / Play)
                        8'h29, 8'h3B: kb_attack <= ~is_break;
                        // 'K' / 'E' / 'Z' (Dash Skill)
                        8'h24, 8'h42, 8'h1A: kb_skill <= ~is_break;
                        // 'L' (360 Nova)
                        8'h4B:        kb_nova   <= ~is_break;
                        // 'U' (Bullet Shoot)
                        8'h3C:        kb_shoot  <= ~is_break;
                        // Enter (Start / Pause)
                        8'h5A:        kb_start  <= ~is_break;
                        // Escape (Guide / Back)
                        8'h76:        kb_esc    <= ~is_break;

                        // Number keys 1..4 for Door Quiz selection + '3'/'4' also trigger nova/shoot during combat
                        8'h16: begin if (!is_break) begin kb_quiz_sel <= 2'd0; kb_quiz_hit <= 1'b1; end end // '1'
                        8'h1E: begin if (!is_break) begin kb_quiz_sel <= 2'd1; kb_quiz_hit <= 1'b1; end end // '2'
                        8'h26: begin kb_nova  <= ~is_break; if (!is_break) begin kb_quiz_sel <= 2'd2; kb_quiz_hit <= 1'b1; end end // '3'
                        8'h25: begin kb_shoot <= ~is_break; if (!is_break) begin kb_quiz_sel <= 2'd3; kb_quiz_hit <= 1'b1; end end // '4'
                        default: ;
                    endcase
                    is_break <= 1'b0;
                end
            end
        end
    end

endmodule
