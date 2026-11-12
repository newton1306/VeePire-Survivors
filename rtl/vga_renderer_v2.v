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
    input  wire [2:0]  hp, hp2,
    input  wire [5:0]  exp,
    input  wire [1:0]  stage,
    input  wire [15:0] score_bcd,
    input  wire [6:0]  chrono_energy,
    input  wire        chrono_active,
    input  wire        mirror, walk_frame,
    input  wire [4:0]  dash_timer, evolve_flash,
    input  wire [5:0]  invuln_timer, p2_invuln,

    input  wire [6:0]  combo_cnt,
    input  wire [3:0]  shake_mag,
    input  wire        p1_nova, p2_nova,

    input  wire        pet_active, blades_active, aura_active,
    input  wire [10:0] blade0_x, blade1_x, pet_bx,
    input  wire [9:0]  blade0_y, blade1_y, pet_by,
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

    input  wire [8*11-1:0] eb_x_vec,
    input  wire [8*10-1:0] eb_y_vec,
    input  wire [7:0]      eb_active_vec,

    input  wire [10:0] boss_x,
    input  wire [9:0]  boss_y, laser_y,
    input  wire [6:0]  boss_hp,
    input  wire [1:0]  boss_kind,
    input  wire        boss_active, boss_locked, boss_enraged,
    input  wire [1:0]  laser_state,

    output reg  [3:0]  VGA_R = 0, VGA_G = 0, VGA_B = 0,
    output reg         VGA_HS = 1, VGA_VS = 1
);
    reg [25:0] anim_cnt = 0;
    always @(posedge clk) anim_cnt <= anim_cnt + 26'd1;

    // Live SW[15:0] 65,536 Non-Rainbow Skins
    wire [2:0] skin_model  = sw[2:0];
    wire [3:0] skin_chroma = sw[6:3];
    wire [2:0] skin_wpn    = sw[9:7];
    wire [1:0] skin_rim    = sw[11:10];
    wire [1:0] skin_p2mod  = sw[13:12];
    wire [1:0] skin_dash   = sw[15:14];

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
    wire signed [12:0] min_cx = boss_locked ? 13'sd1568 : 13'sd0;
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

    // 1. Arcade Title Logo ROM (160 x 48 centered at gx=80..239, gy=10..57)
    wire in_logo_box = (game_state == 3'd0) && (gx >= 9'd80 && gx < 9'd240 && gy >= 9'd10 && gy < 9'd58);
    wire [5:0] logo_ly = gy - 9'd10;
    wire [7:0] logo_lx = gx - 9'd80;
    wire [12:0] logo_addr = ({7'd0, logo_ly} << 7) + ({7'd0, logo_ly} << 5) + {5'd0, logo_lx}; // y*160 + x (no mul!)
    wire [5:0] logo_pix_1;
    rom_1p #(.DW(6), .AW(13), .DEPTH(8192), .FILE("title_logo.mem")) u_logo_rom (
        .clk(clk), .addr(logo_addr), .q(logo_pix_1)
    );

    // 2. Hero Sprites P1 & P2 (8 models x 4 frames incl Lunge/Apex x 32x32 = 32K)
    wire [10:0] target_px  = (game_state == 3'd0) ? (control_mode == 2'd2 ? 11'd80 : 11'd100) : px;
    wire [9:0]  target_py  = (game_state == 3'd0) ? 10'd160 : py;
    wire [10:0] target_p2x = (game_state == 3'd0) ? 11'd120 : p2x;
    wire [9:0]  target_p2y = (game_state == 3'd0) ? 10'd160 : p2y;
    wire [10:0] p_ref_x    = (game_state == 3'd0) ? {2'd0, gx} : wx;
    wire [9:0]  p_ref_y    = (game_state == 3'd0) ? {1'd0, gy} : wy;

    wire signed [11:0] psx  = $signed({1'b0, p_ref_x}) - $signed({1'b0, target_px})  + 12'sd16;
    wire signed [11:0] psy  = $signed({2'b00, p_ref_y}) - $signed({2'b00, target_py})  + 12'sd16;
    wire signed [11:0] p2sx = $signed({1'b0, p_ref_x}) - $signed({1'b0, target_p2x}) + 12'sd16;
    wire signed [11:0] p2sy = $signed({2'b00, p_ref_y}) - $signed({2'b00, target_p2y}) + 12'sd16;

    wire on_p1_box = (psx >= 0 && psx < 32 && psy >= 0 && psy < 32) && ((game_state == 3'd0) || (in_playfield && !(hp == 0 && anim_cnt[21])));
    wire show_p2   = (game_state == 3'd0 && control_mode == 2'd2) || (p2_active && in_playfield && !(hp2 == 0 && anim_cnt[21]));
    wire on_p2_box = show_p2 && (p2sx >= 0 && p2sx < 32 && p2sy >= 0 && p2sy < 32);
    wire on_player_box = on_p1_box || on_p2_box;
    wire sel_p2_0      = !on_p1_box && on_p2_box;

    reg on_aura_0;
    reg [5:0] aura_col_0;
    wire [10:0] rad_sq  = (psx[5:0] - 6'sd16)*(psx[5:0] - 6'sd16) + (psy[5:0] - 6'sd16)*(psy[5:0] - 6'sd16);
    wire [10:0] rad2_sq = (p2sx[5:0] - 6'sd16)*(p2sx[5:0] - 6'sd16) + (p2sy[5:0] - 6'sd16)*(p2sy[5:0] - 6'sd16);
    always @(*) begin
        on_aura_0 = 1'b0; aura_col_0 = 6'd58;
        if (aura_active && (game_state == 3'd2 || (game_state == 3'd1 && cut_id == 2'd3)) && in_playfield) begin
            if ((on_p1_box && hp > 0 && rad_sq >= 11'd210 && rad_sq <= 11'd250) ||
                (on_p2_box && hp2 > 0 && rad2_sq >= 11'd210 && rad2_sq <= 11'd250)) begin
                if ((psx[0]^psy[0]) ^ anim_cnt[22]) begin on_aura_0 = 1'b1; aura_col_0 = anim_cnt[22] ? 6'd58 : 6'd59; end
            end
        end
    end

    wire on_ghost = (game_state == 3'd2 && in_playfield) && (
                    (dash_timer > 0 && hp > 0 && ($signed({1'b0, wx}) >= $signed({1'b0, dash_gx})-12'sd10) && ($signed({1'b0, wx}) < $signed({1'b0, dash_gx})+12'sd10) && ($signed({2'b00, wy}) >= $signed({2'b00, dash_gy})-12'sd10) && ($signed({2'b00, wy}) < $signed({2'b00, dash_gy})+12'sd10) && (wx[0]^wy[0])) ||
                    (p2_active && hp2 > 0 && p2_dash_timer > 0 && ($signed({1'b0, wx}) >= $signed({1'b0, p2_dash_gx})-12'sd10) && ($signed({1'b0, wx}) < $signed({1'b0, p2_dash_gx})+12'sd10) && ($signed({2'b00, wy}) >= $signed({2'b00, p2_dash_gy})-12'sd10) && ($signed({2'b00, wy}) < $signed({2'b00, p2_dash_gy})+12'sd10) && (wx[0]^wy[0])));

    wire on_p1_tag = (game_state == 3'd2 && in_playfield) && p2_active && ((psy == -12'sd2 && psx >= 12'sd14 && psx <= 12'sd18) || (psy == -12'sd1 && psx >= 12'sd15 && psx <= 12'sd17));
    wire on_p2_tag = (game_state == 3'd2 && in_playfield) && p2_active && ((p2sy == -12'sd2 && p2sx >= 12'sd14 && p2sx <= 12'sd18) || (p2sy == -12'sd1 && p2sx >= 12'sd15 && p2sx <= 12'sd17));

    reg [2:0] p_form_idx;
    reg [2:0] p1_sw_model;
    always @(*) begin
        case (skin_model)
            3'd1: p1_sw_model = 3'd0; // SW0: Goose
            3'd2: p1_sw_model = 3'd1; // SW1: PF
            3'd3: p1_sw_model = 3'd2; // SW0+SW1: PPuen
            3'd4: p1_sw_model = 3'd3; // SW2: PPeem
            3'd5: p1_sw_model = 3'd4; // SW0+SW2: PPing
            3'd6: p1_sw_model = 3'd5; // SW1+SW2: NexysA7
            default: p1_sw_model = 3'd5;
        endcase
        if (sel_p2_0 && skin_p2mod != 2'd0) begin
            case (skin_p2mod) 2'd1: p_form_idx = 3'd4; 2'd2: p_form_idx = 3'd0; default: p_form_idx = (skin_model != 3'd0) ? p1_sw_model : 3'd1; endcase
        end else if (skin_model != 3'd0) p_form_idx = sel_p2_0 ? ((p1_sw_model == 3'd5) ? 3'd2 : 3'd5) : p1_sw_model;
        else if (game_state == 3'd0) p_form_idx = sel_p2_0 ? 3'd5 : 3'd0;
        else case (stage) 2'd0: p_form_idx = sel_p2_0 ? 3'd3 : 3'd0; 2'd1: p_form_idx = sel_p2_0 ? 3'd3 : 3'd1; 2'd2: p_form_idx = sel_p2_0 ? 3'd4 : 3'd2; 2'd3: p_form_idx = sel_p2_0 ? 3'd3 : 3'd5; endcase
    end
    wire [1:0] p_pose = (game_state == 3'd0) ? {1'b0, anim_cnt[23]} :
                        (sel_p2_0 ? ((p2_slash_t > 0) ? 2'd2 : (aura_active ? 2'd3 : {1'b0, p2_walk_frame})) :
                                    ((p1_slash_t > 0) ? 2'd2 : (aura_active ? 2'd3 : {1'b0, walk_frame})));
    wire [4:0] p_rawx = sel_p2_0 ? p2sx[4:0] : psx[4:0];
    wire [4:0] p_rawy = sel_p2_0 ? p2sy[4:0] : psy[4:0];
    wire       p_mir  = sel_p2_0 ? p2_mirror : mirror;
    wire [4:0] p_col  = (p_mir && game_state != 3'd0) ? (5'd31 - p_rawx) : p_rawx;
    wire [11:0] player_pix_1;
    rom_1p #(.DW(12), .AW(15), .DEPTH(32768), .FILE("player_sprites.mem")) u_player_rom (
        .clk(clk), .addr({p_form_idx, p_pose, p_rawy, p_col}), .q(player_pix_1)
    );

    // 3. 3 Unique 64x64 Bosses (Ajarn_V_1, Ajarn_V_2, Ajarn_V Thanos -> 32K x 12-bit RGB444!)
    wire show_boss_cut = (game_state == 3'd1 && cut_id == 2'd2);
    wire [10:0] target_bx = (game_state == 3'd0) ? 11'd220 : (show_boss_cut ? 11'd255 : boss_x);
    wire [9:0]  target_by = (game_state == 3'd0) ? 10'd156 : (show_boss_cut ? 10'd120 : boss_y);
    wire [10:0] b_ref_x   = (game_state == 3'd0 || show_boss_cut) ? {2'd0, gx} : wx;
    wire [9:0]  b_ref_y   = (game_state == 3'd0 || show_boss_cut) ? {1'd0, gy} : wy;
    wire signed [11:0] bsx = $signed({1'b0, b_ref_x}) - $signed({1'b0, target_bx}) + 12'sd32;
    wire signed [11:0] bsy = $signed({2'b00, b_ref_y}) - $signed({2'b00, target_by}) + 12'sd32;
    wire on_boss_box = (bsx >= 0 && bsx < 64 && bsy >= 0 && bsy < 64) &&
                       ((game_state == 3'd0) || show_boss_cut || (in_playfield && boss_active && boss_hp > 0));
    wire [1:0] eff_bkind = (game_state == 3'd0) ? 2'd2 : boss_kind;
    wire b_frame = (game_state == 3'd0 || show_boss_cut) ? anim_cnt[24] : boss_enraged;
    wire [11:0] boss_pix_1;
    rom_1p #(.DW(12), .AW(15), .DEPTH(32768), .FILE("boss_sprites.mem")) u_boss_rom (
        .clk(clk), .addr({eff_bkind, b_frame, bsy[5:0], bsx[5:0]}), .q(boss_pix_1)
    );

    // 4. 16 HUGE 32x32 MONSTERS (8 Archetypes x 2 Frames -> 16K!)
    reg        on_mon_box;
    reg [2:0]  mon_kind_0;
    reg [4:0]  mon_lx, mon_ly;
    integer k_mon;
    reg signed [11:0] ox_m, oy_m;
    always @(*) begin
        on_mon_box = 1'b0; mon_kind_0 = 3'd0; mon_lx = 5'd0; mon_ly = 5'd0;
        ox_m = 12'sd0; oy_m = 12'sd0;
        if (in_playfield) begin
            for (k_mon = 15; k_mon >= 0; k_mon = k_mon - 1) begin
                if (en_alive_vec[k_mon]) begin
                    ox_m = $signed({1'b0, wx})  - $signed({1'b0, en_x_vec[k_mon*11 +: 11]}) + 12'sd16;
                    oy_m = $signed({2'b00, wy}) - $signed({2'b00, en_y_vec[k_mon*10 +: 10]}) + 12'sd16;
                    if (ox_m >= 0 && ox_m < 32 && oy_m >= 0 && oy_m < 32) begin
                        on_mon_box = 1'b1; mon_kind_0 = en_type_vec[k_mon*3 +: 3]; mon_lx = ox_m[4:0]; mon_ly = oy_m[4:0];
                    end
                end
            end
        end
    end
    wire [5:0] mon_pix_1;
    rom_1p #(.DW(6), .AW(14), .DEPTH(16384), .FILE("enemy_sprites.mem")) u_monster_rom (
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
                ox_i = $signed({1'b0, wx}) - $signed({1'b0, blade0_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, blade0_y}) + 12'sd8;
                if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
                ox_i = $signed({1'b0, wx}) - $signed({1'b0, blade1_x}) + 12'sd8; oy_i = $signed({2'b00, wy}) - $signed({2'b00, blade1_y}) + 12'sd8;
                if (ox_i >= 0 && ox_i < 16 && oy_i >= 0 && oy_i < 16) begin on_item_box=1; item_fid=4'd10; item_lx=ox_i[3:0]; item_ly=oy_i[3:0]; end
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
    reg signed [11:0] bx_d, by_d, ax_d, ay_d, oct_d, dot_d;
    reg [5:0] wpn_skin_col;
    reg [3:0] e_hp_k;
    reg [4:0] hp_bar_w;
    integer k_fx;

    always @(*) begin
        on_pb_0 = 0; pb_col_0 = 0; on_eb_0 = 0; eb_col_0 = 0;
        on_dropfx_0 = 0; dropfx_col_0 = 0; on_laser_0 = 0; laser_col_0 = 0;
        bx_d = 0; by_d = 0; ax_d = 0; ay_d = 0; oct_d = 0; dot_d = 0; e_hp_k = 0; hp_bar_w = 0;

        case (skin_wpn)
            3'd0: wpn_skin_col = 6'd59; 3'd1: wpn_skin_col = 6'd52; 3'd2: wpn_skin_col = 6'd58; 3'd3: wpn_skin_col = 6'd45;
            3'd4: wpn_skin_col = 6'd60; 3'd5: wpn_skin_col = 6'd61; 3'd6: wpn_skin_col = 6'd62; 3'd7: wpn_skin_col = 6'd36;
        endcase

        if (in_playfield) begin
            // 12 Hit Particle Sparks!
            for (k_fx = 0; k_fx < 12; k_fx = k_fx + 1) begin
                if (sp_alive_vec[k_fx]) begin
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

            // P1 Clear 12-px Crescent Slash + Sword Beam OR 360 Double-Ring Nova!
            if (p1_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, p1_nova ? px : p1_slash_x});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, p1_nova ? py : p1_slash_y});
                if (bx_d >= -12'sd52 && bx_d <= 12'sd52 && by_d >= -12'sd52 && by_d <= 12'sd52) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p1_slash_dx == 0) ? 12'sd0 : ((p1_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p1_slash_dy == 0) ? 12'sd0 : ((p1_slash_dy > 0) ? by_d : -by_d));
                    if ((p1_nova || dot_d >= -12'sd6) &&
                        oct_d <= (12'sd42 - $signed({7'd0, p1_slash_t, 1'b0})) + $signed({8'd0, stage, 2'b00}) + (p1_nova ? 12'sd8 : 12'sd0) &&
                        oct_d >= (12'sd28 - $signed({7'd0, p1_slash_t, 1'b0})) + $signed({9'd0, stage, 1'b0})) begin
                        on_pb_0  = 1;
                        pb_col_0 = (oct_d >= (12'sd38 - $signed({7'd0, p1_slash_t, 1'b0})) + $signed({8'd0, stage, 2'b00}) + (p1_nova ? 12'sd8 : 12'sd0))
                                   ? 6'd17 : (p1_nova ? 6'd58 : wpn_skin_col);
                    end else if (p1_nova && oct_d >= 12'sd12 && oct_d <= 12'sd18) begin
                        on_pb_0 = 1; pb_col_0 = 6'd17;
                    end
                end
            end

            if (p2_active && p2_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, p2_nova ? p2x : p2_slash_x});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, p2_nova ? p2y : p2_slash_y});
                if (bx_d >= -12'sd52 && bx_d <= 12'sd52 && by_d >= -12'sd52 && by_d <= 12'sd52) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p2_slash_dx == 0) ? 12'sd0 : ((p2_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p2_slash_dy == 0) ? 12'sd0 : ((p2_slash_dy > 0) ? by_d : -by_d));
                    if ((p2_nova || dot_d >= -12'sd6) &&
                        oct_d <= (12'sd42 - $signed({7'd0, p2_slash_t, 1'b0})) + $signed({8'd0, stage, 2'b00}) + (p2_nova ? 12'sd8 : 12'sd0) &&
                        oct_d >= (12'sd28 - $signed({7'd0, p2_slash_t, 1'b0})) + $signed({9'd0, stage, 1'b0})) begin
                        on_pb_0  = 1;
                        pb_col_0 = (oct_d >= (12'sd38 - $signed({7'd0, p2_slash_t, 1'b0})) + $signed({8'd0, stage, 2'b00}) + (p2_nova ? 12'sd8 : 12'sd0))
                                   ? 6'd17 : (p2_nova ? 6'd58 : 6'd60);
                    end else if (p2_nova && oct_d >= 12'sd12 && oct_d <= 12'sd18) begin
                        on_pb_0 = 1; pb_col_0 = 6'd17;
                    end
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

            if (boss_active && boss_hp > 0 && wx >= 11'd600 && wx <= boss_x) begin
                if (laser_state == 2'd1 && (wy == laser_y || wy == laser_y - 10'd1) && (wx[2] ^ anim_cnt[22])) begin
                    on_laser_0 = 1; laser_col_0 = anim_cnt[21] ? 6'd51 : 6'd52;
                end else if (laser_state == 2'd2 && wy >= laser_y - 10'd6 && wy <= laser_y + 10'd6) begin
                    on_laser_0 = 1; laser_col_0 = (wy >= laser_y - 10'd2 && wy <= laser_y + 10'd2) ? 6'd53 : 6'd52;
                end
            end
        end
    end

    // ---- STAGE 0: HUD, TITLE SCREEN WITH ARCADE LOGO, < MODE > ARROWS, COMBO RANK ----
    localparam [5:0] C_SP=36, C_COL=37, C_DSH=38, C_EX=39, C_HRT=40, C_SL=41, C_LARW=42, C_RARW=43, C_PLUS=44, C_MUL=45;
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
    wire [8:0] boss_bar_raw = (boss_kind == 2'd2) ? ({1'b0, boss_hp, 1'b0} + {3'd0, boss_hp[6:1]}) : ({1'b0, boss_hp, 1'b0} << 1);
    wire [8:0] boss_bar_w = (boss_bar_raw > 9'd240) ? 9'd240 : boss_bar_raw;

    reg [5:0] hud_char_code, hud_text_color, hud_bg_color;
    reg [2:0] hud_char_row, hud_char_col;
    reg       hud_text_en, hud_bg_en;
    wire [5:0] col_1x = gx[8:3];

    always @(*) begin
        hud_char_code = C_SP; hud_char_row = gy[2:0]; hud_char_col = gx[2:0];
        hud_text_color = 6'd17; hud_text_en = 0; hud_bg_en = 0; hud_bg_color = 6'd54;

        if (game_state == 3'd0) begin
            if (gy >= 9'd62 && gy < 9'd70 && col_1x >= 6'd8 && col_1x < 6'd32) begin
                hud_text_en = 1; hud_text_color = 6'd59; hud_char_row = gy - 9'd62;
                case (col_1x - 6'd8)
                    0:hud_char_code=lch("J"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("Y"); 3:hud_char_code=lch("1");
                    4:hud_char_code=lch("/"); 5:hud_char_code=lch("2"); 6:hud_char_code=C_SP;     7:hud_char_code=lch("O");
                    8:hud_char_code=lch("R"); 9:hud_char_code=C_SP;     10:hud_char_code=lch("B"); 11:hud_char_code=lch("T");
                    12:hud_char_code=lch("N"); 13:hud_char_code=lch("L"); 14:hud_char_code=lch("/"); 15:hud_char_code=lch("R");
                    16:hud_char_code=lch(":"); 17:hud_char_code=lch("S"); 18:hud_char_code=lch("E"); 19:hud_char_code=lch("L");
                    20:hud_char_code=lch("E"); 21:hud_char_code=lch("C"); 22:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                endcase
            end else if (gy >= 9'd76 && gy <= 9'd92 && gx >= 9'd48 && gx < 9'd272) begin
                hud_bg_en = 1; hud_bg_color = (gy==9'd76||gy==9'd92||gx==9'd48||gx==9'd271) ? 6'd58 : 6'd54;
                if (gy >= 9'd80 && gy < 9'd88 && col_1x >= 6'd7 && col_1x <= 6'd32) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd80;
                    if (col_1x == 6'd7)      begin hud_char_code = C_LARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                    else if (col_1x == 6'd32)begin hud_char_code = C_RARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                    else begin
                        hud_text_color = (control_mode == 2'd0) ? 6'd58 : ((control_mode == 2'd1) ? 6'd59 : 6'd60);
                        case (col_1x - 6'd9)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("D"); 3:hud_char_code=lch("E");
                            4:hud_char_code=lch(":"); 5:hud_char_code=C_SP;     6:hud_char_code=(control_mode==2'd2)?lch("2"):lch("1");
                            7:hud_char_code=lch("P"); 8:hud_char_code=C_SP;
                            9:hud_char_code=(control_mode==2'd0)?lch("T"):((control_mode==2'd1)?lch("J"):lch("C"));
                            10:hud_char_code=(control_mode==2'd0)?lch("I"):((control_mode==2'd1)?lch("O"):lch("O"));
                            11:hud_char_code=(control_mode==2'd0)?lch("L"):((control_mode==2'd1)?lch("Y"):lch("-"));
                            12:hud_char_code=(control_mode==2'd0)?lch("T"):((control_mode==2'd1)?lch("S"):lch("O"));
                            13:hud_char_code=(control_mode==2'd0)?C_SP    :((control_mode==2'd1)?lch("T"):lch("P"));
                            14:hud_char_code=(control_mode==2'd0)?C_SP    :((control_mode==2'd1)?lch("I"):C_SP);
                            15:hud_char_code=(control_mode==2'd0)?C_SP    :((control_mode==2'd1)?lch("C"):lch("J"));
                            16:hud_char_code=(control_mode==2'd0)?C_SP    :((control_mode==2'd1)?lch("K"):lch("O"));
                            17:hud_char_code=(control_mode==2'd2)?lch("Y"):C_SP; default:hud_char_code=C_SP;
                        endcase
                    end
                end
            end else if (gy >= 9'd96 && gy < 9'd104 && col_1x >= 6'd10 && col_1x < 6'd30) begin
                hud_text_en = 1; hud_text_color = joy_link_ok ? 6'd28 : 6'd57; hud_char_row = gy - 9'd96;
                case (col_1x - 6'd10)
                    0:hud_char_code=lch("U"); 1:hud_char_code=lch("S"); 2:hud_char_code=lch("B"); 3:hud_char_code=C_SP;
                    4:hud_char_code=lch("J"); 5:hud_char_code=lch("O"); 6:hud_char_code=lch("Y"); 7:hud_char_code=lch(":"); 8:hud_char_code=C_SP;
                    9:hud_char_code=lch("O"); 10:hud_char_code=joy_link_ok?lch("N"):lch("F"); 11:hud_char_code=joy_link_ok?lch("L"):lch("F");
                    12:hud_char_code=joy_link_ok?lch("I"):lch("L"); 13:hud_char_code=joy_link_ok?lch("N"):lch("I");
                    14:hud_char_code=joy_link_ok?lch("E"):lch("N"); 15:hud_char_code=joy_link_ok?lch("!"):lch("E"); default:hud_char_code=C_SP;
                endcase
            end else if (gy >= 9'd202 && gy < 9'd210 && col_1x >= 6'd8 && col_1x < 6'd32) begin
                hud_text_en = anim_cnt[24]; hud_text_color = 6'd17; hud_char_row = gy - 9'd202;
                case (col_1x - 6'd8)
                    0:hud_char_code=lch("P"); 1:hud_char_code=lch("R"); 2:hud_char_code=lch("E"); 3:hud_char_code=lch("S"); 4:hud_char_code=lch("S");
                    5:hud_char_code=C_SP;     6:hud_char_code=lch("J"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("Y"); 9:hud_char_code=lch("1");
                    10:hud_char_code=lch("/"); 11:hud_char_code=lch("2"); 12:hud_char_code=C_SP; 13:hud_char_code=lch("O"); 14:hud_char_code=lch("R");
                    15:hud_char_code=C_SP;     16:hud_char_code=lch("B"); 17:hud_char_code=lch("T"); 18:hud_char_code=lch("N"); 19:hud_char_code=lch("C");
                    default:hud_char_code=C_SP;
                endcase
            end else if (gy >= 9'd218 && gy < 9'd226 && col_1x >= 6'd9 && col_1x < 6'd31) begin
                hud_text_en = 1; hud_text_color = 6'd60; hud_char_row = gy - 9'd218;
                case (col_1x - 6'd9)
                    0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("1"); 3:hud_char_code=lch("5");
                    4:hud_char_code=lch("-"); 5:hud_char_code=lch("S"); 6:hud_char_code=lch("W"); 7:hud_char_code=lch("0");
                    8:hud_char_code=lch(":"); 9:hud_char_code=lch("6"); 10:hud_char_code=lch("5"); 11:hud_char_code=lch("K");
                    12:hud_char_code=C_SP;    13:hud_char_code=lch("S"); 14:hud_char_code=lch("K"); 15:hud_char_code=lch("I");
                    16:hud_char_code=lch("N"); 17:hud_char_code=lch("S"); default:hud_char_code=C_SP;
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
                    if (col_1x == 6'd0) begin hud_text_en = p2_active; hud_char_code = lch("1"); hud_text_color = 6'd58; end
                    else if (col_1x >= 6'd1 && col_1x <= 6'd6) begin hud_text_en = 1; hud_char_code = C_HRT; hud_text_color = (col_1x <= {3'd0, hp}) ? 6'd49 : 6'd42; end
                    else if (p2_active && col_1x == 6'd8) begin hud_text_en = 1; hud_char_code = lch("2"); hud_text_color = 6'd59; end
                    else if (p2_active && col_1x >= 6'd9 && col_1x <= 6'd14) begin hud_text_en = 1; hud_char_code = C_HRT; hud_text_color = ((col_1x - 6'd8) <= {3'd0, hp2}) ? 6'd59 : 6'd42; end
                    else if (col_1x >= 6'd16 && col_1x <= 6'd18) begin
                        hud_text_en = 1; hud_text_color = 6'd59;
                        if (col_1x == 6'd16) hud_char_code = lch("W");
                        else if (wave == 4'd10) hud_char_code = (col_1x == 6'd17) ? lch("1") : lch("0");
                        else hud_char_code = (col_1x == 6'd17) ? {2'd0, wave} : C_SP;
                    end else if (col_1x >= 6'd20 && col_1x <= 6'd26) begin
                        hud_text_en = 1; hud_text_color = 6'd17;
                        case (col_1x - 6'd20)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=C_COL;
                            3:hud_char_code={2'd0,score_bcd[15:12]}; 4:hud_char_code={2'd0,score_bcd[11:8]};
                            5:hud_char_code={2'd0,score_bcd[7:4]};   6:hud_char_code={2'd0,score_bcd[3:0]};
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

            if (game_state == 3'd3 || game_state == 3'd4) begin
                if (gx >= 9'd56 && gx < 9'd264 && gy >= 9'd88 && gy < 9'd172) begin
                    hud_bg_en = 1; hud_bg_color = (gx==9'd56||gx==9'd263||gy==9'd88||gy==9'd171) ? 6'd58 : 6'd54;
                    if (gy >= 9'd98 && gy < 9'd114 && gx >= 9'd88 && gx < 9'd232) begin
                        hud_text_en = 1; hud_text_color = (game_state == 3'd3) ? 6'd58 : 6'd49;
                        hud_char_row = (gy - 9'd98) >> 1; hud_char_col = gx[3:1] - 3'd4;
                        case ((gx - 9'd88) >> 4)
                            0:hud_char_code=(game_state==3'd3)?lch("V"):lch("G"); 1:hud_char_code=(game_state==3'd3)?lch("I"):lch("A");
                            2:hud_char_code=(game_state==3'd3)?lch("C"):lch("M"); 3:hud_char_code=(game_state==3'd3)?lch("T"):lch("E");
                            4:hud_char_code=(game_state==3'd3)?lch("O"):C_SP;     5:hud_char_code=(game_state==3'd3)?lch("R"):lch("O");
                            6:hud_char_code=(game_state==3'd3)?lch("Y"):lch("V"); 7:hud_char_code=(game_state==3'd3)?lch("!"):lch("E");
                            8:hud_char_code=(game_state==3'd3)?C_SP    :lch("R"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd124 && gy < 9'd132 && col_1x >= 6'd14 && col_1x < 6'd25) begin
                        hud_text_en = 1; hud_text_color = 6'd17; hud_char_row = gy - 9'd124;
                        case (col_1x - 6'd14)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=lch("O"); 3:hud_char_code=lch("R"); 4:hud_char_code=lch("E"); 5:hud_char_code=C_COL;
                            6:hud_char_code={2'd0,score_bcd[15:12]}; 7:hud_char_code={2'd0,score_bcd[11:8]}; 8:hud_char_code={2'd0,score_bcd[7:4]}; 9:hud_char_code={2'd0,score_bcd[3:0]};
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd142 && gy < 9'd150 && col_1x >= 6'd9 && col_1x < 6'd31) begin
                        hud_text_en = 1; hud_text_color = 6'd59; hud_char_row = gy - 9'd142;
                        case (col_1x - 6'd9)
                            0:hud_char_code=lch("J"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("Y"); 3:hud_char_code=lch("1"); 4:hud_char_code=lch("/"); 5:hud_char_code=lch("2");
                            6:hud_char_code=C_SP;     7:hud_char_code=lch("F"); 8:hud_char_code=lch("I"); 9:hud_char_code=lch("R"); 10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;
                            12:hud_char_code=lch("R"); 13:hud_char_code=lch("E"); 14:hud_char_code=lch("T"); 15:hud_char_code=lch("R"); 16:hud_char_code=lch("Y"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd156 && gy < 9'd164 && col_1x >= 6'd10 && col_1x < 6'd30) begin
                        hud_text_en = 1; hud_text_color = 6'd58; hud_char_row = gy - 9'd156;
                        case (col_1x - 6'd10)
                            0:hud_char_code=C_LARW; 1:hud_char_code=C_RARW; 2:hud_char_code=C_SP; 3:hud_char_code=lch("T"); 4:hud_char_code=lch("O"); 5:hud_char_code=C_SP;
                            6:hud_char_code=lch("M"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("D"); 9:hud_char_code=lch("E"); 10:hud_char_code=C_SP;
                            11:hud_char_code=lch("M"); 12:hud_char_code=lch("E"); 13:hud_char_code=lch("N"); 14:hud_char_code=lch("U"); default:hud_char_code=C_SP;
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
    reg on_pb_1=0, on_eb_1=0, on_dropfx_1=0, on_laser_1=0, on_tag_1=0;
    reg [5:0] aura_col_1=0, pb_col_1=0, eb_col_1=0, dropfx_col_1=0, laser_col_1=0, tag_col_1=0;
    reg hud_text_en_1=0, hud_bg_en_1=0;
    reg [2:0] hud_col_1=0;
    reg [5:0] hud_tcol_1=0, hud_bcol_1=0;

    always @(posedge clk) begin
        hs_1 <= hs_0; vs_1 <= vs_0; vid_1 <= vid_0;
        wx_1 <= wx[3:0]; wy_1 <= wy[3:0]; gx_1 <= gx; gy_1 <= gy;
        on_p_1 <= on_player_box; sel_p2_1 <= sel_p2_0; on_aura_1 <= on_aura_0; aura_col_1 <= aura_col_0;
        on_ghost_1 <= on_ghost; on_b_1 <= on_boss_box; on_mon_1 <= on_mon_box; on_item_1 <= on_item_box; on_logo_1 <= in_logo_box;
        on_tag_1 <= (on_p1_tag || on_p2_tag); tag_col_1 <= on_p1_tag ? 6'd58 : 6'd59;
        on_pb_1 <= on_pb_0; pb_col_1 <= pb_col_0;
        on_eb_1 <= on_eb_0; eb_col_1 <= eb_col_0;
        on_dropfx_1 <= on_dropfx_0; dropfx_col_1 <= dropfx_col_0;
        on_laser_1  <= on_laser_0;  laser_col_1  <= laser_col_0;
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
    reg [11:0] p_pix_2=0, b_pix_2=0;
    reg [5:0]  mon_pix_2=0, item_pix_2=0, logo_pix_2=0;
    reg on_p_2=0, sel_p2_2=0, on_aura_2=0, on_ghost_2=0, on_b_2=0, on_mon_2=0, on_item_2=0, on_logo_2=0;
    reg on_pb_2=0, on_eb_2=0, on_dropfx_2=0, on_laser_2=0, on_tag_2=0;
    reg [5:0] aura_col_2=0, pb_col_2=0, eb_col_2=0, dropfx_col_2=0, laser_col_2=0, tag_col_2=0;
    reg hud_bit_2=0, hud_bg_en_2=0;
    reg [5:0] hud_tcol_2=0, hud_bcol_2=0;

    always @(posedge clk) begin
        hs_2 <= hs_1; vs_2 <= vs_1; vid_2 <= vid_1; gx_2 <= gx_1; gy_2 <= gy_1;
        p_pix_2 <= player_pix_1; b_pix_2 <= boss_pix_1; mon_pix_2 <= mon_pix_1; item_pix_2 <= item_pix_1; logo_pix_2 <= logo_pix_1;
        on_p_2 <= on_p_1; sel_p2_2 <= sel_p2_1; on_aura_2 <= on_aura_1; aura_col_2 <= aura_col_1;
        on_ghost_2 <= on_ghost_1; on_b_2 <= on_b_1; on_mon_2 <= on_mon_1; on_item_2 <= on_item_1; on_logo_2 <= on_logo_1;
        on_tag_2 <= on_tag_1; tag_col_2 <= tag_col_1;
        on_pb_2 <= on_pb_1; pb_col_2 <= pb_col_1;
        on_eb_2 <= on_eb_1; eb_col_2 <= eb_col_1;
        on_dropfx_2 <= on_dropfx_1; dropfx_col_2 <= dropfx_col_1;
        on_laser_2  <= on_laser_1;  laser_col_2  <= laser_col_1;
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
        else if (hud_bg_en_2)     final_idx_2 = hud_bcol_2;
        else if (on_logo_2 && logo_pix_2 != 6'd0) final_idx_2 = logo_pix_2;
        else if (on_tag_2)        final_idx_2 = tag_col_2;
        else if (on_pb_2)         final_idx_2 = pb_col_2;
        else if (on_eb_2)         final_idx_2 = eb_col_2;
        else if (on_p_2 && p_pix_2 != 12'd0 && !blink_cur) begin
            if (evolve_flash > 0 && evolve_flash[1]) final_idx_2 = 6'd17;
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
        else if (on_mon_2 && mon_pix_2 != 6'd0)   final_idx_2 = mon_pix_2;
        else if (on_dropfx_2)     final_idx_2 = dropfx_col_2;
        else if (on_laser_2)      final_idx_2 = laser_col_2;
        else if (game_state == 3'd0) final_idx_2 = title_grid ? 6'd56 : 6'd16;
        else                      final_idx_2 = tile_pix_2;
    end

    wire [1:0] env_theme = chrono_active ? 2'd2 : ((wave >= 4'd7) ? 2'd3 : (zone3_open ? 2'd1 : 2'd0));

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
