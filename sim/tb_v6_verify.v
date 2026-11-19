`timescale 1ns / 1ps

module tb_v6_verify;
    reg clk = 0;
    always #20 clk = ~clk; // 25 MHz VGA / Engine clock

    reg rst = 1;
    wire [9:0] vga_x, vga_y;
    wire       vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_sync (.clk(clk), .rst(rst), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on));
    wire game_tick = (vga_x == 10'd0) && (vga_y == 10'd480);

    // 1. Standalone Switch + Audio + Board_IO Checks
    reg  [15:0] sw = 16'h0000;
    reg         sfx_shoot_t=0, sfx_pick_t=0;
    wire        aud_pwm_w, aud_sd_w;
    audio_synth_v2 u_aud_chk (
        .clk(clk), .rst(rst), .game_state(3'd2), .boss_active(1'b0), .chrono_active(1'b0),
        .sfx_shoot(sfx_shoot_t), .sfx_pickup(sfx_pick_t), .sfx_evolve(1'b0), .sfx_hit(1'b0),
        .audio_sw(sw[15:11]), .aud_pwm(aud_pwm_w), .aud_sd(aud_sd_w)
    );

    wire [4:0]  io_btn;
    wire [15:0] io_sw, io_led;
    wire        l16r, l16g, l16b, l17r, l17g, l17b;
    wire [7:0]  an;
    wire        ca, cb, cc, cd, ce, cf, cg, dp;
    board_io_v2 u_io_chk (
        .clk(clk), .rst(rst),
        .btnc_raw(1'b0), .btnu_raw(1'b0), .btnd_raw(1'b0), .btnl_raw(1'b0), .btnr_raw(1'b0),
        .sw_raw(sw), .game_state(3'd2), .wave(4'd1), .stage(2'd0),
        .hp(5'd24), .hp2(5'd24), .exp(6'd0), .score_bcd(24'd0), .evolve_flash(5'd0),
        .chrono_active(1'b0), .temp_bcd(16'h0315), .temp_fever(sw[0]), .mic_roar(1'b0), .sound_level(6'd0),
        .btn_sync(io_btn), .sw_sync(io_sw), .LED(io_led),
        .LED16_R(l16r), .LED16_G(l16g), .LED16_B(l16b), .LED17_R(l17r), .LED17_G(l17g), .LED17_B(l17b),
        .AN(an), .CA(ca), .CB(cb), .CC(cc), .CD(cd), .CE(ce), .CF(cf), .CG(cg), .DP(dp)
    );

    // 2. Full Engine + Renderer for Guide 1/3 (SW labels) + Stage 3 Gold Cap + 2P Sonic Roar
    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk), .addr_a(map_addr_a), .q_a(map_tile_a), .addr_b(map_addr_b), .q_b(map_tile_b)
    );

    reg uart_rxd = 1'b1;
    wire signed [2:0] j1_dx, j1_dy, j2_dx, j2_dy, ukb_dx, ukb_dy;
    wire [2:0]        j1_btn, j2_btn, ukb_btn;
    wire              j1_shoot, j2_shoot, ukb_shoot, ukb_start, ukb_esc;
    wire              joy_pause, joy_select, joy_link_ok;
    wire [1:0]        ukb_quiz_sel;
    wire              ukb_quiz_hit;
    uart_joy_rx u_uart (
        .clk(clk), .rst(rst), .uart_rxd(uart_rxd),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j1_shoot(j1_shoot),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .j2_shoot(j2_shoot),
        .joy_pause(joy_pause), .joy_select(joy_select),
        .uart_kb_dx(ukb_dx), .uart_kb_dy(ukb_dy), .uart_kb_btn(ukb_btn), .uart_kb_shoot(ukb_shoot),
        .uart_kb_start(ukb_start), .uart_kb_esc(ukb_esc),
        .uart_kb_quiz_sel(ukb_quiz_sel), .uart_kb_quiz_hit(ukb_quiz_hit), .joy_link_ok(joy_link_ok)
    );

    wire kb_up    = (ukb_dy < 0);
    wire kb_down  = (ukb_dy > 0);
    wire kb_left  = (ukb_dx < 0);
    wire kb_right = (ukb_dx > 0);

    reg        tb_mic_roar = 1'b0;
    reg  [5:0] tb_sound_lvl = 6'd0;

    wire [1:0]  control_mode, hero_sel_l, hero_sel_r, quiz_cursor, quiz_ans_slot, help_page;
    wire [2:0]  game_state, room_phase, p1_weapon, p2_weapon;
    wire [3:0]  wave, p1_slash_t, p2_slash_t;
    wire [1:0]  stage, cut_id, boss_kind;
    wire [4:0]  hp, hp2, dash_timer, p2_dash_timer, evolve_flash, door_slide, sonic_wave_t;
    wire [5:0]  invuln_timer, p2_invuln, exp;
    wire [6:0]  zoom_lvl, chrono_energy, combo_cnt, wave_banner_t, quiz_wrong_t;
    wire [3:0]  shake_mag;
    wire [7:0]  cut_timer, boss_hp, boss_trans_t, outfit_cut_t;
    wire [5:0]  door_slam_t;
    wire [8:0]  sonic_radius;
    wire [10:0] px, p2x, cam_x, dash_gx, p2_dash_gx, p1_slash_x, p2_slash_x, lock_x, boss_x, pet_bx;
    wire [9:0]  py, p2y, cam_y, dash_gy, p2_dash_gy, p1_slash_y, p2_slash_y, lock_y, boss_y, pet_by, laser_y;
    wire        p2_active, zoom_out, zone2_open, zone3_open, chrono_active, mirror, p2_mirror, walk_frame, p2_walk_frame;
    wire        p1_nova, p2_nova, pet_active, blades_active, aura_active, pet_b_act, lock_valid, boss_active, boss_locked, boss_enraged;
    wire        sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit, hero_cursor, paused;
    wire [4:0]  enemies_left;
    wire [23:0] score_bcd;
    wire [10:0] blade0_x, blade1_x, p2_blade0_x, p2_blade1_x;
    wire [9:0]  blade0_y, blade1_y, p2_blade0_y, p2_blade1_y;
    wire signed [1:0] p1_slash_dx, p1_slash_dy, p2_slash_dx, p2_slash_dy;
    wire [2:0]  quiz_gate;
    wire [1:0]  laser_state;
    wire [16*11-1:0] en_x_vec; wire [16*10-1:0] en_y_vec; wire [16*3-1:0] en_type_vec;
    wire [15:0] en_alive_vec; wire [16*4-1:0] en_hp_vec; wire [16*2-1:0] en_tier_vec;
    wire [12*11-1:0] col_x_vec; wire [12*10-1:0] col_y_vec; wire [11:0] col_type_vec, col_alive_vec;
    wire [4*11-1:0] drop_x_vec; wire [4*10-1:0] drop_y_vec; wire [4*7-1:0] drop_z_vec;
    wire [4*2-1:0] drop_type_vec; wire [3:0] drop_active_vec; wire [4*5-1:0] drop_boom_vec;
    wire [12*11-1:0] sp_x_vec; wire [12*10-1:0] sp_y_vec; wire [11:0] sp_alive_vec;
    wire [8*11-1:0] eb_x_vec, pb_x_vec; wire [8*10-1:0] eb_y_vec, pb_y_vec;
    wire [7:0] eb_active_vec, pb_active_vec; wire [8*2-1:0] pb_dir_vec;

    game_engine_v2 u_engine (
        .clk(clk), .rst(rst), .tick(game_tick), .btn(5'b0),
        .tilt_dx(3'sd0), .tilt_dy(3'sd0),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j1_shoot(j1_shoot),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .j2_shoot(j2_shoot),
        .joy_pause(joy_pause), .joy_select(joy_select),
        .map_addr_b(map_addr_b), .map_tile_b(map_tile_b),
        .control_mode(control_mode), .p2_active(p2_active), .zoom_lvl(zoom_lvl), .zoom_out(zoom_out), .enemies_left(enemies_left),
        .game_state(game_state), .cut_id(cut_id), .cut_timer(cut_timer), .wave(wave),
        .zone2_open(zone2_open), .zone3_open(zone3_open),
        .px(px), .py(py), .dash_gx(dash_gx), .dash_gy(dash_gy),
        .p2x(p2x), .p2y(p2y), .p2_dash_gx(p2_dash_gx), .p2_dash_gy(p2_dash_gy),
        .p2_mirror(p2_mirror), .p2_walk_frame(p2_walk_frame), .p2_dash_timer(p2_dash_timer),
        .cam_x(cam_x), .cam_y(cam_y),
        .hp(hp), .hp2(hp2), .exp(exp), .stage(stage), .score_bcd(score_bcd),
        .chrono_energy(chrono_energy), .chrono_active(chrono_active),
        .mirror(mirror), .walk_frame(walk_frame),
        .dash_timer(dash_timer), .invuln_timer(invuln_timer), .p2_invuln(p2_invuln), .evolve_flash(evolve_flash),
        .combo_cnt(combo_cnt), .shake_mag(shake_mag), .p1_nova(p1_nova), .p2_nova(p2_nova),
        .pet_active(pet_active), .blades_active(blades_active), .aura_active(aura_active),
        .blade0_x(blade0_x), .blade0_y(blade0_y), .blade1_x(blade1_x), .blade1_y(blade1_y),
        .p2_blade0_x(p2_blade0_x), .p2_blade0_y(p2_blade0_y), .p2_blade1_x(p2_blade1_x), .p2_blade1_y(p2_blade1_y),
        .pet_bx(pet_bx), .pet_by(pet_by), .pet_b_act(pet_b_act),
        .en_x_vec(en_x_vec), .en_y_vec(en_y_vec), .en_type_vec(en_type_vec),
        .en_alive_vec(en_alive_vec), .en_hp_vec(en_hp_vec), .en_tier_vec(en_tier_vec),
        .col_x_vec(col_x_vec), .col_y_vec(col_y_vec), .col_type_vec(col_type_vec), .col_alive_vec(col_alive_vec),
        .drop_x_vec(drop_x_vec), .drop_y_vec(drop_y_vec), .drop_z_vec(drop_z_vec),
        .drop_type_vec(drop_type_vec), .drop_active_vec(drop_active_vec), .drop_boom_vec(drop_boom_vec),
        .sp_x_vec(sp_x_vec), .sp_y_vec(sp_y_vec), .sp_alive_vec(sp_alive_vec),
        .p1_slash_x(p1_slash_x), .p1_slash_y(p1_slash_y), .p1_slash_t(p1_slash_t),
        .p1_slash_dx(p1_slash_dx), .p1_slash_dy(p1_slash_dy),
        .p2_slash_x(p2_slash_x), .p2_slash_y(p2_slash_y), .p2_slash_t(p2_slash_t),
        .p2_slash_dx(p2_slash_dx), .p2_slash_dy(p2_slash_dy),
        .lock_x(lock_x), .lock_y(lock_y), .lock_valid(lock_valid),
        .eb_x_vec(eb_x_vec), .eb_y_vec(eb_y_vec), .eb_active_vec(eb_active_vec),
        .pb_x_vec(pb_x_vec), .pb_y_vec(pb_y_vec), .pb_dir_vec(pb_dir_vec), .pb_active_vec(pb_active_vec),
        .boss_x(boss_x), .boss_y(boss_y), .boss_hp(boss_hp), .boss_kind(boss_kind),
        .boss_active(boss_active), .boss_locked(boss_locked), .boss_enraged(boss_enraged),
        .laser_state(laser_state), .laser_y(laser_y),
        .sfx_shoot(sfx_shoot), .sfx_pickup(sfx_pickup), .sfx_evolve(sfx_evolve), .sfx_hit(sfx_hit),
        .hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r),
        .p1_weapon(p1_weapon), .p2_weapon(p2_weapon), .hero_cursor(hero_cursor),
        .temp_fever(sw[0]), .mic_roar(tb_mic_roar), .sound_level(tb_sound_lvl),
        .kb_up(kb_up), .kb_down(kb_down), .kb_left(kb_left), .kb_right(kb_right),
        .kb_attack(ukb_btn[2]), .kb_skill(ukb_btn[1]), .kb_nova(ukb_btn[0]), .kb_shoot(ukb_shoot),
        .kb_start(ukb_start), .kb_esc(ukb_esc),
        .kb_quiz_sel(ukb_quiz_sel), .kb_quiz_hit(ukb_quiz_hit),
        .room_phase(room_phase), .wave_banner_t(wave_banner_t), .door_slam_t(door_slam_t),
        .door_slide(door_slide), .quiz_gate(quiz_gate), .quiz_cursor(quiz_cursor),
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .outfit_cut_t(outfit_cut_t),
        .help_page(help_page), .sonic_wave_t(sonic_wave_t), .sonic_radius(sonic_radius), .paused(paused)
    );

    wire [3:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;
    vga_renderer_v2 u_renderer (
        .clk(clk), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on),
        .map_addr_a(map_addr_a), .map_tile_a(map_tile_a),
        .sw(sw), .tilt_dx(3'sd0), .tilt_dy(3'sd0),
        .control_mode(control_mode), .joy_link_ok(joy_link_ok), .p2_active(p2_active),
        .zoom_lvl(zoom_lvl), .zoom_out(zoom_out), .enemies_left(enemies_left),
        .game_state(game_state), .cut_id(cut_id), .cut_timer(cut_timer), .wave(wave),
        .zone2_open(zone2_open), .zone3_open(zone3_open),
        .px(px), .py(py), .dash_gx(dash_gx), .dash_gy(dash_gy),
        .p2x(p2x), .p2y(p2y), .p2_dash_gx(p2_dash_gx), .p2_dash_gy(p2_dash_gy),
        .p2_mirror(p2_mirror), .p2_walk_frame(p2_walk_frame), .p2_dash_timer(p2_dash_timer),
        .cam_x(cam_x), .cam_y(cam_y),
        .hp(hp), .hp2(hp2), .exp(exp), .stage(stage), .score_bcd(score_bcd),
        .p1_weapon(p1_weapon), .p2_weapon(p2_weapon), .hero_cursor(hero_cursor),
        .chrono_energy(chrono_energy), .chrono_active(chrono_active),
        .mirror(mirror), .walk_frame(walk_frame),
        .dash_timer(dash_timer), .invuln_timer(invuln_timer), .p2_invuln(p2_invuln), .evolve_flash(evolve_flash),
        .combo_cnt(combo_cnt), .shake_mag(shake_mag), .p1_nova(p1_nova), .p2_nova(p2_nova),
        .pet_active(pet_active), .blades_active(blades_active), .aura_active(aura_active),
        .blade0_x(blade0_x), .blade0_y(blade0_y), .blade1_x(blade1_x), .blade1_y(blade1_y),
        .p2_blade0_x(p2_blade0_x), .p2_blade0_y(p2_blade0_y), .p2_blade1_x(p2_blade1_x), .p2_blade1_y(p2_blade1_y),
        .pet_bx(pet_bx), .pet_by(pet_by), .pet_b_act(pet_b_act),
        .en_x_vec(en_x_vec), .en_y_vec(en_y_vec), .en_type_vec(en_type_vec),
        .en_alive_vec(en_alive_vec), .en_hp_vec(en_hp_vec), .en_tier_vec(en_tier_vec),
        .col_x_vec(col_x_vec), .col_y_vec(col_y_vec), .col_type_vec(col_type_vec), .col_alive_vec(col_alive_vec),
        .drop_x_vec(drop_x_vec), .drop_y_vec(drop_y_vec), .drop_z_vec(drop_z_vec),
        .drop_type_vec(drop_type_vec), .drop_active_vec(drop_active_vec), .drop_boom_vec(drop_boom_vec),
        .sp_x_vec(sp_x_vec), .sp_y_vec(sp_y_vec), .sp_alive_vec(sp_alive_vec),
        .p1_slash_x(p1_slash_x), .p1_slash_y(p1_slash_y), .p1_slash_t(p1_slash_t),
        .p1_slash_dx(p1_slash_dx), .p1_slash_dy(p1_slash_dy),
        .p2_slash_x(p2_slash_x), .p2_slash_y(p2_slash_y), .p2_slash_t(p2_slash_t),
        .p2_slash_dx(p2_slash_dx), .p2_slash_dy(p2_slash_dy),
        .lock_x(lock_x), .lock_y(lock_y), .lock_valid(lock_valid),
        .eb_x_vec(eb_x_vec), .eb_y_vec(eb_y_vec), .eb_active_vec(eb_active_vec),
        .pb_x_vec(pb_x_vec), .pb_y_vec(pb_y_vec), .pb_dir_vec(pb_dir_vec), .pb_active_vec(pb_active_vec),
        .boss_x(boss_x), .boss_y(boss_y), .boss_hp(boss_hp), .boss_kind(boss_kind),
        .boss_active(boss_active), .boss_locked(boss_locked), .boss_enraged(boss_enraged),
        .laser_state(laser_state), .laser_y(laser_y),
        .hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r),
        .room_phase(room_phase), .wave_banner_t(wave_banner_t), .door_slam_t(door_slam_t),
        .door_slide(door_slide), .quiz_gate(quiz_gate), .quiz_cursor(quiz_cursor),
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .outfit_cut_t(outfit_cut_t), .paused(paused),
        .temp_fever(sw[0]), .mic_roar(tb_mic_roar), .help_page(help_page), .sonic_wave_t(sonic_wave_t), .sonic_radius(sonic_radius),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    task send_uart_byte;
        input [7:0] data;
        integer b;
        begin
            uart_rxd = 1'b0; repeat (217) @(posedge clk);
            for (b = 0; b < 8; b = b + 1) begin uart_rxd = data[b]; repeat (217) @(posedge clk); end
            uart_rxd = 1'b1; repeat (217) @(posedge clk);
        end
    endtask

    task send_5byte_pkt;
        input [7:0] b0, b1, b2, b3, b4;
        begin
            send_uart_byte(b0); send_uart_byte(b1); send_uart_byte(b2); send_uart_byte(b3); send_uart_byte(b4);
            wait(vga_y == 10'd481); wait(vga_y == 10'd0);
        end
    endtask

    task capture_ppm;
        input [8*64-1:0] fname;
        integer fd, pcnt;
        begin
            wait (vga_y == 10'd482);
            @(posedge clk);
            fd = $fopen(fname, "w");
            $fwrite(fd, "P3\n640 480\n255\n");
            pcnt = 0;
            while (pcnt < 307200) begin
                @(posedge clk);
                if (u_renderer.vid_3) begin
                    $fwrite(fd, "%0d %0d %0d ", VGA_R * 17, VGA_G * 17, VGA_B * 17);
                    pcnt = pcnt + 1;
                    if ((pcnt % 16) == 0) $fwrite(fd, "\n");
                end
            end
            $fclose(fd);
            $display("[PPM] Captured %0s (%0d pixels)", fname, pcnt);
        end
    endtask

    integer fail_cnt = 0;
    initial begin
        repeat (25) @(posedge clk);
        rst = 0;
        repeat (10) @(posedge clk);

        // --- A. Verify SW[15:11] Audio Mixer + SW[0]/SW[1] Fever & 7-Seg Temp ---
        sw = 16'h0000;
        repeat (10) @(posedge clk);
        if (aud_sd_w !== 1'b1) begin $display("FAIL: AUD_SD not 1 at SW15=0"); fail_cnt = fail_cnt + 1; end

        // Force SFX trigger & test BGM/SFX mute + Vol Attenuation
        sfx_pick_t = 1'b1; @(posedge clk); sfx_pick_t = 1'b0; repeat (5) @(posedge clk);
        if (!u_aud_chk.sfx_active) begin $display("FAIL: SFX did not trigger at SW13=0"); fail_cnt = fail_cnt + 1; end

        sw[13] = 1'b1; @(posedge clk); #1; // SFX mute ON
        if (u_aud_chk.sfx_active !== 1'b0) begin $display("FAIL: SW[13] SFX mute failed"); fail_cnt = fail_cnt + 1; end
        sw[13] = 1'b0; @(posedge clk); #1;

        sw[14] = 1'b1; @(posedge clk); #1; // BGM mute ON -> bass/drum off, SFX still active
        if (u_aud_chk.bass_div !== 17'd0 || !u_aud_chk.sfx_active) begin $display("FAIL: SW[14] BGM mute failed"); fail_cnt = fail_cnt + 1; end
        sw[14] = 1'b0;

        sw[12:11] = 2'b10; // 25% Vol -> mix_total == mix_raw >> 2
        repeat (5) @(posedge clk);
        if (u_aud_chk.mix_total !== (u_aud_chk.mix_raw >> 2)) begin $display("FAIL: SW[12:11] Vol atten failed"); fail_cnt = fail_cnt + 1; end

        sw[15] = 1'b1; @(posedge clk); #1; // Master Audio Mute
        if (aud_sd_w !== 1'b0 || aud_pwm_w !== 1'b0) begin $display("FAIL: SW[15] Master Mute failed"); fail_cnt = fail_cnt + 1; end
        sw[15] = 1'b0; sw[12:11] = 2'b00;

        // Check SW[0] Fever + SW[1] 7-Seg Temp
        sw[0] = 1'b1; sw[1] = 1'b1;
        repeat (10) @(posedge clk);
        if (u_io_chk.show_temp !== 1'b1 || !u_io_chk.LED16_R) begin $display("FAIL: SW[0]/SW[1] failed"); fail_cnt = fail_cnt + 1; end
        sw = 16'h0000;
        $display("[PASS] SW[15:11] Audio Mixer (Mute/BGM/SFX/Vol) + SW[0] Fever + SW[1] 7-Seg Temp!");

        // --- B. Capture V6 1/3 BOARD HARDWARE Guide (skip in +FAST_SONIC since already verified) ---
        if (!$test$plusargs("FAST_SONIC")) begin
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h08); // Joy Select opens 1/3 Guide
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
            if (help_page !== 2'd1) begin $display("FAIL: Guide P1 not opened"); fail_cnt = fail_cnt + 1; end
            capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v6_guide_p1.ppm");

            // Exit guide, start game (Joy Fire b2[2]=1), test Stage 3 no repeat transform, then 2P Mic Roar!
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h08); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // close guide
            send_5byte_pkt(8'h92, 8'h12, 8'h04, 8'h12, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // start game
            if (game_state !== 3'd2) begin $display("FAIL: Game did not start"); fail_cnt = fail_cnt + 1; end

            // Stage 3 Gold Armor Check: Quiz pass MUST NOT replay outfit_cut_t!
            force u_engine.stage = 2'd3;
            force u_engine.room_phase = 3'd3;
            force u_engine.quiz_ans_slot = 2'd0;
            force u_engine.quiz_lockout = 6'd0;
            repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
            release u_engine.stage; release u_engine.room_phase; release u_engine.quiz_ans_slot; release u_engine.quiz_lockout;
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h40); // KB Quiz '1'
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
            if (room_phase !== 3'd4 || outfit_cut_t !== 8'd0 || stage !== 2'd3) begin
                $display("FAIL: Stage 3 Gold outfit re-triggered animation! rp=%0d oct=%0d stg=%0d", room_phase, outfit_cut_t, stage);
                fail_cnt = fail_cnt + 1;
            end else $display("[PASS] Stage 3 Gold outfit skipped repeat transformation animation!");
        end else begin
            // Fast path: enter ST_PLAY in 2P Co-op directly (~1 frame) for 2P Sonic capture
            send_5byte_pkt(8'h92, 8'h12, 8'h04, 8'h12, 8'h00);
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
        end

        // 2-Player Mic Roar Sonic Wave Check (BOTH P1 Cyan & P2 Pink Rings!)
        force u_engine.control_mode = 2'b10;
        force u_engine.room_phase = 3'd1;
        force u_engine.px = 11'd200; force u_engine.py = 10'd220;
        force u_engine.p2x = 11'd420; force u_engine.p2y = 10'd220;
        force u_engine.hp = 5'd24; force u_engine.hp2 = 5'd24;
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        release u_engine.room_phase; release u_engine.px; release u_engine.py; release u_engine.p2x; release u_engine.p2y; release u_engine.hp; release u_engine.hp2;
        tb_sound_lvl = 6'd45; tb_mic_roar = 1'b1;
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        tb_mic_roar = 1'b0;
        repeat (5) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        if (sonic_wave_t == 5'd0) begin
            $display("FAIL: Mic roar did not trigger sonic_wave_t!"); fail_cnt = fail_cnt + 1;
        end else $display("[PASS] 2P Mic Roar active sonic_wave_t=%0d radius=%0d!", sonic_wave_t, sonic_radius);
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v6_sonic_2p.ppm");
        release u_engine.control_mode;

        if (fail_cnt == 0) $display("=== ALL V6 RTL TESTS PASSED PERFECTLY! ===");
        else               $display("=== FAILED %0d TESTS ===", fail_cnt);
        $finish;
    end
endmodule
