`timescale 1ns / 1ps
// DRAGO-NEXUS V3 OMEGA EDITION: Zero-Bottleneck 5-Stage Pipelined VGA Renderer
//   - Registered Stage -1 -> Stage 0 splits Zoom Multiplier from ROM & Sprite Checks!
//   - Metallic 160x48 Arcade Title Logo ROM + < MODE > Arrows
//   - 32x32 Hero Sprites (4 Frames incl. Lunge & Apex Poses) + SW[15:0] 65K Skins
//   - 16 Huge 32x32 Monsters w/ Tiny 16x2 HP Bars + 3 Unique 64x64 Bosses
//   - 360 Nova Whirlwind Finisher, 12 Hit Sparks, Dual 2P Hearts, Combo Rank HUD
module vga_renderer_v2 (
    input  wire        clk,
    input  wire [9:0]  x, y,
    input  wire        hsync, vsync, video_on,

    output wire [12:0] map_addr_a,
    input  wire [3:0]  map_tile_a,

    input  wire [15:0] sw,
    input  wire signed [2:0] tilt_dx,
    input  wire signed [2:0] tilt_dy,

    input  wire [1:0]  control_mode,
    input  wire        joy_link_ok,
    input  wire        p2_active,
    input  wire [6:0]  zoom_lvl,
    input  wire        zoom_out,
    input  wire [4:0]  enemies_left,
    input  wire [2:0]  game_state,
    input  wire [1:0]  cut_id,
    input  wire [7:0]  cut_timer,
    input  wire [3:0]  wave,
    input  wire        zone2_open,
    input  wire        zone3_open,
    input  wire [10:0] px, dash_gx, cam_x, p2x, p2_dash_gx,
    input  wire [9:0]  py, dash_gy, cam_y, p2y, p2_dash_gy,
    input  wire        p2_mirror, p2_walk_frame,
    input  wire [4:0]  p2_dash_timer,
    input  wire [4:0]  hp, hp2,
    input  wire [5:0]  exp,
    input  wire [1:0]  stage,
    input  wire [23:0] score_bcd,
    input  wire [2:0]  p1_weapon, p2_weapon,
    input  wire        hero_cursor,
    input  wire [6:0]  chrono_energy,
    input  wire        chrono_active,
    input  wire        mirror, walk_frame,
    input  wire [4:0]  dash_timer, evolve_flash,
    input  wire [5:0]  invuln_timer, p2_invuln,

    input  wire [6:0]  combo_cnt,
    input  wire [3:0]  shake_mag,
    input  wire        p1_nova, p2_nova,

    input  wire        pet_active, blades_active, aura_active,
    input  wire [10:0] blade0_x, blade1_x, p2_blade0_x, p2_blade1_x, pet_bx,
    input  wire [9:0]  blade0_y, blade1_y, p2_blade0_y, p2_blade1_y, pet_by,
    input  wire        pet_b_act,

    input  wire [16*11-1:0] en_x_vec,
    input  wire [16*10-1:0] en_y_vec,
    input  wire [16*3-1:0]  en_type_vec,
    input  wire [15:0]      en_alive_vec,
    input  wire [16*4-1:0]  en_hp_vec,
    input  wire [16*2-1:0]  en_tier_vec,

    input  wire [12*11-1:0] col_x_vec,
    input  wire [12*10-1:0] col_y_vec,
    input  wire [11:0]      col_type_vec,
    input  wire [11:0]      col_alive_vec,

    input  wire [4*11-1:0] drop_x_vec,
    input  wire [4*10-1:0] drop_y_vec,
    input  wire [4*7-1:0]  drop_z_vec,
    input  wire [4*2-1:0]  drop_type_vec,
    input  wire [3:0]      drop_active_vec,
    input  wire [4*5-1:0]  drop_boom_vec,

    input  wire [12*11-1:0] sp_x_vec,
    input  wire [12*10-1:0] sp_y_vec,
    input  wire [11:0]      sp_alive_vec,

    input  wire [10:0]      p1_slash_x, p2_slash_x, lock_x,
    input  wire [9:0]       p1_slash_y, p2_slash_y, lock_y,
    input  wire [3:0]       p1_slash_t, p2_slash_t,
    input  wire signed [1:0] p1_slash_dx, p1_slash_dy, p2_slash_dx, p2_slash_dy,
    input  wire             lock_valid,

    input  wire [8*11-1:0] eb_x_vec, pb_x_vec,
    input  wire [8*10-1:0] eb_y_vec, pb_y_vec,
    input  wire [8*2-1:0]  pb_dir_vec,
    input  wire [7:0]      eb_active_vec, pb_active_vec,

    input  wire [10:0] boss_x,
    input  wire [9:0]  boss_y, laser_y,
    input  wire [7:0]  boss_hp,
    input  wire [1:0]  boss_kind,
    input  wire        boss_active, boss_locked, boss_enraged,
    input  wire [1:0]  laser_state,

    input  wire [1:0]  hero_sel_l, hero_sel_r,
    input  wire [2:0]  room_phase,
    input  wire [6:0]  wave_banner_t,
    input  wire [5:0]  door_slam_t,
    input  wire [4:0]  door_slide,
    input  wire [2:0]  quiz_gate,
    input  wire [1:0]  quiz_cursor,
    input  wire [1:0]  quiz_ans_slot,
    input  wire [6:0]  quiz_wrong_t,
    input  wire [7:0]  boss_trans_t,
    input  wire [7:0]  outfit_cut_t,
    input  wire        paused,
    input  wire        temp_fever,
    input  wire        mic_roar,
    input  wire [1:0]  help_page,
    input  wire [4:0]  sonic_wave_t,
    input  wire [8:0]  sonic_radius,

    output reg  [3:0]  VGA_R = 0, VGA_G = 0, VGA_B = 0,
    output reg         VGA_HS = 1, VGA_VS = 1
);
`include "joy_palette.vh"
`include "kb_palette.vh"
    reg [25:0] anim_cnt = 0;
    always @(posedge clk) anim_cnt <= anim_cnt + 26'd1;

    // Hardware visual theme defaults (SW[15:11] reserved for Audio, SW[1:0] for Temp/Fever)
    wire [2:0] skin_model  = 3'd0;
    wire [3:0] skin_chroma = 4'd0;
    wire [2:0] skin_wpn    = 3'd0;
    wire [1:0] skin_rim    = 2'd0;
    wire [1:0] skin_p2mod  = 2'd0;
    wire [1:0] skin_dash   = 2'd0;

    // =========================================================================
    // STAGE -1 -> STAGE 0: VIEWPORT ZOOM & CAMERA PIPELINE REGISTER!
    // =========================================================================
    wire [8:0] gx_in = x[9:1];
    wire [8:0] gy_in = y[9:1];
    wire in_cut_in  = (game_state == 3'd1) && (gy_in < 9'd34 || gy_in >= 9'd206);
    wire in_hud_in  = (game_state >= 3'd2) && (gy_in < 9'd28);
    wire in_boss_in = (game_state == 3'd2) && boss_active && (gy_in >= 9'd224);
    wire in_play_in = (game_state != 3'd0) && !in_hud_in && !in_boss_in && !in_cut_in;

    wire signed [3:0] cut_shx = (game_state == 3'd1 && cut_timer > 8'd20) ? (anim_cnt[21] ? 4'sd2 : -4'sd2) : 4'sd0;
    wire signed [3:0] cut_shy = (game_state == 3'd1 && cut_timer > 8'd20) ? (anim_cnt[20] ? 4'sd2 : -4'sd2) : 4'sd0;
    wire signed [3:0] hit_shx = (shake_mag > 0) ? (anim_cnt[19] ? 4'sd2 : -4'sd2) : 4'sd0;
    wire signed [3:0] hit_shy = (shake_mag > 0) ? (anim_cnt[18] ? 4'sd2 : -4'sd2) : 4'sd0;

    wire [6:0] eff_zoom = (game_state == 3'd1 || game_state == 3'd2) ? zoom_lvl : 7'd0;
    wire [9:0] view_w   = 10'd320 + {2'b00, eff_zoom, 1'b0} + {3'b000, eff_zoom[6:1]};
    wire [9:0] view_h   = 10'd212 + {3'b000, eff_zoom} + {4'b0000, eff_zoom[6:1]} + {5'b00000, eff_zoom[6:3]};

    wire signed [12:0] s_cx = $signed({2'b00, cam_x}) + cut_shx + hit_shx;
    wire signed [12:0] s_cy = $signed({3'b000, cam_y}) + cut_shy + hit_shy;
    wire signed [12:0] min_cx = 13'sd0;
    wire signed [12:0] max_cx = 13'sd2048 - $signed({3'b000, view_w});
    wire signed [12:0] max_cy = 13'sd1024 - $signed({3'b000, view_h});
    wire [10:0] eff_cam_x = (s_cx < min_cx) ? min_cx[10:0] : ((s_cx > max_cx) ? max_cx[10:0] : s_cx[10:0]);
    wire [9:0]  eff_cam_y = (s_cy < 13'sd0) ? 10'd0        : ((s_cy > max_cy) ? max_cy[9:0]  : s_cy[9:0]);

    wire [9:0]  y_pf      = (y >= 10'd56) ? (y - 10'd56) : 10'd0;
    wire [18:0] wx_scaled = ({9'd0, x}    << 7) + ({12'd0, eff_zoom} * {9'd0, x});
    wire [18:0] wy_scaled = ({9'd0, y_pf} << 7) + ({12'd0, eff_zoom} * {9'd0, y_pf});
    wire [10:0] wx_calc   = eff_cam_x + wx_scaled[18:8];
    wire [9:0]  wy_calc   = eff_cam_y + wy_scaled[17:8];

    reg [10:0] wx = 0;
    reg [9:0]  wy = 0;
    reg [8:0]  gx = 0, gy = 0;
    reg        hs_0 = 1, vs_0 = 1, vid_0 = 0;
    reg        in_cut_bar = 0, in_hud_top = 0, in_boss_bar = 0, in_playfield = 0;
    always @(posedge clk) begin
        wx <= wx_calc; wy <= wy_calc; gx <= gx_in; gy <= gy_in;
        hs_0 <= hsync; vs_0 <= vsync; vid_0 <= video_on;
        in_cut_bar <= in_cut_in; in_hud_top <= in_hud_in; in_boss_bar <= in_boss_in; in_playfield <= in_play_in;
    end

    // =========================================================================
    // STAGE 0 -> STAGE 1: REGISTERED (wx, wy, gx, gy) INTO ROMS & SPRITE HIT CHECKS!
    // =========================================================================
    assign map_addr_a = {wy[9:4], wx[10:4]}; // 128 x 64 tilemap

    // 1. Arcade Title Logo ROM (160 x 48 centered at gx=80..239, gy=4..51)
    wire in_logo_box = (game_state == 3'd0 && help_page == 2'd0) && (gx >= 9'd80 && gx < 9'd240 && gy >= 9'd4 && gy < 9'd52);
    wire [5:0] logo_ly = gy - 9'd4;
    wire [7:0] logo_lx = gx - 9'd80;
    wire [12:0] logo_addr = ({7'd0, logo_ly} << 7) + ({7'd0, logo_ly} << 5) + {5'd0, logo_lx}; // y*160 + x (no mul!)
    wire [5:0] logo_pix_1;
    rom_1p #(.DW(6), .AW(13), .DEPTH(8192), .FILE("title_logo.mem")) u_logo_rom (
        .clk(clk), .addr(logo_addr), .q(logo_pix_1)
    );

    wire in_guide_view = (game_state == 3'd0 && help_page != 2'd0) || (game_state == 3'd2 && paused && help_page != 2'd0);

    // 96x64 4-bit DualShock Joystick Pixel Art ROM (3072 bytes) placed at gx=96..191, gy=58..121
    wire in_joy_box = in_guide_view && (help_page == 2'd2) && (gx >= 9'd96 && gx < 9'd192 && gy >= 9'd58 && gy < 9'd122);
    wire [11:0] joy_rom_addr = in_joy_box ? ((gy - 9'd58) * 6'd48 + ((gx - 9'd96) >> 1)) : 12'd0;
    wire [7:0] joy_rom_byte_1;
    rom_1p #(.DW(8), .AW(12), .DEPTH(3072), .FILE("joy_pixel.mem")) u_joy_rom (
        .clk(clk), .addr(joy_rom_addr), .q(joy_rom_byte_1)
    );

    // 256x144 4-bit Real White Keyboard Keycaps Guide ROM (18432 bytes) placed at gx=32..287, gy=46..189
    wire in_kb_box = in_guide_view && (help_page == 2'd3) && (gx >= 9'd32 && gx < 9'd288 && gy >= 9'd46 && gy < 9'd190);
    wire [7:0] kb_ly = gy - 9'd46;
    wire [7:0] kb_lx = gx - 9'd32;
    wire [14:0] kb_rom_addr_ok = in_kb_box ? {kb_ly, kb_lx[7:1]} : 15'd0;
    wire [7:0] kb_rom_byte_1;
    rom_1p #(.DW(8), .AW(15), .DEPTH(18432), .FILE("kb_guide.mem")) u_kb_rom (
        .clk(clk), .addr(kb_rom_addr_ok), .q(kb_rom_byte_1)
    );

    // UI Animated Button, Keycap & Weapon Icon ROM (16 slots x 64x32 x 12-bit RGB444 = 32768 words)
    wire is_kb_mode_0 = control_mode[0];
    wire [8:0] cta_bounce_0 = (anim_cnt[23:21] < 3'd4) ? {6'd0, anim_cnt[23:21]} : {6'd0, 3'd7 - anim_cnt[23:21]};
    wire [8:0] cta_top_0    = 9'd158 - cta_bounce_0;
    wire       cta_press_0  = (anim_cnt[23:21] >= 3'd5);
    wire [8:0] guide_top_0  = 9'd202 - {8'd0, anim_cnt[22]};
    wire [8:0] nav_mid_x0   = (game_state == 3'd2 && paused) ? 9'd114 : 9'd122;

    wire in_cta_icon   = (game_state == 3'd0 && help_page == 2'd0) && (gx >= 9'd128 && gx < 9'd192 && gy >= cta_top_0 && gy < cta_top_0 + 9'd32);
    wire in_guide_pill = (game_state == 3'd0 && help_page == 2'd0) && (gx >= 9'd128 && gx < 9'd192 && gy >= guide_top_0 && gy < guide_top_0 + 9'd16);
    wire in_wpn1_box   = (game_state == 3'd0 && help_page == 2'd0) && (p2_active ? (gx >= 9'd60  && gx < 9'd92)  : (gx >= 9'd180 && gx < 9'd212)) && (gy >= 9'd96 && gy < 9'd128);
    wire in_wpn2_box   = (game_state == 3'd0 && help_page == 2'd0 && p2_active) && (gx >= 9'd228 && gx < 9'd260 && gy >= 9'd96 && gy < 9'd128);
    wire in_nav_prev   = in_guide_view && (help_page > 2'd1)  && (gx >= 9'd36  && gx < 9'd68  && gy >= 9'd199 && gy < 9'd215);
    wire in_nav_exit   = in_guide_view && (gx >= nav_mid_x0 && gx < nav_mid_x0 + 9'd32 && gy >= 9'd199 && gy < 9'd215);
    wire in_nav_next   = in_guide_view && (help_page < 2'd3) && (gx >= 9'd212 && gx < 9'd244 && gy >= 9'd199 && gy < 9'd215);
    wire in_pause_row2 = in_guide_view && paused && (gx >= 9'd108 && gx < 9'd140 && gy >= 9'd215 && gy < 9'd231);
    wire in_end_retry  = (game_state == 3'd3 || game_state == 3'd4) && (gx >= 9'd104 && gx < 9'd136 && gy >= 9'd132 && gy < 9'd148);
    wire in_end_menu   = (game_state == 3'd3 || game_state == 3'd4) && (gx >= 9'd104 && gx < 9'd136 && gy >= 9'd151 && gy < 9'd167);
    wire in_quiz_ico1  = (game_state == 3'd2 && room_phase == 3'd3) && (gx >= 9'd72  && gx < 9'd104 && gy >= 9'd181 && gy < 9'd197);
    wire in_quiz_ico2  = (game_state == 3'd2 && room_phase == 3'd3) && (gx >= 9'd162 && gx < 9'd194 && gy >= 9'd181 && gy < 9'd197);
    wire in_ui_box     = in_cta_icon || in_guide_pill || in_wpn1_box || in_wpn2_box || in_nav_prev || in_nav_exit || in_nav_next || in_pause_row2 || in_end_retry || in_end_menu || in_quiz_ico1 || in_quiz_ico2;

    reg [3:0] ui_slot;
    reg [5:0] ui_lx;
    reg [4:0] ui_ly;
    always @(*) begin
        ui_slot = 4'd0; ui_lx = 6'd0; ui_ly = 5'd0;
        if (in_cta_icon) begin
            ui_slot = is_kb_mode_0 ? (cta_press_0 ? 4'd3 : 4'd2) : (cta_press_0 ? 4'd1 : 4'd0);
            ui_lx   = gx - 9'd128;
            ui_ly   = gy - cta_top_0;
        end else if (in_guide_pill) begin
            ui_slot = 4'd4;
            ui_lx   = gx - 9'd128;
            ui_ly   = (is_kb_mode_0 ? 5'd16 : 5'd0) + (gy - guide_top_0);
        end else if (in_wpn1_box) begin
            ui_slot = 4'd7 + {2'b00, p1_weapon[2:1]};
            ui_lx   = (p1_weapon[0] ? 6'd32 : 6'd0) + (p2_active ? (gx - 9'd60) : (gx - 9'd180));
            ui_ly   = gy - 9'd96;
        end else if (in_wpn2_box) begin
            ui_slot = 4'd7 + {2'b00, p2_weapon[2:1]};
            ui_lx   = (p2_weapon[0] ? 6'd32 : 6'd0) + (gx - 9'd228);
            ui_ly   = gy - 9'd96;
        end else if (in_nav_prev) begin
            ui_slot = is_kb_mode_0 ? 4'd6 : 4'd5;
            ui_lx   = gx - 9'd36;
            ui_ly   = gy - 9'd199;
        end else if (in_nav_exit) begin
            ui_slot = is_kb_mode_0 ? 4'd6 : 4'd5;
            ui_lx   = ((game_state == 3'd2 && paused) ? 6'd32 : 6'd0) + (gx - nav_mid_x0);
            ui_ly   = 5'd16 + (gy - 9'd199);
        end else if (in_nav_next) begin
            ui_slot = is_kb_mode_0 ? 4'd6 : 4'd5;
            ui_lx   = 6'd32 + (gx - 9'd212);
            ui_ly   = gy - 9'd199;
        end else if (in_pause_row2) begin
            ui_slot = is_kb_mode_0 ? 4'd6 : 4'd5;
            ui_lx   = gx - 9'd108;
            ui_ly   = 5'd16 + (gy - 9'd215);
        end else if (in_end_retry) begin
            ui_slot = 4'd10;
            ui_lx   = gx - 9'd104;
            ui_ly   = (is_kb_mode_0 ? 5'd16 : 5'd0) + (gy - 9'd132);
        end else if (in_end_menu) begin
            ui_slot = 4'd10;
            ui_lx   = 6'd32 + (gx - 9'd104);
            ui_ly   = (is_kb_mode_0 ? 5'd16 : 5'd0) + (gy - 9'd151);
        end else if (in_quiz_ico1) begin
            ui_slot = 4'd11;
            ui_lx   = gx - 9'd72;
            ui_ly   = (is_kb_mode_0 ? 5'd16 : 5'd0) + (gy - 9'd181);
        end else if (in_quiz_ico2) begin
            ui_slot = 4'd11;
            ui_lx   = 6'd32 + (gx - 9'd162);
            ui_ly   = (is_kb_mode_0 ? 5'd16 : 5'd0) + (gy - 9'd181);
        end
    end
    wire [11:0] ui_pix_1;
    rom_1p #(.DW(12), .AW(15), .DEPTH(32768), .FILE("ui_icons.mem")) u_ui_rom (
        .clk(clk), .addr({ui_slot, ui_ly, ui_lx}), .q(ui_pix_1)
    );

    // 2. Hero Sprites P1 & P2 (8 models x 4 frames incl Lunge/Apex x 32x32 = 32K)
    wire in_outfit_cut = (game_state == 3'd2 && outfit_cut_t > 8'd0);
    wire [3:0] cur_player_stage = {2'b00, stage} + 4'd1;
    wire [3:0] eff_outfit_wave = (in_outfit_cut && outfit_cut_t > 8'd60 && cur_player_stage > 4'd1) ? (cur_player_stage - 4'd1) : cur_player_stage;
    wire [10:0] target_px  = (game_state == 3'd0) ? (p2_active ? 11'd112 : 11'd160) : px;
    wire [9:0]  target_py  = (game_state == 3'd0) ? 10'd104 : py;
    wire [10:0] target_p2x = (game_state == 3'd0) ? 11'd208 : p2x;
    wire [9:0]  target_p2y = (game_state == 3'd0) ? 10'd104 : p2y;
    wire [10:0] p_ref_x    = (game_state == 3'd0) ? {2'd0, gx} : wx;
    wire [9:0]  p_ref_y    = (game_state == 3'd0) ? {1'd0, gy} : wy;

    wire signed [11:0] psx_norm  = $signed({1'b0, p_ref_x}) - $signed({1'b0, target_px})  + 12'sd16;
    wire signed [11:0] psy_norm  = $signed({2'b00, p_ref_y}) - $signed({2'b00, target_py})  + 12'sd16;
    wire signed [11:0] p2sx_norm = $signed({1'b0, p_ref_x}) - $signed({1'b0, target_p2x}) + 12'sd16;
    wire signed [11:0] p2sy_norm = $signed({2'b00, p_ref_y}) - $signed({2'b00, target_p2y}) + 12'sd16;
    wire signed [11:0] psx  = in_outfit_cut ? (($signed({3'b000, gx}) - (p2_active ? 12'sd96 : 12'sd128)) >>> 1) : psx_norm;
    wire signed [11:0] psy  = in_outfit_cut ? (($signed({3'b000, gy}) - 12'sd74) >>> 1) : psy_norm;
    wire signed [11:0] p2sx = in_outfit_cut ? (($signed({3'b000, gx}) - 12'sd160) >>> 1) : p2sx_norm;
    wire signed [11:0] p2sy = in_outfit_cut ? (($signed({3'b000, gy}) - 12'sd74) >>> 1) : p2sy_norm;

    wire p1_dead_floor = (game_state == 3'd2 && in_playfield && hp == 0 && !in_outfit_cut);
    wire p2_dead_floor = (game_state == 3'd2 && in_playfield && p2_active && hp2 == 0 && !in_outfit_cut);
    wire on_p1_box = (psx >= 0 && psx < 32 && psy >= 0 && psy < (p1_dead_floor ? 32 : 48)) && ((game_state == 3'd0 && help_page == 2'd0) || in_outfit_cut || in_playfield);
    wire show_p2   = (game_state == 3'd0 && help_page == 2'd0 && p2_active) || (p2_active && in_outfit_cut) || (p2_active && in_playfield);
    wire on_p2_box = show_p2 && (p2sx >= 0 && p2sx < 32 && p2sy >= 0 && p2sy < (p2_dead_floor ? 32 : 48));
    wire on_player_box = on_p1_box || on_p2_box;
    wire sel_p2_0      = !on_p1_box && on_p2_box;

    reg on_aura_0;
    reg [5:0] aura_col_0;
    wire [10:0] rad_sq  = (psx[5:0] - 6'sd16)*(psx[5:0] - 6'sd16) + (psy[5:0] - 6'sd16)*(psy[5:0] - 6'sd16);
    wire [10:0] rad2_sq = (p2sx[5:0] - 6'sd16)*(p2sx[5:0] - 6'sd16) + (p2sy[5:0] - 6'sd16)*(p2sy[5:0] - 6'sd16);
    always @(*) begin
        on_aura_0 = 1'b0; aura_col_0 = 6'd58;
        if (aura_active && p1_slash_t == 0 && p2_slash_t == 0 && (game_state == 3'd2 || (game_state == 3'd1 && cut_id == 2'd3)) && in_playfield) begin
            if ((on_p1_box && hp > 0 && rad_sq >= 11'd210 && rad_sq <= 11'd250) ||
                (on_p2_box && hp2 > 0 && rad2_sq >= 11'd210 && rad2_sq <= 11'd250)) begin
                if ((psx[0]^psy[0]) ^ anim_cnt[22]) begin on_aura_0 = 1'b1; aura_col_0 = anim_cnt[22] ? 6'd58 : 6'd59; end
            end
        end
    end

    wire on_ghost = (game_state == 3'd2 && in_playfield && p1_slash_t == 0 && p2_slash_t == 0) && (
                    (dash_timer > 0 && hp > 0 && ($signed({1'b0, wx}) >= $signed({1'b0, dash_gx})-12'sd10) && ($signed({1'b0, wx}) < $signed({1'b0, dash_gx})+12'sd10) && ($signed({2'b00, wy}) >= $signed({2'b00, dash_gy})-12'sd10) && ($signed({2'b00, wy}) < $signed({2'b00, dash_gy})+12'sd10) && (wx[0]^wy[0])) ||
                    (p2_active && hp2 > 0 && p2_dash_timer > 0 && ($signed({1'b0, wx}) >= $signed({1'b0, p2_dash_gx})-12'sd10) && ($signed({1'b0, wx}) < $signed({1'b0, p2_dash_gx})+12'sd10) && ($signed({2'b00, wy}) >= $signed({2'b00, p2_dash_gy})-12'sd10) && ($signed({2'b00, wy}) < $signed({2'b00, p2_dash_gy})+12'sd10) && (wx[0]^wy[0])));

    wire on_p1_tag = (game_state == 3'd2 && in_playfield) && p2_active && ((psy == -12'sd2 && psx >= 12'sd14 && psx <= 12'sd18) || (psy == -12'sd1 && psx >= 12'sd15 && psx <= 12'sd17));
    wire on_p2_tag = (game_state == 3'd2 && in_playfield) && p2_active && ((p2sy == -12'sd2 && p2sx >= 12'sd14 && p2sx <= 12'sd18) || (p2sy == -12'sd1 && p2sx >= 12'sd15 && p2sx <= 12'sd17));

    // 2. 32x32 Human-Face Heroes + 32x24 High-Detail Animated Walk Bodies (4 Outfits x 4 Frames)
    //    SW[15:12] = Left Character (P1), SW[3:0] = Right Character (P2)
    reg [1:0] p1_wstep = 2'd1, p2_wstep = 2'd1;
    reg       prev_wf1 = 1'b0, prev_wf2 = 1'b0;
    always @(posedge clk) begin
        if (walk_frame != prev_wf1) begin
            prev_wf1 <= walk_frame;
            p1_wstep <= p1_wstep + 2'd1;
        end
        if (p2_walk_frame != prev_wf2) begin
            prev_wf2 <= p2_walk_frame;
            p2_wstep <= p2_wstep + 2'd1;
        end
    end

    wire       cur_dead_0 = sel_p2_0 ? p2_dead_floor : p1_dead_floor;
    wire [1:0] p_form_idx = sel_p2_0 ? hero_sel_r : hero_sel_l;
    wire [1:0] p_wstep_0  = (game_state == 3'd0) ? anim_cnt[23:22] :
                            ((in_outfit_cut || cur_dead_0) ? 2'd1 : (sel_p2_0 ? p2_wstep : p1_wstep));
    wire       p_bob_0    = !in_outfit_cut && !cur_dead_0 && (p_wstep_0 == 2'd0 || p_wstep_0 == 2'd2);
    wire [1:0] p_pose = (game_state == 3'd0) ? {1'b0, anim_cnt[23]} :
                        (in_outfit_cut ? ((outfit_cut_t <= 8'd60) ? 2'd3 : 2'd0) :
                        (sel_p2_0 ? ((p2_slash_t > 0) ? 2'd2 : (aura_active ? 2'd3 : {1'b0, p2_walk_frame})) :
                                    ((p1_slash_t > 0) ? 2'd2 : (aura_active ? 2'd3 : {1'b0, walk_frame}))));
    wire [4:0] p_rawx = sel_p2_0 ? p2sx[4:0] : psx[4:0];
    wire [5:0] p_bsy0 = sel_p2_0 ? p2sy[5:0] : psy[5:0];
    wire [5:0] p_bsy_head = p_bob_0 ? (p_bsy0 - 6'd1) : p_bsy0;
    wire [4:0] p_rawy = cur_dead_0 ? p_bsy0[4:0] : p_bsy_head[4:0];
    wire       p_head_en_0 = cur_dead_0 ? (p_bsy0 < 6'd32) : (p_bob_0 ? (p_bsy0 >= 6'd1 && p_bsy0 < 6'd33) : (p_bsy0 < 6'd32));
    wire       p_mir  = sel_p2_0 ? p2_mirror : mirror;
    wire [4:0] p_col_norm = (p_mir && game_state != 3'd0) ? (5'd31 - p_rawx) : p_rawx;
    // Dead player lies flat horizontally on the floor!
    wire [4:0] p_rom_y = cur_dead_0 ? p_rawx : p_rawy;
    wire [4:0] p_rom_x = cur_dead_0 ? (5'd31 - p_rawy) : p_col_norm;
    wire [11:0] player_pix_1;
    rom_1p #(.DW(12), .AW(14), .DEPTH(16384), .FILE("player_sprites.mem")) u_player_rom (
        .clk(clk), .addr({p_form_idx, p_pose, p_rom_y, p_rom_x}), .q(player_pix_1)
    );

    // High-detail BRAM Body ROM (4 Outfits x 4 Walk Frames x 32x24, corresponds to p_bsy0 = 24..47)
    wire [1:0] out_idx_0 = (eff_outfit_wave <= 4'd1) ? 2'd0 : ((eff_outfit_wave == 4'd2) ? 2'd1 : ((eff_outfit_wave == 4'd3) ? 2'd2 : 2'd3));
    wire       on_hero_body_0 = on_player_box && !cur_dead_0 && (p_bsy0 >= 6'd24 && p_bsy0 < 6'd48);
    wire [5:0] body_y_raw_0 = p_bsy0 - 6'd24;
    wire [4:0] body_y_0     = on_hero_body_0 ? body_y_raw_0[4:0] : 5'd0;
    wire [11:0] hero_body_pix_1;
    rom_1p #(.DW(12), .AW(14), .DEPTH(16384), .FILE("hero_body.mem")) u_hero_body_rom (
        .clk(clk), .addr(on_hero_body_0 ? {out_idx_0, p_wstep_0, body_y_0, p_col_norm} : 14'd0), .q(hero_body_pix_1)
    );

    // Attack-Swing Arm Overlay (only active during melee slash p_sl_cur > 0, sits cleanly on top of hero_body_rom)
    wire [3:0] p_sl_cur = sel_p2_0 ? p2_slash_t : p1_slash_t;
    reg [11:0] p_body_0;
    always @(*) begin
        p_body_0 = 12'd0;
        if (on_player_box && !cur_dead_0 && p_sl_cur > 4'd0 && p_bsy0 >= 6'd22 && p_bsy0 < 6'd40) begin
            if (p_sl_cur >= 4'd10) begin
                if ((p_col_norm >= 5'd7 && p_col_norm <= 5'd9 && p_bsy0 >= 6'd23 && p_bsy0 <= 6'd30) ||
                    (p_col_norm >= 5'd21 && p_col_norm <= 5'd24 && p_bsy0 >= 6'd29 && p_bsy0 <= 6'd33))
                    p_body_0 = (p_bsy0 <= 6'd24 || p_col_norm == 5'd24) ? 12'hECA : ((eff_outfit_wave <= 4'd1) ? 12'hFFF : ((eff_outfit_wave == 4'd2) ? 12'h467 : ((eff_outfit_wave == 4'd3) ? 12'hC12 : 12'hFE1)));
            end else if (p_sl_cur >= 4'd7) begin
                if ((p_col_norm >= 5'd21 && p_col_norm <= 5'd27 && p_bsy0 >= 6'd27 && p_bsy0 <= 6'd31) ||
                    (p_col_norm >= 5'd7  && p_col_norm <= 5'd9  && p_bsy0 >= 6'd29 && p_bsy0 <= 6'd34))
                    p_body_0 = (p_col_norm >= 5'd26) ? 12'hECA : ((eff_outfit_wave <= 4'd1) ? 12'hFFF : ((eff_outfit_wave == 4'd2) ? 12'h467 : ((eff_outfit_wave == 4'd3) ? 12'hC12 : 12'hFE1)));
            end else if (p_sl_cur >= 4'd4) begin
                if (p_col_norm >= 5'd22 && p_col_norm <= 5'd29 && p_bsy0 >= 6'd30 && p_bsy0 <= 6'd33)
                    p_body_0 = (p_col_norm >= 5'd28) ? 12'hECA : ((eff_outfit_wave <= 4'd1) ? 12'hFFF : ((eff_outfit_wave == 4'd2) ? 12'h467 : ((eff_outfit_wave == 4'd3) ? 12'hC12 : 12'hFE1)));
            end else begin
                if (p_col_norm >= 5'd21 && p_col_norm <= 5'd28 && p_bsy0 >= 6'd32 && p_bsy0 <= 6'd35)
                    p_body_0 = (p_col_norm >= 5'd27) ? 12'hECA : ((eff_outfit_wave <= 4'd1) ? 12'hFFF : ((eff_outfit_wave == 4'd2) ? 12'h467 : ((eff_outfit_wave == 4'd3) ? 12'hC12 : 12'hFE1)));
            end
        end
    end

    // 3. 3 Unique 64x64 Bosses (or Giant 128x128 Angry Ajarn_V Form 2 on Wrong Quiz!)
    wire wrong_boss_active = (game_state == 3'd2 && room_phase == 3'd3 && quiz_wrong_t > 0);
    wire in_caution_banner = wrong_boss_active && (gy >= 9'd108 && gy < 9'd158);
    wire show_boss_cut = (game_state == 3'd1 && cut_id == 2'd2);
    wire [10:0] target_bx = show_boss_cut ? 11'd255 : boss_x;
    wire [9:0]  target_by = show_boss_cut ? 10'd120 : boss_y;
    wire [10:0] b_ref_x   = show_boss_cut ? {2'd0, gx} : wx;
    wire [9:0]  b_ref_y   = show_boss_cut ? {1'd0, gy} : wy;
    wire signed [11:0] bsx_norm = $signed({1'b0, b_ref_x}) - $signed({1'b0, target_bx}) + 12'sd32;
    wire signed [11:0] bsy_norm = $signed({2'b00, b_ref_y}) - $signed({2'b00, target_by}) + 12'sd32;
    wire signed [11:0] bsx = wrong_boss_active ? (($signed({3'b000, gx}) - 12'sd96) >>> 1) : bsx_norm;
    wire signed [11:0] bsy = wrong_boss_active ? (($signed({3'b000, gy}) - 12'sd36) >>> 1) : bsy_norm;
    wire on_boss_box = wrong_boss_active ? (gx >= 9'd96 && gx < 9'd224 && gy >= 9'd36 && gy < 9'd164) :
                       ((bsx >= 0 && bsx < 64 && bsy >= 0 && bsy < 64) &&
                        (show_boss_cut || (in_playfield && boss_active && boss_hp > 0)));
    wire [1:0] eff_bkind = wrong_boss_active ? 2'd1 : boss_kind;
    wire b_frame = wrong_boss_active ? 1'b1 : (show_boss_cut ? anim_cnt[24] : boss_enraged);
    wire [11:0] boss_pix_1;
    rom_1p #(.DW(12), .AW(15), .DEPTH(32768), .FILE("boss_sprites.mem")) u_boss_rom (
        .clk(clk), .addr({eff_bkind, b_frame, bsy[5:0], bsx[5:0]}), .q(boss_pix_1)
    );

    // 4. 16 HUGE 32x46 MONSTERS (Head 32x32 preserved + Black Suit & White Inner Shirt!)
    reg        on_mon_box;
    reg        mon_head_en_0;
    reg [2:0]  mon_kind_0;
    reg [4:0]  mon_lx, mon_ly;
    reg [11:0] mon_body_0;
    integer k_mon;
    reg signed [11:0] ox_m, oy_m;
    always @(*) begin
        on_mon_box = 1'b0; mon_head_en_0 = 1'b0; mon_kind_0 = 3'd0; mon_lx = 5'd0; mon_ly = 5'd0;
        mon_body_0 = 12'd0;
        ox_m = 12'sd0; oy_m = 12'sd0;
        if (in_playfield) begin
            for (k_mon = 15; k_mon >= 0; k_mon = k_mon - 1) begin
                if (en_alive_vec[k_mon]) begin
                    ox_m = $signed({1'b0, wx})  - $signed({1'b0, en_x_vec[k_mon*11 +: 11]}) + 12'sd16;
                    oy_m = $signed({2'b00, wy}) - $signed({2'b00, en_y_vec[k_mon*10 +: 10]}) + 12'sd16;
                    if (ox_m >= 0 && ox_m < 32 && oy_m >= 0 && oy_m < 46) begin
                        on_mon_box = 1'b1; mon_kind_0 = en_type_vec[k_mon*3 +: 3];
                        mon_lx = ox_m[4:0]; mon_ly = oy_m[4:0];
                        mon_head_en_0 = (oy_m < 12'sd32);
                        mon_body_0 = 12'd0;
                        if (oy_m >= 12'sd28) begin
                            // Black Suit Torso + White Inner Shirt + Tie
                            if (oy_m <= 12'sd37 && ox_m >= 12'sd10 && ox_m <= 12'sd21) begin
                                if (ox_m >= 12'sd14 && ox_m <= 12'sd17 && oy_m <= 12'sd34 &&
                                    ((oy_m <= 12'sd30) || (ox_m >= 12'sd15 && ox_m <= 12'sd16)))
                                    mon_body_0 = (ox_m >= 12'sd15 && ox_m <= 12'sd16 && oy_m >= 12'sd30) ? 12'hA12 : 12'hFFF;
                                else
                                    mon_body_0 = (ox_m == 12'sd10 || ox_m == 12'sd21) ? 12'h111 : 12'h223;
                            end
                            // Black Suit Sleeves & Hands
                            else if ((ox_m >= 12'sd7 && ox_m <= 12'sd9 && oy_m >= 12'sd29 && oy_m <= 12'sd36) ||
                                     (ox_m >= 12'sd22 && ox_m <= 12'sd24 && oy_m >= 12'sd29 && oy_m <= 12'sd36))
                                mon_body_0 = (oy_m >= 12'sd35) ? 12'hECA : 12'h112;
                            // Black Suit Pants & Shoes
                            else if (oy_m >= 12'sd38 &&
                                     ((ox_m >= 12'sd11 && ox_m <= 12'sd14 && oy_m <= (anim_cnt[23] ? 12'sd44 : 12'sd45)) ||
                                      (ox_m >= 12'sd17 && ox_m <= 12'sd20 && oy_m <= (anim_cnt[23] ? 12'sd45 : 12'sd44))))
                                mon_body_0 = (oy_m >= 12'sd44) ? 12'h334 : 12'h112;
                        end
                    end
                end
            end
        end
    end
    wire [11:0] mon_pix_1;
    rom_1p #(.DW(12), .AW(14), .DEPTH(16384), .FILE("enemy_sprites.mem")) u_monster_rom (
        .clk(clk), .addr({mon_kind_0, anim_cnt[23], mon_ly, mon_lx}), .q(mon_pix_1)
    );

    // 5. 16x16 ITEMS, GEMS, CRATES, METEORS, PETS, ORBIT SWORDS (16 frames -> 4K!)
    reg        on_item_box;
    reg [3:0]  item_fid, item_lx, item_ly;
    reg [9:0]  drop_wy;
    integer k_it;
    reg signed [11:0] ox_i, oy_i;
    always @(*) begin
        on_item_box = 1'b0; item_fid = 4'd0; item_lx = 4'd0; item_ly = 4'd0;
        drop_wy = 10'd0; ox_i = 12'sd0; oy_i = 12'sd0;
        if (in_playfield) begin
            if (pet_active && (game_state == 3'd2 || (game_state == 3'd1 && cut_id == 2'd3))) begin
                if (hp > 0) begin
                    ox_i = $signed({1'b0, wx}) - ($signed({1'b0, px}) - 12'sd18) + 12'sd8;
                    oy_i = $signed({2'b00, wy}) - ($signed({2'b00, py}) - 12'sd12 + (anim_cnt[23]?12'sd2:12'sd0)) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd12; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                end
                if (p2_active && hp2 > 0) begin
                    ox_i = $signed({1'b0, wx}) - ($signed({1'b0, p2x}) - 12'sd18) + 12'sd8;
                    oy_i = $signed({2'b00, wy}) - ($signed({2'b00, p2y}) - 12'sd12 + (anim_cnt[23]?12'sd0:12'sd2)) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd13; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                end
            end
            for (k_it = 3; k_it >= 0; k_it = k_it - 1) begin
                if (drop_active_vec[k_it]) begin
                    drop_wy = drop_y_vec[k_it*10 +: 10] - {3'd0, drop_z_vec[k_it*7 +: 7]};
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, drop_x_vec[k_it*11 +: 11]}) + 12'sd8;
                    oy_i = $signed({2'b00, wy}) - $signed({2'b00, drop_wy}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin
                        on_item_box = 1;
                        item_fid = (drop_type_vec[k_it*2 +: 2] == 2'd0) ? 4'd4 : ((drop_type_vec[k_it*2 +: 2] == 2'd1) ? 4'd6 : 4'd8);
                        item_lx = ox_i[3:0]; item_ly = oy_i[3:0];
                    end
                end
            end
            for (k_it = 11; k_it >= 0; k_it = k_it - 1) begin
                if (col_alive_vec[k_it]) begin
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, col_x_vec[k_it*11 +: 11]}) + 12'sd8;
                    oy_i = $signed({2'b00, wy}) - $signed({2'b00, col_y_vec[k_it*10 +: 10]}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin
                        on_item_box = 1; item_fid = col_type_vec[k_it] ? 4'd2 : {3'd0, anim_cnt[23]}; item_lx = ox_i[3:0]; item_ly = oy_i[3:0];
                    end
                end
            end
            if (blades_active) begin
                if (hp > 0) begin
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, blade0_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, blade0_y}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, blade1_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, blade1_y}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                end
                if (p2_active && hp2 > 0) begin
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, p2_blade0_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, p2_blade0_y}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                    ox_i = $signed({1'b0, wx}) - $signed({1'b0, p2_blade1_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, p2_blade1_y}) + 12'sd8;
                    if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                end
            end
        end
    end
    wire [5:0] item_pix_1;
    rom_1p #(.DW(6), .AW(12), .DEPTH(4096), .FILE("obj_sprites.mem")) u_item_rom (
        .clk(clk), .addr({item_fid, item_ly, item_lx}), .q(item_pix_1)
    );

    // 6. VFX OVERLAYS: SLASHES, 360 NOVA FINISHER, 16x2 MINI HP BARS, 12 HIT SPARKS, LOCK RETICLE
    reg       on_pb_0, on_eb_0, on_dropfx_0, on_laser_0;
    reg [5:0] pb_col_0, eb_col_0, dropfx_col_0, laser_col_0;
    reg signed [11:0] bx_d, by_d, ax_d, ay_d, oct_d, dot_d, sw_up;
    reg [5:0] wpn_skin_col;
    reg [3:0] e_hp_k;
    reg [4:0] hp_bar_w;
    integer k_fx;

    always @(*) begin
        on_pb_0 = 0; pb_col_0 = 0; on_eb_0 = 0; eb_col_0 = 0;
        on_dropfx_0 = 0; dropfx_col_0 = 0; on_laser_0 = 0; laser_col_0 = 0;
        bx_d = 0; by_d = 0; ax_d = 0; ay_d = 0; oct_d = 0; dot_d = 0; sw_up = 0; e_hp_k = 0; hp_bar_w = 0;

        case (skin_wpn)
            3'd0: wpn_skin_col = 6'd59; 3'd1: wpn_skin_col = 6'd52; 3'd2: wpn_skin_col = 6'd58; 3'd3: wpn_skin_col = 6'd45;
            3'd4: wpn_skin_col = 6'd60; 3'd5: wpn_skin_col = 6'd61; 3'd6: wpn_skin_col = 6'd62; 3'd7: wpn_skin_col = 6'd36;
        endcase

        if (in_playfield) begin
            // 12 Hit Particle Sparks (suppressed while swinging sword for clean visual!)
            for (k_fx = 0; k_fx < 12; k_fx = k_fx + 1) begin
                if (sp_alive_vec[k_fx] && p1_slash_t == 0 && p2_slash_t == 0) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, sp_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, sp_y_vec[k_fx*10 +: 10]});
                    if (bx_d >= -2 && bx_d <= 2 && by_d >= -2 && by_d <= 2 && (bx_d == 0 || by_d == 0)) begin
                        on_pb_0 = 1; pb_col_0 = (bx_d == 0 && by_d == 0) ? 6'd17 : 6'd58;
                    end
                end
            end

            if (pet_b_act) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, pet_bx}); by_d = $signed({2'b00, wy}) - $signed({2'b00, pet_by});
                if (bx_d >= -2 && bx_d <= 2 && by_d >= -2 && by_d <= 2) begin on_pb_0 = 1; pb_col_0 = (bx_d==0&&by_d==0)?6'd17:6'd59; end
            end

            // Tiny Non-Obscuring 16x2 Overhead HP Bars for 32x32 Enemies
            for (k_fx = 0; k_fx < 16; k_fx = k_fx + 1) begin
                if (en_alive_vec[k_fx]) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, en_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, en_y_vec[k_fx*10 +: 10]});
                    if (bx_d >= -12'sd8 && bx_d < 12'sd8 && by_d >= -12'sd19 && by_d <= -12'sd18) begin
                        e_hp_k = en_hp_vec[k_fx*4 +: 4];
                        case (en_tier_vec[k_fx*2 +: 2])
                            2'd0: hp_bar_w = {1'b0, e_hp_k, 2'b00};                              // *4 (max 16)
                            2'd1: hp_bar_w = {1'b0, e_hp_k, 1'b0} + {2'b00, e_hp_k[3:1]};        // *2.5 (6->15)
                            2'd2: hp_bar_w = {1'b0, e_hp_k, 1'b0};                               // *2 (8->16)
                            2'd3: hp_bar_w = {1'b0, e_hp_k} + {2'b00, e_hp_k[3:1]};              // *1.5 (12->18->16)
                        endcase
                        on_pb_0 = 1;
                        pb_col_0 = (($signed({1'b0, wx}) - ($signed({1'b0, en_x_vec[k_fx*11 +: 11]}) - 12'sd8)) < $signed({7'd0, hp_bar_w})) ? ((e_hp_k <= 4'd2) ? 6'd52 : 6'd28) : 6'd16;
                    end
                end
            end

            if (lock_valid) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, lock_x}); by_d = $signed({2'b00, wy}) - $signed({2'b00, lock_y});
                ax_d = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                if ((ax_d == 12'sd16 && ay_d >= 12'sd10 && ay_d <= 12'sd16) || (ay_d == 12'sd16 && ax_d >= 12'sd10 && ax_d <= 12'sd16)) begin
                    on_pb_0 = 1; pb_col_0 = anim_cnt[22] ? 6'd58 : 6'd52;
                end
            end

            // =========================================================================
            // 6 DISTINCT MELEE WEAPONS WITH CUSTOM PIXEL-ART ATTACK ANIMATIONS
            // 0: Greatsword, 1: Lightsaber, 2: Boxing Fists, 3: Battleaxe, 4: Spear, 5: Scythe
            // =========================================================================
            if (p1_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, px});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, py});
                if (bx_d >= -12'sd38 && bx_d <= 12'sd38 && by_d >= -12'sd38 && by_d <= 12'sd38) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p1_slash_dx == 0) ? 12'sd0 : ((p1_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p1_slash_dy == 0) ? 12'sd0 : ((p1_slash_dy > 0) ? by_d : -by_d));
                    sw_up = (p1_slash_dy == 0) ? -by_d : ((p1_slash_dx == 0) ? bx_d : -by_d);

                    if (p1_nova) begin
                        if (oct_d >= 12'sd22 && oct_d <= 12'sd32) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd28) ? 6'd17 : 6'd55;
                        end
                    end else case (p1_weapon)
                        // Weapon 0: Dragon Slayer Greatsword (Heavy crescent sweep)
                        3'd0: begin
                            if (p1_slash_t >= 4'd10) begin
                                if (sw_up >= 12'sd6 && sw_up <= 12'sd28 && dot_d >= -12'sd12 && dot_d <= -12'sd1 &&
                                    (dot_d + (sw_up >> 2) >= -12'sd6) && (dot_d + (sw_up >> 2) <= -12'sd2)) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d + (sw_up >> 2) >= -12'sd4) ? 6'd17 : 6'd58;
                                end
                            end else if (p1_slash_t >= 4'd7) begin
                                if (sw_up >= -12'sd4 && oct_d >= 12'sd16 && oct_d <= 12'sd34 &&
                                    (dot_d >= -12'sd6 || sw_up >= 12'sd10) && (dot_d + sw_up >= 12'sd8)) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd26 || dot_d >= 12'sd20) ? 6'd17 : 6'd55;
                                end
                            end else if (p1_slash_t >= 4'd4) begin
                                if (dot_d >= 12'sd6 && sw_up >= -12'sd12 && sw_up <= 12'sd20 &&
                                    oct_d >= 12'sd16 && oct_d <= 12'sd32 && (dot_d >= (sw_up < 0 ? -sw_up : sw_up) + 12'sd2)) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd24 || sw_up >= 12'sd8) ? 6'd17 : 6'd58;
                                end
                            end else begin
                                if (dot_d >= 12'sd8 && dot_d <= 12'sd34 && sw_up >= -12'sd2 && sw_up <= 12'sd1) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || dot_d >= 12'sd22) ? 6'd17 : 6'd55;
                                end
                            end
                        end

                        // Weapon 1: Lightsaber / Laser Katana (Cyan glowing plasma beam)
                        3'd1: begin
                            if (p1_slash_t >= 4'd10) begin
                                if (dot_d + sw_up >= 12'sd10 && dot_d + sw_up <= 12'sd34 && dot_d - sw_up >= -12'sd4 && dot_d - sw_up <= 12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d - sw_up >= -12'sd1 && dot_d - sw_up <= 12'sd1) ? 6'd17 : 6'd36;
                                end
                            end else if (p1_slash_t >= 4'd5) begin
                                if (oct_d >= 12'sd14 && oct_d <= 12'sd34 && sw_up >= -12'sd6) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd24) ? 6'd17 : 6'd36;
                                end
                            end else begin
                                if (dot_d >= 12'sd6 && dot_d <= 12'sd36 && sw_up >= -12'sd3 && sw_up <= 12'sd3) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || sw_up == -12'sd1) ? 6'd17 : 6'd39;
                                end
                            end
                        end

                        // Weapon 2: Titan Boxing Fists (Dual flurry punch animation)
                        3'd2: begin
                            if (p1_slash_t >= 4'd6) begin
                                if (dot_d >= 12'sd10 && dot_d <= 12'sd24 && sw_up >= 12'sd4 && sw_up <= 12'sd14) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd20) ? 6'd58 : 6'd52;
                                end else if (dot_d >= 12'sd22 && dot_d <= 12'sd30 && sw_up >= 12'sd2 && sw_up <= 12'sd16 && (dot_d == 12'sd28 || sw_up == 12'sd14)) begin
                                    on_pb_0 = 1; pb_col_0 = 6'd17;
                                end
                            end else begin
                                if (dot_d >= 12'sd12 && dot_d <= 12'sd26 && sw_up >= -12'sd14 && sw_up <= -12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd22) ? 6'd58 : 6'd52;
                                end else if (dot_d >= 12'sd24 && dot_d <= 12'sd32 && sw_up >= -12'sd16 && sw_up <= -12'sd2 && (dot_d == 12'sd30 || sw_up == -12'sd14)) begin
                                    on_pb_0 = 1; pb_col_0 = 6'd17;
                                end
                            end
                        end

                        // Weapon 3: Titan Battleaxe (Double-crescent crescent axe)
                        3'd3: begin
                            if (p1_slash_t >= 4'd8) begin
                                if (sw_up >= 12'sd8 && sw_up <= 12'sd28 && dot_d >= 12'sd4 && dot_d <= 12'sd26) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up >= 12'sd22 || dot_d >= 12'sd20) ? 6'd52 : 6'd17;
                                end
                            end else if (p1_slash_t >= 4'd4) begin
                                if (dot_d >= 12'sd12 && dot_d <= 12'sd30 && sw_up >= -12'sd16 && sw_up <= 12'sd16) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd24) ? 6'd52 : 6'd58;
                                end
                            end else begin
                                if (dot_d >= 12'sd8 && dot_d <= 12'sd28 && sw_up >= -12'sd24 && sw_up <= -12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up <= -12'sd18) ? 6'd52 : 6'd17;
                                end
                            end
                        end

                        // Weapon 4: Plasma Spear (Extended reach thrusting spear)
                        3'd4: begin
                            if (dot_d >= 12'sd6 && dot_d <= 12'sd38 && sw_up >= -12'sd2 && sw_up <= 12'sd2) begin
                                on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd28) ? 6'd17 : 6'd55;
                            end else if (dot_d >= 12'sd24 && dot_d <= 12'sd32 && (sw_up >= -12'sd6 && sw_up <= 12'sd6) &&
                                         (dot_d - 12'sd24 + (sw_up < 0 ? -sw_up : sw_up) <= 12'sd6)) begin
                                on_pb_0 = 1; pb_col_0 = 6'd58;
                            end
                        end

                        // Weapon 5: Reaper Scythe (Giant curved crescent blade)
                        3'd5: begin
                            if (oct_d >= 12'sd18 && oct_d <= 12'sd36 && sw_up >= 12'sd2 && dot_d >= 12'sd2) begin
                                on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd28) ? 6'd17 : 6'd45;
                            end else if (dot_d >= 12'sd4 && dot_d <= 12'sd22 && sw_up >= 12'sd20 && sw_up <= 12'sd32) begin
                                on_pb_0 = 1; pb_col_0 = 6'd36;
                            end
                        end
                        default: on_pb_0 = 0;
                    endcase
                end
            end

            if (p2_active && p2_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, p2x});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, p2y});
                if (bx_d >= -12'sd38 && bx_d <= 12'sd38 && by_d >= -12'sd38 && by_d <= 12'sd38) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p2_slash_dx == 0) ? 12'sd0 : ((p2_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p2_slash_dy == 0) ? 12'sd0 : ((p2_slash_dy > 0) ? by_d : -by_d));
                    sw_up = (p2_slash_dy == 0) ? -by_d : ((p2_slash_dx == 0) ? bx_d : -by_d);

                    if (p2_nova) begin
                        if (oct_d >= 12'sd22 && oct_d <= 12'sd32) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd28) ? 6'd17 : 6'd55;
                        end
                    end else case (p2_weapon)
                        3'd0: begin
                            if (p2_slash_t >= 4'd10) begin
                                if (sw_up >= 12'sd6 && sw_up <= 12'sd28 && dot_d >= -12'sd12 && dot_d <= -12'sd1 &&
                                    (dot_d + (sw_up >> 2) >= -12'sd6) && (dot_d + (sw_up >> 2) <= -12'sd2)) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d + (sw_up >> 2) >= -12'sd4) ? 6'd17 : 6'd58;
                                end
                            end else if (p2_slash_t >= 4'd7) begin
                                if (sw_up >= -12'sd4 && oct_d >= 12'sd16 && oct_d <= 12'sd34 &&
                                    (dot_d >= -12'sd6 || sw_up >= 12'sd10) && (dot_d + sw_up >= 12'sd8)) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd26 || dot_d >= 12'sd20) ? 6'd17 : 6'd55;
                                end
                            end else if (p2_slash_t >= 4'd4) begin
                                if (dot_d >= 12'sd6 && sw_up >= -12'sd12 && sw_up <= 12'sd20 &&
                                    oct_d >= 12'sd16 && oct_d <= 12'sd32 && (dot_d >= (sw_up < 0 ? -sw_up : sw_up) + 12'sd2)) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd24 || sw_up >= 12'sd8) ? 6'd17 : 6'd58;
                                end
                            end else begin
                                if (dot_d >= 12'sd8 && dot_d <= 12'sd34 && sw_up >= -12'sd2 && sw_up <= 12'sd1) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || dot_d >= 12'sd22) ? 6'd17 : 6'd55;
                                end
                            end
                        end

                        3'd1: begin
                            if (p2_slash_t >= 4'd10) begin
                                if (dot_d + sw_up >= 12'sd10 && dot_d + sw_up <= 12'sd34 && dot_d - sw_up >= -12'sd4 && dot_d - sw_up <= 12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d - sw_up >= -12'sd1 && dot_d - sw_up <= 12'sd1) ? 6'd17 : 6'd36;
                                end
                            end else if (p2_slash_t >= 4'd5) begin
                                if (oct_d >= 12'sd14 && oct_d <= 12'sd34 && sw_up >= -12'sd6) begin
                                    on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd24) ? 6'd17 : 6'd36;
                                end
                            end else begin
                                if (dot_d >= 12'sd6 && dot_d <= 12'sd36 && sw_up >= -12'sd3 && sw_up <= 12'sd3) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || sw_up == -12'sd1) ? 6'd17 : 6'd39;
                                end
                            end
                        end

                        3'd2: begin
                            if (p2_slash_t >= 4'd6) begin
                                if (dot_d >= 12'sd10 && dot_d <= 12'sd24 && sw_up >= 12'sd4 && sw_up <= 12'sd14) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd20) ? 6'd58 : 6'd52;
                                end else if (dot_d >= 12'sd22 && dot_d <= 12'sd30 && sw_up >= 12'sd2 && sw_up <= 12'sd16 && (dot_d == 12'sd28 || sw_up == 12'sd14)) begin
                                    on_pb_0 = 1; pb_col_0 = 6'd17;
                                end
                            end else begin
                                if (dot_d >= 12'sd12 && dot_d <= 12'sd26 && sw_up >= -12'sd14 && sw_up <= -12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd22) ? 6'd58 : 6'd52;
                                end else if (dot_d >= 12'sd24 && dot_d <= 12'sd32 && sw_up >= -12'sd16 && sw_up <= -12'sd2 && (dot_d == 12'sd30 || sw_up == -12'sd14)) begin
                                    on_pb_0 = 1; pb_col_0 = 6'd17;
                                end
                            end
                        end

                        3'd3: begin
                            if (p2_slash_t >= 4'd8) begin
                                if (sw_up >= 12'sd8 && sw_up <= 12'sd28 && dot_d >= 12'sd4 && dot_d <= 12'sd26) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up >= 12'sd22 || dot_d >= 12'sd20) ? 6'd52 : 6'd17;
                                end
                            end else if (p2_slash_t >= 4'd4) begin
                                if (dot_d >= 12'sd12 && dot_d <= 12'sd30 && sw_up >= -12'sd16 && sw_up <= 12'sd16) begin
                                    on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd24) ? 6'd52 : 6'd58;
                                end
                            end else begin
                                if (dot_d >= 12'sd8 && dot_d <= 12'sd28 && sw_up >= -12'sd24 && sw_up <= -12'sd4) begin
                                    on_pb_0 = 1; pb_col_0 = (sw_up <= -12'sd18) ? 6'd52 : 6'd17;
                                end
                            end
                        end

                        3'd4: begin
                            if (dot_d >= 12'sd6 && dot_d <= 12'sd38 && sw_up >= -12'sd2 && sw_up <= 12'sd2) begin
                                on_pb_0 = 1; pb_col_0 = (dot_d >= 12'sd28) ? 6'd17 : 6'd55;
                            end else if (dot_d >= 12'sd24 && dot_d <= 12'sd32 && (sw_up >= -12'sd6 && sw_up <= 12'sd6) &&
                                         (dot_d - 12'sd24 + (sw_up < 0 ? -sw_up : sw_up) <= 12'sd6)) begin
                                on_pb_0 = 1; pb_col_0 = 6'd58;
                            end
                        end

                        3'd5: begin
                            if (oct_d >= 12'sd18 && oct_d <= 12'sd36 && sw_up >= 12'sd2 && dot_d >= 12'sd2) begin
                                on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd28) ? 6'd17 : 6'd45;
                            end else if (dot_d >= 12'sd4 && dot_d <= 12'sd22 && sw_up >= 12'sd20 && sw_up <= 12'sd32) begin
                                on_pb_0 = 1; pb_col_0 = 6'd36;
                            end
                        end
                        default: on_pb_0 = 0;
                    endcase
                end
            end

            // Elongated Blue Gun Bullets (Y Button)
            for (k_fx = 0; k_fx < 8; k_fx = k_fx + 1) begin
                if (pb_active_vec[k_fx]) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, pb_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, pb_y_vec[k_fx*10 +: 10]});
                    case (pb_dir_vec[k_fx*2 +: 2])
                        2'd0: if (bx_d >= -7 && bx_d <= 7 && by_d >= -1 && by_d <= 1) begin
                            on_pb_0 = 1; pb_col_0 = (by_d == 0 && bx_d >= -4 && bx_d <= 4) ? 6'd17 : 6'd59;
                        end
                        2'd1: if (bx_d >= -1 && bx_d <= 1 && by_d >= -7 && by_d <= 7) begin
                            on_pb_0 = 1; pb_col_0 = (bx_d == 0 && by_d >= -4 && by_d <= 4) ? 6'd17 : 6'd59;
                        end
                        2'd2: if (bx_d >= -5 && bx_d <= 5 && by_d >= -5 && by_d <= 5 && (bx_d - by_d >= -1) && (bx_d - by_d <= 1)) begin
                            on_pb_0 = 1; pb_col_0 = (bx_d == by_d) ? 6'd17 : 6'd59;
                        end
                        default: if (bx_d >= -5 && bx_d <= 5 && by_d >= -5 && by_d <= 5 && (bx_d + by_d >= -1) && (bx_d + by_d <= 1)) begin
                            on_pb_0 = 1; pb_col_0 = (bx_d == -by_d) ? 6'd17 : 6'd59;
                        end
                    endcase
                end
            end

            for (k_fx = 0; k_fx < 8; k_fx = k_fx + 1) begin
                if (eb_active_vec[k_fx]) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, eb_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, eb_y_vec[k_fx*10 +: 10]});
                    if (bx_d >= -3 && bx_d <= 3 && by_d >= -3 && by_d <= 3) begin
                        ax_d = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                        if ((ax_d + ay_d) <= 12'sd4) begin
                            on_eb_0 = 1; eb_col_0 = ((ax_d + ay_d) <= 12'sd1) ? 6'd58 : 6'd52;
                        end
                    end
                end
            end

            for (k_fx = 0; k_fx < 4; k_fx = k_fx + 1) begin
                if (drop_active_vec[k_fx]) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, drop_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, drop_y_vec[k_fx*10 +: 10]});
                    if (bx_d >= -7 && bx_d <= 7 && by_d >= -7 && by_d <= 7) begin
                        ax_d = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                        oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                        if (oct_d <= 12'sd7) begin
                            if (drop_type_vec[k_fx*2 +: 2] == 2'd2 && oct_d >= 12'sd5) begin on_dropfx_0=1; dropfx_col_0=anim_cnt[21]?6'd52:6'd51; end
                            else if (oct_d <= 12'sd4) begin on_dropfx_0=1; dropfx_col_0=6'd54; end
                        end
                    end
                end else if (drop_boom_vec[k_fx*5 +: 5] > 0) begin
                    bx_d = $signed({1'b0, wx}) - $signed({1'b0, drop_x_vec[k_fx*11 +: 11]});
                    by_d = $signed({2'b00, wy}) - $signed({2'b00, drop_y_vec[k_fx*10 +: 10]});
                    if (bx_d >= -18 && bx_d <= 18 && by_d >= -18 && by_d <= 18) begin
                        ax_d = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                        oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                        if (oct_d <= 12'sd18) begin on_dropfx_0=1; dropfx_col_0=(oct_d<=12'sd10)?6'd58:6'd52; end
                    end
                end
            end

            if (boss_active && boss_hp > 0 && wx >= 11'd80 && wx <= boss_x) begin
                if (laser_state == 2'd1 && (wy == laser_y || wy == laser_y - 10'd1) && (wx[2] ^ anim_cnt[22])) begin
                    on_laser_0 = 1; laser_col_0 = anim_cnt[21] ? 6'd51 : 6'd52;
                end else if (laser_state == 2'd2 && wy >= laser_y - 10'd6 && wy <= laser_y + 10'd6) begin
                    on_laser_0 = 1; laser_col_0 = (wy >= laser_y - 10'd2 && wy <= laser_y + 10'd2) ? 6'd53 : 6'd52;
                end
            end

            // Sliding Door at Right Wall (wx=560..575, wy=192..255)
            if (wx >= 11'd560 && wx < 11'd576 && wy >= 10'd192 && wy < 10'd256) begin
                if (wy < (10'd256 - {4'd0, door_slide, 1'b0})) begin
                    on_laser_0 = 1;
                    laser_col_0 = (wx == 11'd560 || wy[3:0] == 4'd0) ? 6'd44 : 6'd42;
                end else begin
                    on_laser_0 = 1;
                    laser_col_0 = ((wy[2] ^ anim_cnt[22])) ? 6'd59 : 6'd56; // Glowing open exit portal
                end
            end

            // Door Lock Slam Burst ("PANG!") on left entrance when entering new wave
            if (door_slam_t > 0 && wx >= 11'd64 && wx <= 11'd96 && wy >= 10'd184 && wy <= 10'd264) begin
                if ((wx <= 11'd80) || ((wx + wy + anim_cnt[21]) & 2'b11) == 2'b00) begin
                    on_dropfx_0 = 1;
                    dropfx_col_0 = door_slam_t[2] ? 6'd52 : 6'd58;
                end
            end

            // Bouncing Flashing Arrow pointing to Sliding Door when room is cleared!
            if ((room_phase == 3'd2 || room_phase == 3'd4) && anim_cnt[23]) begin
                bx_d = $signed({1'b0, wx}) - ($signed(12'sd496) + (anim_cnt[22] ? 12'sd6 : -12'sd6));
                by_d = $signed({2'b00, wy}) - 12'sd224;
                if (bx_d >= -16 && bx_d <= 16 && by_d >= -12 && by_d <= 12) begin
                    ay_d = (by_d < 0) ? -by_d : by_d;
                    if ((bx_d >= -16 && bx_d <= 4 && ay_d <= 4) ||
                        (bx_d >= 0 && bx_d <= 14 && ay_d <= (12'sd14 - bx_d))) begin
                        on_dropfx_0 = 1;
                        dropfx_col_0 = (room_phase == 3'd4) ? 6'd28 : 6'd58;
                    end
                end
            end

            // Boss Death Explosion & Swirling Portal Regrowth (room_phase == 3'd5)
            if (room_phase == 3'd5 && boss_trans_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, boss_x});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, boss_y});
                if (bx_d >= -44 && bx_d <= 44 && by_d >= -44 && by_d <= 44) begin
                    ax_d = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    if (boss_trans_t > 8'd80) begin
                        if (oct_d <= 12'sd38 && ((oct_d[2] ^ anim_cnt[20]))) begin
                            on_dropfx_0 = 1; dropfx_col_0 = (oct_d <= 12'sd18) ? 6'd58 : 6'd52;
                        end
                    end else if (boss_kind < 2'd2) begin
                        if (oct_d <= 12'sd40 && (oct_d >= 12'sd14 || ((ax_d ^ ay_d ^ anim_cnt[21]) & 1'b1))) begin
                            on_dropfx_0 = 1; dropfx_col_0 = (oct_d >= 12'sd28) ? 6'd36 : 6'd59;
                        end
                    end
                end
            end
        end
    end

    // Expanding Sonic Shockwave Rings (Acoustic Voice Roar Pushback on BOTH P1 and P2!)
    wire signed [11:0] s_dx = $signed({1'b0, wx}) - $signed({1'b0, px});
    wire signed [11:0] s_dy = $signed({2'b00, wy}) - $signed({2'b00, py});
    wire [11:0] as_dx = (s_dx < 0) ? -s_dx : s_dx;
    wire [11:0] as_dy = (s_dy < 0) ? -s_dy : s_dy;
    wire [11:0] oct_sonic = (as_dx >= as_dy) ? (as_dx + (as_dy >> 1)) : (as_dy + (as_dx >> 1));

    wire signed [11:0] s2_dx = $signed({1'b0, wx}) - $signed({1'b0, p2x});
    wire signed [11:0] s2_dy = $signed({2'b00, wy}) - $signed({2'b00, p2y});
    wire [11:0] as2_dx = (s2_dx < 0) ? -s2_dx : s2_dx;
    wire [11:0] as2_dy = (s2_dy < 0) ? -s2_dy : s2_dy;
    wire [11:0] oct_sonic2 = (as2_dx >= as2_dy) ? (as2_dx + (as2_dy >> 1)) : (as2_dy + (as2_dx >> 1));

    wire [4:0]  sonic_age = 5'd24 - sonic_wave_t;
    wire [13:0] cur_r_raw = (sonic_radius * sonic_age) / 5'd24;
    wire [8:0]  cur_r = cur_r_raw[8:0];
    wire is_p1_r1 = (hp > 5'd0) && (oct_sonic >= cur_r - 9'd3 && oct_sonic <= cur_r + 9'd3);
    wire is_p1_r2 = (hp > 5'd0) && (cur_r > 9'd18) && (oct_sonic >= cur_r - 9'd16 && oct_sonic <= cur_r - 9'd12);
    wire is_p2_r1 = p2_active && (hp2 > 5'd0) && (oct_sonic2 >= cur_r - 9'd3 && oct_sonic2 <= cur_r + 9'd3);
    wire is_p2_r2 = p2_active && (hp2 > 5'd0) && (cur_r > 9'd18) && (oct_sonic2 >= cur_r - 9'd16 && oct_sonic2 <= cur_r - 9'd12);
    wire is_sonic_ring1 = is_p1_r1 || is_p2_r1;
    wire is_sonic_ring2 = is_p1_r2 || is_p2_r2;
    wire on_sonic_0 = (sonic_wave_t > 0) && in_playfield && (is_sonic_ring1 || is_sonic_ring2);
    wire [11:0] sonic_col_0 = is_sonic_ring1 ? (anim_cnt[1] ? 12'hFFF : ((is_p2_r1 && !is_p1_r1) ? 12'hF5E : 12'h3FF))
                                             : ((is_p2_r2 && !is_p1_r2) ? 12'hB2C : 12'h0BF);

    // ---- STAGE 0: HUD, TITLE SCREEN WITH ARCADE LOGO, < MODE > ARROWS, COMBO RANK ----
    localparam [5:0] C_SP=36, C_COL=37, C_DSH=38, C_EX=39, C_HRT=40, C_SL=41, C_LARW=42, C_RARW=43, C_PLUS=44, C_MUL=45;
        function automatic [5:0] wname_ch;
        input [2:0] wid;
        input [2:0] cpos;
        begin
            case (wid)
                3'd0: case (cpos) 0:wname_ch=lch("S"); 1:wname_ch=lch("W"); 2:wname_ch=lch("O"); 3:wname_ch=lch("R"); 4:wname_ch=lch("D"); default:wname_ch=C_SP; endcase
                3'd1: case (cpos) 0:wname_ch=lch("S"); 1:wname_ch=lch("A"); 2:wname_ch=lch("B"); 3:wname_ch=lch("E"); 4:wname_ch=lch("R"); default:wname_ch=C_SP; endcase
                3'd2: case (cpos) 0:wname_ch=lch("F"); 1:wname_ch=lch("I"); 2:wname_ch=lch("S"); 3:wname_ch=lch("T"); 4:wname_ch=lch("S"); default:wname_ch=C_SP; endcase
                3'd3: case (cpos) 0:wname_ch=lch("B"); 1:wname_ch=C_DSH;    2:wname_ch=lch("A"); 3:wname_ch=lch("X"); 4:wname_ch=lch("E"); default:wname_ch=C_SP; endcase
                3'd4: case (cpos) 0:wname_ch=lch("S"); 1:wname_ch=lch("P"); 2:wname_ch=lch("E"); 3:wname_ch=lch("A"); 4:wname_ch=lch("R"); default:wname_ch=C_SP; endcase
                3'd5: case (cpos) 0:wname_ch=lch("S"); 1:wname_ch=lch("C"); 2:wname_ch=lch("Y"); 3:wname_ch=lch("T"); 4:wname_ch=lch("H"); default:wname_ch=C_SP; endcase
                default: wname_ch=C_SP;
            endcase
        end
    endfunction
    function automatic [5:0] lch;
        input [7:0] ac;
        begin
            if      (ac >= "0" && ac <= "9") lch = ac - "0";
            else if (ac >= "A" && ac <= "Z") lch = ac - "A" + 6'd10;
            else if (ac == ":")              lch = C_COL;
            else if (ac == "-")              lch = C_DSH;
            else if (ac == "!")              lch = C_EX;
            else if (ac == "/")              lch = C_SL;
            else if (ac == "<")              lch = C_LARW;
            else if (ac == ">")              lch = C_RARW;
            else if (ac == "+")              lch = C_PLUS;
            else                             lch = C_SP;
        end
    endfunction

    // Precompute Combo decimal digits & Rank letter (ZERO divider!)
    reg [3:0] cmb_tens, cmb_ones;
    always @(*) begin
        if      (combo_cnt >= 7'd90) begin cmb_tens = 4'd9; cmb_ones = combo_cnt - 7'd90; end
        else if (combo_cnt >= 7'd80) begin cmb_tens = 4'd8; cmb_ones = combo_cnt - 7'd80; end
        else if (combo_cnt >= 7'd70) begin cmb_tens = 4'd7; cmb_ones = combo_cnt - 7'd70; end
        else if (combo_cnt >= 7'd60) begin cmb_tens = 4'd6; cmb_ones = combo_cnt - 7'd60; end
        else if (combo_cnt >= 7'd50) begin cmb_tens = 4'd5; cmb_ones = combo_cnt - 7'd50; end
        else if (combo_cnt >= 7'd40) begin cmb_tens = 4'd4; cmb_ones = combo_cnt - 7'd40; end
        else if (combo_cnt >= 7'd30) begin cmb_tens = 4'd3; cmb_ones = combo_cnt - 7'd30; end
        else if (combo_cnt >= 7'd20) begin cmb_tens = 4'd2; cmb_ones = combo_cnt - 7'd20; end
        else if (combo_cnt >= 7'd10) begin cmb_tens = 4'd1; cmb_ones = combo_cnt - 7'd10; end
        else                         begin cmb_tens = 4'd0; cmb_ones = combo_cnt[3:0]; end
    end
    wire [5:0] rank_ch = (combo_cnt >= 7'd25) ? lch("S") : ((combo_cnt >= 7'd15) ? lch("A") : ((combo_cnt >= 7'd8) ? lch("B") : ((combo_cnt >= 7'd3) ? lch("C") : lch("D"))));
    wire [3:0] en_tens = (enemies_left >= 5'd10) ? 4'd1 : 4'd0;
    wire [3:0] en_ones = (enemies_left >= 5'd10) ? (enemies_left - 5'd10) : enemies_left[3:0];
    wire [8:0] boss_bar_raw = (boss_kind == 2'd2) ? {1'b0, boss_hp} : ((boss_kind == 2'd1) ? ({1'b0, boss_hp} + {3'd0, boss_hp[7:2]}) : ({1'b0, boss_hp} + {2'd0, boss_hp[7:1]}));
    wire [8:0] boss_bar_w = (boss_bar_raw > 9'd240) ? 9'd240 : boss_bar_raw;

    reg [5:0] hud_char_code, hud_text_color, hud_bg_color, guide_line_col;
    reg [2:0] hud_char_row, hud_char_col;
    reg       hud_text_en, hud_bg_en, guide_line_en;
    wire [5:0] col_1x = gx[8:3];

    // Precomputed Title Screen Wires (Outside procedural always block)
    wire [8:0] tri_y_base = 9'd72 + (anim_cnt[23:22]==2'd1||anim_cnt[23:22]==2'd2 ? 9'd2 : 9'd0);
    wire [8:0] cur_cx = p2_active ? (hero_cursor ? 9'd208 : 9'd112) : 9'd160;
    wire [8:0] tri_dx = (gx >= cur_cx) ? (gx - cur_cx) : (cur_cx - gx);
    wire [3:0] tri_row = gy - tri_y_base;
    wire [3:0] tri_hw = (tri_row <= 4'd1) ? 4'd4 : ((tri_row <= 4'd3) ? 4'd3 : ((tri_row <= 4'd5) ? 4'd2 : ((tri_row <= 4'd7) ? 4'd1 : 4'd0)));

    always @(*) begin
        hud_char_code = C_SP; hud_char_row = gy[2:0]; hud_char_col = gx[2:0];
        hud_text_color = 6'd17; hud_text_en = 0; hud_bg_en = 0; hud_bg_color = 6'd54;
        guide_line_en = 0; guide_line_col = 6'd58;

        if (in_guide_view) begin
            // =================================================================
            // UNIFIED CONTROLS GUIDE TERMINAL (TITLE GUIDE & IN-GAME PAUSE)
            // =================================================================
            if (paused && gx >= 9'd128 && gx < 9'd192 && gy >= 9'd5 && gy < 9'd16) begin
                hud_bg_en = 1;
                hud_bg_color = (gx == 9'd128 || gx == 9'd191 || gy == 9'd5 || gy == 9'd15) ? 6'd52 : 6'd16;
                if (gy >= 9'd7 && gy < 9'd15 && col_1x >= 6'd17 && col_1x < 6'd23) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd7; hud_text_color = 6'd58;
                    case (col_1x - 6'd17)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("A"); 2:hud_char_code=lch("U");
                        3:hud_char_code=lch("S"); 4:hud_char_code=lch("E"); 5:hud_char_code=lch("D");
                        default:hud_char_code=C_SP;
                    endcase
                end
            end else if (gx >= 9'd24 && gx < 9'd296 && gy >= 9'd16 && gy < (paused ? 9'd236 : 9'd228)) begin
                hud_bg_en = 1;
                hud_bg_color = (gx == 9'd24 || gx == 9'd295 || gy == 9'd16 || gy == (paused ? 9'd235 : 9'd227) || gy == 9'd42 || gy == 9'd196) ?
                               ((help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd28)) : 6'd54;
            end
            // Header (gy=24..32) — NO < > ARROWS!
            if (gy >= 9'd24 && gy < 9'd32 && col_1x >= 6'd6 && col_1x < 6'd34) begin
                hud_text_en = 1; hud_char_row = gy - 9'd24;
                hud_text_color = (help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd28);
                if (help_page == 2'd1) begin
                    case (col_1x - 6'd11)
                        0:hud_char_code=lch("1"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("3");
                        3:hud_char_code=C_SP;     4:hud_char_code=lch("B"); 5:hud_char_code=lch("O"); 6:hud_char_code=lch("A"); 7:hud_char_code=lch("R");
                        8:hud_char_code=lch("D"); 9:hud_char_code=C_SP;   10:hud_char_code=lch("H"); 11:hud_char_code=lch("A"); 12:hud_char_code=lch("R");
                        13:hud_char_code=lch("D"); 14:hud_char_code=lch("W"); 15:hud_char_code=lch("A"); 16:hud_char_code=lch("R"); 17:hud_char_code=lch("E");
                        default:hud_char_code=C_SP;
                    endcase
                end else if (help_page == 2'd2) begin
                    case (col_1x - 6'd9)
                        0:hud_char_code=lch("2"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("3");
                        3:hud_char_code=C_SP;     4:hud_char_code=lch("J"); 5:hud_char_code=lch("O"); 6:hud_char_code=lch("Y"); 7:hud_char_code=lch("S");
                        8:hud_char_code=lch("T"); 9:hud_char_code=lch("I"); 10:hud_char_code=lch("C"); 11:hud_char_code=lch("K"); 12:hud_char_code=C_SP;
                        13:hud_char_code=lch("C"); 14:hud_char_code=lch("O"); 15:hud_char_code=lch("N"); 16:hud_char_code=lch("T"); 17:hud_char_code=lch("R");
                        18:hud_char_code=lch("O"); 19:hud_char_code=lch("L"); 20:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                    endcase
                end else begin
                    case (col_1x - 6'd9)
                        0:hud_char_code=lch("3"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("3");
                        3:hud_char_code=C_SP;     4:hud_char_code=lch("K"); 5:hud_char_code=lch("E"); 6:hud_char_code=lch("Y"); 7:hud_char_code=lch("B");
                        8:hud_char_code=lch("O"); 9:hud_char_code=lch("A"); 10:hud_char_code=lch("R"); 11:hud_char_code=lch("D"); 12:hud_char_code=C_SP;
                        13:hud_char_code=lch("C"); 14:hud_char_code=lch("O"); 15:hud_char_code=lch("N"); 16:hud_char_code=lch("T"); 17:hud_char_code=lch("R");
                        18:hud_char_code=lch("O"); 19:hud_char_code=lch("L"); 20:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                    endcase
                end
            end

                // PAGE 1: BOARD HARDWARE TERMINAL
                if (help_page == 2'd1) begin
                    if (gy >= 9'd48 && gy < 9'd56 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd48; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("L"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("R"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("S"); 9:hud_char_code=lch("E");
                            10:hud_char_code=lch("L"); 11:hud_char_code=lch("E"); 12:hud_char_code=lch("C"); 13:hud_char_code=lch("T"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("P"); 16:hud_char_code=lch("1"); 17:hud_char_code=C_SP;   18:hud_char_code=lch("/"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("P"); 21:hud_char_code=lch("2"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd62 && gy < 9'd70 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd62; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("C"); 4:hud_char_code=C_COL;
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("C"); 7:hud_char_code=lch("Y"); 8:hud_char_code=lch("C"); 9:hud_char_code=lch("L");
                            10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("H"); 13:hud_char_code=lch("E"); 14:hud_char_code=lch("A");
                            15:hud_char_code=lch("D"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("S"); 18:hud_char_code=lch("T"); 19:hud_char_code=lch("Y");
                            20:hud_char_code=lch("L"); 21:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd76 && gy < 9'd84 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd76; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("U"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("D"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("C"); 9:hud_char_code=lch("Y");
                            10:hud_char_code=lch("C"); 11:hud_char_code=lch("L"); 12:hud_char_code=lch("E"); 13:hud_char_code=C_SP;   14:hud_char_code=lch("6");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("E"); 18:hud_char_code=lch("A"); 19:hud_char_code=lch("P");
                            20:hud_char_code=lch("O"); 21:hud_char_code=lch("N"); 22:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd94 && gy < 9'd102 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd94; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("C"); 3:hud_char_code=C_SP;     4:hud_char_code=lch("R");
                            5:hud_char_code=lch("O"); 6:hud_char_code=lch("A"); 7:hud_char_code=lch("R"); 8:hud_char_code=C_COL;    9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("O"); 12:hud_char_code=lch("N"); 13:hud_char_code=lch("I"); 14:hud_char_code=lch("C");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("A"); 18:hud_char_code=lch("V"); 19:hud_char_code=lch("E");
                            20:hud_char_code=C_SP;    21:hud_char_code=lch("P"); 22:hud_char_code=lch("U"); 23:hud_char_code=lch("S"); 24:hud_char_code=lch("H");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd108 && gy < 9'd116 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd108; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("T"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("M"); 3:hud_char_code=lch("P"); 4:hud_char_code=C_SP;
                            5:hud_char_code=lch("C"); 6:hud_char_code=lch("H"); 7:hud_char_code=lch("I"); 8:hud_char_code=lch("P"); 9:hud_char_code=C_COL;
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("T"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("U"); 14:hud_char_code=lch("C");
                            15:hud_char_code=lch("H"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("F"); 18:hud_char_code=lch("L"); 19:hud_char_code=lch("A");
                            20:hud_char_code=lch("M"); 21:hud_char_code=lch("E"); 22:hud_char_code=C_SP;   23:hud_char_code=lch("A"); 24:hud_char_code=lch("U");
                            25:hud_char_code=lch("R"); 26:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd124 && gy < 9'd132 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd124; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("0"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("F"); 6:hud_char_code=lch("E"); 7:hud_char_code=lch("V"); 8:hud_char_code=lch("E"); 9:hud_char_code=lch("R");
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("D"); 12:hud_char_code=lch("E"); 13:hud_char_code=lch("M"); 14:hud_char_code=lch("O");
                            15:hud_char_code=C_SP;   16:hud_char_code=lch("F"); 17:hud_char_code=lch("O"); 18:hud_char_code=lch("R"); 19:hud_char_code=lch("C");
                            20:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd138 && gy < 9'd146 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd138; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("1"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("7"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("E"); 8:hud_char_code=lch("G"); 9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("H"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("W"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("L"); 16:hud_char_code=lch("I"); 17:hud_char_code=lch("V"); 18:hud_char_code=lch("E"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("T"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("M"); 23:hud_char_code=lch("P"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd152 && gy < 9'd160 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd152; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("1"); 3:hud_char_code=lch("5"); 4:hud_char_code=C_DSH;
                            5:hud_char_code=lch("1"); 6:hud_char_code=lch("1"); 7:hud_char_code=C_COL;    8:hud_char_code=C_SP;     9:hud_char_code=lch("A");
                            10:hud_char_code=lch("U"); 11:hud_char_code=lch("D"); 12:hud_char_code=lch("I"); 13:hud_char_code=lch("O"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("M"); 16:hud_char_code=lch("U"); 17:hud_char_code=lch("T"); 18:hud_char_code=lch("E"); 19:hud_char_code=C_SL;
                            20:hud_char_code=lch("V"); 21:hud_char_code=lch("O"); 22:hud_char_code=lch("L"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd168 && gy < 9'd176 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd168; hud_text_color = 6'd28;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("A"); 1:hud_char_code=lch("N"); 2:hud_char_code=C_COL;    3:hud_char_code=C_SP;     4:hud_char_code=lch("6");
                            5:hud_char_code=C_DSH;    6:hud_char_code=lch("D"); 7:hud_char_code=lch("I"); 8:hud_char_code=lch("G"); 9:hud_char_code=lch("I");
                            10:hud_char_code=lch("T"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("S"); 13:hud_char_code=lch("C"); 14:hud_char_code=lch("O");
                            15:hud_char_code=lch("R"); 16:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end
                // PAGE 2: JOYSTICK TERMINAL (ACCURATE POINTER LINES TO EXACT BUTTONS, NO BUTTON NAMES!)
                // joy_pixel placed at gx=96..191, gy=58..121
                end else if (help_page == 2'd2) begin
                    // 1. Left D-Pad Cross exact center (115, 79) -> Left to gx=68 -> MOVE
                    if ((gy == 9'd79 && gx >= 9'd68 && gx <= 9'd115) ||
                        (gx >= 9'd114 && gx <= 9'd116 && gy >= 9'd78 && gy <= 9'd80)) begin
                        guide_line_en = 1; guide_line_col = 6'd59; // Cyan
                    // 2. Left Button '4' (164, 79) -> (161, 79) -> UP to (161, 50) -> RIGHT to (228, 50) -> NOVA
                    end else if ((gy == 9'd79 && gx >= 9'd161 && gx <= 9'd164) ||
                                 (gx == 9'd161 && gy >= 9'd50 && gy <= 9'd79) ||
                                 (gy == 9'd50 && gx >= 9'd161 && gx <= 9'd228) ||
                                 (gx >= 9'd163 && gx <= 9'd165 && gy >= 9'd78 && gy <= 9'd80)) begin
                        guide_line_en = 1; guide_line_col = 6'd51; // Pink/Magenta
                    // 3. Top Button '1' (171, 73) -> UP to (171, 65) -> RIGHT to (228, 65) -> BULLET
                    end else if ((gx == 9'd171 && gy >= 9'd65 && gy <= 9'd73) ||
                                 (gy == 9'd65 && gx >= 9'd171 && gx <= 9'd228) ||
                                 (gx >= 9'd170 && gx <= 9'd172 && gy >= 9'd72 && gy <= 9'd74)) begin
                        guide_line_en = 1; guide_line_col = 6'd28; // Green
                    // 4. Right Button '2' (178, 79) -> RIGHT to (228, 79) -> DASH
                    end else if ((gy == 9'd79 && gx >= 9'd178 && gx <= 9'd228) ||
                                 (gx >= 9'd177 && gx <= 9'd179 && gy >= 9'd78 && gy <= 9'd80)) begin
                        guide_line_en = 1; guide_line_col = 6'd52; // Red
                    // 5. Bottom Button '3' (171, 85) -> RIGHT to (194, 85) -> DOWN to (194, 96) -> RIGHT to (228, 96) -> ATTACK
                    end else if ((gy == 9'd85 && gx >= 9'd171 && gx <= 9'd194) ||
                                 (gx == 9'd194 && gy >= 9'd85 && gy <= 9'd96) ||
                                 (gy == 9'd96 && gx >= 9'd194 && gx <= 9'd228) ||
                                 (gx >= 9'd170 && gx <= 9'd172 && gy >= 9'd84 && gy <= 9'd86)) begin
                        guide_line_en = 1; guide_line_col = 6'd59; // Blue/Cyan
                    // 6. Center SELECT (138, 85) -> DOWN to (138, 138) -> LEFT to (84, 138) -> EXIT
                    end else if ((gx == 9'd138 && gy >= 9'd85 && gy <= 9'd138) ||
                                 (gy == 9'd138 && gx >= 9'd84 && gx <= 9'd138) ||
                                 (gx >= 9'd137 && gx <= 9'd139 && gy >= 9'd84 && gy <= 9'd86)) begin
                        guide_line_en = 1; guide_line_col = 6'd58; // Gold
                    // 7. Center START (148, 85) -> DOWN to (148, 138) -> RIGHT to (196, 138) -> PAUSE
                    end else if ((gx == 9'd148 && gy >= 9'd85 && gy <= 9'd138) ||
                                 (gy == 9'd138 && gx >= 9'd148 && gx <= 9'd196) ||
                                 (gx >= 9'd147 && gx <= 9'd149 && gy >= 9'd84 && gy <= 9'd86)) begin
                        guide_line_en = 1; guide_line_col = 6'd17; // White
                    end

                    // Pure Action Labels ONLY (NO button names like D-PAD or 1/A!)
                    if (gy >= 9'd74 && gy < 9'd82 && col_1x >= 6'd4 && col_1x < 6'd8) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd74; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("V"); 3:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd46 && gy < 9'd54 && col_1x >= 6'd29 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd46; hud_text_color = 6'd51;
                        case (col_1x - 6'd29)
                            0:hud_char_code=lch("N"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("V"); 3:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd61 && gy < 9'd69 && col_1x >= 6'd29 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd61; hud_text_color = 6'd28;
                        case (col_1x - 6'd29)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("U"); 2:hud_char_code=lch("L"); 3:hud_char_code=lch("L");
                            4:hud_char_code=lch("E"); 5:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd75 && gy < 9'd83 && col_1x >= 6'd29 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd75; hud_text_color = 6'd52;
                        case (col_1x - 6'd29)
                            0:hud_char_code=lch("D"); 1:hud_char_code=lch("A"); 2:hud_char_code=lch("S"); 3:hud_char_code=lch("H"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd92 && gy < 9'd100 && col_1x >= 6'd29 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd92; hud_text_color = 6'd59;
                        case (col_1x - 6'd29)
                            0:hud_char_code=lch("A"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("T"); 3:hud_char_code=lch("A");
                            4:hud_char_code=lch("C"); 5:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd134 && gy < 9'd142 && col_1x >= 6'd6 && col_1x < 6'd10) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd134; hud_text_color = 6'd58;
                        case (col_1x - 6'd6)
                            0:hud_char_code=lch("E"); 1:hud_char_code=lch("X"); 2:hud_char_code=lch("I"); 3:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd134 && gy < 9'd142 && col_1x >= 6'd25 && col_1x < 6'd30) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd134; hud_text_color = 6'd17;
                        case (col_1x - 6'd25)
                            0:hud_char_code=lch("P"); 1:hud_char_code=lch("A"); 2:hud_char_code=lch("U"); 3:hud_char_code=lch("S");
                            4:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end
                // PAGE 3: KEYBOARD CONTROLS TERMINAL (Rendered cleanly via kb_guide ROM real white keycaps!)
                end else begin
                    // Real white mechanical keycaps are composited directly from u_kb_rom at gx=32..287, gy=46..189
                end

                // Footer Labels beside Real Button Icons (gy=203..211, NO < > arrows!)
                // PREV (col_1x=9..12, only when help_page > 1)
                if (help_page > 2'd1 && gy >= 9'd203 && gy < 9'd211 && col_1x >= 6'd9 && col_1x < 6'd13) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd203; hud_text_color = 6'd59;
                    case (col_1x - 6'd9)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("R"); 2:hud_char_code=lch("E"); 3:hud_char_code=lch("V");
                    endcase
                // RESUME (when in-game Pause) or EXIT (when Title Guide)
                end else if (paused && gy >= 9'd203 && gy < 9'd211 && col_1x >= 6'd19 && col_1x < 6'd25) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd203; hud_text_color = 6'd28;
                    case (col_1x - 6'd19)
                        0:hud_char_code=lch("R"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("S");
                        3:hud_char_code=lch("U"); 4:hud_char_code=lch("M"); 5:hud_char_code=lch("E");
                    endcase
                end else if (!paused && gy >= 9'd203 && gy < 9'd211 && col_1x >= 6'd20 && col_1x < 6'd24) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd203; hud_text_color = 6'd58;
                    case (col_1x - 6'd20)
                        0:hud_char_code=lch("E"); 1:hud_char_code=lch("X"); 2:hud_char_code=lch("I"); 3:hud_char_code=lch("T");
                    endcase
                // NEXT (col_1x=31..34, hidden on Page 3!)
                end else if (help_page < 2'd3 && gy >= 9'd203 && gy < 9'd211 && col_1x >= 6'd31 && col_1x < 6'd35) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd203; hud_text_color = 6'd59;
                    case (col_1x - 6'd31)
                        0:hud_char_code=lch("N"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("X"); 3:hud_char_code=lch("T");
                    endcase
                // Second Footer Row when PAUSED (Real Button Icons ONLY, zero redundant yellow text!)
                // [SEL] MENU (Joy) or [ESC] RESUME (KB) aligned cleanly under [STR]/[ENT] RESUME
                end else if (paused && gy >= 9'd219 && gy < 9'd227 && col_1x >= 6'd18 && col_1x < 6'd25) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd219;
                    if (is_kb_mode_0) begin
                        hud_text_color = 6'd28;
                        case (col_1x - 6'd18)
                            0:hud_char_code=lch("R"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("S");
                            3:hud_char_code=lch("U"); 4:hud_char_code=lch("M"); 5:hud_char_code=lch("E");
                            default:hud_char_code=C_SP;
                        endcase
                    end else begin
                        hud_text_color = 6'd17;
                        case (col_1x - 6'd18)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("U");
                            default:hud_char_code=C_SP;
                        endcase
                    end
                end
        end else if (game_state == 3'd0) begin
                // =============================================================
                // TITLE SCREEN (Dead-Cells Auto-Detected UI, Joystick 1P/2P Toggle)
                // =============================================================
                // 0. Joystick 1P / 2P Pill (ONLY visible when Joystick detected; Keyboard forces 1P Solo!)
                if (!is_kb_mode_0 && gy >= 9'd56 && gy <= 9'd69 && gx >= 9'd96 && gx < 9'd224) begin
                    hud_bg_en = 1;
                    hud_bg_color = (gy == 9'd56 || gy == 9'd69 || gx == 9'd96 || gx == 9'd223) ? (p2_active ? 6'd58 : 6'd59) : 6'd54;
                    if (gy >= 9'd59 && gy < 9'd67 && col_1x >= 6'd13 && col_1x <= 6'd26) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd59;
                        if (col_1x == 6'd13)      begin hud_char_code = C_LARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                        else if (col_1x == 6'd26) begin hud_char_code = C_RARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                        else begin
                            hud_text_color = p2_active ? 6'd51 : 6'd59;
                            case (col_1x - 6'd15)
                                0: hud_char_code = p2_active ? lch("2") : C_SP;
                                1: hud_char_code = p2_active ? C_SP     : lch("1");
                                2: hud_char_code = p2_active ? lch("P") : C_SP;
                                3: hud_char_code = p2_active ? lch("L") : lch("P");
                                4: hud_char_code = p2_active ? lch("A") : lch("L");
                                5: hud_char_code = p2_active ? lch("Y") : lch("A");
                                6: hud_char_code = p2_active ? lch("E") : lch("Y");
                                7: hud_char_code = p2_active ? lch("R") : lch("E");
                                8: hud_char_code = p2_active ? lch("S") : lch("R");
                                default: hud_char_code = C_SP;
                            endcase
                        end
                    end
                // 1. Inverted Triangle Cursor (▼) pointing down at selected hero
                end else if (gy >= tri_y_base && gy < tri_y_base + 9'd9) begin
                    if (tri_dx <= tri_hw) begin
                        hud_bg_en = 1;
                        hud_bg_color = (tri_dx == tri_hw || tri_row == 4'd0) ? 6'd17 : 6'd58;
                    end
                // 2. Weapon Names under centered characters (gy=138..146)
                end else if (!p2_active && gy >= 9'd138 && gy < 9'd146 && col_1x >= 6'd16 && col_1x < 6'd24) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd138;
                    hud_text_color = 6'd58;
                    case (col_1x - 6'd16)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("1"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p1_weapon, 3'd0); 4:hud_char_code=wname_ch(p1_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p1_weapon, 3'd2); 6:hud_char_code=wname_ch(p1_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p1_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                end else if (p2_active && gy >= 9'd138 && gy < 9'd146 && col_1x >= 6'd10 && col_1x < 6'd18) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd138;
                    hud_text_color = (hero_cursor == 1'b0) ? 6'd58 : 6'd60;
                    case (col_1x - 6'd10)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("1"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p1_weapon, 3'd0); 4:hud_char_code=wname_ch(p1_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p1_weapon, 3'd2); 6:hud_char_code=wname_ch(p1_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p1_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                end else if (p2_active && gy >= 9'd138 && gy < 9'd146 && col_1x >= 6'd22 && col_1x < 6'd30) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd138;
                    hud_text_color = (hero_cursor == 1'b1) ? 6'd58 : 6'd60;
                    case (col_1x - 6'd22)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("2"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p2_weapon, 3'd0); 4:hud_char_code=wname_ch(p2_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p2_weapon, 3'd2); 6:hud_char_code=wname_ch(p2_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p2_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                end
        end else if (game_state == 3'd1) begin
            if (in_cut_bar) begin
                hud_bg_en = 1; hud_bg_color = (gy == 9'd33 || gy == 9'd206) ? ((cut_id == 2'd2) ? 6'd52 : 6'd58) : 6'd16;
                if (gy >= 9'd10 && gy < 9'd26 && gx >= 9'd64 && gx < 9'd256) begin
                    hud_text_en = 1; hud_text_color = (cut_id == 2'd2) ? 6'd52 : ((cut_id == 2'd3) ? 6'd59 : 6'd58);
                    hud_char_row = (gy - 9'd10) >> 1; hud_char_col = gx[3:1];
                    case ((gx - 9'd64) >> 4)
                        0:hud_char_code=(cut_id==0)?lch("O"):((cut_id==1)?lch("W"):((cut_id==2)?lch("O"):lch("U")));
                        1:hud_char_code=(cut_id==0)?lch("M"):((cut_id==1)?lch("A"):((cut_id==2)?lch("M"):lch("P")));
                        2:hud_char_code=(cut_id==0)?lch("E"):((cut_id==1)?lch("V"):((cut_id==2)?lch("E"):lch("G")));
                        3:hud_char_code=(cut_id==0)?lch("G"):((cut_id==1)?lch("E"):((cut_id==2)?lch("G"):lch("R")));
                        4:hud_char_code=(cut_id==0)?lch("A"):((cut_id==1)?C_SP    :((cut_id==2)?lch("A"):lch("A")));
                        5:hud_char_code=(cut_id==0)?C_SP    :((cut_id==1)?((wave == 4'd10) ? lch("X") : {2'd0, wave}):((cut_id==2)?C_SP:lch("D")));
                        6:hud_char_code=(cut_id==0)?lch("W"):((cut_id==1)?C_SP    :((cut_id==2)?lch("S"):lch("E")));
                        7:hud_char_code=(cut_id==0)?lch("A"):((cut_id==1)?lch("N"):((cut_id==2)?lch("E"):lch("!")));
                        8:hud_char_code=(cut_id==0)?lch("V"):((cut_id==1)?lch("E"):((cut_id==2)?lch("A"):C_SP));
                        9:hud_char_code=(cut_id==0)?lch("E"):((cut_id==1)?lch("X"):((cut_id==2)?lch("L"):lch("U")));
                        10:hud_char_code=(cut_id==0)?lch("1"):((cut_id==1)?lch("T"):((cut_id==2)?lch("E"):lch("P")));
                        11:hud_char_code=(cut_id==0)?lch("!"):((cut_id==1)?lch("!"):((cut_id==2)?lch("D"):{4'd0,stage}));
                        default: hud_char_code=C_SP;
                    endcase
                end else if (gy >= 9'd218 && gy < 9'd226 && col_1x >= 6'd8 && col_1x < 6'd32) begin
                    hud_text_en = 1; hud_text_color = 6'd58; hud_char_row = gy - 9'd218;
                    if (cut_id == 2'd3) begin
                        case (col_1x - 6'd8)
                            0:hud_char_code=(stage==1)?lch("P"):((stage==2)?lch("O"):lch("A"));
                            1:hud_char_code=(stage==1)?lch("E"):((stage==2)?lch("R"):lch("P"));
                            2:hud_char_code=(stage==1)?lch("T"):((stage==2)?lch("B"):lch("E"));
                            3:hud_char_code=(stage==1)?C_SP    :((stage==2)?lch("I"):lch("X"));
                            4:hud_char_code=(stage==1)?lch("M"):((stage==2)?lch("T"):C_SP);
                            5:hud_char_code=(stage==1)?lch("O"):((stage==2)?C_SP    :lch("A"));
                            6:hud_char_code=(stage==1)?lch("B"):((stage==2)?lch("S"):lch("U"));
                            7:hud_char_code=(stage==1)?C_SP    :((stage==2)?lch("W"):lch("R"));
                            8:hud_char_code=(stage==1)?lch("S"):((stage==2)?lch("O"):lch("A"));
                            9:hud_char_code=(stage==1)?lch("P"):((stage==2)?lch("R"):C_SP);
                            10:hud_char_code=(stage==1)?lch("A"):((stage==2)?lch("D"):lch("A"));
                            11:hud_char_code=(stage==1)?lch("W"):((stage==2)?lch("S"):lch("W"));
                            12:hud_char_code=(stage==1)?lch("N"):((stage==2)?C_SP    :lch("A"));
                            13:hud_char_code=(stage==1)?lch("E"):((stage==2)?lch("O"):lch("K"));
                            14:hud_char_code=(stage==1)?lch("D"):((stage==2)?lch("N"):lch("E"));
                            15:hud_char_code=(stage==1)?lch("!"):((stage==2)?lch("!"):lch("N"));
                            default: hud_char_code=C_SP;
                        endcase
                    end else begin
                        case (col_1x - 6'd8)
                            0:hud_char_code=(cut_id==0)?lch("L"):((cut_id==1)?lch("H"):lch("S"));
                            1:hud_char_code=(cut_id==0)?lch("U"):((cut_id==1)?lch("O"):lch("E"));
                            2:hud_char_code=(cut_id==0)?lch("N"):((cut_id==1)?lch("R"):lch("A"));
                            3:hud_char_code=(cut_id==0)?lch("G"):((cut_id==1)?lch("D"):lch("L"));
                            4:hud_char_code=(cut_id==0)?lch("E"):((cut_id==1)?lch("E"):lch("E"));
                            5:hud_char_code=(cut_id==0)?C_SP    :((cut_id==1)?C_SP    :lch("D"));
                            6:hud_char_code=(cut_id==0)?lch("3"):((cut_id==1)?lch("I"):C_SP);
                            7:hud_char_code=(cut_id==0)?C_MUL   :((cut_id==1)?lch("N"):lch("S"));
                            8:hud_char_code=(cut_id==0)?lch("C"):((cut_id==1)?lch("C"):lch("A"));
                            9:hud_char_code=(cut_id==0)?lch("O"):((cut_id==1)?lch("O"):lch("N"));
                            10:hud_char_code=(cut_id==0)?lch("M"):((cut_id==1)?lch("M"):lch("C"));
                            11:hud_char_code=(cut_id==0)?lch("B"):((cut_id==1)?lch("I"):lch("T"));
                            12:hud_char_code=(cut_id==0)?lch("O"):((cut_id==1)?lch("N"):lch("U"));
                            13:hud_char_code=(cut_id==0)?lch("!"):((cut_id==1)?lch("G"):lch("M"));
                            14:hud_char_code=(cut_id==0)?C_SP    :((cut_id==1)?lch("!"):lch("!"));
                            default: hud_char_code=C_SP;
                        endcase
                    end
                end
            end
        end else begin
            // TOP HUD (P1 Hearts, P2 Hearts, Wave 1..X, Combo Rank, Score, Enemies, Gem/Chrono Bars)
            if (in_hud_top) begin
                hud_bg_en = 1; hud_bg_color = (gy == 9'd27) ? 6'd55 : 6'd54;
                if (gx >= 9'd296 && gx <= 9'd312 && gy >= 9'd5 && gy <= 9'd21) begin
                    if (gx==9'd296||gx==9'd312||gy==9'd5||gy==9'd21) hud_bg_color = 6'd55;
                    else if ($signed({1'b0, gx}) >= 11'sd304 + (tilt_dx * 3) - 1 && $signed({1'b0, gx}) <= 11'sd304 + (tilt_dx * 3) + 1 &&
                             $signed({1'b0, gy}) >= 11'sd13  + (tilt_dy * 3) - 1 && $signed({1'b0, gy}) <= 11'sd13  + (tilt_dy * 3) + 1)
                        hud_bg_color = 6'd59;
                    else hud_bg_color = 6'd16;
                end else if (gy >= 9'd4 && gy < 9'd12) begin
                    hud_char_row = gy - 9'd4;
                    if (col_1x == 6'd0) begin hud_text_en = 1'b1; hud_char_code = p2_active ? lch("1") : lch("H"); hud_text_color = 6'd58; end
                    else if (gx >= 9'd10 && gx <= 9'd59 && gy >= 9'd5 && gy <= 9'd10) begin
                        if (gx == 9'd10 || gx == 9'd59 || gy == 9'd5 || gy == 9'd10) hud_bg_color = 6'd55;
                        else if ((gx - 9'd11) < {4'd0, hp, 1'b0}) hud_bg_color = (hp >= 5'd13) ? 6'd51 : ((hp >= 5'd7) ? 6'd58 : 6'd52);
                        else hud_bg_color = 6'd16;
                    end else if (p2_active && col_1x == 6'd8) begin hud_text_en = 1; hud_char_code = lch("2"); hud_text_color = 6'd59; end
                    else if (p2_active && gx >= 9'd74 && gx <= 9'd123 && gy >= 9'd5 && gy <= 9'd10) begin
                        if (gx == 9'd74 || gx == 9'd123 || gy == 9'd5 || gy == 9'd10) hud_bg_color = 6'd55;
                        else if ((gx - 9'd75) < {4'd0, hp2, 1'b0}) hud_bg_color = (hp2 >= 5'd7) ? 6'd59 : 6'd52;
                        else hud_bg_color = 6'd16;
                    end else if (col_1x >= 6'd16 && col_1x <= 6'd18) begin
                        hud_text_en = 1; hud_text_color = 6'd59;
                        if (col_1x == 6'd16) hud_char_code = lch("W");
                        else if (wave == 4'd10) hud_char_code = (col_1x == 6'd17) ? lch("1") : lch("0");
                        else hud_char_code = (col_1x == 6'd17) ? {2'd0, wave} : C_SP;
                    end else if (col_1x >= 6'd19 && col_1x <= 6'd27) begin
                        hud_text_en = 1; hud_text_color = 6'd17;
                        case (col_1x - 6'd19)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=C_COL;
                            3:hud_char_code={2'd0,score_bcd[23:20]}; 4:hud_char_code={2'd0,score_bcd[19:16]};
                            5:hud_char_code={2'd0,score_bcd[15:12]}; 6:hud_char_code={2'd0,score_bcd[11:8]};
                            7:hud_char_code={2'd0,score_bcd[7:4]};   8:hud_char_code={2'd0,score_bcd[3:0]};
                        endcase
                    end else if (col_1x >= 6'd28 && col_1x <= 6'd35 && combo_cnt > 0) begin
                        hud_text_en = 1; hud_text_color = (combo_cnt >= 7'd25) ? 6'd58 : ((combo_cnt >= 7'd15) ? 6'd52 : 6'd61);
                        case (col_1x - 6'd28)
                            0: hud_char_code={2'd0, cmb_tens}; 1: hud_char_code={2'd0, cmb_ones}; 2: hud_char_code=C_MUL;
                            3: hud_char_code=rank_ch; default: hud_char_code=C_SP;
                        endcase
                    end
                end else if (gy >= 9'd15 && gy < 9'd23) begin
                    hud_char_row = gy - 9'd15;
                    if (col_1x >= 6'd1 && col_1x <= 6'd3) begin
                        hud_text_en = 1; hud_text_color = 6'd59;
                        case (col_1x - 6'd1) 0:hud_char_code=lch("G"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("M"); endcase
                    end else if (gx >= 9'd36 && gx < 9'd100 && gy >= 9'd16 && gy < 9'd22) begin
                        if (gy==9'd16||gy==9'd21||gx==9'd36||gx==9'd99) hud_bg_color = 6'd55;
                        else if ((gx - 9'd36) <= {3'd0, exp}) hud_bg_color = 6'd59; else hud_bg_color = 6'd16;
                    end else if (col_1x >= 6'd14 && col_1x <= 6'd16) begin
                        hud_text_en = 1; hud_text_color = 6'd50;
                        case (col_1x - 6'd14) 0:hud_char_code=lch("C"); 1:hud_char_code=lch("H"); 2:hud_char_code=lch("R"); endcase
                    end else if (gx >= 9'd140 && gx < 9'd240 && gy >= 9'd16 && gy < 9'd22) begin
                        if (gy==9'd16||gy==9'd21||gx==9'd140||gx==9'd239) hud_bg_color = 6'd55;
                        else if ((gx - 9'd140) < {2'd0, chrono_energy}) hud_bg_color = 6'd50; else hud_bg_color = 6'd16;
                    end else if (col_1x >= 6'd31 && col_1x <= 6'd35) begin
                        hud_text_en = 1; hud_text_color = zoom_out ? 6'd58 : 6'd52;
                        case (col_1x - 6'd31)
                            0: hud_char_code=lch("F"); 1: hud_char_code=(en_tens>0)?{2'd0,en_tens}:{2'd0,en_ones};
                            2: hud_char_code=(en_tens>0)?{2'd0,en_ones}:(zoom_out?lch("Z"):C_SP);
                            3: hud_char_code=pet_active?lch("P"):lch("-"); 4: hud_char_code=blades_active?lch("S"):lch("-");
                        endcase
                    end
                end
            end

            if (in_boss_bar) begin
                hud_bg_en = 1; hud_bg_color = (gy == 9'd224) ? 6'd55 : 6'd54;
                if (gy >= 9'd228 && gy < 9'd236 && col_1x >= 6'd2 && col_1x <= 6'd5) begin
                    hud_text_en = 1; hud_text_color = 6'd52; hud_char_row = gy - 9'd228;
                    case (col_1x - 6'd2) 0:hud_char_code=lch("B"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("S"); 3:hud_char_code=lch("S"); endcase
                end else if (gx >= 9'd56 && gx < 9'd296 && gy >= 9'd228 && gy < 9'd236) begin
                    if (gy==9'd228||gy==9'd235||gx==9'd56||gx==9'd295) hud_bg_color = 6'd55;
                    else if ((gx - 9'd56) < boss_bar_w) hud_bg_color = boss_enraged ? 6'd51 : 6'd52; else hud_bg_color = 6'd16;
                end
            end

            // V5 ARENA OVERLAYS: WAVE BANNER SLIDE-OUT, DOOR SLAM, LOGIC GATE QUIZ, BOSS QUOTE!
            if (game_state == 3'd2 && room_phase == 3'd0 && wave_banner_t > 0) begin
                // Wave Banner: centered for wave_banner_t > 40, then slides out to the right!
                if (gy >= 9'd96 && gy < 9'd128) begin : blk_wban
                    integer ban_sx, ban_cx;
                    ban_sx = (wave_banner_t <= 7'd40) ? (({25'd0, 7'd40 - wave_banner_t}) * 8) : 0;
                    if ($signed({1'b0, gx}) >= (11'sd72 + ban_sx) && $signed({1'b0, gx}) < (11'sd248 + ban_sx)) begin
                        hud_bg_en = 1;
                        hud_bg_color = (gy == 9'd96 || gy == 9'd127) ? 6'd58 : 6'd16;
                        if (gy >= 9'd104 && gy < 9'd120) begin
                            ban_cx = ($signed({1'b0, gx}) - (11'sd88 + ban_sx)) >> 4;
                            if (ban_cx >= 0 && ban_cx < 10) begin
                                hud_text_en = 1; hud_text_color = (wave == 4'd6) ? 6'd52 : 6'd58;
                                hud_char_row = (gy - 9'd104) >> 1;
                                hud_char_col = ($signed({1'b0, gx}) - (11'sd88 + ban_sx)) >> 1;
                                if (wave == 4'd6) begin
                                    case (ban_cx)
                                        0:hud_char_code=lch("F"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("N");
                                        3:hud_char_code=lch("A"); 4:hud_char_code=lch("L"); 5:hud_char_code=C_SP;
                                        6:hud_char_code=lch("B"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("S");
                                        9:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                                    endcase
                                end else begin
                                    case (ban_cx)
                                        2:hud_char_code=lch("W"); 3:hud_char_code=lch("A"); 4:hud_char_code=lch("V");
                                        5:hud_char_code=lch("E"); 6:hud_char_code=C_SP; 7:hud_char_code={2'd0, wave};
                                        default:hud_char_code=C_SP;
                                    endcase
                                end
                            end
                        end
                    end
                end
            end

            if (game_state == 3'd2 && door_slam_t > 0 && gy >= 9'd32 && gy < 9'd46 && col_1x >= 6'd11 && col_1x < 6'd29) begin
                hud_bg_en = 1; hud_bg_color = door_slam_t[2] ? 6'd52 : 6'd16;
                if (gy >= 9'd35 && gy < 9'd43) begin
                    hud_text_en = 1; hud_text_color = 6'd58; hud_char_row = gy - 9'd35;
                    case (col_1x - 6'd11)
                        0:hud_char_code=lch("D"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("O"); 3:hud_char_code=lch("R");
                        4:hud_char_code=C_SP; 5:hud_char_code=lch("L"); 6:hud_char_code=lch("O"); 7:hud_char_code=lch("C");
                        8:hud_char_code=lch("K"); 9:hud_char_code=lch("E"); 10:hud_char_code=lch("D"); 11:hud_char_code=lch("!");
                        12:hud_char_code=C_SP; 13:hud_char_code=lch("P"); 14:hud_char_code=lch("A"); 15:hud_char_code=lch("N");
                        16:hud_char_code=lch("G"); 17:hud_char_code=lch("!"); default:hud_char_code=C_SP;
                    endcase
                end
            end

            // Screen-Space Bouncing Flashing Arrow ("GO >>>") when room cleared or door open!
            if (game_state == 3'd2 && (room_phase == 3'd2 || room_phase == 3'd4) && anim_cnt[23]) begin : blk_hud_arw
                integer arw_x;
                arw_x = 248 + (anim_cnt[22] ? 8 : 0);
                if (gy >= 9'd108 && gy < 9'd124 && $signed({1'b0, gx}) >= arw_x && $signed({1'b0, gx}) < arw_x + 48) begin
                    hud_text_en = 1;
                    hud_text_color = (room_phase == 3'd4) ? 6'd28 : 6'd58;
                    hud_char_row = (gy - 9'd108) >> 1;
                    hud_char_col = ($signed({1'b0, gx}) - arw_x) >> 1;
                    case (($signed({1'b0, gx}) - arw_x) >> 4)
                        0: hud_char_code = C_RARW;
                        1: hud_char_code = C_RARW;
                        2: hud_char_code = C_RARW;
                        default: hud_char_code = C_SP;
                    endcase
                end
            end

            if (game_state == 3'd2 && room_phase == 3'd3 && gx >= 9'd56 && gx < 9'd264 && gy >= 9'd44 && gy < 9'd204) begin : blk_quiz
                integer qdx, qdy, q_opt;
                reg [3:0] opt_sum;
                reg [2:0] opt_gate;
                reg [1:0] opt_k;
                reg [8:0] or_back_x, or_front_x;
                hud_bg_en = 1;
                hud_bg_color = (gx == 9'd56 || gx == 9'd263 || gy == 9'd44 || gy == 9'd203) ? 6'd59 : 6'd54;
                // Title: "LOGIC GATE QUIZ"
                if (gy >= 9'd52 && gy < 9'd60 && col_1x >= 6'd12 && col_1x < 6'd27) begin
                    hud_text_en = 1; hud_text_color = 6'd58; hud_char_row = gy - 9'd52;
                    case (col_1x - 6'd12)
                        0:hud_char_code=lch("L"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("G"); 3:hud_char_code=lch("I");
                        4:hud_char_code=lch("C"); 5:hud_char_code=C_SP; 6:hud_char_code=lch("G"); 7:hud_char_code=lch("A");
                        8:hud_char_code=lch("T"); 9:hud_char_code=lch("E"); 10:hud_char_code=C_SP; 11:hud_char_code=lch("Q");
                        12:hud_char_code=lch("U"); 13:hud_char_code=lch("I"); 14:hud_char_code=lch("Z"); default:hud_char_code=C_SP;
                    endcase
                end
                // IEEE Logic Gate Symbol (gx=128..192, gy=66..106, center y=86)
                if (gx >= 9'd128 && gx < 9'd192 && gy >= 9'd66 && gy < 9'd106) begin
                    hud_bg_color = 6'd16;
                    qdy = (gy >= 9'd86) ? (gy - 9'd86) : (9'd86 - gy);
                    or_back_x  = 9'd144 + ((14 - qdy) >> 1);
                    or_front_x = 9'd174 - qdy - (qdy >> 1);
                    // Input & Output pins
                    if (quiz_gate == 3'd2) begin
                        if (gx >= 9'd134 && gx < 9'd148 && gy == 9'd86) hud_bg_color = 6'd59; // NOT single input
                    end else if (quiz_gate == 3'd0 || quiz_gate == 3'd3) begin
                        if (gx >= 9'd134 && gx < 9'd148 && (gy == 9'd78 || gy == 9'd94)) hud_bg_color = 6'd59; // AND/NAND pins
                    end else begin
                        if (gx >= 9'd134 && gx <= or_back_x && (gy == 9'd78 || gy == 9'd94)) hud_bg_color = 6'd59; // OR/NOR/XOR pins touch back curve!
                    end
                    if (gx >= 9'd174 && gx < 9'd188 && gy == 9'd86) hud_bg_color = 6'd58; // Output Y
                    // Gate Body
                    if (quiz_gate == 3'd0 || quiz_gate == 3'd3) begin
                        // AND / NAND
                        if (gx >= 9'd148 && gx <= 9'd160 && qdy <= 14) hud_bg_color = 6'd17;
                        else if (gx > 9'd160 && gx <= 9'd172) begin
                            qdx = gx - 9'd160;
                            if (qdx*qdx + qdy*qdy <= 196) hud_bg_color = 6'd17;
                        end
                    end else if (quiz_gate == 3'd2) begin
                        // NOT triangle
                        if (gx >= 9'd148 && gx <= 9'd170 && qdy <= ((170 - gx) >> 1) + 2) hud_bg_color = 6'd17;
                    end else begin
                        // OR / NOR / XOR (Pointed IEEE tip + Concave input curve)
                        if (gx >= or_back_x && gx <= or_front_x && qdy <= 14)
                            hud_bg_color = 6'd17;
                        if (quiz_gate == 3'd5 && gx >= (or_back_x - 9'd4) && gx <= (or_back_x - 9'd3) && qdy <= 14)
                            hud_bg_color = 6'd58; // XOR extra input curve
                    end
                    // Inversion bubble for NOT(2), NAND(3), NOR(4)
                    if ((quiz_gate == 3'd2 || quiz_gate == 3'd3 || quiz_gate == 3'd4) &&
                        gx >= 9'd174 && gx <= 9'd178 && qdy <= 2)
                        hud_bg_color = 6'd52;
                end
                // 4 Answer Options (gy = 114, 130, 146, 162) - Guaranteed Zero Duplicate Choices!
                for (q_opt = 0; q_opt < 4; q_opt = q_opt + 1) begin
                    if (gy >= (9'd114 + q_opt*16) && gy < (9'd122 + q_opt*16) && col_1x >= 6'd14 && col_1x < 6'd23) begin
                        if (q_opt[1:0] == quiz_ans_slot) opt_gate = quiz_gate;
                        else begin
                            opt_k = (q_opt[1:0] < quiz_ans_slot) ? q_opt[1:0] : (q_opt[1:0] - 2'd1);
                            opt_sum = {1'b0, quiz_gate} + {2'b00, opt_k} + 4'd1;
                            opt_gate = (opt_sum >= 4'd6) ? (opt_sum - 4'd6) : opt_sum[2:0];
                        end
                        hud_text_en = 1;
                        hud_text_color = (quiz_cursor == q_opt[1:0]) ? 6'd58 : 6'd17;
                        hud_char_row = gy - (9'd114 + q_opt*16);
                        case (col_1x - 6'd14)
                            0: hud_char_code = (quiz_cursor == q_opt[1:0]) ? C_RARW : C_SP;
                            1: hud_char_code = C_SP;
                            2: case (opt_gate) 0:hud_char_code=lch("A"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("N"); 4:hud_char_code=lch("N"); default:hud_char_code=lch("X"); endcase
                            3: case (opt_gate) 0:hud_char_code=lch("N"); 1:hud_char_code=lch("R"); 2:hud_char_code=lch("O"); 3:hud_char_code=lch("A"); 4:hud_char_code=lch("O"); default:hud_char_code=lch("O"); endcase
                            4: case (opt_gate) 0:hud_char_code=lch("D"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("T"); 3:hud_char_code=lch("N"); 4:hud_char_code=lch("R"); default:hud_char_code=lch("R"); endcase
                            5: hud_char_code = (opt_gate == 3'd3) ? lch("D") : C_SP;
                            default: hud_char_code = C_SP;
                        endcase
                    end
                end
                // Quiz Control Labels beside Slot 11 Real Button Icons (gy=185..193)
                if (!wrong_boss_active && gy >= 9'd185 && gy < 9'd193) begin
                    if (col_1x >= 6'd14 && col_1x < 6'd18) begin
                        hud_text_en = 1; hud_text_color = 6'd59; hud_char_row = gy - 9'd185;
                        case (col_1x - 6'd14)
                            0:hud_char_code=lch("P"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("C"); 3:hud_char_code=lch("K");
                        endcase
                    end else if (col_1x >= 6'd25 && col_1x < 6'd27) begin
                        hud_text_en = 1; hud_text_color = 6'd28; hud_char_row = gy - 9'd185;
                        case (col_1x - 6'd25)
                            0:hud_char_code=lch("O"); 1:hud_char_code=lch("K");
                        endcase
                    end
                end
                // Wrong Answer: Giant Angry Ajarn_V Form 2 + Yellow Caution Tape + Huge "F" & "GO RETAKE !!"
                if (wrong_boss_active) begin
                    if (gy >= 9'd117 && gy < 9'd149 && gx >= 9'd40 && gx < 9'd72) begin
                        // Huge 4x4 "F" in Red
                        hud_text_en = 1; hud_text_color = 6'd52;
                        hud_char_row = (gy - 9'd117) >> 2; hud_char_col = (gx - 9'd40) >> 2;
                        hud_char_code = lch("F");
                    end else if (gy >= 9'd125 && gy < 9'd141 && gx >= 9'd88 && gx < 9'd280) begin
                        // Bold 2x2 "GO RETAKE !!" in Black on Yellow Caution Tape
                        hud_text_en = 1; hud_text_color = 6'd16;
                        hud_char_row = (gy - 9'd125) >> 1; hud_char_col = (gx - 9'd88) >> 1;
                        case ((gx - 9'd88) >> 4)
                            0:hud_char_code=lch("G"); 1:hud_char_code=lch("O"); 2:hud_char_code=C_SP;
                            3:hud_char_code=lch("R"); 4:hud_char_code=lch("E"); 5:hud_char_code=lch("T");
                            6:hud_char_code=lch("A"); 7:hud_char_code=lch("K"); 8:hud_char_code=lch("E");
                            9:hud_char_code=C_SP;     10:hud_char_code=C_EX;    11:hud_char_code=C_EX;
                            default:hud_char_code=C_SP;
                        endcase
                    end
                end
            end

            // Cool Outfit-Change Transformation Cutscene (after Quiz Pass!)
            if (in_outfit_cut && gy >= 9'd36 && gy < 9'd204) begin
                hud_bg_en = 1;
                if (outfit_cut_t >= 8'd56 && outfit_cut_t <= 8'd64)
                    hud_bg_color = 6'd17; // Bright henshin flash!
                else if (gy == 9'd36 || gy == 9'd203)
                    hud_bg_color = 6'd58;
                else if ((gx >= 9'd154 && gx <= 9'd166) || (((gx - gy) & 5'd15) == 0) || (((gx + gy) & 5'd15) == 0))
                    hud_bg_color = (outfit_cut_t <= 8'd60) ? 6'd54 : 6'd55; // Spotlight beams
                else
                    hud_bg_color = 6'd16;
                if (gy >= 9'd44 && gy < 9'd60 && gx >= 9'd96 && gx < 9'd224) begin
                    hud_text_en = 1; hud_text_color = (outfit_cut_t <= 8'd60) ? 6'd58 : 6'd59;
                    hud_char_row = (gy - 9'd44) >> 1; hud_char_col = gx[3:1];
                    case ((gx - 9'd96) >> 4)
                        0:hud_char_code=(outfit_cut_t<=8'd60)?lch("E"):lch("N"); 1:hud_char_code=(outfit_cut_t<=8'd60)?lch("Q"):lch("E");
                        2:hud_char_code=(outfit_cut_t<=8'd60)?lch("U"):lch("W"); 3:hud_char_code=(outfit_cut_t<=8'd60)?lch("I"):C_SP;
                        4:hud_char_code=(outfit_cut_t<=8'd60)?lch("P"):lch("G"); 5:hud_char_code=(outfit_cut_t<=8'd60)?lch("P"):lch("E");
                        6:hud_char_code=(outfit_cut_t<=8'd60)?lch("E"):lch("A"); 7:hud_char_code=(outfit_cut_t<=8'd60)?lch("D"):lch("R");
                        default:hud_char_code=C_SP;
                    endcase
                end
            end

            // Boss Death Chuunibyou Quote Banner (room_phase == 3'd5)
            if (game_state == 3'd2 && room_phase == 3'd5 && boss_trans_t > 0 && gy >= 9'd188 && gy < 9'd210) begin
                hud_bg_en = 1; hud_bg_color = (gy == 9'd188 || gy == 9'd209) ? 6'd36 : 6'd16;
                if (gy >= 9'd195 && gy < 9'd203 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                    hud_text_en = 1; hud_text_color = (boss_kind == 2'd2) ? 6'd58 : 6'd60;
                    hud_char_row = gy - 9'd195;
                    if (boss_kind == 2'd0) begin
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("Y"); 2:hud_char_code=C_SP; 3:hud_char_code=lch("S");
                            4:hud_char_code=lch("E"); 5:hud_char_code=lch("A"); 6:hud_char_code=lch("L"); 7:hud_char_code=C_SP;
                            8:hud_char_code=lch("B"); 9:hud_char_code=lch("R"); 10:hud_char_code=lch("E"); 11:hud_char_code=lch("A");
                            12:hud_char_code=lch("K"); 13:hud_char_code=lch("S"); 14:hud_char_code=C_SP; 15:hud_char_code=lch("A");
                            16:hud_char_code=lch("W"); 17:hud_char_code=lch("A"); 18:hud_char_code=lch("K"); 19:hud_char_code=lch("E");
                            20:hud_char_code=lch("N"); 21:hud_char_code=C_SP; 22:hud_char_code=lch("P"); 23:hud_char_code=lch("H");
                            24:hud_char_code=lch("A"); 25:hud_char_code=lch("S"); 26:hud_char_code=lch("E"); 27:hud_char_code=C_SP;
                            28:hud_char_code=lch("2"); 29:hud_char_code=lch("!"); default:hud_char_code=C_SP;
                        endcase
                    end else if (boss_kind == 2'd1) begin
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("A"); 1:hud_char_code=lch("B"); 2:hud_char_code=lch("Y"); 3:hud_char_code=lch("S");
                            4:hud_char_code=lch("S"); 5:hud_char_code=C_SP; 6:hud_char_code=lch("C"); 7:hud_char_code=lch("A");
                            8:hud_char_code=lch("L"); 9:hud_char_code=lch("L"); 10:hud_char_code=lch("S"); 11:hud_char_code=C_SP;
                            12:hud_char_code=lch("I"); 13:hud_char_code=C_SP; 14:hud_char_code=lch("A"); 15:hud_char_code=lch("M");
                            16:hud_char_code=C_SP; 17:hud_char_code=lch("I"); 18:hud_char_code=lch("N"); 19:hud_char_code=lch("E");
                            20:hud_char_code=lch("V"); 21:hud_char_code=lch("I"); 22:hud_char_code=lch("T"); 23:hud_char_code=lch("A");
                            24:hud_char_code=lch("B"); 25:hud_char_code=lch("L"); 26:hud_char_code=lch("E"); 27:hud_char_code=lch("!");
                            default:hud_char_code=C_SP;
                        endcase
                    end else begin
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("Y"); 2:hud_char_code=C_SP; 3:hud_char_code=lch("I");
                            4:hud_char_code=lch("N"); 5:hud_char_code=lch("F"); 6:hud_char_code=lch("I"); 7:hud_char_code=lch("N");
                            8:hud_char_code=lch("I"); 9:hud_char_code=lch("T"); 10:hud_char_code=lch("Y"); 11:hud_char_code=C_SP;
                            12:hud_char_code=lch("S"); 13:hud_char_code=lch("H"); 14:hud_char_code=lch("A"); 15:hud_char_code=lch("T");
                            16:hud_char_code=lch("T"); 17:hud_char_code=lch("E"); 18:hud_char_code=lch("R"); 19:hud_char_code=lch("S");
                            20:hud_char_code=lch("!"); default:hud_char_code=C_SP;
                        endcase
                    end
                end
            end

            // (In-game Pause Guide now uses unified in_guide_view terminal at top!)

            if (game_state == 3'd3 || game_state == 3'd4) begin
                if (gx >= 9'd56 && gx < 9'd264 && gy >= 9'd82 && gy < 9'd176) begin
                    hud_bg_en = 1; hud_bg_color = (gx==9'd56||gx==9'd263||gy==9'd82||gy==9'd175) ? 6'd58 : 6'd54;
                    if (gy >= 9'd90 && gy < 9'd106 && gx >= 9'd88 && gx < 9'd232) begin
                        hud_text_en = 1; hud_text_color = (game_state == 3'd3) ? 6'd58 : 6'd49;
                        hud_char_row = (gy - 9'd90) >> 1; hud_char_col = gx[3:1] - 3'd4;
                        case ((gx - 9'd88) >> 4)
                            0:hud_char_code=(game_state==3'd3)?lch("V"):lch("G"); 1:hud_char_code=(game_state==3'd3)?lch("I"):lch("A");
                            2:hud_char_code=(game_state==3'd3)?lch("C"):lch("M"); 3:hud_char_code=(game_state==3'd3)?lch("T"):lch("E");
                            4:hud_char_code=(game_state==3'd3)?lch("O"):C_SP;     5:hud_char_code=(game_state==3'd3)?lch("R"):lch("O");
                            6:hud_char_code=(game_state==3'd3)?lch("Y"):lch("V"); 7:hud_char_code=(game_state==3'd3)?lch("!"):lch("E");
                            8:hud_char_code=(game_state==3'd3)?C_SP    :lch("R"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd114 && gy < 9'd122 && col_1x >= 6'd14 && col_1x < 6'd25) begin
                        hud_text_en = 1; hud_text_color = 6'd17; hud_char_row = gy - 9'd114;
                        case (col_1x - 6'd14)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=lch("O"); 3:hud_char_code=lch("R"); 4:hud_char_code=lch("E"); 5:hud_char_code=C_COL;
                            6:hud_char_code={2'd0,score_bcd[15:12]}; 7:hud_char_code={2'd0,score_bcd[11:8]}; 8:hud_char_code={2'd0,score_bcd[7:4]}; 9:hud_char_code={2'd0,score_bcd[3:0]};
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd136 && gy < 9'd144 && col_1x >= 6'd18 && col_1x < 6'd23) begin
                        hud_text_en = 1; hud_text_color = 6'd59; hud_char_row = gy - 9'd136;
                        case (col_1x - 6'd18)
                            0:hud_char_code=lch("R"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("T"); 3:hud_char_code=lch("R"); 4:hud_char_code=lch("Y"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd155 && gy < 9'd163 && col_1x >= 6'd18 && col_1x < 6'd22) begin
                        hud_text_en = 1; hud_text_color = 6'd17; hud_char_row = gy - 9'd155;
                        case (col_1x - 6'd18)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("U"); default:hud_char_code=C_SP;
                        endcase
                    end
                end
            end
        end
    end

    wire [7:0] font_row_1;
    rom_1p #(.DW(8), .AW(9), .DEPTH(512), .FILE("font.mem")) u_font_rom (
        .clk(clk), .addr({hud_char_code, hud_char_row}), .q(font_row_1)
    );

    // =========================================================================
    // STAGE 1 REGISTERS & TILE GFX LOOKUP
    // =========================================================================
    reg hs_1=1, vs_1=1, vid_1=0;
    reg [3:0] wx_1=0, wy_1=0;
    reg [8:0] gx_1=0, gy_1=0;
    reg on_p_1=0, sel_p2_1=0, on_aura_1=0, on_ghost_1=0, on_b_1=0, on_mon_1=0, on_item_1=0, on_logo_1=0;
    reg on_joy_1=0, joy_x0_1=0, on_kb_1=0, kb_x0_1=0, on_ui_1=0, guide_line_1=0;
    reg on_pb_1=0, on_eb_1=0, on_dropfx_1=0, on_laser_1=0, on_tag_1=0, on_sonic_1=0;
    reg [5:0] aura_col_1=0, pb_col_1=0, eb_col_1=0, dropfx_col_1=0, laser_col_1=0, tag_col_1=0, guide_lcol_1=0;
    reg [11:0] sonic_col_1=0;
    reg hud_text_en_1=0, hud_bg_en_1=0;
    reg [2:0] hud_col_1=0;
    reg [5:0] hud_tcol_1=0, hud_bcol_1=0;

    reg in_room_1=0, in_room_2=0;
    reg cur_dead_1=0, cur_dead_2=0;
    reg wrong_boss_1=0, wrong_boss_2=0, in_caution_1=0, in_caution_2=0;
    reg p_head_en_1=0, on_hero_body_1=0, mon_head_en_1=0;
    reg in_outfit_1=0, in_outfit_2=0;
    reg [11:0] p_body_1=0, mon_body_1=0;
    wire in_room_0 = (wx >= 11'd64 && wx < 11'd576 && wy >= 10'd64 && wy < 10'd384);

    always @(posedge clk) begin
        hs_1 <= hs_0; vs_1 <= vs_0; vid_1 <= vid_0; in_room_1 <= in_room_0;
        cur_dead_1 <= cur_dead_0; wrong_boss_1 <= wrong_boss_active; in_caution_1 <= in_caution_banner;
        in_outfit_1 <= in_outfit_cut;
        p_head_en_1 <= p_head_en_0; on_hero_body_1 <= on_hero_body_0; p_body_1 <= p_body_0;
        mon_head_en_1 <= mon_head_en_0; mon_body_1 <= mon_body_0;
        wx_1 <= wx[3:0]; wy_1 <= wy[3:0]; gx_1 <= gx; gy_1 <= gy;
        on_p_1 <= on_player_box; sel_p2_1 <= sel_p2_0; on_aura_1 <= on_aura_0; aura_col_1 <= aura_col_0;
        on_ghost_1 <= on_ghost; on_b_1 <= on_boss_box; on_mon_1 <= on_mon_box; on_item_1 <= on_item_box; on_logo_1 <= in_logo_box;
        on_joy_1 <= in_joy_box; joy_x0_1 <= gx[0]; on_kb_1 <= in_kb_box; kb_x0_1 <= kb_lx[0]; on_ui_1 <= in_ui_box;
        guide_line_1 <= guide_line_en; guide_lcol_1 <= guide_line_col;
        on_tag_1 <= (on_p1_tag || on_p2_tag); tag_col_1 <= on_p1_tag ? 6'd58 : 6'd59;
        on_pb_1 <= on_pb_0; pb_col_1 <= pb_col_0;
        on_eb_1 <= on_eb_0; eb_col_1 <= eb_col_0;
        on_dropfx_1 <= on_dropfx_0; dropfx_col_1 <= dropfx_col_0;
        on_laser_1  <= on_laser_0;  laser_col_1  <= laser_col_0;
        on_sonic_1  <= on_sonic_0;  sonic_col_1  <= sonic_col_0;
        hud_text_en_1 <= hud_text_en; hud_col_1 <= hud_char_col; hud_tcol_1 <= hud_text_color;
        hud_bg_en_1   <= hud_bg_en;   hud_bcol_1 <= hud_bg_color;
    end

    wire [3:0] eff_tile = ((map_tile_a == 4'd11 && zone2_open) || (map_tile_a == 4'd13 && zone3_open)) ? 4'd7 : map_tile_a;
    wire [5:0] tile_pix_2;
    rom_1p #(.DW(6), .AW(12), .DEPTH(4096), .FILE("tiles.mem")) u_tile_rom (
        .clk(clk), .addr({eff_tile, wy_1, wx_1}), .q(tile_pix_2)
    );

    // =========================================================================
    // STAGE 2: PRIORITY COMPOSITOR
    // =========================================================================
    reg hs_2=1, vs_2=1, vid_2=0;
    reg [8:0] gx_2=0, gy_2=0;
    reg [11:0] p_pix_2=0, b_pix_2=0, mon_pix_2=0;
    reg [5:0]  item_pix_2=0, logo_pix_2=0;
    reg on_p_2=0, sel_p2_2=0, on_aura_2=0, on_ghost_2=0, on_b_2=0, on_mon_2=0, on_item_2=0, on_logo_2=0;
    reg on_joy_2=0, on_kb_2=0, on_ui_2=0, guide_line_2=0; reg [3:0] joy_nib_2=0, kb_nib_2=0; reg [11:0] ui_pix_2=0;
    reg on_pb_2=0, on_eb_2=0, on_dropfx_2=0, on_laser_2=0, on_tag_2=0, on_sonic_2=0;
    reg [5:0] aura_col_2=0, pb_col_2=0, eb_col_2=0, dropfx_col_2=0, laser_col_2=0, tag_col_2=0, guide_lcol_2=0;
    reg [11:0] sonic_col_2=0;
    reg hud_bit_2=0, hud_bg_en_2=0;
    reg [5:0] hud_tcol_2=0, hud_bcol_2=0;

    always @(posedge clk) begin
        hs_2 <= hs_1; vs_2 <= vs_1; vid_2 <= vid_1; gx_2 <= gx_1; gy_2 <= gy_1; in_room_2 <= in_room_1;
        cur_dead_2 <= cur_dead_1; wrong_boss_2 <= wrong_boss_1; in_caution_2 <= in_caution_1;
        in_outfit_2 <= in_outfit_1;
        p_pix_2 <= (p_head_en_1 && player_pix_1 != 12'd0) ? player_pix_1 : ((p_body_1 != 12'd0) ? p_body_1 : (on_hero_body_1 ? hero_body_pix_1 : 12'd0));
        b_pix_2 <= boss_pix_1;
        mon_pix_2 <= (mon_head_en_1 && mon_pix_1 != 12'd0) ? mon_pix_1 : mon_body_1;
        item_pix_2 <= item_pix_1; logo_pix_2 <= logo_pix_1;
        on_p_2 <= on_p_1; sel_p2_2 <= sel_p2_1; on_aura_2 <= on_aura_1; aura_col_2 <= aura_col_1;
        on_ghost_2 <= on_ghost_1; on_b_2 <= on_b_1; on_mon_2 <= on_mon_1; on_item_2 <= on_item_1; on_logo_2 <= on_logo_1;
        on_joy_2 <= on_joy_1; joy_nib_2 <= (joy_x0_1 == 1'b0) ? joy_rom_byte_1[7:4] : joy_rom_byte_1[3:0];
        on_kb_2  <= on_kb_1;  kb_nib_2  <= (kb_x0_1  == 1'b0) ? kb_rom_byte_1[7:4]  : kb_rom_byte_1[3:0];
        on_ui_2 <= on_ui_1; ui_pix_2 <= ui_pix_1;
        guide_line_2 <= guide_line_1; guide_lcol_2 <= guide_lcol_1;
        on_tag_2 <= on_tag_1; tag_col_2 <= tag_col_1;
        on_pb_2 <= on_pb_1; pb_col_2 <= pb_col_1;
        on_eb_2 <= on_eb_1; eb_col_2 <= eb_col_1;
        on_dropfx_2 <= on_dropfx_1; dropfx_col_2 <= dropfx_col_1;
        on_laser_2  <= on_laser_1;  laser_col_2  <= laser_col_1;
        on_sonic_2  <= on_sonic_1;  sonic_col_2  <= sonic_col_1;
        hud_bit_2   <= hud_text_en_1 && font_row_1[3'd7 - hud_col_1];
        hud_tcol_2  <= hud_tcol_1;
        hud_bg_en_2 <= hud_bg_en_1; hud_bcol_2 <= hud_bcol_1;
    end

    reg [5:0] final_idx_2;
    reg       use_direct_rgb_2;
    reg [11:0] direct_rgb_2;
    wire blink_cur = sel_p2_2 ? ((p2_invuln > 0) && p2_invuln[2]) : ((invuln_timer > 0) && invuln_timer[2]);
    wire title_grid = (gx_2[4:0] == 0 || gy_2[4:0] == 0);

    always @(*) begin
        use_direct_rgb_2 = 1'b0;
        direct_rgb_2     = 12'h000;
        final_idx_2      = 6'd0;
        if (hud_bit_2)            final_idx_2 = hud_tcol_2;
        else if (in_outfit_2 && on_p_2 && p_pix_2 != 12'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = p_pix_2;
        end
        else if (in_caution_2)    final_idx_2 = ((gy_2 < 9'd114 || gy_2 >= 9'd152) ? ((gx_2[3] ^ gy_2[3]) ? 6'd58 : 6'd16) : 6'd58);
        else if (wrong_boss_2 && on_b_2 && b_pix_2 != 12'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = { (b_pix_2[11:8] > 4'hA ? 4'hF : (b_pix_2[11:8] + 4'h5)), b_pix_2[7:4] >> 1, b_pix_2[3:0] >> 1 };
        end
        else if (on_logo_2 && logo_pix_2 != 6'd0) final_idx_2 = logo_pix_2;
        else if (on_ui_2 && ui_pix_2 != 12'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = ui_pix_2;
        end
        else if (guide_line_2)    final_idx_2 = guide_lcol_2;
        else if (on_joy_2 && joy_nib_2 != 4'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = joy_palette(joy_nib_2);
        end
        else if (on_kb_2 && kb_nib_2 != 4'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = kb_palette(kb_nib_2);
        end
        else if (hud_bg_en_2)     final_idx_2 = hud_bcol_2;
        else if (on_tag_2)        final_idx_2 = tag_col_2;
        else if (on_pb_2)         final_idx_2 = pb_col_2;
        else if (on_eb_2)         final_idx_2 = eb_col_2;
        else if (on_p_2 && p_pix_2 != 12'd0 && (!blink_cur || cur_dead_2)) begin
            if (cur_dead_2) begin
                use_direct_rgb_2 = 1'b1;
                direct_rgb_2     = { p_pix_2[11:8] >> 1, p_pix_2[7:4] >> 2, p_pix_2[3:0] >> 2 };
            end else if (evolve_flash > 0 && evolve_flash[1]) final_idx_2 = 6'd17;
            else if (p_pix_2 == 12'h112 && skin_rim != 2'd0)
                final_idx_2 = (skin_rim == 2'd1) ? 6'd59 : ((skin_rim == 2'd2) ? 6'd58 : 6'd52);
            else begin
                use_direct_rgb_2 = 1'b1;
                direct_rgb_2     = p_pix_2;
            end
        end
        else if (on_aura_2)       final_idx_2 = aura_col_2;
        else if (on_ghost_2)      final_idx_2 = (skin_dash==2'd0)?6'd59:((skin_dash==2'd1)?6'd52:((skin_dash==2'd2)?6'd58:6'd60));
        else if (on_b_2 && b_pix_2 != 12'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = b_pix_2;
        end
        else if (on_item_2 && item_pix_2 != 6'd0) final_idx_2 = item_pix_2;
        else if (on_mon_2 && mon_pix_2 != 12'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = mon_pix_2;
        end
        else if (on_dropfx_2)     final_idx_2 = dropfx_col_2;
        else if (on_laser_2)      final_idx_2 = laser_col_2;
        else if (on_sonic_2)      begin use_direct_rgb_2 = 1'b1; direct_rgb_2 = sonic_col_2; end
        else if (game_state == 3'd0) final_idx_2 = title_grid ? 6'd56 : 6'd16;
        else if (!in_room_2)      begin use_direct_rgb_2 = 1'b1; direct_rgb_2 = 12'h000; end
        else                      final_idx_2 = tile_pix_2;
    end

    wire [1:0] env_theme = chrono_active ? 2'd2 : wave[1:0];

    wire [11:0] rgb_env_3, rgb_fg_3;
    rom_lut #(.DW(12), .AW(6), .DEPTH(64), .FILE("pal_env.mem")) u_pal_env (
        .clk(clk), .addr({env_theme, final_idx_2[3:0]}), .q(rgb_env_3)
    );
    rom_lut #(.DW(12), .AW(6), .DEPTH(64), .FILE("pal_fg.mem")) u_pal_fg (
        .clk(clk), .addr(final_idx_2), .q(rgb_fg_3)
    );

    reg hs_3=1, vs_3=1, vid_3=0, is_env_3=0, is_direct_3=0;
    reg [11:0] direct_rgb_3 = 12'h000;
    always @(posedge clk) begin
        hs_3 <= hs_2; vs_3 <= vs_2; vid_3 <= vid_2;
        is_env_3     <= (final_idx_2 >= 6'd1 && final_idx_2 <= 6'd15);
        is_direct_3  <= use_direct_rgb_2;
        direct_rgb_3 <= direct_rgb_2;
    end

    wire [11:0] final_rgb_3 = is_direct_3 ? direct_rgb_3 : (is_env_3 ? rgb_env_3 : rgb_fg_3);

    always @(posedge clk) begin
        {VGA_R, VGA_G, VGA_B} <= vid_3 ? final_rgb_3 : 12'h000;
        VGA_HS <= hs_3;
        VGA_VS <= vs_3;
    end
endmodule
