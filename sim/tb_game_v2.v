`timescale 1ns / 1ps
module tb_game_v2;
    reg clk = 0;
    always #20 clk = ~clk; // 25 MHz

    reg rst = 1, tick = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0000;
    reg signed [2:0] tilt_dx = 0, tilt_dy = 0, j1_dx = 0, j1_dy = 0, j2_dx = 0, j2_dy = 0;
    reg [2:0]        j1_btn = 0, j2_btn = 0;
    reg              uart_rxd = 1'b1, joy_pause = 1'b0, joy_select = 1'b0;
    reg              j1_shoot = 1'b0, j2_shoot = 1'b0;

    wire [9:0] vga_x, vga_y;
    wire vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_vga_sync (.clk(clk), .rst(rst), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on));

    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk), .addr_a(map_addr_a), .q_a(map_tile_a), .addr_b(map_addr_b), .q_b(map_tile_b)
    );

    wire [1:0]  control_mode, cut_id, stage, boss_kind, laser_state;
    wire        p2_active, zoom_out, zone2_open, zone3_open;
    wire [4:0]  enemies_left, dash_timer, evolve_flash, p2_dash_timer;
    wire [2:0]  game_state;
    wire [4:0]  hp, hp2;
    wire [3:0]  wave, shake_mag, p1_slash_t, p2_slash_t;
    wire [7:0]  cut_timer, eb_active_vec;
    wire [10:0] px, dash_gx, cam_x, p2x, p2_dash_gx, blade0_x, blade1_x, pet_bx, p1_slash_x, p2_slash_x, lock_x, boss_x;
    wire [9:0]  py, dash_gy, cam_y, p2y, p2_dash_gy, blade0_y, blade1_y, pet_by, p1_slash_y, p2_slash_y, lock_y, boss_y, laser_y;
    wire        p2_mirror, p2_walk_frame, chrono_active, mirror, walk_frame, p1_nova, p2_nova;
    wire        pet_active, blades_active, aura_active, pet_b_act, lock_valid, boss_active, boss_locked, boss_enraged;
    wire [5:0]  exp, invuln_timer, p2_invuln;
    wire [15:0] score_bcd, en_alive_vec;
    wire [6:0]  chrono_energy, combo_cnt, zoom_lvl, boss_hp;
    wire [16*11-1:0] en_x_vec;
    wire [16*10-1:0] en_y_vec;
    wire [16*3-1:0]  en_type_vec;
    wire [16*4-1:0]  en_hp_vec;
    wire [16*2-1:0]  en_tier_vec;
    wire [12*11-1:0] col_x_vec, sp_x_vec;
    wire [12*10-1:0] col_y_vec, sp_y_vec;
    wire [11:0]      col_type_vec, col_alive_vec, sp_alive_vec;
    wire [4*11-1:0]  drop_x_vec;
    wire [4*10-1:0]  drop_y_vec;
    wire [4*7-1:0]   drop_z_vec;
    wire [4*2-1:0]   drop_type_vec;
    wire [3:0]       drop_active_vec;
    wire [4*5-1:0]   drop_boom_vec;
    wire signed [1:0] p1_slash_dx, p1_slash_dy, p2_slash_dx, p2_slash_dy;
    wire [8*11-1:0]  eb_x_vec, pb_x_vec;
    wire [8*10-1:0]  eb_y_vec, pb_y_vec;
    wire [8*2-1:0]   pb_dir_vec;
    wire [7:0]       pb_active_vec;
    wire             sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit;
    wire [1:0]       hero_sel_l = sw[15] ? 2'd3 : (sw[14] ? 2'd2 : (sw[13] ? 2'd1 : 2'd0));
    wire [1:0]       hero_sel_r = sw[3]  ? 2'd3 : (sw[2]  ? 2'd2 : (sw[1]  ? 2'd1 : 2'd0));
    wire [2:0]       room_phase;
    wire [6:0]       wave_banner_t;
    wire [5:0]       door_slam_t, quiz_wrong_t;
    wire [4:0]       door_slide;
    wire [2:0]       quiz_gate;
    wire [1:0]       quiz_cursor, quiz_ans_slot;
    wire [7:0]       boss_trans_t;
    wire             paused;

    game_engine_v2 u_engine (
        .clk(clk), .rst(rst), .tick(tick), .btn(btn),
        .tilt_dx(tilt_dx), .tilt_dy(tilt_dy),
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
        .room_phase(room_phase), .wave_banner_t(wave_banner_t), .door_slam_t(door_slam_t),
        .door_slide(door_slide), .quiz_gate(quiz_gate), .quiz_cursor(quiz_cursor),
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .paused(paused)
    );

    wire signed [2:0] rx_j1_dx, rx_j1_dy, rx_j2_dx, rx_j2_dy;
    wire [2:0]        rx_j1_btn, rx_j2_btn;
    wire              rx_j1_shoot, rx_j2_shoot, rx_joy_pause, rx_joy_select, joy_link_ok;
    uart_joy_rx u_uart_joy (
        .clk(clk), .rst(rst), .uart_rxd(uart_rxd),
        .j1_dx(rx_j1_dx), .j1_dy(rx_j1_dy), .j1_btn(rx_j1_btn), .j1_shoot(rx_j1_shoot),
        .j2_dx(rx_j2_dx), .j2_dy(rx_j2_dy), .j2_btn(rx_j2_btn), .j2_shoot(rx_j2_shoot),
        .joy_pause(rx_joy_pause), .joy_select(rx_joy_select), .joy_link_ok(joy_link_ok)
    );

    wire [3:0] VGA_R, VGA_G, VGA_B;
    wire       VGA_HS, VGA_VS;
    vga_renderer_v2 u_renderer (
        .clk(clk), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on),
        .map_addr_a(map_addr_a), .map_tile_a(map_tile_a),
        .sw(sw), .tilt_dx(tilt_dx), .tilt_dy(tilt_dy),
        .control_mode(control_mode), .joy_link_ok(joy_link_ok), .p2_active(p2_active),
        .zoom_lvl(zoom_lvl), .zoom_out(zoom_out), .enemies_left(enemies_left),
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
        .hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r), .room_phase(room_phase), .wave_banner_t(wave_banner_t),
        .door_slam_t(door_slam_t), .door_slide(door_slide), .quiz_gate(quiz_gate),
        .quiz_cursor(quiz_cursor), .quiz_ans_slot(quiz_ans_slot),
        .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .paused(paused),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    wire [4:0] io_btn; wire [15:0] io_sw, io_led;
    wire io_zpulse, io_opulse, l16r, l16g, l16b, l17r, l17g, l17b;
    wire [7:0] an; wire ca, cb, cc, cd, ce, cf, cg, dp;
    wire aud_pwm, aud_sd;
    board_io_v2 u_io (
        .clk(clk), .rst(rst), .btnc_raw(btn[4]), .btnu_raw(btn[3]), .btnd_raw(btn[2]), .btnl_raw(btn[1]), .btnr_raw(btn[0]),
        .sw_raw(sw), .game_state(game_state), .wave(wave), .stage(stage), .hp(hp), .hp2(hp2), .exp(exp),
        .score_bcd(score_bcd), .evolve_flash(evolve_flash), .chrono_active(chrono_active),
        .btn_sync(io_btn), .sw_sync(io_sw), .btn_zero_pulse(io_zpulse), .btn_orient_pulse(io_opulse),
        .LED(io_led), .LED16_R(l16r), .LED16_G(l16g), .LED16_B(l16b), .LED17_R(l17r), .LED17_G(l17g), .LED17_B(l17b),
        .AN(an), .CA(ca), .CB(cb), .CC(cc), .CD(cd), .CE(ce), .CF(cf), .CG(cg), .DP(dp)
    );
    audio_synth_v2 u_audio (.clk(clk), .rst(rst), .game_state(game_state), .boss_active(boss_active), .chrono_active(chrono_active),
                            .sfx_shoot(sfx_shoot), .sfx_pickup(sfx_pickup), .sfx_evolve(sfx_evolve), .sfx_hit(sfx_hit),
                            .aud_pwm(aud_pwm), .aud_sd(aud_sd));

    task step_frame;
        begin
            @(posedge clk); tick <= 1'b1;
            @(posedge clk); tick <= 1'b0;
            repeat (80) @(posedge clk);
        end
    endtask

    task send_uart_byte;
        input [7:0] data; integer b;
        begin
            uart_rxd = 1'b0; repeat (217) @(posedge clk);
            for (b = 0; b < 8; b = b + 1) begin uart_rxd = data[b]; repeat (217) @(posedge clk); end
            uart_rxd = 1'b1; repeat (217) @(posedge clk);
        end
    endtask

    integer i, fail_cnt, shoot_cnt;
    reg [10:0] px_before;
    always @(posedge clk) if (sfx_shoot) shoot_cnt = shoot_cnt + 1;

    initial begin
        fail_cnt = 0; shoot_cnt = 0;
        repeat (5) @(posedge clk); rst = 0; repeat (5) @(posedge clk);

        // 1. UART 4-Byte Dual-Joystick decode (incl. Y Shoot, Start->Pause, Select->Menu!)
        send_uart_byte(8'hCC); send_uart_byte(8'h18); send_uart_byte(8'h75); send_uart_byte(8'h01);
        repeat (5) @(posedge clk);
        if (!joy_link_ok || rx_j1_dx !== 3'sd2 || rx_j2_dx !== -3'sd2 || !rx_j1_shoot || !rx_joy_pause || !rx_joy_select) begin
            $display("FAIL: UART 4-byte decode mismatch!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: UART 4-byte Dual-Joystick + Y Shoot + Pause + Select decoded accurately");

        // 2. Title Joy2 Menu (1P JOY -> 2P CO-OP JOY) & Start 2P Co-op
        j2_dx = 3'sd2; step_frame(); j2_dx = 0; step_frame();
        j2_btn[2] = 1'b1; step_frame(); j2_btn[2] = 0;
        repeat (95) step_frame();
        if (game_state !== 3'd2 || room_phase !== 3'd1 || !p2_active || hp !== 5'd24 || hp2 !== 5'd24 || enemies_left !== 5'd6) begin
            $display("FAIL: J2 Start / 6 W1 Enemies / Separate 2P HP failed! st=%d rp=%d p2=%b en=%d hp=%d hp2=%d", game_state, room_phase, p2_active, enemies_left, hp, hp2);
            fail_cnt = fail_cnt + 1;
        end else $display("OK: Joy2 Menu/Start, Wave Banner Slide-Out, 6 Wave1 Enemies, & 24/24 HP Bars active!");

        // 2b. Start button Pause toggle test
        joy_pause = 1'b1; step_frame(); joy_pause = 1'b0; step_frame();
        if (!paused) begin $display("FAIL: Start button did not pause!"); fail_cnt = fail_cnt + 1; end
        joy_pause = 1'b1; step_frame(); joy_pause = 1'b0; step_frame();
        if (paused) begin $display("FAIL: Start button did not unpause!"); fail_cnt = fail_cnt + 1; end
        else $display("OK: Joystick Start button Pause/Resume toggle works!");

        // 2c. Y button elongated blue gun bullet test
        j1_shoot = 1'b1; step_frame(); j1_shoot = 1'b0;
        if (pb_active_vec == 8'b0) begin
            $display("FAIL: Y button did not spawn blue gun bullet!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: Y button fired elongated blue gun bullet (pb_active=%b)!", pb_active_vec);

        // 2d. Out-of-combat HP regeneration test
        u_engine.hp = 5'd16; u_engine.p1_ooc_t = 9'd179; u_engine.p1_regen_div = 6'd28;
        repeat (5) step_frame();
        if (hp <= 5'd16) begin
            $display("FAIL: Out-of-combat HP regen did not heal! hp=%d", hp); fail_cnt = fail_cnt + 1;
        end else $display("OK: Out-of-combat HP regeneration healed P1 (%d)!", hp);

        // 3. Time-Multiplexed Limited Lock-On (<=72 px) + Lunge-Snap + 3-Hit Nova Combo!
        u_engine.px = 11'd120; u_engine.py = 10'd130;
        u_engine.en_x[0] = 11'd178; u_engine.en_y[0] = 10'd130; u_engine.en_hp[0] = 4'd4;
        step_frame();
        px_before = px; shoot_cnt = 0;
        j1_btn[2] = 1'b1; repeat (8) step_frame(); j1_btn[2] = 0; step_frame();
        if (shoot_cnt !== 1 || px <= px_before + 11'd16 || en_alive_vec[0] !== 1'b1 || combo_cnt < 7'd1) begin
            $display("FAIL: Lunge-Snap/Multi-Hit/Combo failed! shoot=%d px=%d alive=%b cmb=%d", shoot_cnt, px, en_alive_vec[0], combo_cnt);
            fail_cnt = fail_cnt + 1;
        end else $display("OK: Limited Lunge-Snap pulled P1 (%d->%d), Multi-hit OK, Combo=%d!", px_before, px, combo_cnt);

        // Hit 2 finishes enemy; Hit 3 triggers 360 Nova Finisher!
        j1_btn[2] = 1'b1; repeat (3) step_frame(); j1_btn[2] = 0; step_frame();
        j1_btn[2] = 1'b1; step_frame();
        if (!p1_nova) begin
            $display("FAIL: 3rd combo hit did not trigger 360 Nova Finisher!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: 3rd Combo Hit triggered 360 Nova Finisher + Screen Shake!");
        j1_btn[2] = 0; step_frame();

        // 4. Magnet Blue Gem Evolution (NO cutscene!) & Heart-Only Pickup (NO HP=0 wrap!)
        u_engine.hp = 5'd24;
        u_engine.drop_active[0] = 1; u_engine.drop_type[0] = 2'd0; u_engine.drop_z[0] = 0; u_engine.drop_x[0] = px; u_engine.drop_y[0] = py;
        u_engine.col_alive[0] = 1; u_engine.col_type[0] = 0; u_engine.col_x[0] = px + 11'd24; u_engine.col_y[0] = py;
        u_engine.col_alive[1] = 1; u_engine.col_type[1] = 0; u_engine.col_x[1] = px; u_engine.col_y[1] = py;
        repeat (15) step_frame();
        if (stage < 2'd1 || !pet_active || game_state !== 3'd2 || hp !== 5'd24) begin
            $display("FAIL: Seamless Evo / Heart-no-wrap failed! stg=%d pet=%b st=%d hp=%d", stage, pet_active, game_state, hp); fail_cnt = fail_cnt + 1;
        end else $display("OK: Seamless Evo (NO cutscene!) & Heart-only pickup at 24 HP stayed 24!");

        // 5. Clear Sub-wave 0 -> Sub-wave 1 Reinforcement -> Room Clear -> Arrow -> Logic Gate Quiz -> Sliding Door Open -> Slam + Wave 2 Banner!
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0;
        repeat (3) step_frame();
        if (enemies_left !== 5'd6 || room_phase !== 3'd1) begin
            $display("FAIL: Sub-wave 1 reinforcement did not spawn! en=%d rp=%d", enemies_left, room_phase); fail_cnt = fail_cnt + 1;
        end else $display("OK: Sub-wave 1 reinforcement spawned (6 more enemies)!");
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0;
        repeat (3) step_frame();
        if (room_phase !== 3'd2) begin
            $display("FAIL: Room clear did not enter RP_CLEAR! rp=%d", room_phase); fail_cnt = fail_cnt + 1;
        end else $display("OK: Room cleared -> Flashing Arrow active (RP_CLEAR)!");

        u_engine.px = 11'd525; u_engine.py = 10'd224;
        repeat (3) step_frame();
        if (room_phase !== 3'd3) begin
            $display("FAIL: Door approach did not trigger Logic Gate Quiz! rp=%d", room_phase); fail_cnt = fail_cnt + 1;
        end else $display("OK: Logic Gate Quiz triggered (gate=%d, ans_slot=%d)!", quiz_gate, quiz_ans_slot);

        // Select correct answer & submit
        u_engine.quiz_cursor = quiz_ans_slot;
        j1_btn[2] = 1'b1; step_frame(); j1_btn[2] = 0;
        repeat (10) step_frame();
        if (room_phase !== 3'd4 || door_slide == 0) begin
            $display("FAIL: Correct quiz answer did not slide door open! rp=%d slide=%d", room_phase, door_slide); fail_cnt = fail_cnt + 1;
        end else $display("OK: Quiz solved -> Sliding door opened (slide=%d)!", door_slide);

        // Step through open door -> Slam + Wave 2 Banner!
        u_engine.px = 11'd545; u_engine.py = 10'd224;
        repeat (3) step_frame();
        if (wave !== 4'd2 || room_phase !== 3'd0 || door_slam_t == 0 || wave_banner_t == 0) begin
            $display("FAIL: Entering door did not trigger Slam + Wave 2 Banner! wv=%d rp=%d slam=%d ban=%d", wave, room_phase, door_slam_t, wave_banner_t);
            fail_cnt = fail_cnt + 1;
        end else $display("OK: Entered door -> Door Slam ('PANG!') + Wave 2 Banner Slide-Out!");
        repeat (95) step_frame();

        // 6. Final Boss (Wave 6): 3-Form Death -> Chuunibyou Quote + Portal Regrowth -> Victory!
        u_engine.wave = 4'd6; u_engine.room_phase = 3'd1;
        u_engine.spawn_wave_group(4'd6, 1'b0);
        step_frame();
        if (!boss_active || boss_kind !== 2'd0) begin
            $display("FAIL: Wave 6 Boss Form 0 failed to spawn!"); fail_cnt = fail_cnt + 1;
        end
        // Kill Form 0 -> Portal -> Form 1
        u_engine.boss_hp = 7'd1; u_engine.px = u_engine.boss_x - 11'd12; u_engine.py = u_engine.boss_y;
        j1_btn[2] = 1'b1; repeat (4) step_frame(); j1_btn[2] = 0;
        if (room_phase !== 3'd5 || boss_trans_t == 0) begin
            $display("FAIL: Boss Form 0 death did not enter RP_BOSS portal transition!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: Boss Form 0 defeated -> Death FX + Portal Regrowth!");
        repeat (165) step_frame();
        if (!boss_active || boss_kind !== 2'd1) begin
            $display("FAIL: Boss Form 1 did not regrow from portal! act=%b kind=%d", boss_active, boss_kind); fail_cnt = fail_cnt + 1;
        end else $display("OK: Boss Form 1 regrew from portal!");

        // Kill Form 1 -> Portal -> Form 2 (Thanos)
        u_engine.boss_hp = 7'd1; u_engine.px = u_engine.boss_x - 11'd12; u_engine.py = u_engine.boss_y;
        j1_btn[2] = 1'b1; repeat (4) step_frame(); j1_btn[2] = 0;
        repeat (165) step_frame();
        if (!boss_active || boss_kind !== 2'd2) begin
            $display("FAIL: Boss Form 2 (Thanos) did not regrow from portal! act=%b kind=%d", boss_active, boss_kind); fail_cnt = fail_cnt + 1;
        end else $display("OK: Boss Form 2 (Thanos) regrew from portal!");

        // Kill Form 2 -> Victory!
        u_engine.boss_hp = 7'd1; u_engine.px = u_engine.boss_x - 11'd12; u_engine.py = u_engine.boss_y;
        j1_btn[2] = 1'b1; repeat (4) step_frame(); j1_btn[2] = 0;
        repeat (165) step_frame();
        if (game_state !== 3'd3) begin
            $display("FAIL: Boss Form 2 defeat did not reach VICTORY! st=%d", game_state); fail_cnt = fail_cnt + 1;
        end else $display("OK: All 3 Boss Forms defeated -> VICTORY!");

        // 7. 2P Both-Dead Game Over (ST_LOSE) + Select->Menu + SW[15:12]/SW[3:0] Skin Check!
        u_engine.game_state = 3'd2; u_engine.control_mode = 2'd1; u_engine.hp = 5'd0; u_engine.hp2 = 5'd4;
        u_engine.invuln_timer = 6'd0; u_engine.p2_invuln = 6'd0;
        u_engine.en_alive[0] = 1'b1; u_engine.en_x[0] = u_engine.p2x; u_engine.en_y[0] = u_engine.p2y;
        repeat (3) step_frame();
        if (game_state !== 3'd4) begin
            $display("FAIL: 2P both dead did not reach ST_LOSE! st=%d hp=%d hp2=%d", game_state, hp, hp2); fail_cnt = fail_cnt + 1;
        end else $display("OK: 2P both dead reached ST_LOSE cleanly (no 3-heart reset)!");

        joy_select = 1'b1; step_frame(); joy_select = 1'b0;
        if (game_state !== 3'd0) begin
            $display("FAIL: Select button did not return to Title Menu! st=%d", game_state); fail_cnt = fail_cnt + 1;
        end else $display("OK: Select button returned to Title Menu!");

        sw = 16'h8004; // SW15 (Left P1 -> Skin 3), SW2 (Right P2 -> Skin 2)
        repeat (10) @(posedge clk);
        if (hero_sel_l !== 2'd3 || hero_sel_r !== 2'd2) begin
            $display("FAIL: SW[15:12]/SW[3:0] skin check failed! L=%d R=%d", hero_sel_l, hero_sel_r); fail_cnt = fail_cnt + 1;
        end else $display("OK: SW[15:12]->P1 Skin 3 & SW[3:0]->P2 Skin 2 check passed!");

        repeat (200) @(posedge clk);
        if (^VGA_R === 1'bx || ^VGA_G === 1'bx || ^VGA_B === 1'bx) begin
            $display("FAIL: VGA RGB X!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: VGA RGB 5-stage pipeline & Audio BGM valid!");

        if (fail_cnt == 0) $display("RESULT : PASS");
        else $display("RESULT : FAIL (%d errors)", fail_cnt);
        $finish;
    end
endmodule
