`timescale 1ns / 1ps
// Nexys A7-100T Console I/O (V2):
//   - Synchronizes 5 buttons + SW[15:0] (Skin controls)
//   - Generates edge pulses for BTNR (Re-zero Tilt) and BTNL (Rotate Tilt Axis)
//   - 8-Digit 7-Segment: [W<wave> H<hp>] [SCORE 4 digits]
//   - 16-LED bar: EXP Progress & Cutscene / Evolve celebration flashes
module board_io_v2 (
    input  wire        clk,
    input  wire        rst,
    input  wire        btnc_raw, btnu_raw, btnd_raw, btnl_raw, btnr_raw,
    input  wire [15:0] sw_raw,
    input  wire [2:0]  game_state,   // 0=TITLE, 1=CUTSCENE, 2=PLAY, 3=WIN, 4=LOSE
    input  wire [3:0]  wave,         // 1..10
    input  wire [1:0]  stage,        // 0..3
    input  wire [4:0]  hp,           // 0..24 HP bar
    input  wire [4:0]  hp2,          // 0..24 P2 HP bar
    input  wire [5:0]  exp,          // 0..63
    input  wire [23:0] score_bcd,
    input  wire [4:0]  evolve_flash,
    input  wire        chrono_active,
    input  wire [15:0] temp_bcd,
    input  wire        temp_fever,
    input  wire        mic_roar,
    input  wire [5:0]  sound_level,
    output reg  [4:0]  btn_sync = 0, // {btnc, btnu, btnd, btnl, btnr}
    output reg  [15:0] sw_sync  = 0,
    output wire        btn_zero_pulse,
    output wire        btn_orient_pulse,
    output reg  [15:0] LED      = 0,
    output wire        LED16_R, LED16_G, LED16_B,
    output wire        LED17_R, LED17_G, LED17_B,
    output reg  [7:0]  AN       = 8'hFF,
    output reg         CA = 1, CB = 1, CC = 1, CD = 1, CE = 1, CF = 1, CG = 1, DP = 1
);
    reg [4:0] btn_s0 = 0, btn_s1 = 0, btn_prev = 0;
    reg [15:0] sw_s1 = 0;
    reg [16:0] deb_cnt [0:4]; // 5 ms @ 25 MHz = 125,000 cycles (eliminates bounce, allows unlimited rapid tapping)
    integer b;
    initial begin
        for (b = 0; b < 5; b = b + 1) deb_cnt[b] = 17'd0;
    end
    always @(posedge clk) begin
        btn_s0 <= {btnc_raw, btnu_raw, btnd_raw, btnl_raw, btnr_raw};
        btn_s1 <= btn_s0;
        for (b = 0; b < 5; b = b + 1) begin
            if (btn_s1[b] == btn_sync[b]) begin
                deb_cnt[b] <= 17'd0;
            end else if (deb_cnt[b] >= 17'd124999) begin
                btn_sync[b] <= btn_s1[b];
                deb_cnt[b]  <= 17'd0;
            end else begin
                deb_cnt[b] <= deb_cnt[b] + 17'd1;
            end
        end
        btn_prev <= btn_sync;
        sw_s1    <= sw_raw;
        sw_sync  <= sw_s1;
    end

    assign btn_orient_pulse = btn_sync[1] && !btn_prev[1]; // BTNL
    assign btn_zero_pulse   = btn_sync[0] && !btn_prev[0]; // BTNR

    reg [23:0] anim_cnt = 0;
    always @(posedge clk) anim_cnt <= anim_cnt + 24'd1;

    wire [4:0] led_level = (exp >= 6'd60) ? 5'd16 : {1'b0, exp[5:2]};
    integer i;
    always @(posedge clk) begin
        if (rst) begin
            LED <= 16'h0000;
        end else if (mic_roar) begin
            LED <= anim_cnt[18] ? 16'hFFFF : 16'h0000; // Microphone Roar Strobe!
        end else if (temp_fever) begin
            LED <= (16'h0007 << anim_cnt[21:18]) | (16'hE000 >> anim_cnt[21:18]); // Fever Knight-Rider Flame!
        end else if (evolve_flash > 0 || game_state == 3'd1) begin
            LED <= anim_cnt[19] ? 16'hAAAA : 16'h5555;
        end else if (game_state == 3'd3) begin
            LED <= (16'h0001 << anim_cnt[22:19]) | (16'h8000 >> anim_cnt[22:19]);
        end else begin
            for (i = 0; i < 16; i = i + 1)
                LED[i] <= (i < led_level) || (i == 0 && exp > 0);
        end
    end

    wire pwm_dim = (anim_cnt[5:0] < 6'd8);
    assign LED16_R = pwm_dim && (temp_fever ? 1'b1 : (hp <= 5'd8));
    assign LED16_G = pwm_dim && (temp_fever ? anim_cnt[21] : (hp >= 5'd9));
    assign LED16_B = pwm_dim && (temp_fever ? 1'b0 : chrono_active);

    assign LED17_R = pwm_dim && (mic_roar ? 1'b1 : sw_sync[15]);
    assign LED17_G = pwm_dim && (mic_roar ? anim_cnt[20] : (!sw_sync[15] && !sw_sync[14]));
    assign LED17_B = pwm_dim && (mic_roar ? 1'b1 : (!sw_sync[15] && !sw_sync[13]));

    // 8-Digit 7-Segment:
    // When SW[1] is ON: Displays Live Temperature [  30.5 C] [SCORE]
    // Otherwise: Standard RPG Status [E<wave>.] [SCORE]
    wire [2:0] dig_sel = anim_cnt[15:13];
    reg  [4:0] char_code;
    reg        dp_val;
    wire show_temp = sw_sync[1];

    always @(*) begin
        AN     = ~(8'b00000001 << dig_sel);
        dp_val = 1'b1;
        case (dig_sel)
            3'd7: char_code = show_temp ? {1'b0, temp_bcd[11:8]} : 5'd14; // 'E' or Temp Tens
            3'd6: begin
                char_code = show_temp ? {1'b0, temp_bcd[7:4]} : {1'b0, wave}; // Wave 1..10 or Temp Ones
                dp_val = 1'b0; // Decimal point separator
            end
            3'd5: char_code = show_temp ? {1'b0, temp_bcd[3:0]} : {1'b0, score_bcd[23:20]}; // 100k digit or Temp Frac
            3'd4: begin
                char_code = show_temp ? 5'd12 : {1'b0, score_bcd[19:16]}; // 10k digit or 'C'
                dp_val = show_temp ? 1'b1 : 1'b1;
            end
            3'd3: char_code = {1'b0, score_bcd[15:12]}; // 1k digit
            3'd2: char_code = {1'b0, score_bcd[11:8]};  // 100 digit
            3'd1: char_code = {1'b0, score_bcd[7:4]};   // 10 digit
            3'd0: char_code = {1'b0, score_bcd[3:0]};   // 1 digit
        endcase
    end

    reg [6:0] seg;
    always @(*) begin
        case (char_code)
            5'd0:  seg = 7'b0000001;
            5'd1:  seg = 7'b1001111;
            5'd2:  seg = 7'b0010010;
            5'd3:  seg = 7'b0000110;
            5'd4:  seg = 7'b1001100;
            5'd5:  seg = 7'b0100100;
            5'd6:  seg = 7'b0100000;
            5'd7:  seg = 7'b0001111;
            5'd8:  seg = 7'b0000000;
            5'd9:  seg = 7'b0000100;
            5'd12: seg = 7'b0110001; // C (Celsius)
            5'd14: seg = 7'b0110000; // E (Evolution Stage)
            5'd17: seg = 7'b1001000; // H (HP)
            default: seg = 7'b1111111;
        endcase
    end

    always @(posedge clk) begin
        {CA, CB, CC, CD, CE, CF, CG} <= seg;
        DP <= dp_val;
    end
endmodule
