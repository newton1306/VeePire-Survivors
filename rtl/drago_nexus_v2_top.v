`timescale 1ns / 1ps
// DRAGO-NEXUS V3 OMEGA EDITION Top-Level for Digilent Nexys A7-100T
module drago_nexus_v2_top (
    input  wire        CLK100MHZ,
    input  wire        CPU_RESETN,
    input  wire        BTNC, BTNU, BTND, BTNL, BTNR,
    input  wire [15:0] SW,

    input  wire        ACL_MISO,
    output wire        ACL_MOSI, ACL_SCLK, ACL_CSN,

    input  wire        UART_TXD_IN,

    output wire [15:0] LED,
    output wire        LED16_R, LED16_G, LED16_B,
    output wire        LED17_R, LED17_G, LED17_B,
    output wire [7:0]  AN,
    output wire        CA, CB, CC, CD, CE, CF, CG, DP,

    output wire [3:0]  VGA_R, VGA_G, VGA_B,
    output wire        VGA_HS, VGA_VS,

    output wire        AUD_PWM, AUD_SD
);
    wire clk25, clk_locked;
    clk_gen u_clk (.clk100(CLK100MHZ), .clk25(clk25), .locked(clk_locked));

    reg [2:0] rst_sr = 3'b111;
    wire ext_rst = !CPU_RESETN || !clk_locked;
    always @(posedge clk25) begin
        if (ext_rst) rst_sr <= 3'b111;
        else         rst_sr <= {rst_sr[1:0], 1'b0};
    end
    wire rst = rst_sr[2];

    wire [9:0] vga_x, vga_y;
    wire       vga_hsync, vga_vsync, vga_video_on;
    vga_sync u_vga_sync (
        .clk(clk25), .rst(rst), .x(vga_x), .y(vga_y),
        .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on)
    );
    wire game_tick = (vga_x == 10'd0) && (vga_y == 10'd480);

    // 128 x 64 Dual-Port World Map (8192 x 4-bit tiles = 2048 x 1024 px!)
    wire [12:0] map_addr_a, map_addr_b;
    wire [3:0]  map_tile_a, map_tile_b;
    rom_dp #(.DW(4), .AW(13), .DEPTH(8192), .FILE("tilemap.mem")) u_tilemap (
        .clk(clk25), .addr_a(map_addr_a), .q_a(map_tile_a), .addr_b(map_addr_b), .q_b(map_tile_b)
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
    wire [2:0]  hp, hp2;
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
    wire [8*11-1:0]   eb_x_vec;
    wire [8*10-1:0]   eb_y_vec;
    wire [7:0]        eb_active_vec;

    wire [10:0] boss_x;
    wire [9:0]  boss_y, laser_y;
    wire [6:0]  boss_hp;
    wire [1:0]  boss_kind, laser_state;
    wire        boss_active, boss_locked, boss_enraged;
    wire        sfx_shoot, sfx_pickup, sfx_evolve, sfx_hit;

    wire [4:0]  btn_sync;
    wire [15:0] sw_sync;
    wire        btn_zero_pulse, btn_orient_pulse;
    board_io_v2 u_board_io (
        .clk(clk25), .rst(rst),
        .btnc_raw(BTNC), .btnu_raw(BTNU), .btnd_raw(BTND), .btnl_raw(BTNL), .btnr_raw(BTNR),
        .sw_raw(SW), .game_state(game_state), .wave(wave), .stage(stage), .hp(hp), .hp2(hp2), .exp(exp),
        .score_bcd(score_bcd), .evolve_flash(evolve_flash), .chrono_active(chrono_active),
        .btn_sync(btn_sync), .sw_sync(sw_sync), .btn_zero_pulse(btn_zero_pulse), .btn_orient_pulse(btn_orient_pulse),
        .LED(LED), .LED16_R(LED16_R), .LED16_G(LED16_G), .LED16_B(LED16_B),
        .LED17_R(LED17_R), .LED17_G(LED17_G), .LED17_B(LED17_B),
        .AN(AN), .CA(CA), .CB(CB), .CC(CC), .CD(CD), .CE(CE), .CF(CF), .CG(CG), .DP(DP)
    );

    wire signed [7:0] raw_x, raw_y;
    wire signed [2:0] tilt_dx, tilt_dy;
    wire [1:0]        orient_mode;
    acl_tilt u_acl_tilt (
        .clk(clk25), .rst(rst), .miso(ACL_MISO), .sclk(ACL_SCLK), .mosi(ACL_MOSI), .csn(ACL_CSN),
        .btn_zero(btn_zero_pulse), .btn_orient(1'b0),
        .raw_x(raw_x), .raw_y(raw_y), .tilt_dx(tilt_dx), .tilt_dy(tilt_dy), .orient_mode(orient_mode)
    );

    wire signed [2:0] j1_dx, j1_dy, j2_dx, j2_dy;
    wire [2:0]        j1_btn, j2_btn;
    wire              joy_link_ok;
    uart_joy_rx u_uart_joy (
        .clk(clk25), .rst(rst), .uart_rxd(UART_TXD_IN),
        .j1_dx(j1_dx), .j1_dy(j1_dy), .j1_btn(j1_btn),
        .j2_dx(j2_dx), .j2_dy(j2_dy), .j2_btn(j2_btn), .joy_link_ok(joy_link_ok)
    );

    wire signed [2:0] hud_dx = (control_mode == 2'd0) ? tilt_dx : j1_dx;
    wire signed [2:0] hud_dy = (control_mode == 2'd0) ? tilt_dy : j1_dy;

    // SW[3:0] Priority Human-Face Skin Selector (highest ON switch wins, no mixing!)
    wire [1:0] hero_sel = sw_sync[3] ? 2'd3 :
                          sw_sync[2] ? 2'd2 :
                          sw_sync[1] ? 2'd1 : 2'd0;

    wire [2:0] room_phase;
    wire [6:0] wave_banner_t;
    wire [5:0] door_slam_t, quiz_wrong_t;
    wire [4:0] door_slide;
    wire [2:0] quiz_gate;
    wire [1:0] quiz_cursor, quiz_ans_slot;
    wire [7:0] boss_trans_t;

    game_engine_v2 u_engine (
        .clk(clk25), .rst(rst), .tick(game_tick), .btn(btn_sync),
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
        .sfx_shoot(sfx_shoot), .sfx_pickup(sfx_pickup), .sfx_evolve(sfx_evolve), .sfx_hit(sfx_hit),
        .room_phase(room_phase), .wave_banner_t(wave_banner_t), .door_slam_t(door_slam_t),
        .door_slide(door_slide), .quiz_gate(quiz_gate), .quiz_cursor(quiz_cursor),
        .quiz_ans_slot(quiz_ans_slot), .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t)
    );

    vga_renderer_v2 u_renderer (
        .clk(clk25), .x(vga_x), .y(vga_y), .hsync(vga_hsync), .vsync(vga_vsync), .video_on(vga_video_on),
        .map_addr_a(map_addr_a), .map_tile_a(map_tile_a),
        .sw(sw_sync), .tilt_dx(hud_dx), .tilt_dy(hud_dy),
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
        .hero_sel(hero_sel), .room_phase(room_phase), .wave_banner_t(wave_banner_t),
        .door_slam_t(door_slam_t), .door_slide(door_slide), .quiz_gate(quiz_gate),
        .quiz_cursor(quiz_cursor), .quiz_ans_slot(quiz_ans_slot),
        .quiz_wrong_t(quiz_wrong_t), .boss_trans_t(boss_trans_t),
        .VGA_R(VGA_R), .VGA_G(VGA_G), .VGA_B(VGA_B), .VGA_HS(VGA_HS), .VGA_VS(VGA_VS)
    );

    audio_synth_v2 u_audio (
        .clk(clk25), .rst(rst), .game_state(game_state), .boss_active(boss_active), .chrono_active(chrono_active),
        .sfx_shoot(sfx_shoot), .sfx_pickup(sfx_pickup), .sfx_evolve(sfx_evolve), .sfx_hit(sfx_hit),
        .aud_pwm(AUD_PWM), .aud_sd(AUD_SD)
    );
endmodule
