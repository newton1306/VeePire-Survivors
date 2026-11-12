`timescale 1ns / 1ps
// Hardware 3-Voice + Noise Chiptune PWM Synthesizer (BRAM BGM Sequencer + Impact SFX)
module audio_synth_v2 (
    input  wire       clk,         // 25 MHz
    input  wire       rst,
    input  wire [2:0] game_state,  // 0=TITLE, 1=CUTSCENE, 2=PLAY, 3=WIN, 4=LOSE
    input  wire       boss_active,
    input  wire       chrono_active,
    input  wire       sfx_shoot,   // Melee Slash / Lunge
    input  wire       sfx_pickup,  // Gem / Heart
    input  wire       sfx_evolve,  // Upgrade Cutscene / Boss Kill
    input  wire       sfx_hit,     // Enemy Hit / Crit
    output wire       aud_pwm,
    output wire       aud_sd
);
    assign aud_sd = 1'b1;

    // 1 ms timer @ 25 MHz
    reg [14:0] ms_cnt = 0;
    wire       ms_tick = (ms_cnt == 15'd24999);
    always @(posedge clk) ms_cnt <= ms_tick ? 15'd0 : ms_cnt + 15'd1;

    // BRAM Music Sequencer (4 Songs x 256 steps)
    reg [7:0] bgm_ms   = 0;
    reg [7:0] bgm_step = 0;
    wire [1:0] song_sel = (game_state == 3'd3) ? 2'd3 :
                          (boss_active         ? 2'd2 :
                          ((game_state == 3'd2)? 2'd1 : 2'd0));
    wire [7:0] step_ms = chrono_active ? 8'd210 : (boss_active ? 8'd105 : 8'd135);

    always @(posedge clk) begin
        if (rst) begin
            bgm_ms <= 0; bgm_step <= 0;
        end else if (ms_tick) begin
            if (bgm_ms >= step_ms) begin
                bgm_ms   <= 0;
                bgm_step <= bgm_step + 8'd1;
            end else begin
                bgm_ms <= bgm_ms + 8'd1;
            end
        end
    end

    wire [15:0] bgm_word;
    rom_1p #(.DW(16), .AW(10), .DEPTH(1024), .FILE("bgm_rom.mem")) u_bgm_rom (
        .clk  (clk),
        .addr ({song_sel, bgm_step}),
        .q    (bgm_word)
    );

    wire [5:0] lead_note = bgm_word[15:10];
    wire [5:0] bass_note = bgm_word[9:4];
    wire [3:0] drum_trig = bgm_word[3:0];

    // Half-period table (25MHz / (2*f)) for note index 1..32 (C3 minor/pentatonic to G5)
    function automatic [16:0] note_div;
        input [5:0] idx;
        begin
            case (idx)
                6'd1:  note_div = 17'd95556; // C3
                6'd2:  note_div = 17'd90192; // D3
                6'd3:  note_div = 17'd80353; // Eb3
                6'd4:  note_div = 17'd71586; // F3
                6'd5:  note_div = 17'd63776; // G3
                6'd6:  note_div = 17'd56818; // Ab3
                6'd7:  note_div = 17'd53629; // Bb3
                6'd8:  note_div = 17'd47778; // C4
                6'd9:  note_div = 17'd45096; // C#4
                6'd10: note_div = 17'd42566; // D4
                6'd11: note_div = 17'd40176; // Eb4
                6'd12: note_div = 17'd37922; // E4
                6'd13: note_div = 17'd35793; // F4
                6'd14: note_div = 17'd33784; // F#4
                6'd15: note_div = 17'd31888; // G4
                6'd16: note_div = 17'd30098; // Ab4
                6'd17: note_div = 17'd28409; // A4
                6'd18: note_div = 17'd26815; // Bb4
                6'd19: note_div = 17'd25309; // B4
                6'd20: note_div = 17'd23889; // C5
                6'd21: note_div = 17'd22548; // C#5
                6'd22: note_div = 17'd21283; // D5
                6'd23: note_div = 17'd20088; // Eb5
                6'd24: note_div = 17'd18961; // E5
                6'd25: note_div = 17'd17896; // F5
                6'd26: note_div = 17'd16892; // F#5
                6'd27: note_div = 17'd15944; // G5
                6'd28: note_div = 17'd14205; // A5
                6'd29: note_div = 17'd12655; // B5
                6'd30: note_div = 17'd11945; // C6
                6'd31: note_div = 17'd10641; // D6
                default: note_div = 17'd0;
            endcase
        end
    endfunction

    // SFX Engine (overrides Lead briefly so Slashes/Hits feel super punchy!)
    reg [8:0] sfx_timer = 0;
    reg [2:0] sfx_kind  = 0;
    always @(posedge clk) begin
        if (rst) begin sfx_timer <= 0; sfx_kind <= 0; end
        else if (sfx_evolve) begin sfx_kind <= 3'd3; sfx_timer <= 9'd360; end
        else if (sfx_hit)    begin sfx_kind <= 3'd4; sfx_timer <= 9'd110; end
        else if (sfx_pickup) begin sfx_kind <= 3'd2; sfx_timer <= 9'd100; end
        else if (sfx_shoot && sfx_timer == 0) begin sfx_kind <= 3'd1; sfx_timer <= 9'd70; end
        else if (ms_tick && sfx_timer > 0) sfx_timer <= sfx_timer - 9'd1;
    end

    reg [16:0] lead_div;
    always @(*) begin
        if (sfx_timer > 0) begin
            case (sfx_kind)
                3'd1: lead_div = 17'd14000 + ({8'd0, (9'd70 - sfx_timer)} << 8); // Whoosh sweep
                3'd2: lead_div = (sfx_timer > 9'd50) ? 17'd21283 : 17'd15944;     // Crisp Gem ding
                3'd3: begin                                                       // Fanfare!
                    if      (sfx_timer > 9'd270) lead_div = 17'd23889;
                    else if (sfx_timer > 9'd180) lead_div = 17'd18961;
                    else if (sfx_timer > 9'd90)  lead_div = 17'd15944;
                    else                         lead_div = 17'd11945;
                end
                3'd4: lead_div = 17'd24000 + ({8'd0, (9'd110 - sfx_timer)} << 7); // Crunch impact
                default: lead_div = 17'd0;
            endcase
        end else if (game_state == 3'd4) begin
            lead_div = 17'd0;
        end else begin
            lead_div = note_div(lead_note);
        end
    end
    wire [16:0] bass_div = (game_state == 3'd4) ? 17'd0 : note_div(bass_note);

    // Oscillators + LFSR Percussion Noise
    reg [16:0] cnt_lead = 0, cnt_bass = 0;
    reg        sq_lead = 0, sq_bass = 0;
    reg [11:0] lfsr = 12'hACE;
    wire       drum_env = (bgm_ms < 8'd24) && (drum_trig != 4'd0) && (game_state == 3'd2 || game_state == 3'd3);

    always @(posedge clk) begin
        if (rst) begin
            cnt_lead <= 0; sq_lead <= 0;
            cnt_bass <= 0; sq_bass <= 0;
            lfsr <= 12'hACE;
        end else begin
            if (ms_cnt[5:0] == 6'd0)
                lfsr <= {lfsr[10:0], lfsr[11] ^ lfsr[5] ^ lfsr[3] ^ lfsr[0]};

            if (lead_div == 0) begin cnt_lead <= 0; sq_lead <= 0; end
            else if (cnt_lead >= lead_div) begin cnt_lead <= 0; sq_lead <= ~sq_lead; end
            else cnt_lead <= cnt_lead + 17'd1;

            if (bass_div == 0) begin cnt_bass <= 0; sq_bass <= 0; end
            else if (cnt_bass >= bass_div) begin cnt_bass <= 0; sq_bass <= ~sq_bass; end
            else cnt_bass <= cnt_bass + 17'd1;
        end
    end

    // 8-bit 97.6 kHz Sigma-Delta / PWM Mixer
    wire [7:0] mix_lead = (lead_div != 0 && sq_lead) ? (sfx_timer > 0 ? 8'd110 : 8'd70) : 8'd0;
    wire [7:0] mix_bass = (bass_div != 0 && sq_bass) ? 8'd55 : 8'd0;
    wire [7:0] mix_drum = (drum_env && lfsr[0])      ? (drum_trig[0] ? 8'd50 : 8'd30) : 8'd0;
    wire [7:0] mix_total = mix_lead + mix_bass + mix_drum;

    reg [7:0] pwm_cnt = 0;
    always @(posedge clk) pwm_cnt <= pwm_cnt + 8'd1;
    wire pwm_out = (pwm_cnt < mix_total);

    assign aud_pwm = pwm_out ? 1'bz : 1'b0;
endmodule
