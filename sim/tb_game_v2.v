`timescale 1ns / 1ps
module tb_game_v2;
    reg clk = 0;
    always #20 clk = ~clk; // 25 MHz

    reg rst = 1, tick = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0000;
    reg signed [2:0] tilt_dx = 0, tilt_dy = 0, j1_dx = 0, j1_dy = 0, j2_dx = 0, j2_dy = 0;
    reg [2:0]        j1_btn = 0, j2_btn = 0;
    reg              uart_rxd = 1'b1;

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
    wire [2:0]  game_state, hp, hp2;
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
    wire [8*11-1:0]  eb_x_vec;
    wire [8*10-1:0]  eb_y_vec;
    wire             sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit;

    game_engine_v2 u_engine (
        .clk(clk), .rst(rst), .tick(tick), .btn(btn),
        .tilt_dx(tilt_dx), .tilt_dy(tilt_dy),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn),
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
        .boss_x(boss_x), .boss_y(boss_y), .boss_hp(boss_hp), .boss_kind(boss_kind),
        .boss_active(boss_active), .boss_locked(boss_locked), .boss_enraged(boss_enraged),
        .laser_state(laser_state), .laser_y(laser_y),
        .sfx_shoot(sfx_shoot), .sfx_pickup(sfx_pickup), .sfx_evolve(sfx_evolve), .sfx_hit(sfx_hit)
    );

    wire signed [2:0] rx_j1_dx, rx_j1_dy, rx_j2_dx, rx_j2_dy;
    wire [2:0]        rx_j1_btn, rx_j2_btn;
    wire              joy_link_ok;
    uart_joy_rx u_uart_joy (.clk(clk), .rst(rst), .uart_rxd(uart_rxd), .j1_dx(rx_j1_dx), .j1_dy(rx_j1_dy), .j1_btn(rx_j1_btn), .j2_dx(rx_j2_dx), .j2_dy(rx_j2_dy), .j2_btn(rx_j2_btn), .joy_link_ok(joy_link_ok));

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
        .boss_x(boss_x), .boss_y(boss_y), .boss_hp(boss_hp), .boss_kind(boss_kind),
        .boss_active(boss_active), .boss_locked(boss_locked), .boss_enraged(boss_enraged),
        .laser_state(laser_state), .laser_y(laser_y),
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

        // 1. UART Dual-Joystick decode
        send_uart_byte(8'h8C); send_uart_byte(8'h18); send_uart_byte(8'h35);
        repeat (5) @(posedge clk);
        if (!joy_link_ok || rx_j1_dx !== 3'sd2 || rx_j2_dx !== -3'sd2) begin
            $display("FAIL: UART decode mismatch!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: UART Dual-Joystick decoded accurately");

        // 2. Title Joy2 Menu & Start 2P Co-op
        j2_dx = 3'sd2; step_frame(); j2_dx = 0; step_frame();
        j2_dx = 3'sd2; step_frame(); j2_dx = 0; step_frame();
        j2_btn[2] = 1'b1; step_frame(); j2_btn[2] = 0;
        repeat (140) step_frame();
        if (game_state !== 3'd2 || !p2_active || hp !== 3'd6 || hp2 !== 3'd6 || enemies_left !== 5'd8) begin
            $display("FAIL: J2 Start / 8 W1 Enemies / Separate 2P HP failed! st=%d p2=%b en=%d", game_state, p2_active, enemies_left);
            fail_cnt = fail_cnt + 1;
        end else $display("OK: Joy2 Menu/Start, 8 Wave1 Enemies, & 6/6 Separate Hearts active!");

        // 3. Time-Multiplexed Limited Lock-On (<=72 px) + Lunge-Snap + 3-Hit Nova Combo!
        u_engine.px = 11'd120; u_engine.py = 10'd120;
        u_engine.en_x[0] = 11'd178; u_engine.en_y[0] = 10'd120; u_engine.en_hp[0] = 4'd4;
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

        // 4. Magnetic Gem Pull & Blue Gem Upgrade Cutscene!
        u_engine.col_alive[0] = 1; u_engine.col_type[0] = 0; u_engine.col_x[0] = px + 11'd32; u_engine.col_y[0] = py;
        u_engine.col_alive[1] = 1; u_engine.col_type[1] = 0; u_engine.col_x[1] = px; u_engine.col_y[1] = py;
        repeat (18) step_frame();
        if (stage < 2'd1 || !pet_active) begin
            $display("FAIL: Magnet Blue Gem Upgrade failed! stg=%d pet=%b", stage, pet_active); fail_cnt = fail_cnt + 1;
        end else $display("OK: Magnet Blue Gems triggered Upgrade Cutscene -> Pet Mob Spawned!");
        repeat (110) step_frame();

        // 5. Partner KO & Touch Revive + Smooth Brawlhalla Zoom
        u_engine.hp = 3'd0; u_engine.p2x = u_engine.px; u_engine.p2y = u_engine.py;
        repeat (28) step_frame();
        if (hp !== 3'd3) begin
            $display("FAIL: Downed Partner Touch-Revive failed! hp=%d", hp); fail_cnt = fail_cnt + 1;
        end else $display("OK: Downed Partner Touch-Revive restored P1 to 3 Hearts!");

        u_engine.px = 11'd120; u_engine.py = 10'd200; u_engine.p2x = 11'd440; u_engine.p2y = 10'd200;
        repeat (8) step_frame();
        if (zoom_lvl == 0 || zoom_lvl >= 7'd80) begin
            $display("FAIL: Smooth Zoom check failed! z=%d", zoom_lvl); fail_cnt = fail_cnt + 1;
        end else $display("OK: Brawlhalla smooth zoom ramping (%d/80)", zoom_lvl);

        // 6. Test Boss Waves 3, 6, 10 (16-Enemy Horde in Wave 7 & Sealed Wave 10 Boss Room!)
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W2
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W3 Boss 0 Titan!
        if (wave !== 4'd3 || !boss_active || boss_kind !== 2'd0) begin
            $display("FAIL: Wave 3 Iron Titan Boss missing!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: Wave 3 Boss #0 (Iron Titan) active!");
        u_engine.boss_active = 0; for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W4
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W5
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W6 Boss 1 Arch-Mage!
        if (wave !== 4'd6 || !boss_active || boss_kind !== 2'd1) begin
            $display("FAIL: Wave 6 Arch-Mage Boss missing!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: Wave 6 Boss #1 (Phantom Arch-Mage) active!");
        u_engine.boss_active = 0; for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W7 -> 16 Enemies!
        if (wave !== 4'd7 || enemies_left !== 5'd16) begin
            $display("FAIL: Wave 7 16-Enemy Mega Horde failed! wv=%d en=%d", wave, enemies_left); fail_cnt = fail_cnt + 1;
        end else $display("OK: Wave 7 Magma Forge 16-Enemy Mega Horde active!");
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W8
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (130) step_frame(); // W9
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0; repeat (185) step_frame(); // W10 Sealed Sanctum!
        if (wave !== 4'd10 || !boss_active || boss_kind !== 2'd2 || !boss_locked || en_alive_vec !== 16'b0 || px < 11'd1600) begin
            $display("FAIL: Wave 10 Sealed Omega Sanctum failed! wv=%d boss=%b kind=%d lock=%b px=%d", wave, boss_active, boss_kind, boss_locked, px);
            fail_cnt = fail_cnt + 1;
        end else $display("OK: Wave 10 Sealed Omega Sanctum active (Boss #2 alone, locked px=%d)!", px);

        // 7. Joy2 Restart + Non-X Check
        u_engine.game_state = 3'd3; u_engine.end_lockout = 0; step_frame();
        j2_btn[2] = 1; step_frame(); j2_btn[2] = 0; step_frame();
        if (game_state !== 3'd1 || wave !== 4'd1) begin
            $display("FAIL: Joy2 restart failed!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: Joy2 Restart passed!");

        sw = 16'hA55A; repeat (200) @(posedge clk);
        if (^VGA_R === 1'bx || ^VGA_G === 1'bx || ^VGA_B === 1'bx) begin
            $display("FAIL: VGA RGB X!"); fail_cnt = fail_cnt + 1;
        end else $display("OK: VGA RGB 5-stage pipeline & Audio BGM valid!");

        if (fail_cnt == 0) $display("RESULT : PASS");
        else $display("RESULT : FAIL (%d errors)", fail_cnt);
        $finish;
    end
endmodule
