`timescale 1ns / 1ps
// Captures 5 pixel-accurate 640x480 VGA screenshots (.ppm) directly from DRAGO-NEXUS V3 OMEGA RTL!
module tb_vga_capture;
    reg clk = 0;
    always #20 clk = ~clk;

    reg rst = 1;
    reg tick = 0;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0000;
    reg signed [2:0] tilt_dx = 0, tilt_dy = 0;
    reg signed [2:0] j1_dx = 0, j1_dy = 0, j2_dx = 0, j2_dy = 0;
    reg [2:0]        j1_btn = 0, j2_btn = 0;
    reg              uart_rxd = 1'b1;

    wire [9:0] vga_x, vga_y;
    wire vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_vga_sync (
        .clk(clk), .rst(rst),
        .x(vga_x), .y(vga_y),
        .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on)
    );

    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk), .addr_a(map_addr_a), .q_a(map_tile_a),
        .addr_b(map_addr_b), .q_b(map_tile_b)
    );

    wire [1:0]  control_mode;
    wire        p2_active;
    wire [6:0]  zoom_lvl;
    wire        zoom_out;
    wire [4:0]  enemies_left;
    wire [2:0]  game_state;
    wire [1:0]  cut_id, stage;
    wire [7:0]  cut_timer;
    wire [3:0]  wave;
    wire        zone2_open, zone3_open;
    wire [10:0] px, dash_gx, cam_x, p2x, p2_dash_gx;
    wire [9:0]  py, dash_gy, cam_y, p2y, p2_dash_gy;
    wire        p2_mirror, p2_walk_frame;
    wire [4:0]  p2_dash_timer;
    wire [4:0]  hp, hp2;
    wire [5:0]  exp;
    wire [15:0] score_bcd;
    wire [6:0]  chrono_energy;
    wire        chrono_active, mirror, walk_frame;
    wire [4:0]  dash_timer, evolve_flash;
    wire [5:0]  invuln_timer, p2_invuln;
    wire [6:0]  combo_cnt;
    wire [3:0]  shake_mag;
    wire        p1_nova, p2_nova;
    wire        pet_active, blades_active, aura_active;
    wire [10:0] blade0_x, blade1_x, pet_bx;
    wire [9:0]  blade0_y, blade1_y, pet_by;
    wire        pet_b_act;

    wire [16*11-1:0] en_x_vec;
    wire [16*10-1:0] en_y_vec;
    wire [16*3-1:0]  en_type_vec;
    wire [15:0]      en_alive_vec;
    wire [16*4-1:0]  en_hp_vec;
    wire [16*2-1:0]  en_tier_vec;

    wire [12*11-1:0] col_x_vec;
    wire [12*10-1:0] col_y_vec;
    wire [11:0]      col_type_vec, col_alive_vec;

    wire [4*11-1:0]  drop_x_vec;
    wire [4*10-1:0]  drop_y_vec;
    wire [4*7-1:0]   drop_z_vec;
    wire [4*2-1:0]   drop_type_vec;
    wire [3:0]       drop_active_vec;
    wire [4*5-1:0]   drop_boom_vec;

    wire [12*11-1:0] sp_x_vec;
    wire [12*10-1:0] sp_y_vec;
    wire [11:0]      sp_alive_vec;

    wire [10:0]       p1_slash_x, p2_slash_x, lock_x;
    wire [9:0]        p1_slash_y, p2_slash_y, lock_y;
    wire [3:0]        p1_slash_t, p2_slash_t;
    wire signed [1:0] p1_slash_dx, p1_slash_dy, p2_slash_dx, p2_slash_dy;
    wire              lock_valid;
    wire [8*11-1:0]   eb_x_vec, pb_x_vec;
    wire [8*10-1:0]   eb_y_vec, pb_y_vec;
    wire [8*2-1:0]    pb_dir_vec;
    wire [7:0]        eb_active_vec, pb_active_vec;

    wire [10:0] boss_x;
    wire [9:0]  boss_y, laser_y;
    wire [7:0]  boss_hp;
    wire [1:0]  boss_kind, laser_state;
    wire        boss_active, boss_locked, boss_enraged;
    wire        sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit;
    wire [1:0]  hero_sel_l = sw[15] ? 2'd3 : (sw[14] ? 2'd2 : (sw[13] ? 2'd1 : 2'd0));
    wire [1:0]  hero_sel_r = sw[3]  ? 2'd3 : (sw[2]  ? 2'd2 : (sw[1]  ? 2'd1 : 2'd0));
    wire [2:0]  room_phase;
    wire [6:0]  wave_banner_t;
    wire [5:0]  door_slam_t;
    wire [6:0]  quiz_wrong_t;
    wire [4:0]  door_slide;
    wire [2:0]  quiz_gate;
    wire [1:0]  quiz_cursor, quiz_ans_slot;
    wire [7:0]  boss_trans_t, outfit_cut_t;
    wire        paused;

    game_engine_v2 u_engine (
        .clk(clk), .rst(rst), .tick(tick), .btn(btn),
        .tilt_dx(tilt_dx), .tilt_dy(tilt_dy),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j1_shoot(1'b0),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .j2_shoot(1'b0), .joy_pause(1'b0), .joy_select(1'b0),
        .map_addr_b(map_addr_b), .map_tile_b(map_tile_b),
        .control_mode(control_mode), .p2_active(p2_active),
        .zoom_lvl(zoom_lvl), .zoom_out(zoom_out), .enemies_left(enemies_left),
        .game_state(game_state), .cut_id(cut_id), .cut_timer(cut_timer),
        .wave(wave), .zone2_open(zone2_open), .zone3_open(zone3_open),
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
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .outfit_cut_t(outfit_cut_t), .paused(paused)
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
        .game_state(game_state), .cut_id(cut_id), .cut_timer(cut_timer),
        .wave(wave), .zone2_open(zone2_open), .zone3_open(zone3_open),
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
        .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t), .outfit_cut_t(outfit_cut_t), .paused(paused),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    task step_frame;
        begin
            @(posedge clk); tick <= 1'b1;
            @(posedge clk); tick <= 1'b0;
            repeat (75) @(posedge clk);
        end
    endtask

    task send_uart_byte;
        input [7:0] data;
        integer b;
        begin
            uart_rxd = 1'b0; repeat (217) @(posedge clk);
            for (b = 0; b < 8; b = b + 1) begin uart_rxd = data[b]; repeat (217) @(posedge clk); end
            uart_rxd = 1'b1; repeat (217) @(posedge clk);
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
            $display("Captured %0s (%0d pixels)", fname, pcnt);
        end
    endtask

    integer i;
    initial begin
        repeat (5) @(posedge clk);
        rst = 0;
        repeat (5) @(posedge clk);

        // Make USB JOY: ONLINE! and select 2P CO-OP JOY
        send_uart_byte(8'h92); send_uart_byte(8'h12); send_uart_byte(8'h00);
        j1_dx = 3'sd2; step_frame(); j1_dx = 3'sd0; step_frame();
        j1_dx = 3'sd2; step_frame(); j1_dx = 3'sd0; step_frame();
        sw = 16'h0010;
        u_renderer.anim_cnt = 26'h0140_0000;

        // SHOT 1: V3 OMEGA Title Screen (Arcade Logo + < 2P CO-OP JOY > + Online Badge)
        capture_ppm("shot_title.ppm");

        // Start 2P Co-op Game & wait for Wave 1 Banner to slide out
        j1_btn[2] = 1'b1; step_frame(); j1_btn[2] = 1'b0;
        repeat (95) step_frame();

        // SHOT 2: Single Rectangular Arena Room + Human Heroes + Human Enemies + 360 Nova!
        u_engine.px = 11'd240; u_engine.py = 10'd210;
        u_engine.p2x = 11'd190; u_engine.p2y = 10'd240;
        u_engine.en_x[0] = 11'd300; u_engine.en_y[0] = 10'd210; u_engine.en_hp[0] = 4'd3; u_engine.en_alive[0] = 1;
        u_engine.en_x[1] = 11'd340; u_engine.en_y[1] = 10'd160; u_engine.en_hp[1] = 4'd2; u_engine.en_alive[1] = 1;
        u_engine.en_x[2] = 11'd280; u_engine.en_y[2] = 10'd270; u_engine.en_hp[2] = 4'd4; u_engine.en_alive[2] = 1;
        u_engine.hp = 3'd5; u_engine.hp2 = 3'd6;
        u_engine.score_bcd = 16'h0480;
        u_engine.p1_combo_step = 2'd2; u_engine.p1_combo_rst = 6'd40;
        step_frame();
        j1_btn[2] = 1'b1; repeat (5) step_frame(); j1_btn[2] = 1'b0;
        u_engine.invuln_timer = 0; u_engine.shake_mag = 0;
        u_renderer.anim_cnt = 26'h0080_0000;
        capture_ppm("shot_combat_lunge.ppm");

        // SHOT 3: Cool Outfit Transformation Cutscene (after Quiz Pass)
        for (i = 0; i < 16; i = i + 1) u_engine.en_alive[i] = 0;
        u_engine.room_phase = 3'd4;
        u_engine.outfit_cut_t = 8'd45; // "EQUIPPED" spotlight phase!
        u_engine.px = 11'd380; u_engine.py = 10'd224;
        u_engine.p2x = 11'd340; u_engine.p2y = 10'd244;
        step_frame();
        u_renderer.anim_cnt = 26'h00C0_0000;
        capture_ppm("shot_upgrade_cutscene.ppm");
        u_engine.outfit_cut_t = 8'd0;

        // SHOT 4: Logic Gate Quiz Modal before Sliding Door!
        u_engine.px = 11'd525; u_engine.py = 10'd224;
        repeat (3) step_frame();
        u_engine.quiz_gate = 3'd5; // XOR Gate!
        step_frame();
        capture_ppm("shot_coop_zoom.ppm");

        // SHOT 5: Final Boss Portal Regrowth + Chuunibyou Quote!
        u_engine.wave = 4'd6; u_engine.room_phase = 3'd5;
        u_engine.boss_kind = 2'd1; u_engine.boss_trans_t = 8'd60;
        u_engine.boss_x = 11'd460; u_engine.boss_y = 10'd224;
        u_engine.px = 11'd180; u_engine.py = 10'd224;
        u_engine.p2x = 11'd180; u_engine.p2y = 10'd260;
        u_engine.cam_x = 11'd60; u_engine.cam_y = 10'd54;
        u_engine.zoom_lvl = 7'd40;
        sw = 16'h0006; // SW1+SW2 -> Skin 2!
        u_renderer.anim_cnt = 26'h0040_0000;
        capture_ppm("shot_boss_locked.ppm");

        $display("ALL 5 REAL V5 RTL SCREENSHOTS CAPTURED!");
        $finish;
    end
endmodule
