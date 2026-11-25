`timescale 1ns / 1ps
// V8 Verification: Quiz-Only Mouse Support + 4/4 MOUSE CONTROLS Guide Page
module tb_v8_mouse_quiz;
    reg clk = 0;
    always #20 clk = ~clk; // 25 MHz

    reg rst = 1;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0000;
    reg uart_rxd = 1'b1;

    wire [9:0] vga_x, vga_y;
    wire vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_vga_sync (
        .clk(clk), .rst(rst), .x(vga_x), .y(vga_y),
        .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on)
    );
    wire game_tick = (vga_x == 10'd0) && (vga_y == 10'd480);
    reg  fast_tick_en = 1'b1;
    reg  fast_tick_p  = 1'b0;
    wire eff_tick     = fast_tick_en ? fast_tick_p : game_tick;

    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk), .addr_a(map_addr_a), .q_a(map_tile_a), .addr_b(map_addr_b), .q_b(map_tile_b)
    );

    wire signed [2:0] j1_dx, j1_dy, j2_dx, j2_dy, ukb_dx, ukb_dy;
    wire [2:0]        j1_btn, j2_btn, ukb_btn;
    wire              j1_shoot, j2_shoot, ukb_shoot, ukb_start, ukb_esc;
    wire              joy_pause, joy_select, joy_link_ok;
    wire [1:0]        ukb_quiz_sel;
    wire              ukb_quiz_hit;
    wire [8:0]        mouse_x;
    wire [7:0]        mouse_y;
    wire              mouse_lmb;
    uart_joy_rx u_uart_joy (
        .clk(clk), .rst(rst), .uart_rxd(uart_rxd),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j1_shoot(j1_shoot),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .j2_shoot(j2_shoot),
        .joy_pause(joy_pause), .joy_select(joy_select),
        .uart_kb_dx(ukb_dx), .uart_kb_dy(ukb_dy), .uart_kb_btn(ukb_btn), .uart_kb_shoot(ukb_shoot),
        .uart_kb_start(ukb_start), .uart_kb_esc(ukb_esc),
        .uart_kb_quiz_sel(ukb_quiz_sel), .uart_kb_quiz_hit(ukb_quiz_hit),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_lmb(mouse_lmb),
        .joy_link_ok(joy_link_ok)
    );

    wire kb_up    = (ukb_dy < 0);
    wire kb_down  = (ukb_dy > 0);
    wire kb_left  = (ukb_dx < 0);
    wire kb_right = (ukb_dx > 0);

    wire [1:0]  control_mode, hero_sel_l, hero_sel_r, quiz_cursor, quiz_ans_slot;
    wire [2:0]  game_state, room_phase, p1_weapon, p2_weapon, help_page;
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
        .clk(clk), .rst(rst), .tick(eff_tick), .btn(btn),
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
        .temp_fever(sw[0]), .mic_roar(1'b0), .sound_level(6'd0),
        .kb_up(kb_up), .kb_down(kb_down), .kb_left(kb_left), .kb_right(kb_right),
        .kb_attack(ukb_btn[2]), .kb_skill(ukb_btn[1]), .kb_nova(ukb_btn[0]), .kb_shoot(ukb_shoot),
        .kb_start(ukb_start), .kb_esc(ukb_esc),
        .kb_quiz_sel(ukb_quiz_sel), .kb_quiz_hit(ukb_quiz_hit),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_lmb(mouse_lmb),
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
        .temp_fever(sw[0]), .mic_roar(1'b0), .help_page(help_page), .sonic_wave_t(sonic_wave_t), .sonic_radius(sonic_radius),
        .mouse_x(mouse_x), .mouse_y(mouse_y), .mouse_lmb(mouse_lmb),
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

    task send_8byte_pkt;
        input [7:0] b0, b1, b2, b3, b4;
        input [8:0] mx;
        input [7:0] my;
        input       mlmb;
        reg [7:0] b5, b6, b7;
        begin
            b5 = {1'b0, mlmb, mx[8:3]};
            b6 = {1'b0, mx[2:0], my[7:4]};
            b7 = {1'b0, 3'b000, my[3:0]};
            send_uart_byte(b0); send_uart_byte(b1); send_uart_byte(b2); send_uart_byte(b3);
            send_uart_byte(b4); send_uart_byte(b5); send_uart_byte(b6); send_uart_byte(b7);
            @(negedge clk); fast_tick_p = 1'b1;
            @(posedge clk); #1; fast_tick_p = 1'b0;
            repeat (64) @(posedge clk);
        end
    endtask

    task capture_ppm;
        input [8*64-1:0] fname;
        integer fd, pcnt;
        begin
            fast_tick_en = 1'b0;
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
            fast_tick_en = 1'b1;
            $display("[PPM] Captured %0s (%0d pixels)", fname, pcnt);
        end
    endtask

    integer fail_cnt = 0;
    initial begin
        repeat (20) @(posedge clk);
        rst = 0;
        repeat (50) @(posedge clk);

        // 1. Verify Mouse on Title Screen does NOT start game & does NOT auto-detect control_mode[0]!
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b1);
        if (mouse_x !== 9'd150 || mouse_y !== 8'd148 || mouse_lmb !== 1'b1) begin
            $display("FAIL: 8-byte UART mouse decode mismatch (%0d,%0d,%b)", mouse_x, mouse_y, mouse_lmb);
            fail_cnt = fail_cnt + 1;
        end
        if (game_state !== 3'd0 || control_mode !== 2'b00) begin
            $display("FAIL: Mouse touched Title state or auto-detect control_mode! gs=%0d cm=%b", game_state, control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] 8-byte UART mouse decoded & ignored on Title (zero auto-detect)!");
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);

        // 2. Navigate Controls Guide 1/4 -> 2/4 -> 3/4 -> 4/4 (Mouse Controls Page!)
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h08, 9'd150, 8'd148, 1'b0); // Joy Select -> P1
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);
        if (help_page !== 3'd1) begin $display("FAIL: Guide P1 not opened"); fail_cnt = fail_cnt + 1; end
        send_8byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0); // P2
        send_8byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0); // P3
        send_8byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0); // P4
        send_8byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0); // Right blocked on P4
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd148, 1'b0);
        if (help_page !== 3'd4) begin $display("FAIL: Guide did not reach/clamp at Page 4! page=%0d", help_page); fail_cnt = fail_cnt + 1; end
        else $display("[PASS] Controls Guide reached 4/4 MOUSE CONTROLS!");
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v8_guide_p4_mouse.ppm");

        // Exit Guide back to Title and start game
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h08, 9'd160, 8'd120, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd160, 8'd120, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h04, 8'h12, 8'h00, 9'd160, 8'd120, 1'b0); // J1 Fire -> Play
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd160, 8'd120, 1'b0);
        if (game_state !== 3'd2) begin $display("FAIL: Game did not start"); fail_cnt = fail_cnt + 1; end

        // 3. Mouse during active RP_FIGHT MUST NOT attack/shoot or alter control_mode
        force u_engine.room_phase = 3'd1;
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd140, 8'd148, 1'b1);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd140, 8'd148, 1'b0);
        if (p1_slash_t !== 4'd0 || control_mode !== 2'b00) begin
            $display("FAIL: Mouse triggered slash or auto-detect in FIGHT! slash=%0d cm=%b", p1_slash_t, control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Mouse completely ignored during RP_FIGHT!");
        release u_engine.room_phase;

        // 4. Enter RP_QUIZ -> Mouse hover moves quiz_cursor; stationary mouse leaves Joy D-Pad free!
        force u_engine.room_phase    = 3'd3;
        force u_engine.quiz_gate     = 3'd5; // XOR
        force u_engine.quiz_ans_slot = 2'd2; // Row 2 = XOR
        force u_engine.quiz_lockout  = 6'd0;
        force u_engine.quiz_wrong_t  = 7'd0;
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd148, 8'd118, 1'b0); // Hover Row 0 first
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd148, 8'd148, 1'b0); // Move mouse -> Row 2!
        if (quiz_cursor !== 2'd2) begin
            $display("FAIL: Mouse hover Row 2 did not move quiz_cursor! cur=%0d", quiz_cursor);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Mouse hover snapped quiz_cursor to Row 2!");

        // Keep mouse stationary and press Joy DOWN -> cursor moves to Row 3 cleanly
        send_8byte_pkt(8'h9A, 8'h12, 8'h00, 8'h12, 8'h00, 9'd148, 8'd148, 1'b0);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd148, 8'd148, 1'b0);
        if (quiz_cursor !== 2'd3) begin
            $display("FAIL: Joy DOWN blocked by stationary mouse! cur=%0d", quiz_cursor);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Stationary mouse preserved Joy/KB D-pad selection!");

        // Move mouse slightly back over Row 2 (hover highlight + cursor sprite visual capture!)
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd154, 8'd148, 1'b0);
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v8_quiz_mouse.ppm");

        // 5. Release forces so engine can transition quiz_wrong_t / RP_DOOR naturally
        release u_engine.room_phase; release u_engine.quiz_gate;
        release u_engine.quiz_ans_slot; release u_engine.quiz_lockout; release u_engine.quiz_wrong_t;

        // Place in RP_QUIZ state cleanly via force/release single edge? Set internal state cleanly via hierarchical step at negetive clock or test wrong click & pass click:
        @(negedge clk);
        u_engine.room_phase    = 3'd3;
        u_engine.quiz_gate     = 3'd5;
        u_engine.quiz_ans_slot = 2'd2;
        u_engine.quiz_lockout  = 6'd0;
        u_engine.quiz_wrong_t  = 7'd0;
        // Click WRONG option (Row 0: gy=118)
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd118, 1'b1);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd118, 1'b0);
        if (quiz_wrong_t === 7'd0) begin
            $display("FAIL: Wrong mouse click did not trigger quiz_wrong_t!");
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Wrong LMB click triggered quiz_wrong_t (%0d)!", quiz_wrong_t);

        // Reset quiz back to active and click CORRECT option (quiz_ans_slot)
        @(negedge clk);
        u_engine.quiz_wrong_t  = 7'd0;
        u_engine.quiz_lockout  = 6'd0;
        u_engine.quiz_ans_slot = 2'd2;
        u_engine.stage         = 2'd0;
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd150, 1'b1);
        send_8byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00, 9'd150, 8'd150, 1'b0);
        if (room_phase !== 3'd4) begin
            $display("FAIL: Correct LMB click did not advance to RP_DOOR! rp=%0d", room_phase);
            fail_cnt = fail_cnt + 1;
        end else if (control_mode !== 2'b00) begin
            $display("FAIL: Mouse Quiz activity mutated control_mode=%b!", control_mode);
            fail_cnt = fail_cnt + 1;
        end else begin
            $display("[PASS] Correct LMB click passed Quiz -> RP_DOOR (control_mode still %b)!", control_mode);
        end

        if (fail_cnt == 0) $display("=== ALL V8 MOUSE QUIZ + GUIDE TESTS PASSED! ===");
        else $display("=== V8 TESTS FAILED (%0d failures) ===", fail_cnt);
        $finish;
    end
endmodule
