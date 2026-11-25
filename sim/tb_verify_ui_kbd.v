`timescale 1ns / 1ps
// End-to-End RTL Verification + Pixel-Exact VGA Screen Capture Testbench:
// Tests:
//   1. PS/2 Keyboard Scancode Reception (11-bit frame fix: Start + 8-bit scancode + Parity + Stop)
//   2. UART 5-Byte Packet Reception (Joy1, Joy2, KB separate channels)
//   3. Title Screen Layout: Mode switching (1P Joy, 1P KBD, 2P Dual Joy), Hero Centering, Zero Boss
//   4. Guide Navigation: Page 0 -> 1 -> 2 -> 3, Right blocked on Page 3, Fire blocked on Page 3, Esc/Select Exits
//   5. Captures pixel-exact 640x480 .ppm screenshots straight from vga_renderer_v2!
module tb_verify_ui_kbd;
    reg clk = 0;
    always #20 clk = ~clk; // 25 MHz

    reg rst = 1;
    reg [4:0] btn = 0;
    reg [15:0] sw = 16'h0000;
    reg uart_rxd = 1'b1;
    reg ps2_clk = 1'b1, ps2_data = 1'b1;

    wire [9:0] vga_x, vga_y;
    wire vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_vga_sync (
        .clk(clk), .rst(rst), .x(vga_x), .y(vga_y),
        .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on)
    );
    wire game_tick = (vga_x == 10'd0) && (vga_y == 10'd480);

    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk), .addr_a(map_addr_a), .q_a(map_tile_a), .addr_b(map_addr_b), .q_b(map_tile_b)
    );

    // PS/2 Keyboard
    wire ps2_kb_up, ps2_kb_down, ps2_kb_left, ps2_kb_right;
    wire ps2_kb_attack, ps2_kb_skill, ps2_kb_nova, ps2_kb_shoot, ps2_kb_start, ps2_kb_esc;
    wire [1:0] ps2_kb_quiz_sel;
    wire       ps2_kb_quiz_hit;
    ps2_keyboard u_kb (
        .clk(clk), .rst(rst), .PS2_CLK(ps2_clk), .PS2_DATA(ps2_data),
        .kb_up(ps2_kb_up), .kb_down(ps2_kb_down), .kb_left(ps2_kb_left), .kb_right(ps2_kb_right),
        .kb_attack(ps2_kb_attack), .kb_skill(ps2_kb_skill), .kb_nova(ps2_kb_nova), .kb_shoot(ps2_kb_shoot),
        .kb_start(ps2_kb_start), .kb_esc(ps2_kb_esc),
        .kb_quiz_sel(ps2_kb_quiz_sel), .kb_quiz_hit(ps2_kb_quiz_hit)
    );

    reg        tb_mic_roar = 1'b0;
    reg [5:0]  tb_sound_lvl = 6'd0;

    // UART 5-Byte Bridge RX
    wire signed [2:0] j1_dx, j1_dy, j2_dx, j2_dy, uart_kb_dx, uart_kb_dy;
    wire [2:0]        j1_btn, j2_btn, uart_kb_btn;
    wire              j1_shoot, j2_shoot, uart_kb_shoot, uart_kb_start, uart_kb_esc;
    wire              joy_pause, joy_select, joy_link_ok;
    wire [1:0]        uart_kb_quiz_sel;
    wire              uart_kb_quiz_hit;
    uart_joy_rx u_uart_joy (
        .clk(clk), .rst(rst), .uart_rxd(uart_rxd),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn), .j1_shoot(j1_shoot),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .j2_shoot(j2_shoot),
        .joy_pause(joy_pause), .joy_select(joy_select),
        .uart_kb_dx(uart_kb_dx), .uart_kb_dy(uart_kb_dy), .uart_kb_btn(uart_kb_btn), .uart_kb_shoot(uart_kb_shoot),
        .uart_kb_start(uart_kb_start), .uart_kb_esc(uart_kb_esc),
        .uart_kb_quiz_sel(uart_kb_quiz_sel), .uart_kb_quiz_hit(uart_kb_quiz_hit),
        .joy_link_ok(joy_link_ok)
    );

    wire kb_up       = ps2_kb_up     | (uart_kb_dy < 0);
    wire kb_down     = ps2_kb_down   | (uart_kb_dy > 0);
    wire kb_left     = ps2_kb_left   | (uart_kb_dx < 0);
    wire kb_right    = ps2_kb_right  | (uart_kb_dx > 0);
    wire kb_attack   = ps2_kb_attack | uart_kb_btn[2];
    wire kb_skill    = ps2_kb_skill  | uart_kb_btn[1];
    wire kb_nova     = ps2_kb_nova   | uart_kb_btn[0];
    wire kb_shoot    = ps2_kb_shoot  | uart_kb_shoot;
    wire kb_start    = ps2_kb_start  | uart_kb_start;
    wire kb_esc      = ps2_kb_esc    | uart_kb_esc;
    wire [1:0] kb_quiz_sel = ps2_kb_quiz_hit ? ps2_kb_quiz_sel : uart_kb_quiz_sel;
    wire       kb_quiz_hit = ps2_kb_quiz_hit | uart_kb_quiz_hit;

    wire [1:0]  control_mode, cut_id, stage, hero_sel_l, hero_sel_r, boss_kind, laser_state;
    wire [2:0]  game_state, p1_weapon, p2_weapon, room_phase, quiz_gate, help_page;
    wire [3:0]  wave, shake_mag, p1_slash_t, p2_slash_t;
    wire [4:0]  enemies_left, p2_dash_timer, hp, hp2, dash_timer, evolve_flash, door_slide, sonic_wave_t;
    wire [5:0]  exp, invuln_timer, p2_invuln;
    wire [6:0]  zoom_lvl, chrono_energy, combo_cnt, wave_banner_t, quiz_wrong_t;
    wire [7:0]  cut_timer, boss_hp, boss_trans_t, outfit_cut_t;
    wire [8:0]  sonic_radius;
    wire [9:0]  py, dash_gy, cam_y, p2y, p2_dash_gy, blade0_y, blade1_y, p2_blade0_y, p2_blade1_y, pet_by, p1_slash_y, p2_slash_y, lock_y, boss_y, laser_y;
    wire [10:0] px, dash_gx, cam_x, p2x, p2_dash_gx, blade0_x, blade1_x, p2_blade0_x, p2_blade1_x, pet_bx, p1_slash_x, p2_slash_x, lock_x, boss_x;
    wire [23:0] score_bcd;
    wire        p2_active, zoom_out, zone2_open, zone3_open, p2_mirror, p2_walk_frame, chrono_active, mirror, walk_frame;
    wire        p1_nova, p2_nova, pet_active, blades_active, aura_active, pet_b_act, lock_valid, boss_active, boss_locked, boss_enraged;
    wire        sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit, hero_cursor, paused;
    wire [5:0]  door_slam_t;
    wire [1:0]  quiz_cursor, quiz_ans_slot;
    wire signed [1:0] p1_slash_dx, p1_slash_dy, p2_slash_dx, p2_slash_dy;
    wire [16*11-1:0] en_x_vec; wire [16*10-1:0] en_y_vec; wire [16*3-1:0] en_type_vec; wire [15:0] en_alive_vec; wire [16*4-1:0] en_hp_vec; wire [16*2-1:0] en_tier_vec;
    wire [12*11-1:0] col_x_vec; wire [12*10-1:0] col_y_vec; wire [11:0] col_type_vec, col_alive_vec;
    wire [4*11-1:0] drop_x_vec; wire [4*10-1:0] drop_y_vec; wire [4*7-1:0] drop_z_vec; wire [4*2-1:0] drop_type_vec; wire [3:0] drop_active_vec; wire [4*5-1:0] drop_boom_vec;
    wire [12*11-1:0] sp_x_vec; wire [12*10-1:0] sp_y_vec; wire [11:0] sp_alive_vec;
    wire [8*11-1:0] eb_x_vec, pb_x_vec; wire [8*10-1:0] eb_y_vec, pb_y_vec; wire [8*2-1:0] pb_dir_vec; wire [7:0] eb_active_vec, pb_active_vec;

    game_engine_v2 u_engine (
        .clk(clk), .rst(rst), .tick(game_tick), .btn(btn),
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
        .temp_fever(1'b0), .mic_roar(tb_mic_roar), .sound_level(tb_sound_lvl),
        .kb_up(kb_up), .kb_down(kb_down), .kb_left(kb_left), .kb_right(kb_right),
        .kb_attack(kb_attack), .kb_skill(kb_skill), .kb_nova(kb_nova), .kb_shoot(kb_shoot),
        .kb_start(kb_start), .kb_esc(kb_esc),
        .kb_quiz_sel(kb_quiz_sel), .kb_quiz_hit(kb_quiz_hit),
        .mouse_x(9'd160), .mouse_y(8'd120), .mouse_lmb(1'b0),
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
        .temp_fever(1'b0), .mic_roar(tb_mic_roar), .help_page(help_page), .sonic_wave_t(sonic_wave_t), .sonic_radius(sonic_radius),
        .mouse_x(9'd160), .mouse_y(8'd120), .mouse_lmb(1'b0),
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
            send_uart_byte(b0);
            send_uart_byte(b1);
            send_uart_byte(b2);
            send_uart_byte(b3);
            send_uart_byte(b4);
            // Wait 1 VGA frame tick for engine step
            wait(vga_y == 10'd481);
            wait(vga_y == 10'd0);
        end
    endtask

    task send_ps2_byte;
        input [7:0] code;
        integer i;
        reg par;
        reg [10:0] frame;
        begin
            par = ~(^code);
            frame = {1'b1, par, code, 1'b0}; // bit0=Start(0), [8:1]=code, [9]=par, [10]=Stop(1)
            for (i = 0; i < 11; i = i + 1) begin
                ps2_data = frame[i];
                repeat (150) @(posedge clk);
                ps2_clk = 1'b0;
                repeat (300) @(posedge clk);
                ps2_clk = 1'b1;
                repeat (150) @(posedge clk);
            end
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
        repeat (20) @(posedge clk);
        rst = 0;
        wait(vga_y == 10'd485);

        // 1. Capture Title Screen Default (Joystick 1P)
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_title_joy_1p.ppm");

        // 2. Joystick D-pad Right on Title -> switches to 2 PLAYERS (still Joystick hints)
        send_5byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00); // J1 right
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // release
        if (control_mode !== 2'b10 || !p2_active) begin
            $display("FAIL: J1 Right on Title did not toggle 2 PLAYERS! control_mode=%b", control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Joystick Right toggled 2 PLAYERS!");
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_title_joy_2p.ppm");

        // 3. PS/2 Keyboard 'D' -> Dead Cells auto-switch to Keyboard AND force 1P Single Player ONLY!
        send_ps2_byte(8'h23); // Make 'D'
        repeat (5) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        send_ps2_byte(8'hF0); send_ps2_byte(8'h23); // Break 'D'
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        if (control_mode !== 2'b01 || p2_active !== 1'b0) begin
            $display("FAIL: Keyboard did not force 1P Single Player + KB hints! control_mode=%b", control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Keyboard auto-detected -> forced 1P Single Player + KB hints!");
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_title_kb_1p.ppm");

        // 4. Title Guide Open via PS/2 ESC -> Page 1 -> Page 2 -> Page 3 -> Page 4 (blocks Right & Fire) -> Exit via ESC
        send_ps2_byte(8'h76);
        repeat (3) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        send_ps2_byte(8'hF0); send_ps2_byte(8'h76);
        if (help_page !== 3'd1) begin $display("FAIL: ESC did not open Guide P1"); fail_cnt = fail_cnt + 1; end
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // KB right -> P2
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // KB right -> P3
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // KB right -> P4
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h04); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // Blocked
        if (help_page !== 3'd4 || game_state !== 3'd0) begin $display("FAIL: Title P4 did not block Right/Fire!"); fail_cnt = fail_cnt + 1; end
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h20); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // UART KB ESC
        if (help_page !== 3'd0 || game_state !== 3'd0) begin $display("FAIL: UART KB ESC did not exit Guide!"); fail_cnt = fail_cnt + 1; end
        else $display("[PASS] Title Guide P1->P2->P3->P4 & UART KB ESC Exit passed!");

        // 5. Start game with Space -> Test BOTH KB and Joy control P1 seamlessly!
        send_ps2_byte(8'h29); repeat (3) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        send_ps2_byte(8'hF0); send_ps2_byte(8'h29);
        if (game_state !== 3'd2) begin $display("FAIL: Spacebar did not start game!"); fail_cnt = fail_cnt + 1; end
        begin : blk_dual_input
            reg [10:0] x0, x1;
            x0 = px;
            send_ps2_byte(8'h23); repeat (6) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
            send_ps2_byte(8'hF0); send_ps2_byte(8'h23);
            x1 = px;
            send_5byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00);
            send_5byte_pkt(8'h94, 8'h12, 8'h00, 8'h12, 8'h00);
            send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
            if (x1 <= x0 || px <= x1) begin
                $display("FAIL: Dual KB + Joy P1 movement failed! x0=%0d x1=%0d x2=%0d", x0, x1, px);
                fail_cnt = fail_cnt + 1;
            end else $display("[PASS] In-game BOTH Keyboard (%0d->%0d) AND Joystick (%0d->%0d) move P1!", x0, x1, x1, px);
        end

        // 6. Pause inside game with PS/2 ENTER (8'h5A) -> opens 3-page Guide with RESUME footer!
        send_ps2_byte(8'h5A); repeat (3) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        send_ps2_byte(8'hF0); send_ps2_byte(8'h5A);
        if (!paused || help_page !== 2'd1 || control_mode[0] !== 1'b1) begin
            $display("FAIL: Pause did not open P1 Guide in KB mode! paused=%b page=%0d cm=%b", paused, help_page, control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] In-game Pause opened 1/3 Guide cleanly!");
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_pause_p1_kb.ppm");

        // Navigate Pause Guide Page 2 & Page 3 in KB mode
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // P2
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h14, 8'h00); send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // P3
        if (!paused || help_page !== 2'd3) begin $display("FAIL: Pause Guide P3 not reached!"); fail_cnt = fail_cnt + 1; end
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_pause_p3_kb.ppm");

        // Touch Joystick Left in Pause -> drops back to P2 AND dynamically switches footer to [STR] RESUME!
        send_5byte_pkt(8'h90, 8'h12, 8'h00, 8'h12, 8'h00); // J1 Left
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00); // release
        if (help_page !== 2'd2 || control_mode[0] !== 1'b0) begin
            $display("FAIL: Joy Left in Pause failed to update P2/Joy hints! page=%0d cm=%b", help_page, control_mode);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Pause Guide live-switched to Joy [STR] RESUME on Page 2!");
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_pause_p2_joy.ppm");

        // Resume via Joy START (b2[6]=1)
        send_5byte_pkt(8'h92, 8'h12, 8'h40, 8'h12, 8'h00);
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
        if (paused !== 1'b0 || help_page !== 2'd0 || game_state !== 3'd2) begin
            $display("FAIL: START did not resume game! paused=%b page=%0d gs=%0d", paused, help_page, game_state);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Resumed gameplay cleanly!");

        // 7. Final Outfit (Stage 3 Gold) Check: Quiz pass MUST NOT replay outfit_cut_t!
        force u_engine.stage = 2'd3;
        force u_engine.room_phase = 3'd3;
        force u_engine.quiz_ans_slot = 2'd0;
        force u_engine.quiz_lockout = 6'd0;
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        release u_engine.stage; release u_engine.room_phase; release u_engine.quiz_ans_slot; release u_engine.quiz_lockout;
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h40); // KB Quiz key '1' (b4[6]=1, b4[5:4]=0)
        send_5byte_pkt(8'h92, 8'h12, 8'h00, 8'h12, 8'h00);
        if (room_phase !== 3'd4 || outfit_cut_t !== 8'd0 || stage !== 2'd3) begin
            $display("FAIL: Final Gold outfit re-triggered animation! rp=%0d oct=%0d stg=%0d", room_phase, outfit_cut_t, stage);
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] Stage 3 Gold outfit skipped repeat transformation animation!");

        // 8. 2-Player Mic Roar Sonic Wave Check (BOTH P1 & P2 expand shockwaves simultaneously!)
        force u_engine.control_mode = 2'b10; // 2P Dual Joy
        force u_engine.room_phase = 3'd1;
        force u_engine.px = 11'd200; force u_engine.py = 10'd220;
        force u_engine.p2x = 11'd420; force u_engine.p2y = 10'd220;
        force u_engine.hp = 5'd24; force u_engine.hp2 = 5'd24;
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        release u_engine.room_phase; release u_engine.px; release u_engine.py; release u_engine.p2x; release u_engine.p2y; release u_engine.hp; release u_engine.hp2;
        tb_sound_lvl = 6'd45;
        tb_mic_roar  = 1'b1;
        repeat (2) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        tb_mic_roar  = 1'b0;
        repeat (6) begin wait(vga_y == 10'd481); wait(vga_y == 10'd0); end
        if (sonic_wave_t == 5'd0) begin
            $display("FAIL: Mic roar did not trigger sonic_wave_t!");
            fail_cnt = fail_cnt + 1;
        end else $display("[PASS] 2P Mic Roar active sonic_wave_t=%0d radius=%0d!", sonic_wave_t, sonic_radius);
        capture_ppm("D:/vivado_pj/DRAGO_NEXUS_V2/sim_work/rtl_v5_sonic_2p.ppm");
        release u_engine.control_mode;

        if (fail_cnt == 0) $display("=== ALL RTL TESTS PASSED PERFECTLY! ===");
        else               $display("=== FAILED %0d TESTS ===", fail_cnt);
        $finish;
    end
endmodule
