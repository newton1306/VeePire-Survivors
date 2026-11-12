`timescale 1ns / 1ps
// DRAGO-NEXUS V3 OMEGA EDITION: Mega-Scale Zero-Bottleneck ARPG Engine
//   - Time-Multiplexed 16 Enemies & Lock-On Scanner (eliminates deep combinational chains!)
//   - Giant 2048x1024 Multi-Biome Map (Emerald Citadel, Twilight Chasm, Magma Forge, Sealed Sanctum)
//   - 10 Expanding Waves + 3 Unique 64x64 Bosses (Wave 3 Titan, Wave 6 Arch-Mage, Wave 10 Omega Boss)
//   - 3-Hit Melee Lunge-Snap Combo + 360 Nova Finisher + Combo Rank (D..SS) + 16 Hit Sparks
//   - Magnet Gem Pull + Blue Gem Upgrade Cutscenes (Pet Mob, Orbit Swords, Apex Aura)
//   - Separate 2P Hearts + 3-Way Revive + 17-Step Brawlhalla Smooth Zoom + Dual-Joy Full Control
module game_engine_v2 (
    input  wire        clk,
    input  wire        rst,
    input  wire        tick,             // 60 Hz frame pulse
    input  wire [4:0]  btn,              // {btnc, btnu, btnd, btnl, btnr}
    input  wire signed [2:0] tilt_dx,
    input  wire signed [2:0] tilt_dy,
    input  wire signed [2:0] j1_dx,
    input  wire signed [2:0] j1_dy,
    input  wire [2:0]        j1_btn,     // {fire, dash, chrono}
    input  wire signed [2:0] j2_dx,
    input  wire signed [2:0] j2_dy,
    input  wire [2:0]        j2_btn,     // {fire, dash, chrono}
    input  wire              j1_shoot,   // Y button on Joy1 -> Blue Gun Bullet
    input  wire              j2_shoot,   // Y button on Joy2 -> Blue Gun Bullet
    input  wire              joy_pause,  // Start button on Joystick -> Pause
    input  wire              joy_select, // Select button on Joystick -> Return to Menu

    // Tilemap Dual-Port B (128x64 = 13-bit addr)
    output reg  [12:0] map_addr_b = 0,
    input  wire [3:0]  map_tile_b,

    // Core State Outputs
    output reg  [1:0]  control_mode  = 2'd0,
    output wire        p2_active,
    output reg  [6:0]  zoom_lvl      = 7'd0,
    output wire        zoom_out,
    output wire [4:0]  enemies_left,         // 0..16
    output reg  [2:0]  game_state    = 3'd0, // 0=TITLE, 1=CUTSCENE, 2=PLAY, 3=WIN, 4=LOSE
    output reg  [1:0]  cut_id        = 2'd0, // 0=Intro, 1=Expand/Biome, 2=Boss Sealed, 3=Gem Upgrade!
    output reg  [7:0]  cut_timer     = 8'd0,
    output reg  [3:0]  wave          = 4'd1, // 1..10
    output reg         zone2_open    = 1'b0,
    output reg         zone3_open    = 1'b0,
    output reg  [10:0] px            = 11'd128,
    output reg  [9:0]  py            = 10'd192,
    output reg  [10:0] dash_gx       = 11'd128,
    output reg  [9:0]  dash_gy       = 10'd192,
    output reg  [10:0] p2x           = 11'd128,
    output reg  [9:0]  p2y           = 10'd220,
    output reg  [10:0] p2_dash_gx    = 11'd128,
    output reg  [9:0]  p2_dash_gy    = 10'd220,
    output reg         p2_mirror     = 1'b0,
    output reg         p2_walk_frame = 1'b0,
    output reg  [4:0]  p2_dash_timer = 5'd0,
    output reg  [10:0] cam_x         = 11'd0,
    output reg  [9:0]  cam_y         = 10'd86,
    output reg  [4:0]  hp            = 5'd24,
    output reg  [4:0]  hp2           = 5'd24,
    output reg  [5:0]  exp           = 6'd0,
    output reg  [1:0]  stage         = 2'd0,
    output reg  [15:0] score_bcd     = 16'd0,
    output reg  [6:0]  chrono_energy = 7'd100,
    output wire        chrono_active,
    output reg         mirror        = 1'b0,
    output reg         walk_frame    = 1'b0,
    output reg  [4:0]  dash_timer    = 5'd0,
    output reg  [5:0]  invuln_timer  = 6'd0,
    output reg  [5:0]  p2_invuln     = 6'd0,
    output reg  [4:0]  evolve_flash  = 5'd0,

    // Combo Counter, Screen Shake & Attack Pose Signals
    output reg  [6:0]  combo_cnt     = 7'd0,
    output reg  [3:0]  shake_mag     = 4'd0,
    output wire        p1_nova,
    output wire        p2_nova,

    // Progression-Earned Upgrades (Blue Gems!)
    output wire        pet_active,
    output wire        blades_active,
    output wire        aura_active,
    output reg  [10:0] blade0_x = 0, blade1_x = 0, pet_bx = 0,
    output reg  [9:0]  blade0_y = 0, blade1_y = 0, pet_by = 0,
    output reg  [10:0] p2_blade0_x = 0, p2_blade1_x = 0,
    output reg  [9:0]  p2_blade0_y = 0, p2_blade1_y = 0,
    output reg         pet_b_act = 1'b0,

    // 16 Enemies (32x32 Sprites, 8 Types)
    output reg  [16*11-1:0] en_x_vec     = 0,
    output reg  [16*10-1:0] en_y_vec     = 0,
    output reg  [16*3-1:0]  en_type_vec  = 0,
    output reg  [15:0]      en_alive_vec = 16'b0,
    output reg  [16*4-1:0]  en_hp_vec    = 0,
    output reg  [16*2-1:0]  en_tier_vec  = 0,

    // 12 Ground Collectibles (Blue Gems & Hearts)
    output reg  [12*11-1:0] col_x_vec     = 0,
    output reg  [12*10-1:0] col_y_vec     = 0,
    output reg  [11:0]      col_type_vec  = 12'b0,
    output reg  [11:0]      col_alive_vec = 12'b0,

    // 4 Sky-Falling Objects
    output reg  [4*11-1:0] drop_x_vec    = 0,
    output reg  [4*10-1:0] drop_y_vec    = 0,
    output reg  [4*7-1:0]  drop_z_vec    = 0,
    output reg  [4*2-1:0]  drop_type_vec = 0,
    output reg  [3:0]      drop_active_vec = 4'b0,
    output reg  [4*5-1:0]  drop_boom_vec = 0,

    // 12 Particle Hit Sparks!
    output reg  [12*11-1:0] sp_x_vec      = 0,
    output reg  [12*10-1:0] sp_y_vec      = 0,
    output reg  [11:0]      sp_alive_vec  = 12'b0,

    // Melee Slash Arcs + Lock-On + 8 Enemy Bullets
    output reg  [10:0]      p1_slash_x    = 11'd0,
    output reg  [9:0]       p1_slash_y    = 10'd0,
    output reg  [3:0]       p1_slash_t    = 4'd0,
    output reg signed [1:0] p1_slash_dx   = 2'sd1,
    output reg signed [1:0] p1_slash_dy   = 2'sd0,
    output reg  [10:0]      p2_slash_x    = 11'd0,
    output reg  [9:0]       p2_slash_y    = 10'd0,
    output reg  [3:0]       p2_slash_t    = 4'd0,
    output reg signed [1:0] p2_slash_dx   = 2'sd1,
    output reg signed [1:0] p2_slash_dy   = 2'sd0,
    output reg  [10:0]      lock_x        = 11'd0,
    output reg  [9:0]       lock_y        = 10'd0,
    output reg              lock_valid    = 1'b0,
    output reg  [8*11-1:0]  eb_x_vec      = 0,
    output reg  [8*10-1:0]  eb_y_vec      = 0,
    output reg  [7:0]       eb_active_vec = 8'b0,
    output reg  [8*11-1:0]  pb_x_vec      = 0,
    output reg  [8*10-1:0]  pb_y_vec      = 0,
    output reg  [8*2-1:0]   pb_dir_vec    = 0, // 0=H, 1=V, 2=diag\, 3=diag/
    output reg  [7:0]       pb_active_vec = 8'b0,

    // 3 Distinct Bosses (Ajarn_V_1 Goose, Ajarn_V_2 Iron-Arm, Ajarn_V Thanos)
    output reg  [10:0] boss_x        = 11'd1840,
    output reg  [9:0]  boss_y        = 10'd512,
    output reg  [7:0]  boss_hp       = 8'd140,
    output reg  [1:0]  boss_kind     = 2'd0,
    output reg         boss_active   = 1'b0,
    output wire        boss_locked,
    output wire        boss_enraged,
    output reg  [1:0]  laser_state   = 2'd0,
    output reg  [9:0]  laser_y       = 10'd512,

    // Audio SFX pulses
    output reg         sfx_shoot     = 1'b0,
    output reg         sfx_pickup    = 1'b0,
    output reg         sfx_evolve    = 1'b0,
    output reg         sfx_hit       = 1'b0,

    // V5 Arena Room, Sliding Door, Logic Gate Quiz & 3-Form Boss Portal Transition
    output reg  [2:0]  room_phase    = 3'd0, // 0=BANNER, 1=FIGHT, 2=CLEAR_ARROW, 3=QUIZ, 4=DOOR_OPEN, 5=BOSS_TRANS
    output reg  [6:0]  wave_banner_t = 7'd0,
    output reg  [5:0]  door_slam_t   = 6'd0,
    output reg  [4:0]  door_slide    = 5'd0,
    output reg  [2:0]  quiz_gate     = 3'd0, // 0=AND,1=OR,2=NOT,3=NAND,4=NOR,5=XOR
    output reg  [1:0]  quiz_cursor   = 2'd0,
    output reg  [1:0]  quiz_ans_slot = 2'd0,
    output reg  [6:0]  quiz_wrong_t  = 7'd0,
    output reg  [7:0]  boss_trans_t  = 8'd0,
    output reg  [7:0]  outfit_cut_t  = 8'd0,
    output reg         paused        = 1'b0
);
    localparam [2:0] ST_TITLE=3'd0, ST_CUTSCENE=3'd1, ST_PLAY=3'd2, ST_WIN=3'd3, ST_LOSE=3'd4;
    localparam [2:0] RP_BANNER=3'd0, RP_FIGHT=3'd1, RP_CLEAR=3'd2, RP_QUIZ=3'd3, RP_DOOR=3'd4, RP_BOSS=3'd5;
    localparam [3:0] FINAL_WAVE = 4'd6;

    wire btnc = btn[4], btnu = btn[3], btnd = btn[2], btnl = btn[1], btnr = btn[0];
    wire use_joy   = 1'b1;
    assign p2_active = (control_mode == 2'd1);
    assign zoom_out  = (zoom_lvl > 7'd0);

    wire p1_alive = (hp > 5'd0);
    wire p2_alive = p2_active && (hp2 > 5'd0);

    wire signed [2:0] p1_in_dx = j1_dx;
    wire signed [2:0] p1_in_dy = j1_dy;

    reg [4:0] btn_prev = 0;
    reg [2:0] j1_btn_prev = 0, j2_btn_prev = 0;
    reg       joy_pause_prev = 1'b0, joy_select_prev = 1'b0;
    reg [2:0] wave_sub = 3'd0;
    reg signed [2:0] j1_dx_prev = 0, j2_dx_prev = 0;
    reg signed [2:0] j1_dy_prev = 0, j2_dy_prev = 0;

    wire btnc_edge    = btnc && !btn_prev[4];
    wire btnu_edge    = btnu && !btn_prev[3];
    wire btnd_edge    = btnd && !btn_prev[2];
    wire btnl_edge    = btnl && !btn_prev[1];
    wire btnr_edge    = btnr && !btn_prev[0];
    wire j1_fire_edge = j1_btn[2] && !j1_btn_prev[2];
    wire j1_dash_edge = j1_btn[1] && !j1_btn_prev[1];
    wire j2_fire_edge = j2_btn[2] && !j2_btn_prev[2];
    wire j2_dash_edge = j2_btn[1] && !j2_btn_prev[1];
    wire j1_left_edge = (j1_dx < 0) && (j1_dx_prev >= 0);
    wire j1_right_edge= (j1_dx > 0) && (j1_dx_prev <= 0);
    wire j2_left_edge = (j2_dx < 0) && (j2_dx_prev >= 0);
    wire j2_right_edge= (j2_dx > 0) && (j2_dx_prev <= 0);
    wire j1_up_edge   = (j1_dy < 0) && (j1_dy_prev >= 0);
    wire j1_down_edge = (j1_dy > 0) && (j1_dy_prev <= 0);
    wire j2_up_edge   = (j2_dy < 0) && (j2_dy_prev >= 0);
    wire j2_down_edge = (j2_dy > 0) && (j2_dy_prev <= 0);

    wire any_left_edge  = btnl_edge || j1_left_edge  || j2_left_edge;
    wire any_right_edge = btnr_edge || j1_right_edge || j2_right_edge;
    wire any_up_edge    = btnu_edge || j1_up_edge    || j2_up_edge;
    wire any_down_edge  = btnd_edge || j1_down_edge  || j2_down_edge;
    wire any_start_edge = btnc_edge || j1_fire_edge  || j2_fire_edge || j1_dash_edge || j2_dash_edge;
    wire any_skip_edge  = btnc_edge || j1_fire_edge  || j2_fire_edge;

    assign chrono_active = (game_state == ST_PLAY) && (room_phase == RP_FIGHT) &&
                           ((p1_alive && (btnd || (use_joy && j1_btn[0]))) || (p2_alive && j2_btn[0])) &&
                           (chrono_energy > 0);
    assign pet_active    = (stage >= 2'd1);
    assign blades_active = (game_state == ST_PLAY) && (stage >= 2'd2);
    assign aura_active   = (stage >= 2'd3);
    assign boss_locked   = (wave == FINAL_WAVE) && boss_active && (boss_hp > 0);
    assign boss_enraged  = (boss_kind == 2'd2) ? (boss_hp <= 8'd95) : ((boss_kind == 2'd1) ? (boss_hp <= 8'd70) : (boss_hp <= 8'd50));

    reg [1:0] p1_combo_step = 2'd0, p2_combo_step = 2'd0;
    reg [5:0] p1_combo_rst = 6'd0, p2_combo_rst = 6'd0;
    reg       p1_nova_r = 1'b0, p2_nova_r = 1'b0;
    assign p1_nova = p1_nova_r && (p1_slash_t > 0);
    assign p2_nova = p2_nova_r && (p2_slash_t > 0);

    // ---- Internal Arrays (Time-Multiplexed Friendly!) ----
    reg [10:0] en_x    [0:15];
    reg [9:0]  en_y    [0:15];
    reg [2:0]  en_type [0:15];
    reg [3:0]  en_hp   [0:15];
    reg [1:0]  en_tier [0:15];
    reg        en_alive[0:15];
    reg [7:0]  en_cd   [0:15];

    assign enemies_left = en_alive_vec[0]  + en_alive_vec[1]  + en_alive_vec[2]  + en_alive_vec[3] +
                          en_alive_vec[4]  + en_alive_vec[5]  + en_alive_vec[6]  + en_alive_vec[7] +
                          en_alive_vec[8]  + en_alive_vec[9]  + en_alive_vec[10] + en_alive_vec[11] +
                          en_alive_vec[12] + en_alive_vec[13] + en_alive_vec[14] + en_alive_vec[15];

    reg [10:0] col_x    [0:11];
    reg [9:0]  col_y    [0:11];
    reg        col_type [0:11];
    reg        col_alive[0:11];

    reg [10:0] drop_x    [0:3];
    reg [9:0]  drop_y    [0:3];
    reg [6:0]  drop_z    [0:3];
    reg [1:0]  drop_type [0:3];
    reg        drop_active[0:3];
    reg [4:0]  drop_boom [0:3];

    reg [10:0] eb_x      [0:7];
    reg [9:0]  eb_y      [0:7];
    reg signed [4:0] eb_vx [0:7];
    reg signed [4:0] eb_vy [0:7];
    reg        eb_active [0:7];

    // 8 Player Blue Gun Bullets (Y Button)
    reg [10:0] pb_x      [0:7];
    reg [9:0]  pb_y      [0:7];
    reg signed [4:0] pb_vx [0:7];
    reg signed [4:0] pb_vy [0:7];
    reg [1:0]  pb_dir    [0:7];
    reg        pb_active [0:7];
    reg [4:0]  pb_tgt    [0:7];
    reg        pb_homing [0:7];
    reg [3:0]  p1_gun_cd = 4'd0, p2_gun_cd = 4'd0;
    reg [8:0]  p1_ooc_t  = 9'd0, p2_ooc_t  = 9'd0;
    reg [6:0]  p1_regen_div = 7'd0, p2_regen_div = 7'd0;
    reg [5:0]  p1_stun_t = 6'd0, p2_stun_t = 6'd0;
    reg [2:0]  p1_boss_melee_cnt = 3'd0, p2_boss_melee_cnt = 3'd0;
    reg [6:0]  p1_bmelee_rst = 7'd0, p2_bmelee_rst = 7'd0;
    reg [5:0]  quiz_lockout = 6'd0;

    reg [10:0] sp_x      [0:11];
    reg [9:0]  sp_y      [0:11];
    reg signed [3:0] sp_vx [0:11], sp_vy [0:11];
    reg [4:0]  sp_t      [0:11];
    reg [3:0]  sp_ptr = 0;

    function automatic [12:0] tile_addr;
        input [10:0] xx;
        input [9:0]  yy;
        begin
            tile_addr = {yy[9:4], xx[10:4]}; // 128 x 64 tilemap!
        end
    endfunction

    function automatic is_solid;
        input [3:0] tid;
        input       z2_op, z3_op, chr_on;
        begin
            case (tid)
                4'd2:  is_solid = 1'b1;      // Wall
                4'd5:  is_solid = 1'b1;      // Torch pillar
                4'd10: is_solid = 1'b1;      // Abyss
                4'd12: is_solid = 1'b1;      // Lava River
                4'd4:  is_solid = ~chr_on;   // Shadow Bridge
                4'd11: is_solid = ~z2_op;    // Gate 11 (Biome 1 East)
                4'd13: is_solid = ~z3_op;    // Gate 13 (Biome 2/3)
                4'd9:  is_solid = 1'b1;      // Sealed Red Boss Gate!
                default: is_solid = 1'b0;
            endcase
        end
    endfunction

    task automatic add_score;
        input [9:0] pts;
        reg [4:0] d0, d1, d2, d3;
        begin
            d0 = {1'b0, score_bcd[3:0]};   d1 = {1'b0, score_bcd[7:4]};
            d2 = {1'b0, score_bcd[11:8]};  d3 = {1'b0, score_bcd[15:12]};
            if      (pts == 10'd10)  d1 = d1 + 1;
            else if (pts == 10'd25)  begin d0 = d0 + 5; d1 = d1 + 2; end
            else if (pts == 10'd50)  d1 = d1 + 5;
            else if (pts == 10'd100) d2 = d2 + 1;
            else if (pts == 10'd500) d2 = d2 + 5;
            if (d0 >= 5'd10) begin d0 = d0 - 5'd10; d1 = d1 + 1; end
            if (d1 >= 5'd10) begin d1 = d1 - 5'd10; d2 = d2 + 1; end
            if (d2 >= 5'd10) begin d2 = d2 - 5'd10; d3 = d3 + 1; end
            if (d3 >= 5'd10) begin d3 = 5'd9; d2 = 5'd9; d1 = 5'd9; d0 = 5'd9; end
            score_bcd <= {d3[3:0], d2[3:0], d1[3:0], d0[3:0]};
        end
    endtask

    task automatic spawn_sparks;
        input [10:0] sx;
        input [9:0]  sy;
        reg [3:0] sp_next;
        begin
            sp_next = (sp_ptr >= 4'd11) ? 4'd0 : (sp_ptr + 4'd1);
            sp_x[sp_ptr]  <= sx; sp_y[sp_ptr]  <= sy; sp_t[sp_ptr]  <= 5'd14;
            sp_vx[sp_ptr] <= 4'sd3; sp_vy[sp_ptr] <= -4'sd3;
            sp_x[sp_next] <= sx; sp_y[sp_next] <= sy; sp_t[sp_next] <= 5'd14;
            sp_vx[sp_next] <= -4'sd3; sp_vy[sp_next] <= 4'sd2;
            sp_ptr <= (sp_ptr >= 4'd10) ? 4'd0 : (sp_ptr + 4'd2);
        end
    endtask

    // ---- Counters & Sequential Time-Multiplexed State ----
    reg [5:0] step_state = 0;
    reg [3:0] e_idx = 0;
    reg [1:0] chrono_div = 0;
    reg       world_tick = 0;
    reg [8:0] frame_cnt  = 0;
    reg [5:0] dash_cd = 0, p2_dash_cd = 0;
    reg       btnc_prev_clk = 0, j1f_prev_clk = 0, j2f_prev_clk = 0;
    reg       fire_req = 0, p2_fire_req = 0;
    reg [3:0] p1_lunge_t = 0, p2_lunge_t = 0;
    reg       p1_has_tgt = 0, p2_has_tgt = 0;
    reg [10:0] p1_tgt_x = 0, p2_tgt_x = 0;
    reg [9:0]  p1_tgt_y = 0, p2_tgt_y = 0;
    reg [15:0] p1_hit_mask = 0, p2_hit_mask = 0;
    reg        p1_boss_hit = 0, p2_boss_hit = 0;
    reg [7:0]  shrine_cd = 0;
    reg [8:0]  sky_drop_timer = 0;
    reg [6:0]  pet_fire_cd = 0;
    reg signed [4:0] pet_bvx = 0, pet_bvy = 0;
    reg [4:0]  revive_prog = 0;
    reg [7:0]  combo_timer = 0;
    reg [2:0]  hit_stop = 0;
    reg signed [2:0] face_dx = 3'sd1, face_dy = 3'sd0, p2_face_dx = 3'sd1, p2_face_dy = 3'sd0;

    // Registered Lock-On outputs & running scan accumulator
    reg        best1_valid = 0, best2_valid = 0;
    reg [10:0] best1_x = 0, best2_x = 0;
    reg        gun1_valid = 0, gun2_valid = 0;
    reg [4:0]  gun1_idx = 0, gun2_idx = 0;
    reg [10:0] gun1_x = 0, gun2_x = 0;
    reg [9:0]  gun1_y = 0, gun2_y = 0;
    reg [11:0] gun1_d = 12'd260, gun2_d = 12'd260;
    reg signed [11:0] gdx, gdy;
    reg [11:0] agx, agy;
    reg [9:0]  best1_y = 0, best2_y = 0;
    reg [11:0] best1_d = 12'd220, best2_d = 12'd220;

    reg [10:0] cand_px = 0, cand_p2x = 0;
    reg [9:0]  cand_py = 0, cand_p2y = 0;
    reg        x_blocked = 0, y_blocked = 0, cur_center_solid = 0;
    reg        p2_x_blk  = 0, p2_y_blk  = 0, p2_cur_solid = 0;
    reg [3:0]  blade_ang = 0;
    reg [6:0]  end_lockout = 0;
    reg signed [12:0] sx_tmp, sy_tmp;
    reg [7:0]  boss_ai_timer = 0;
    reg        boss_dir_y = 0;
    reg [7:0]  laser_timer = 0;
    reg        tdmg1_acc = 0, tdmg2_acc = 0;
    reg        tdmg1_now = 0, tdmg2_now = 0;
    reg        pb_hit_found = 0;
    reg [2:0]  pb_hit_idx = 0;

    // Smooth Zoom & Clamping Wires (exact match to vga_renderer_v2 7-bit 0..80 scale!)
    wire [9:0]  view_w = 10'd320 + {2'b00, zoom_lvl, 1'b0} + {3'b000, zoom_lvl[6:1]}; // 320..520
    wire [9:0]  view_h = 10'd212 + {3'b000, zoom_lvl} + {4'b0000, zoom_lvl[6:1]} + {5'b00000, zoom_lvl[6:3]}; // 212..342
    wire [10:0] dx_sep = (p1_alive && p2_alive) ? ((px >= p2x) ? (px - p2x) : (p2x - px)) : 11'd0;
    wire [9:0]  dy_sep = (p1_alive && p2_alive) ? ((py >= p2y) ? (py - p2y) : (p2y - py)) : 10'd0;
    wire [10:0] need_w = dx_sep + 11'd120;
    wire [9:0]  need_h = dy_sep + 10'd84;
    wire [10:0] zx_raw = (need_w > 11'd320) ? ((need_w - 11'd320) >> 1) : 11'd0;
    wire [9:0]  zy_raw = (need_h > 10'd212) ? ((need_h - 10'd212) >> 1) : 10'd0;
    wire [10:0] z_max_raw = (zx_raw > {1'b0, zy_raw}) ? zx_raw : {1'b0, zy_raw};
    wire [6:0]  target_zoom = (!p2_active || !p1_alive || !p2_alive) ? 7'd0 :
                              ((z_max_raw > 11'd80) ? 7'd80 : z_max_raw[6:0]);

    reg signed [5:0] cos_val, sin_val;
    always @(*) begin
        case (blade_ang)
            4'd0:  begin cos_val =  24; sin_val =   0; end
            4'd1:  begin cos_val =  22; sin_val =   9; end
            4'd2:  begin cos_val =  17; sin_val =  17; end
            4'd3:  begin cos_val =   9; sin_val =  22; end
            4'd4:  begin cos_val =   0; sin_val =  24; end
            4'd5:  begin cos_val =  -9; sin_val =  22; end
            4'd6:  begin cos_val = -17; sin_val =  17; end
            4'd7:  begin cos_val = -22; sin_val =   9; end
            4'd8:  begin cos_val = -24; sin_val =   0; end
            4'd9:  begin cos_val = -22; sin_val =  -9; end
            4'd10: begin cos_val = -17; sin_val = -17; end
            4'd11: begin cos_val =  -9; sin_val = -22; end
            4'd12: begin cos_val =   0; sin_val = -24; end
            4'd13: begin cos_val =   9; sin_val = -22; end
            4'd14: begin cos_val =  17; sin_val = -17; end
            4'd15: begin cos_val =  22; sin_val =  -9; end
        endcase
    end

    integer idx;
    task automatic set_en;
        input integer ei;
        input [10:0] ex;
        input [9:0]  ey;
        input [2:0]  etp;
        input [1:0]  etr;
        input [3:0]  ehp;
        input [7:0]  ecd;
        begin
            en_x[ei] <= ex; en_y[ei] <= ey; en_type[ei] <= etp;
            en_tier[ei] <= etr; en_hp[ei] <= ehp; en_alive[ei] <= 1'b1; en_cd[ei] <= ecd;
        end
    endtask

    task automatic spawn_wave_group;
        input [3:0] wv;
        input [2:0] sub;
        begin
            for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;
            case (wv)
                4'd1: begin // Wave 1: 3 sub-waves x 10 = 30 Human-Face Minions (8..9 HP)
                    for (idx = 0; idx < 10; idx = idx + 1)
                        set_en(idx, 11'd250 + ((idx % 5) * 11'd64), 10'd108 + ((idx / 5) * 10'd185), idx[2:0] + sub, (sub >= 3'd1) ? 2'd1 : 2'd0, (sub >= 3'd1) ? 4'd9 : 4'd8, 16 + idx*5);
                end
                4'd2: begin // Wave 2: 4 sub-waves x 12 = 48 Human-Face Minions (10..11 HP)
                    for (idx = 0; idx < 12; idx = idx + 1)
                        set_en(idx, 11'd235 + ((idx % 4) * 11'd82), 10'd104 + ((idx / 4) * 10'd95), idx[2:0] + sub, 2'd1, (sub >= 3'd2) ? 4'd11 : 4'd10, 15 + idx*4);
                end
                4'd3: begin // Wave 3: 4 sub-waves x 14 = 56 Human-Face Strikers (11..12 HP)
                    for (idx = 0; idx < 14; idx = idx + 1)
                        set_en(idx, 11'd225 + ((idx % 5) * 11'd72), 10'd104 + ((idx / 5) * 10'd95), idx[2:0] + sub, 2'd2, (sub >= 3'd2) ? 4'd12 : 4'd11, 14 + idx*4);
                end
                4'd4: begin // Wave 4: 5 sub-waves x 15 = 75 Human-Face Raiders (13..14 HP)
                    for (idx = 0; idx < 15; idx = idx + 1)
                        set_en(idx, 11'd215 + ((idx % 5) * 11'd74), 10'd102 + ((idx / 5) * 10'd95), idx[2:0] + sub, 2'd2, (sub >= 3'd2) ? 4'd14 : 4'd13, 12 + idx*3);
                end
                4'd5: begin // Wave 5: 5 sub-waves x 16 = 80 Human-Face Elites (14..15 HP)
                    for (idx = 0; idx < 16; idx = idx + 1)
                        set_en(idx, 11'd205 + ((idx % 4) * 11'd95), 10'd100 + ((idx / 4) * 10'd72), idx[2:0] + sub, 2'd3, (sub >= 3'd2) ? 4'd15 : 4'd14, 10 + idx*3);
                end
                default: begin // Wave 6 (FINAL): Boss Form 0 (Ajarn_V_1 105 HP -> 145 HP -> 190 HP!)
                    boss_kind <= 2'd0; boss_active <= 1'b1; boss_x <= 11'd480; boss_y <= 10'd224; boss_hp <= 8'd105;
                end
            endcase
        end
    endtask

    task automatic init_game;
        begin
            px <= 11'd104; py <= 10'd224; dash_gx <= 11'd104; dash_gy <= 10'd224;
            p2x <= 11'd104; p2y <= 10'd252; p2_dash_gx <= 11'd104; p2_dash_gy <= 10'd252;
            cam_x <= 11'd0; cam_y <= 10'd118; zoom_lvl <= 7'd0;
            hp <= 5'd24; hp2 <= 5'd24; exp <= 6'd0; stage <= 2'd0;
            p1_gun_cd <= 4'd0; p2_gun_cd <= 4'd0;
            p1_ooc_t <= 9'd0; p2_ooc_t <= 9'd0; p1_regen_div <= 7'd0; p2_regen_div <= 7'd0;
            p1_stun_t <= 6'd0; p2_stun_t <= 6'd0; p1_boss_melee_cnt <= 3'd0; p2_boss_melee_cnt <= 3'd0;
            p1_bmelee_rst <= 7'd0; p2_bmelee_rst <= 7'd0;
            score_bcd <= 16'd0; chrono_energy <= 7'd100;
            wave <= 4'd1; wave_sub <= 3'd0; paused <= 1'b0; zone2_open <= 1'b0; zone3_open <= 1'b0;
            room_phase <= RP_BANNER; wave_banner_t <= 7'd90; door_slam_t <= 6'd45;
            door_slide <= 5'd0; boss_trans_t <= 8'd0; quiz_wrong_t <= 7'd0;
            quiz_lockout <= 6'd0; outfit_cut_t <= 8'd0;
            quiz_cursor <= 2'd0; quiz_gate <= 3'd0; quiz_ans_slot <= 2'd0;
            mirror <= 1'b0; walk_frame <= 1'b0; p2_mirror <= 1'b0; p2_walk_frame <= 1'b0;
            dash_timer <= 0; dash_cd <= 0; invuln_timer <= 0; p2_invuln <= 0; evolve_flash <= 0;
            p2_dash_timer <= 0; p2_dash_cd <= 0; end_lockout <= 7'd0; revive_prog <= 5'd0;
            p1_lunge_t <= 0; p2_lunge_t <= 0; p1_slash_t <= 0; p2_slash_t <= 0;
            p1_hit_mask <= 0; p2_hit_mask <= 0; p1_boss_hit <= 0; p2_boss_hit <= 0;
            p1_combo_step <= 0; p2_combo_step <= 0; p1_nova_r <= 0; p2_nova_r <= 0;
            combo_cnt <= 0; combo_timer <= 0; shake_mag <= 4'd6; hit_stop <= 0;
            lock_valid <= 0; fire_req <= 0; p2_fire_req <= 0;
            shrine_cd <= 0; sky_drop_timer <= 0; pet_fire_cd <= 0; pet_b_act <= 0;
            face_dx <= 3'sd1; face_dy <= 3'sd0; p2_face_dx <= 3'sd1; p2_face_dy <= 3'sd0;
            boss_active <= 1'b0; boss_kind <= 2'd0; boss_hp <= 8'd105;
            gun1_valid <= 1'b0; gun2_valid <= 1'b0; gun1_idx <= 5'd0; gun2_idx <= 5'd0;
            boss_ai_timer <= 0; laser_state <= 0; laser_timer <= 0;

            for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;

            // Ground Blue Evo Gems + Hearts inside the room (NO mushrooms!)
            col_x[0] <= 11'd200; col_y[0] <= 10'd150; col_type[0] <= 1'b0; col_alive[0] <= 1'b1;
            col_x[1] <= 11'd240; col_y[1] <= 10'd290; col_type[1] <= 1'b0; col_alive[1] <= 1'b1;
            col_x[2] <= 11'd360; col_y[2] <= 10'd150; col_type[2] <= 1'b0; col_alive[2] <= 1'b1;
            col_x[3] <= 11'd360; col_y[3] <= 10'd290; col_type[3] <= 1'b1; col_alive[3] <= 1'b1;
            for (idx = 4; idx < 12; idx = idx + 1) col_alive[idx] <= 1'b0;

            for (idx = 0; idx < 4; idx = idx + 1) begin drop_active[idx] <= 1'b0; drop_boom[idx] <= 0; drop_z[idx] <= 0; end
            for (idx = 0; idx < 8; idx = idx + 1) begin eb_active[idx] <= 1'b0; pb_active[idx] <= 1'b0; pb_homing[idx] <= 1'b0; pb_tgt[idx] <= 5'd0; end
            for (idx = 0; idx < 12; idx = idx + 1) sp_t[idx] <= 5'd0;
        end
    endtask

    // ---- Combinational Movement for P1 & P2 (reads registered p1_tgt_x/y -> zero enemy mux!) ----
    function automatic signed [4:0] lunge_step;
        input signed [11:0] delta;
        begin
            if      (delta >=  12'sd24) lunge_step =  5'sd6;
            else if (delta >=  12'sd10) lunge_step =  5'sd4;
            else if (delta >=  12'sd4)  lunge_step =  5'sd2;
            else if (delta <= -12'sd24) lunge_step = -5'sd6;
            else if (delta <= -12'sd10) lunge_step = -5'sd4;
            else if (delta <= -12'sd4)  lunge_step = -5'sd2;
            else                        lunge_step =  5'sd0;
        end
    endfunction

    reg signed [4:0] move_dx, move_dy, p2_move_dx, p2_move_dy;
    reg signed [11:0] ldx1, ldy1, ldx2, ldy2;
    always @(*) begin
        ldx1 = $signed({1'b0, p1_tgt_x}) - $signed({1'b0, px});
        ldy1 = $signed({2'b00, p1_tgt_y}) - $signed({2'b00, py});
        ldx2 = $signed({1'b0, p2_tgt_x}) - $signed({1'b0, p2x});
        ldy2 = $signed({2'b00, p2_tgt_y}) - $signed({2'b00, p2y});

        if (!p1_alive || p1_stun_t > 0) begin
            move_dx = 5'sd0; move_dy = 5'sd0;
        end else if (p1_lunge_t > 0) begin
            if (p1_has_tgt) begin
                if (ldx1 >= -12'sd12 && ldx1 <= 12'sd12 && ldy1 >= -12'sd12 && ldy1 <= 12'sd12) begin
                    move_dx = 5'sd0; move_dy = 5'sd0;
                end else begin
                    move_dx = lunge_step(ldx1); move_dy = lunge_step(ldy1);
                end
            end else begin
                move_dx = face_dx * 5'sd3; move_dy = face_dy * 5'sd3;
            end
        end else if (dash_timer > 0) begin
            move_dx = face_dx * 5'sd4; move_dy = face_dy * 5'sd4;
        end else begin
            move_dx = (stage >= 2'd1 && p1_in_dx != 0) ? (p1_in_dx > 0 ? p1_in_dx + 5'sd1 : p1_in_dx - 5'sd1) : p1_in_dx;
            move_dy = (stage >= 2'd1 && p1_in_dy != 0) ? (p1_in_dy > 0 ? p1_in_dy + 5'sd1 : p1_in_dy - 5'sd1) : p1_in_dy;
        end

        if (!p2_alive || p2_stun_t > 0) begin
            p2_move_dx = 5'sd0; p2_move_dy = 5'sd0;
        end else if (p2_lunge_t > 0) begin
            if (p2_has_tgt) begin
                if (ldx2 >= -12'sd12 && ldx2 <= 12'sd12 && ldy2 >= -12'sd12 && ldy2 <= 12'sd12) begin
                    p2_move_dx = 5'sd0; p2_move_dy = 5'sd0;
                end else begin
                    p2_move_dx = lunge_step(ldx2); p2_move_dy = lunge_step(ldy2);
                end
            end else begin
                p2_move_dx = p2_face_dx * 5'sd3; p2_move_dy = p2_face_dy * 5'sd3;
            end
        end else if (p2_dash_timer > 0) begin
            p2_move_dx = p2_face_dx * 5'sd4; p2_move_dy = p2_face_dy * 5'sd4;
        end else begin
            p2_move_dx = (stage >= 2'd1 && j2_dx != 0) ? (j2_dx > 0 ? j2_dx + 5'sd1 : j2_dx - 5'sd1) : j2_dx;
            p2_move_dy = (stage >= 2'd1 && j2_dy != 0) ? (j2_dy > 0 ? j2_dy + 5'sd1 : j2_dy - 5'sd1) : j2_dy;
        end
    end

    reg        evolved_now;
    reg [5:0]  next_exp;
    reg [10:0] next_x, t_cam_x, max_cx, min_cx, min_px, max_px;
    reg [9:0]  next_y, t_cam_y, max_cy;
    reg signed [11:0] dx_diff, dy_diff, dx2_diff, dy2_diff;
    reg [11:0] d1_m, d2_m;
    reg [5:0]  r1, r2;
    reg [3:0]  d1_pow, d2_pow;
    wire [3:0] col_slot_e = (e_idx >= 4'd12) ? (e_idx - 4'd12) : e_idx;
    wire [5:0] melee_reach = (stage == 2'd0) ? 6'd30 : ((stage == 2'd1) ? 6'd36 : ((stage == 2'd2) ? 6'd42 : 6'd50));
    wire [3:0] melee_dmg   = (stage == 2'd3) ? 4'd3  : 4'd2;
    wire [5:0] reach1_eff  = p1_nova ? (melee_reach + 6'd12) : melee_reach;
    wire [5:0] reach2_eff  = p2_nova ? (melee_reach + 6'd12) : melee_reach;
    wire [3:0] dmg1_eff    = (p1_nova || p1_combo_step == 2'd2 || combo_cnt >= 7'd15) ? (melee_dmg + 4'd1) : melee_dmg;
    wire [3:0] dmg2_eff    = (p2_nova || p2_combo_step == 2'd2 || combo_cnt >= 7'd15) ? (melee_dmg + 4'd1) : melee_dmg;

    always @(posedge clk) begin
        sfx_shoot  <= 1'b0; sfx_pickup <= 1'b0; sfx_evolve <= 1'b0; sfx_hit <= 1'b0;
        btnc_prev_clk <= btnc; j1f_prev_clk <= j1_btn[2]; j2f_prev_clk <= j2_btn[2];

        if (rst) begin
            game_state <= ST_TITLE;
            init_game();
            step_state <= 0;
            btn_prev <= 0; j1_btn_prev <= 0; j2_btn_prev <= 0; j1_dx_prev <= 0; j2_dx_prev <= 0;
            fire_req <= 0; p2_fire_req <= 0;
        end else begin
            if (game_state != ST_PLAY || room_phase == RP_QUIZ || paused) begin
                fire_req <= 1'b0; p2_fire_req <= 1'b0;
            end else begin
                if (p1_alive && j1_btn[2] && !j1f_prev_clk)
                    fire_req <= 1'b1;
                if (p2_alive && j2_btn[2] && !j2f_prev_clk)
                    p2_fire_req <= 1'b1;
            end

            for (idx = 0; idx < 16; idx = idx + 1) begin
                en_x_vec[idx*11 +: 11] <= en_x[idx]; en_y_vec[idx*10 +: 10] <= en_y[idx];
                en_type_vec[idx*3 +: 3] <= en_type[idx]; en_alive_vec[idx] <= en_alive[idx];
                en_hp_vec[idx*4 +: 4] <= en_hp[idx]; en_tier_vec[idx*2 +: 2] <= en_tier[idx];
            end
            for (idx = 0; idx < 12; idx = idx + 1) begin
                col_x_vec[idx*11 +: 11] <= col_x[idx]; col_y_vec[idx*10 +: 10] <= col_y[idx];
                col_type_vec[idx] <= col_type[idx]; col_alive_vec[idx] <= col_alive[idx];
                sp_x_vec[idx*11 +: 11] <= sp_x[idx]; sp_y_vec[idx*10 +: 10] <= sp_y[idx];
                sp_alive_vec[idx] <= (sp_t[idx] > 0);
            end
            for (idx = 0; idx < 8; idx = idx + 1) begin
                eb_x_vec[idx*11 +: 11] <= eb_x[idx]; eb_y_vec[idx*10 +: 10] <= eb_y[idx];
                eb_active_vec[idx] <= eb_active[idx];
                pb_x_vec[idx*11 +: 11] <= pb_x[idx]; pb_y_vec[idx*10 +: 10] <= pb_y[idx];
                pb_dir_vec[idx*2 +: 2] <= pb_dir[idx]; pb_active_vec[idx] <= pb_active[idx];
            end
            for (idx = 0; idx < 4; idx = idx + 1) begin
                drop_x_vec[idx*11 +: 11] <= drop_x[idx]; drop_y_vec[idx*10 +: 10] <= drop_y[idx];
                drop_z_vec[idx*7 +: 7] <= drop_z[idx]; drop_type_vec[idx*2 +: 2] <= drop_type[idx];
                drop_active_vec[idx] <= drop_active[idx]; drop_boom_vec[idx*5 +: 5] <= drop_boom[idx];
            end

            blade0_x <= $signed({1'b0, px}) + cos_val; blade0_y <= $signed({1'b0, py}) + sin_val;
            blade1_x <= $signed({1'b0, px}) - cos_val; blade1_y <= $signed({1'b0, py}) - sin_val;
            p2_blade0_x <= $signed({1'b0, p2x}) + cos_val; p2_blade0_y <= $signed({1'b0, p2y}) + sin_val;
            p2_blade1_x <= $signed({1'b0, p2x}) - cos_val; p2_blade1_y <= $signed({1'b0, p2y}) - sin_val;

            case (step_state)
                6'd0: if (tick) begin
                    btn_prev <= btn; j1_btn_prev <= j1_btn; j2_btn_prev <= j2_btn;
                    j1_dx_prev <= j1_dx; j2_dx_prev <= j2_dx;
                    j1_dy_prev <= j1_dy; j2_dy_prev <= j2_dy;
                    joy_pause_prev <= joy_pause;
                    joy_select_prev <= joy_select;
                    frame_cnt <= frame_cnt + 9'd1;

                    if (shake_mag > 0) shake_mag <= shake_mag - 4'd1;
                    if (hit_stop > 0)  hit_stop  <= hit_stop - 3'd1;

                    if (joy_select && !joy_select_prev && game_state != ST_TITLE) begin
                        init_game(); game_state <= ST_TITLE; paused <= 1'b0; sfx_pickup <= 1'b1;
                    end else if (game_state == ST_TITLE) begin
                        if (any_right_edge || any_left_edge) begin
                            control_mode <= (control_mode == 2'd0) ? 2'd1 : 2'd0; sfx_pickup <= 1'b1;
                        end else if (any_start_edge) begin
                            init_game(); game_state <= ST_PLAY; sfx_evolve <= 1'b1;
                        end
                    end else if (game_state == ST_CUTSCENE) begin
                        game_state <= ST_PLAY;
                    end else if (game_state == ST_WIN || game_state == ST_LOSE) begin
                        if (end_lockout > 0) end_lockout <= end_lockout - 7'd1;
                        else if (any_start_edge) begin
                            init_game(); game_state <= ST_PLAY; sfx_evolve <= 1'b1;
                        end else if (any_left_edge || any_right_edge) begin
                            init_game(); game_state <= ST_TITLE; sfx_pickup <= 1'b1;
                        end
                    end else if (joy_pause && !joy_pause_prev && room_phase != RP_QUIZ) begin
                        paused <= ~paused; sfx_pickup <= 1'b1;
                    end else if (paused) begin
                        // Game paused via Joystick Start button: freeze engine cleanly!
                        step_state <= 6'd0;
                    end else if (room_phase == RP_QUIZ) begin
                        // ---- LOGIC GATE QUIZ BEFORE SLIDING DOOR (Anti-Mash + Retake Replay!) ----
                        if (quiz_lockout > 0) quiz_lockout <= quiz_lockout - 6'd1;
                        if (quiz_wrong_t > 0) begin
                            quiz_wrong_t <= quiz_wrong_t - 7'd1;
                            if (quiz_wrong_t == 7'd1) begin
                                // Wrong answer -> GO RETAKE! Replay current wave from start!
                                px <= 11'd104; py <= 10'd224; mirror <= 1'b0;
                                p2x <= 11'd104; p2y <= 10'd252; p2_mirror <= 1'b0;
                                for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                wave_sub <= 3'd0; door_slam_t <= 6'd45; door_slide <= 5'd0;
                                wave_banner_t <= 7'd90; room_phase <= RP_BANNER;
                            end
                        end else if (quiz_lockout == 0) begin
                            if (any_up_edge || any_left_edge) begin
                                quiz_cursor <= quiz_cursor - 2'd1; sfx_pickup <= 1'b1;
                            end else if (any_down_edge || any_right_edge) begin
                                quiz_cursor <= quiz_cursor + 2'd1; sfx_pickup <= 1'b1;
                            end else if (any_start_edge) begin
                                if (quiz_cursor == quiz_ans_slot) begin
                                    room_phase <= RP_DOOR; door_slide <= 5'd0; quiz_wrong_t <= 7'd0; sfx_evolve <= 1'b1;
                                end else begin
                                    quiz_wrong_t <= 7'd105; sfx_hit <= 1'b1; shake_mag <= 4'd6;
                                    quiz_gate <= (quiz_gate == 3'd5) ? 3'd0 : (quiz_gate + 3'd1);
                                    quiz_ans_slot <= frame_cnt[1:0];
                                end
                            end
                        end
                    end else if (outfit_cut_t > 0) begin
                        // ---- OUTFIT TRANSFORMATION CUTSCENE AFTER QUIZ PASS! ----
                        outfit_cut_t <= outfit_cut_t - 8'd1;
                        if (outfit_cut_t == 8'd60) begin sfx_evolve <= 1'b1; evolve_flash <= 5'd16; end
                        step_state <= 6'd0;
                    end else begin
                        // ---- ST_PLAY (WAVE_BANNER / FIGHT / CLEAR_ARROW / DOOR_OPEN / BOSS_TRANS) ----
                        if (door_slam_t > 0)   door_slam_t   <= door_slam_t - 6'd1;
                        if (wave_banner_t > 0) wave_banner_t <= wave_banner_t - 7'd1;
                        if (room_phase == RP_BANNER && wave_banner_t == 7'd0) begin
                            wave_sub <= 3'd0;
                            spawn_wave_group(wave, 3'd0);
                            room_phase <= RP_FIGHT;
                        end else if (room_phase == RP_DOOR) begin
                            if (door_slide < 5'd31) door_slide <= door_slide + 5'd1;
                        end else if (room_phase == RP_BOSS) begin
                            if (boss_trans_t > 8'd0) begin
                                boss_trans_t <= boss_trans_t - 8'd1;
                                if (boss_trans_t == 8'd1) begin
                                    if (boss_kind == 2'd0) begin
                                        boss_kind <= 2'd1; boss_hp <= 8'd145; boss_active <= 1'b1;
                                        boss_ai_timer <= 8'd0;
                                        room_phase <= RP_FIGHT; sfx_evolve <= 1'b1;
                                    end else if (boss_kind == 2'd1) begin
                                        boss_kind <= 2'd2; boss_hp <= 8'd190; boss_active <= 1'b1;
                                        boss_ai_timer <= 8'd0;
                                        room_phase <= RP_FIGHT; sfx_evolve <= 1'b1;
                                    end else begin
                                        game_state <= ST_WIN; end_lockout <= 7'd90; sfx_evolve <= 1'b1;
                                    end
                                end
                            end
                        end
                        if (chrono_active) begin
                            chrono_div <= (chrono_div >= 2'd2) ? 2'd0 : chrono_div + 2'd1;
                            world_tick <= (chrono_div == 2'd0);
                            if (frame_cnt[0] && chrono_energy > 0) chrono_energy <= chrono_energy - 7'd1;
                        end else begin
                            chrono_div <= 2'd0; world_tick <= 1'b1;
                            if (frame_cnt[2:0] == 3'b000 && chrono_energy < 7'd100) chrono_energy <= chrono_energy + 7'd1;
                        end

                        if (combo_timer > 0) combo_timer <= combo_timer - 8'd1; else combo_cnt <= 7'd0;
                        if (p1_combo_rst > 0) p1_combo_rst <= p1_combo_rst - 6'd1; else p1_combo_step <= 2'd0;
                        if (p2_combo_rst > 0) p2_combo_rst <= p2_combo_rst - 6'd1; else p2_combo_step <= 2'd0;

                        if (p1_alive && (p1_in_dx != 0 || p1_in_dy != 0)) begin
                            if (p1_in_dx < 0) begin face_dx <= -3'sd1; mirror <= 1'b1; end
                            else if (p1_in_dx > 0) begin face_dx <= 3'sd1; mirror <= 1'b0; end
                            else face_dx <= 3'sd0;
                            if (p1_in_dy < 0) face_dy <= -3'sd1; else if (p1_in_dy > 0) face_dy <= 3'sd1; else face_dy <= 3'sd0;
                            if (frame_cnt[2:0] == 3'b000) walk_frame <= ~walk_frame;
                        end
                        if (p2_alive && (j2_dx != 0 || j2_dy != 0)) begin
                            if (j2_dx < 0) begin p2_face_dx <= -3'sd1; p2_mirror <= 1'b1; end
                            else if (j2_dx > 0) begin p2_face_dx <= 3'sd1; p2_mirror <= 1'b0; end
                            else p2_face_dx <= 3'sd0;
                            if (j2_dy < 0) p2_face_dy <= -3'sd1; else if (j2_dy > 0) p2_face_dy <= 3'sd1; else p2_face_dy <= 3'sd0;
                            if (frame_cnt[2:0] == 3'b000) p2_walk_frame <= ~p2_walk_frame;
                        end

                        if (p1_alive && p1_stun_t == 0 && (btnu_edge || (use_joy && j1_dash_edge)) && dash_cd == 0) begin
                            dash_timer <= 5'd10; dash_cd <= 6'd36; invuln_timer <= 6'd15;
                            dash_gx <= px; dash_gy <= py; sfx_shoot <= 1'b1;
                        end else begin
                            if (dash_timer > 0) dash_timer <= dash_timer - 5'd1;
                            if (dash_cd > 0)    dash_cd    <= dash_cd - 6'd1;
                        end

                        if (p2_alive && p2_stun_t == 0 && j2_dash_edge && p2_dash_cd == 0) begin
                            p2_dash_timer <= 5'd10; p2_dash_cd <= 6'd36; p2_invuln <= 6'd15;
                            p2_dash_gx <= p2x; p2_dash_gy <= p2y; sfx_shoot <= 1'b1;
                        end else begin
                            if (p2_dash_timer > 0) p2_dash_timer <= p2_dash_timer - 5'd1;
                            if (p2_dash_cd > 0)    p2_dash_cd    <= p2_dash_cd - 6'd1;
                        end

                        if (invuln_timer > 0) invuln_timer <= invuln_timer - 6'd1;
                        if (p2_invuln > 0)    p2_invuln    <= p2_invuln - 6'd1;
                        if (evolve_flash > 0) evolve_flash <= evolve_flash - 5'd1;
                        if (shrine_cd > 0)    shrine_cd    <= shrine_cd - 8'd1;
                        if (frame_cnt[1:0] == 2'b00) blade_ang <= blade_ang + 4'd1;
                        if (p1_lunge_t > 0) p1_lunge_t <= p1_lunge_t - 4'd1;
                        if (p2_lunge_t > 0) p2_lunge_t <= p2_lunge_t - 4'd1;
                        if (p1_slash_t > 0) p1_slash_t <= p1_slash_t - 4'd1;
                        if (p2_slash_t > 0) p2_slash_t <= p2_slash_t - 4'd1;
                        if (p1_gun_cd > 0)  p1_gun_cd  <= p1_gun_cd - 4'd1;
                        if (p2_gun_cd > 0)  p2_gun_cd  <= p2_gun_cd - 4'd1;
                        if (p1_stun_t > 0)  p1_stun_t  <= p1_stun_t - 6'd1;
                        if (p2_stun_t > 0)  p2_stun_t  <= p2_stun_t - 6'd1;
                        if (p1_bmelee_rst > 0) p1_bmelee_rst <= p1_bmelee_rst - 7'd1; else p1_boss_melee_cnt <= 3'd0;
                        if (p2_bmelee_rst > 0) p2_bmelee_rst <= p2_bmelee_rst - 7'd1; else p2_boss_melee_cnt <= 3'd0;

                        // Y Button: Fire 100% Single-Target Lock-On Homing Blue Gun Bullets!
                        if (p1_alive && p1_stun_t == 0 && j1_shoot && p1_gun_cd == 0) begin
                            p1_gun_cd <= 4'd10; sfx_shoot <= 1'b1; p1_ooc_t <= 9'd0; p1_regen_div <= 7'd0;
                            if (gun1_valid) begin
                                gdx = $signed({1'b0, gun1_x}) - $signed({1'b0, px});
                                gdy = $signed({2'b00, gun1_y}) - $signed({2'b00, py});
                            end else begin
                                gdx = (face_dx == 0 && face_dy == 0) ? 12'sd6 : {{9{face_dx[2]}}, face_dx};
                                gdy = {{9{face_dy[2]}}, face_dy};
                            end
                            agx = (gdx < 0) ? -gdx : gdx;
                            agy = (gdy < 0) ? -gdy : gdy;
                            for (idx = 0; idx < 4; idx = idx + 1) begin
                                if (!pb_active[idx] && (idx == 0 || (idx == 1 && pb_active[0]) || (idx == 2 && pb_active[0] && pb_active[1]) || (idx == 3 && pb_active[0] && pb_active[1] && pb_active[2]))) begin
                                    pb_active[idx] <= 1'b1; pb_x[idx] <= px; pb_y[idx] <= py;
                                    pb_tgt[idx] <= gun1_idx; pb_homing[idx] <= gun1_valid;
                                    if (agx > (agy << 1)) begin
                                        pb_vx[idx] <= (gdx >= 0) ? 5'sd6 : -5'sd6; pb_vy[idx] <= 5'sd0; pb_dir[idx] <= 2'd0;
                                    end else if (agy > (agx << 1)) begin
                                        pb_vx[idx] <= 5'sd0; pb_vy[idx] <= (gdy >= 0) ? 5'sd6 : -5'sd6; pb_dir[idx] <= 2'd1;
                                    end else begin
                                        pb_vx[idx] <= (gdx >= 0) ? 5'sd5 : -5'sd5; pb_vy[idx] <= (gdy >= 0) ? 5'sd5 : -5'sd5;
                                        pb_dir[idx] <= ((gdx >= 0) == (gdy >= 0)) ? 2'd2 : 2'd3;
                                    end
                                end
                            end
                        end
                        if (p2_alive && p2_stun_t == 0 && j2_shoot && p2_gun_cd == 0) begin
                            p2_gun_cd <= 4'd10; sfx_shoot <= 1'b1; p2_ooc_t <= 9'd0; p2_regen_div <= 7'd0;
                            if (gun2_valid) begin
                                gdx = $signed({1'b0, gun2_x}) - $signed({1'b0, p2x});
                                gdy = $signed({2'b00, gun2_y}) - $signed({2'b00, p2y});
                            end else begin
                                gdx = (p2_face_dx == 0 && p2_face_dy == 0) ? 12'sd6 : {{9{p2_face_dx[2]}}, p2_face_dx};
                                gdy = {{9{p2_face_dy[2]}}, p2_face_dy};
                            end
                            agx = (gdx < 0) ? -gdx : gdx;
                            agy = (gdy < 0) ? -gdy : gdy;
                            for (idx = 4; idx < 8; idx = idx + 1) begin
                                if (!pb_active[idx] && (idx == 4 || (idx == 5 && pb_active[4]) || (idx == 6 && pb_active[4] && pb_active[5]) || (idx == 7 && pb_active[4] && pb_active[5] && pb_active[6]))) begin
                                    pb_active[idx] <= 1'b1; pb_x[idx] <= p2x; pb_y[idx] <= p2y;
                                    pb_tgt[idx] <= gun2_idx; pb_homing[idx] <= gun2_valid;
                                    if (agx > (agy << 1)) begin
                                        pb_vx[idx] <= (gdx >= 0) ? 5'sd6 : -5'sd6; pb_vy[idx] <= 5'sd0; pb_dir[idx] <= 2'd0;
                                    end else if (agy > (agx << 1)) begin
                                        pb_vx[idx] <= 5'sd0; pb_vy[idx] <= (gdy >= 0) ? 5'sd6 : -5'sd6; pb_dir[idx] <= 2'd1;
                                    end else begin
                                        pb_vx[idx] <= (gdx >= 0) ? 5'sd5 : -5'sd5; pb_vy[idx] <= (gdy >= 0) ? 5'sd5 : -5'sd5;
                                        pb_dir[idx] <= ((gdx >= 0) == (gdy >= 0)) ? 2'd2 : 2'd3;
                                    end
                                end
                            end
                        end

                        // Slower Out-of-Combat Regen (6s wait = 360 frames, +1 HP every 1.5s = 90 frames)
                        if (p1_alive && !fire_req && !j1_shoot) begin
                            if (p1_ooc_t < 9'd360) p1_ooc_t <= p1_ooc_t + 9'd1;
                            else if (hp < 5'd24) begin
                                if (p1_regen_div >= 7'd89) begin hp <= hp + 5'd1; p1_regen_div <= 7'd0; end
                                else p1_regen_div <= p1_regen_div + 7'd1;
                            end else p1_regen_div <= 7'd0;
                        end else if (fire_req) begin
                            p1_ooc_t <= 9'd0; p1_regen_div <= 7'd0;
                        end
                        if (p2_alive && !p2_fire_req && !j2_shoot) begin
                            if (p2_ooc_t < 9'd360) p2_ooc_t <= p2_ooc_t + 9'd1;
                            else if (hp2 < 5'd24) begin
                                if (p2_regen_div >= 7'd89) begin hp2 <= hp2 + 5'd1; p2_regen_div <= 7'd0; end
                                else p2_regen_div <= p2_regen_div + 7'd1;
                            end else p2_regen_div <= 7'd0;
                        end else if (p2_fire_req) begin
                            p2_ooc_t <= 9'd0; p2_regen_div <= 7'd0;
                        end

                        // P1 3-Hit Melee Combo & Magnetic Lunge-Snap (blocked while stunned!)
                        if (fire_req && p1_alive && p1_stun_t == 0) begin
                            fire_req <= 1'b0; sfx_shoot <= 1'b1;
                            p1_slash_t <= 4'd12; p1_hit_mask <= 16'b0; p1_boss_hit <= 1'b0;
                            p1_nova_r <= (p1_combo_step == 2'd2);
                            p1_combo_step <= (p1_combo_step == 2'd2) ? 2'd0 : (p1_combo_step + 2'd1);
                            p1_combo_rst  <= 6'd50;
                            if (invuln_timer < 6'd14) invuln_timer <= 6'd14;
                            dash_timer <= 5'd8; dash_gx <= px; dash_gy <= py; walk_frame <= ~walk_frame;

                            if (best1_valid) begin
                                p1_lunge_t <= 4'd6; p1_has_tgt <= 1'b1; p1_tgt_x <= best1_x; p1_tgt_y <= best1_y;
                                dx_diff = $signed({1'b0, best1_x}) - $signed({1'b0, px});
                                dy_diff = $signed({2'b00, best1_y}) - $signed({2'b00, py});
                                if (dx_diff > 12'sd6)       begin face_dx <=  3'sd1; mirror <= 1'b0; p1_slash_dx <=  2'sd1; end
                                else if (dx_diff < -12'sd6) begin face_dx <= -3'sd1; mirror <= 1'b1; p1_slash_dx <= -2'sd1; end
                                else                        begin face_dx <=  3'sd0;                 p1_slash_dx <=  2'sd0; end
                                if (dy_diff > 12'sd6)       begin face_dy <=  3'sd1; p1_slash_dy <=  2'sd1; end
                                else if (dy_diff < -12'sd6) begin face_dy <= -3'sd1; p1_slash_dy <= -2'sd1; end
                                else                        begin face_dy <=  3'sd0; p1_slash_dy <=  2'sd0; end
                            end else begin
                                p1_lunge_t <= 4'd3; p1_has_tgt <= 1'b0;
                                p1_slash_dx <= face_dx[1:0]; p1_slash_dy <= face_dy[1:0];
                            end
                        end else fire_req <= 1'b0;

                        // P2 3-Hit Melee Combo & Magnetic Lunge-Snap (blocked while stunned!)
                        if (p2_fire_req && p2_alive && p2_stun_t == 0) begin
                            p2_fire_req <= 1'b0; sfx_shoot <= 1'b1;
                            p2_slash_t <= 4'd12; p2_hit_mask <= 16'b0; p2_boss_hit <= 1'b0;
                            p2_nova_r <= (p2_combo_step == 2'd2);
                            p2_combo_step <= (p2_combo_step == 2'd2) ? 2'd0 : (p2_combo_step + 2'd1);
                            p2_combo_rst  <= 6'd50;
                            if (p2_invuln < 6'd14) p2_invuln <= 6'd14;
                            p2_dash_timer <= 5'd8; p2_dash_gx <= p2x; p2_dash_gy <= p2y; p2_walk_frame <= ~p2_walk_frame;

                            if (best2_valid) begin
                                p2_lunge_t <= 4'd6; p2_has_tgt <= 1'b1; p2_tgt_x <= best2_x; p2_tgt_y <= best2_y;
                                dx2_diff = $signed({1'b0, best2_x}) - $signed({1'b0, p2x});
                                dy2_diff = $signed({2'b00, best2_y}) - $signed({2'b00, p2y});
                                if (dx2_diff > 12'sd6)       begin p2_face_dx <=  3'sd1; p2_mirror <= 1'b0; p2_slash_dx <=  2'sd1; end
                                else if (dx2_diff < -12'sd6) begin p2_face_dx <= -3'sd1; p2_mirror <= 1'b1; p2_slash_dx <= -2'sd1; end
                                else                         begin p2_face_dx <=  3'sd0;                    p2_slash_dx <=  2'sd0; end
                                if (dy2_diff > 12'sd6)       begin p2_face_dy <=  3'sd1; p2_slash_dy <=  2'sd1; end
                                else if (dy2_diff < -12'sd6) begin p2_face_dy <= -3'sd1; p2_slash_dy <= -2'sd1; end
                                else                         begin p2_face_dy <=  3'sd0; p2_slash_dy <=  2'sd0; end
                            end else begin
                                p2_lunge_t <= 4'd3; p2_has_tgt <= 1'b0;
                                p2_slash_dx <= p2_face_dx[1:0]; p2_slash_dy <= p2_face_dy[1:0];
                            end
                        end else p2_fire_req <= 1'b0;

                        // Single Rectangular Arena Bounds (x=[84..550], y=[84..358], doorway x=564)
                        min_px = 11'd84;
                        max_px = ((room_phase == RP_DOOR) && (py >= 10'd192 && py <= 10'd256)) ? 11'd566 : 11'd548;

                        sx_tmp = $signed({2'b00, px}) + move_dx;
                        sy_tmp = $signed({3'b000, py}) + move_dy;
                        cand_px <= (sx_tmp < $signed({2'b00, min_px})) ? min_px : ((sx_tmp > $signed({2'b00, max_px})) ? max_px : sx_tmp[10:0]);
                        cand_py <= (sy_tmp < 13'sd84) ? 10'd84 : ((sy_tmp > 13'sd358) ? 10'd358 : sy_tmp[9:0]);

                        max_px = ((room_phase == RP_DOOR) && (p2y >= 10'd192 && p2y <= 10'd256)) ? 11'd566 : 11'd548;
                        sx_tmp = $signed({2'b00, p2x}) + p2_move_dx;
                        sy_tmp = $signed({3'b000, p2y}) + p2_move_dy;
                        if (p1_alive && p2_alive) begin
                            if (sx_tmp > $signed({2'b00, px}) + 13'sd430) sx_tmp = $signed({2'b00, px}) + 13'sd430;
                            else if (sx_tmp < $signed({2'b00, px}) - 13'sd430) sx_tmp = $signed({2'b00, px}) - 13'sd430;
                            if (sy_tmp > $signed({3'b000, py}) + 13'sd260) sy_tmp = $signed({3'b000, py}) + 13'sd260;
                            else if (sy_tmp < $signed({3'b000, py}) - 13'sd260) sy_tmp = $signed({3'b000, py}) - 13'sd260;
                        end
                        cand_p2x <= (sx_tmp < $signed({2'b00, min_px})) ? min_px : ((sx_tmp > $signed({2'b00, max_px})) ? max_px : sx_tmp[10:0]);
                        cand_p2y <= (sy_tmp < 13'sd84) ? 10'd84 : ((sy_tmp > 13'sd358) ? 10'd358 : sy_tmp[9:0]);

                        x_blocked <= 0; y_blocked <= 0; p2_x_blk <= 0; p2_y_blk <= 0;
                        map_addr_b <= tile_addr(px, py);
                        step_state <= 6'd1;
                    end
                end

                // ---- SEQUENTIAL TILEMAP COLLISION P1 (1..19) & P2 (20..38) ----
                6'd1: step_state <= 6'd2;
                6'd2: begin
                    cur_center_solid <= is_solid(map_tile_b, zone2_open, zone3_open, chrono_active);
                    if (p1_alive && map_tile_b == 4'd6 && shrine_cd == 0 && hp < 5'd24) begin
                        hp <= (hp >= 5'd20) ? 5'd24 : (hp + 5'd4); shrine_cd <= 8'd240; sfx_pickup <= 1'b1;
                    end
                    map_addr_b <= tile_addr(cand_px - 11'd5, py - 10'd4); step_state <= 6'd3;
                end
                6'd3: step_state <= 6'd4;
                6'd4: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) x_blocked <= 1; map_addr_b <= tile_addr(cand_px + 11'd5, py - 10'd4); step_state <= 6'd5; end
                6'd5: step_state <= 6'd6;
                6'd6: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) x_blocked <= 1; map_addr_b <= tile_addr(cand_px - 11'd5, py + 10'd6); step_state <= 6'd7; end
                6'd7: step_state <= 6'd8;
                6'd8: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) x_blocked <= 1; map_addr_b <= tile_addr(cand_px + 11'd5, py + 10'd6); step_state <= 6'd9; end
                6'd9: step_state <= 6'd10;
                6'd10: begin if ((!x_blocked && !is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) || cur_center_solid) px <= cand_px; map_addr_b <= tile_addr(px - 11'd5, cand_py - 10'd4); step_state <= 6'd11; end
                6'd11: step_state <= 6'd12;
                6'd12: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) y_blocked <= 1; map_addr_b <= tile_addr(px + 11'd5, cand_py - 10'd4); step_state <= 6'd13; end
                6'd13: step_state <= 6'd14;
                6'd14: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) y_blocked <= 1; map_addr_b <= tile_addr(px - 11'd5, cand_py + 10'd6); step_state <= 6'd15; end
                6'd15: step_state <= 6'd16;
                6'd16: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) y_blocked <= 1; map_addr_b <= tile_addr(px + 11'd5, cand_py + 10'd6); step_state <= 6'd17; end
                6'd17: step_state <= 6'd18;
                6'd18: begin
                    if ((!y_blocked && !is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) || cur_center_solid) py <= cand_py;
                    if (p2_active) begin map_addr_b <= tile_addr(p2x, p2y); step_state <= 6'd20; end
                    else step_state <= 6'd40;
                end

                6'd20: step_state <= 6'd21;
                6'd21: begin
                    p2_cur_solid <= is_solid(map_tile_b, zone2_open, zone3_open, chrono_active);
                    if (p2_alive && map_tile_b == 4'd6 && shrine_cd == 0 && hp2 < 5'd24) begin
                        hp2 <= (hp2 >= 5'd20) ? 5'd24 : (hp2 + 5'd4); shrine_cd <= 8'd240; sfx_pickup <= 1'b1;
                    end
                    map_addr_b <= tile_addr(cand_p2x - 11'd5, p2y - 10'd4); step_state <= 6'd22;
                end
                6'd22: step_state <= 6'd23;
                6'd23: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_x_blk <= 1; map_addr_b <= tile_addr(cand_p2x + 11'd5, p2y - 10'd4); step_state <= 6'd24; end
                6'd24: step_state <= 6'd25;
                6'd25: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_x_blk <= 1; map_addr_b <= tile_addr(cand_p2x - 11'd5, p2y + 10'd6); step_state <= 6'd26; end
                6'd26: step_state <= 6'd27;
                6'd27: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_x_blk <= 1; map_addr_b <= tile_addr(cand_p2x + 11'd5, p2y + 10'd6); step_state <= 6'd28; end
                6'd28: step_state <= 6'd29;
                6'd29: begin if ((!p2_x_blk && !is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) || p2_cur_solid) p2x <= cand_p2x; map_addr_b <= tile_addr(p2x - 11'd5, cand_p2y - 10'd4); step_state <= 6'd30; end
                6'd30: step_state <= 6'd31;
                6'd31: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_y_blk <= 1; map_addr_b <= tile_addr(p2x + 11'd5, cand_p2y - 10'd4); step_state <= 6'd32; end
                6'd32: step_state <= 6'd33;
                6'd33: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_y_blk <= 1; map_addr_b <= tile_addr(p2x - 11'd5, cand_p2y + 10'd6); step_state <= 6'd34; end
                6'd34: step_state <= 6'd35;
                6'd35: begin if (is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) p2_y_blk <= 1; map_addr_b <= tile_addr(p2x + 11'd5, cand_p2y + 10'd6); step_state <= 6'd36; end
                6'd36: step_state <= 6'd37;
                6'd37: begin if ((!p2_y_blk && !is_solid(map_tile_b, zone2_open, zone3_open, chrono_active)) || p2_cur_solid) p2y <= cand_p2y; step_state <= 6'd40; end

                // ---- STEP 40: SMOOTH BRAWLHALLA CAMERA, REVIVE, PET BOLT, SLASH CENTER, SPARKS ----
                6'd40: begin
                    // 60 Hz Fine-Grain Smooth Zoom (2.5 px/step, zero jump!)
                    if (target_zoom > zoom_lvl)
                        zoom_lvl <= (target_zoom - zoom_lvl > 7'd8) ? (zoom_lvl + 7'd2) : (zoom_lvl + 7'd1);
                    else if ((target_zoom + 7'd2 < zoom_lvl) || (target_zoom == 7'd0 && zoom_lvl > 7'd0))
                        zoom_lvl <= (zoom_lvl - target_zoom > 7'd8 && zoom_lvl >= 7'd2) ? (zoom_lvl - 7'd2) : (zoom_lvl - 7'd1);

                    if (p1_alive && p2_alive) begin next_x = ({1'b0, px} + {1'b0, p2x}) >> 1; next_y = ({1'b0, py} + {1'b0, p2y}) >> 1; end
                    else if (p2_alive)        begin next_x = p2x; next_y = p2y; end
                    else                      begin next_x = px;  next_y = py; end

                    if (view_w >= 10'd512)
                        t_cam_x = 11'd320 - {1'b0, view_w >> 1};
                    else begin
                        min_cx = 11'd48;
                        max_cx = 11'd592 - {1'b0, view_w};
                        t_cam_x = (next_x < (min_cx + {1'b0, view_w >> 1})) ? min_cx :
                                  ((next_x > (max_cx + {1'b0, view_w >> 1})) ? max_cx : (next_x - {1'b0, view_w >> 1}));
                    end
                    if (view_h >= 10'd320)
                        t_cam_y = 10'd224 - (view_h >> 1);
                    else begin
                        max_cy = 10'd400 - view_h;
                        t_cam_y = (next_y < (10'd48 + (view_h >> 1))) ? 10'd48 :
                                  ((next_y > (max_cy + (view_h >> 1))) ? max_cy : (next_y - (view_h >> 1)));
                    end

                    // Smooth Proportional Camera Follow (1..8 px/frame)
                    if (cam_x < t_cam_x) begin
                        d1_m = ({1'b0, t_cam_x} - {1'b0, cam_x}) >> 3;
                        cam_x <= cam_x + ((d1_m == 0) ? 11'd1 : ((d1_m > 12'd8) ? 11'd8 : d1_m[10:0]));
                    end else if (t_cam_x < cam_x) begin
                        d1_m = ({1'b0, cam_x} - {1'b0, t_cam_x}) >> 3;
                        cam_x <= cam_x - ((d1_m == 0) ? 11'd1 : ((d1_m > 12'd8) ? 11'd8 : d1_m[10:0]));
                    end
                    if (cam_y < t_cam_y) begin
                        d2_m = ({2'b00, t_cam_y} - {2'b00, cam_y}) >> 3;
                        cam_y <= cam_y + ((d2_m == 0) ? 10'd1 : ((d2_m > 12'd8) ? 10'd8 : d2_m[9:0]));
                    end else if (t_cam_y < cam_y) begin
                        d2_m = ({2'b00, cam_y} - {2'b00, t_cam_y}) >> 3;
                        cam_y <= cam_y - ((d2_m == 0) ? 10'd1 : ((d2_m > 12'd8) ? 10'd8 : d2_m[9:0]));
                    end

                    // 2P dead partner stays down on floor until surviving player clears the wave!
                    revive_prog <= 5'd0;

                    sx_tmp = $signed({2'b00, px}) + (p1_slash_dx * 13'sd16);
                    sy_tmp = $signed({3'b000, py}) + (p1_slash_dy * 13'sd16);
                    p1_slash_x <= (sx_tmp < 13'sd16) ? 11'd16 : ((sx_tmp > 13'sd2031) ? 11'd2031 : sx_tmp[10:0]);
                    p1_slash_y <= (sy_tmp < 13'sd16) ? 10'd16 : ((sy_tmp > 13'sd1007) ? 10'd1007 : sy_tmp[9:0]);

                    sx_tmp = $signed({2'b00, p2x}) + (p2_slash_dx * 13'sd16);
                    sy_tmp = $signed({3'b000, p2y}) + (p2_slash_dy * 13'sd16);
                    p2_slash_x <= (sx_tmp < 13'sd16) ? 11'd16 : ((sx_tmp > 13'sd2031) ? 11'd2031 : sx_tmp[10:0]);
                    p2_slash_y <= (sy_tmp < 13'sd16) ? 10'd16 : ((sy_tmp > 13'sd1007) ? 10'd1007 : sy_tmp[9:0]);

                    if (pet_active) begin
                        if (pet_b_act) begin
                            if (pet_bx < 11'd24 || pet_bx > 11'd2020 || pet_by < 10'd24 || pet_by > 10'd1000) pet_b_act <= 0;
                            else begin pet_bx <= $signed({1'b0, pet_bx}) + pet_bvx; pet_by <= $signed({1'b0, pet_by}) + pet_bvy; end
                        end else if (pet_fire_cd == 0 && ((p1_alive && best1_valid) || (!p1_alive && p2_alive && best2_valid))) begin
                            pet_fire_cd <= 7'd65; pet_b_act <= 1'b1;
                            pet_bx <= (p1_alive ? px : p2x) - 11'd16; pet_by <= (p1_alive ? py : p2y) - 10'd10;
                            dx_diff = $signed({1'b0, p1_alive ? best1_x : best2_x}) - $signed({1'b0, (p1_alive ? px : p2x) - 11'd16});
                            dy_diff = $signed({2'b00, p1_alive ? best1_y : best2_y}) - $signed({2'b00, (p1_alive ? py : p2y) - 10'd10});
                            pet_bvx <= (dx_diff > 12'sd12) ? 5'sd5 : ((dx_diff < -12'sd12) ? -5'sd5 : 5'sd0);
                            pet_bvy <= (dy_diff > 12'sd12) ? 5'sd5 : ((dy_diff < -12'sd12) ? -5'sd5 : 5'sd0);
                        end else if (pet_fire_cd > 0) pet_fire_cd <= pet_fire_cd - 7'd1;
                    end

                    for (idx = 0; idx < 12; idx = idx + 1) begin
                        if (sp_t[idx] > 0) begin
                            sp_t[idx] <= sp_t[idx] - 5'd1;
                            sp_x[idx] <= $signed({1'b0, sp_x[idx]}) + sp_vx[idx];
                            sp_y[idx] <= $signed({1'b0, sp_y[idx]}) + sp_vy[idx];
                        end
                    end

                    if (world_tick) begin
                        if (sky_drop_timer >= 9'd260) begin
                            sky_drop_timer <= 0;
                            if (!drop_active[2]) begin
                                drop_active[2] <= 1; drop_z[2] <= 7'd96; drop_boom[2] <= 0;
                                drop_x[2] <= (px < 11'd1960) ? (px + 11'd56) : (px - 11'd56); drop_y[2] <= py; drop_type[2] <= 2'd2;
                            end else if (!drop_active[3]) begin
                                drop_active[3] <= 1; drop_z[3] <= 7'd96; drop_boom[3] <= 0;
                                drop_x[3] <= (px > 11'd140 && !boss_locked) ? (px - 11'd60) : (px + 11'd60);
                                drop_y[3] <= (py > 10'd140) ? (py - 10'd50) : (py + 10'd50); drop_type[3] <= 2'd1;
                            end
                        end else sky_drop_timer <= sky_drop_timer + 9'd1;
                    end

                    step_state <= 6'd41;
                end

                // ---- STEP 41: MAGNETIC BLUE GEMS, SKY DROPS & UPGRADE CUTSCENES ----
                6'd41: begin
                    next_exp = exp;
                    for (idx = 0; idx < 12; idx = idx + 1) begin
                        if (col_alive[idx]) begin
                            // Magnet Pull when within 76px (or anytime no enemies left!)
                            dx_diff = $signed({1'b0, px}) - $signed({1'b0, col_x[idx]});
                            dy_diff = $signed({2'b00, py}) - $signed({2'b00, col_y[idx]});
                            if (p1_alive && ((dx_diff > -12'sd76 && dx_diff < 12'sd76 && dy_diff > -12'sd76 && dy_diff < 12'sd76) || enemies_left == 0)) begin
                                if (col_x[idx] + 11'd2 < px) col_x[idx] <= col_x[idx] + 11'd2;
                                else if (px + 11'd2 < col_x[idx]) col_x[idx] <= col_x[idx] - 11'd2;
                                if (col_y[idx] + 10'd2 < py) col_y[idx] <= col_y[idx] + 10'd2;
                                else if (py + 10'd2 < col_y[idx]) col_y[idx] <= col_y[idx] - 10'd2;
                            end

                            if (p1_alive && (px + 14 > col_x[idx] && px < col_x[idx] + 14) && (py + 14 > col_y[idx] && py < col_y[idx] + 14)) begin
                                col_alive[idx] <= 0; sfx_pickup <= 1;
                                if (col_type[idx] == 0) begin next_exp = (next_exp + 6'd5 > 6'd63) ? 6'd63 : (next_exp + 6'd5); add_score(10'd25); end
                                else begin if (hp < 5'd24) hp <= ({1'b0, hp} + 6'd8 > 6'd24) ? 5'd24 : (hp + 5'd8); add_score(10'd50); end
                            end else if (p2_alive && (p2x + 14 > col_x[idx] && p2x < col_x[idx] + 14) && (p2y + 14 > col_y[idx] && p2y < col_y[idx] + 14)) begin
                                col_alive[idx] <= 0; sfx_pickup <= 1;
                                if (col_type[idx] == 0) begin next_exp = (next_exp + 6'd5 > 6'd63) ? 6'd63 : (next_exp + 6'd5); add_score(10'd25); end
                                else begin if (hp2 < 5'd24) hp2 <= ({1'b0, hp2} + 6'd8 > 6'd24) ? 5'd24 : (hp2 + 5'd8); add_score(10'd50); end
                            end
                        end
                    end

                    for (idx = 0; idx < 4; idx = idx + 1) begin
                        if (drop_boom[idx] > 0) drop_boom[idx] <= drop_boom[idx] - 5'd1;
                        if (drop_active[idx]) begin
                            if (drop_z[idx] > 0) drop_z[idx] <= drop_z[idx] - 7'd1;
                            else if (drop_type[idx] == 2'd2) begin
                                drop_active[idx] <= 0; drop_boom[idx] <= 5'd20; sfx_hit <= 1; shake_mag <= 4'd5;
                                if (p1_alive && invuln_timer == 0 && (px + 20 > drop_x[idx] && px < drop_x[idx] + 20) && (py + 20 > drop_y[idx] && py < drop_y[idx] + 20)) begin
                                    invuln_timer <= 6'd60; p1_ooc_t <= 9'd0; p1_regen_div <= 6'd0; combo_cnt <= combo_cnt >> 1;
                                    if (hp <= 5'd4) begin hp <= 0; if (!p2_alive) begin game_state <= ST_LOSE; end_lockout <= 7'd90; end end
                                    else hp <= hp - 5'd4;
                                end
                                if (p2_alive && p2_invuln == 0 && (p2x + 20 > drop_x[idx] && p2x < drop_x[idx] + 20) && (p2y + 20 > drop_y[idx] && p2y < drop_y[idx] + 20)) begin
                                    p2_invuln <= 6'd60; p2_ooc_t <= 9'd0; p2_regen_div <= 6'd0; combo_cnt <= combo_cnt >> 1;
                                    if (hp2 <= 5'd4) begin hp2 <= 0; if (!(p1_alive && hp > 5'd4)) begin game_state <= ST_LOSE; end_lockout <= 7'd90; end end
                                    else hp2 <= hp2 - 5'd4;
                                end
                            end else if ((p1_alive && (px + 16 > drop_x[idx] && px < drop_x[idx] + 16) && (py + 16 > drop_y[idx] && py < drop_y[idx] + 16)) ||
                                         (p2_alive && (p2x + 16 > drop_x[idx] && p2x < drop_x[idx] + 16) && (p2y + 16 > drop_y[idx] && p2y < drop_y[idx] + 16))) begin
                                drop_active[idx] <= 0; sfx_pickup <= 1;
                                next_exp = (next_exp + 6'd10 > 6'd63) ? 6'd63 : (next_exp + 6'd10);
                                if (drop_type[idx] == 2'd0) begin
                                    if (p1_alive) hp <= ({1'b0, hp} + 6'd8 > 6'd24) ? 5'd24 : (hp + 5'd8);
                                    if (p2_active && p2_alive) hp2 <= ({1'b0, hp2} + 6'd8 > 6'd24) ? 5'd24 : (hp2 + 5'd8);
                                    chrono_energy <= 7'd100; add_score(10'd100);
                                end else add_score(10'd50);
                            end
                        end
                    end

                    evolved_now = 1'b0;
                    if      (stage == 2'd0 && next_exp >= 6'd10) begin stage <= 2'd1; evolved_now = 1; end
                    else if (stage == 2'd1 && next_exp >= 6'd25) begin stage <= 2'd2; evolved_now = 1; end
                    else if (stage == 2'd2 && next_exp >= 6'd45) begin stage <= 2'd3; evolved_now = 1; if (p1_alive) hp <= 5'd24; if (p2_alive) hp2 <= 5'd24; end
                    exp <= next_exp;
                    if (evolved_now && game_state == ST_PLAY) begin
                        // Seamless real-time evolution (NO cutscene pause!)
                        evolve_flash <= 5'd24; sfx_evolve <= 1'b1; add_score(10'd100);
                    end

                    step_state <= 6'd42;
                end

                // ---- STEP 42: PREPARE TIME-MULTIPLEXED 16-ENEMY + LIMITED MELEE LOCK-ON ----
                6'd42: begin
                    best1_valid <= 0; best1_d <= 12'd72; best1_x <= px; best1_y <= py;
                    best2_valid <= 0; best2_d <= 12'd72; best2_x <= p2x; best2_y <= p2y;
                    gun1_valid  <= 0; gun1_d  <= 12'd240; gun1_x <= px; gun1_y <= py;
                    gun2_valid  <= 0; gun2_d  <= 12'd240; gun2_x <= p2x; gun2_y <= p2y;
                    tdmg1_acc   <= 0; tdmg2_acc <= 0;
                    e_idx       <= 4'd0;
                    step_state  <= 6'd43;
                end

                // ---- STEP 43: PROCESS 1 ENEMY PER CLOCK (e_idx = 0..15) -> TINY TIMING! ----
                6'd43: begin
                    if (en_alive[e_idx]) begin
                        dx_diff  = $signed({1'b0, px})  - $signed({1'b0, en_x[e_idx]});
                        dy_diff  = $signed({2'b00, py}) - $signed({2'b00, en_y[e_idx]});
                        dx2_diff = $signed({1'b0, p2x}) - $signed({1'b0, en_x[e_idx]});
                        dy2_diff = $signed({2'b00, p2y}) - $signed({2'b00, en_y[e_idx]});
                        d1_m = (dx_diff < 0 ? -dx_diff : dx_diff) + (dy_diff < 0 ? -dy_diff : dy_diff);
                        d2_m = (dx2_diff < 0 ? -dx2_diff : dx2_diff) + (dy2_diff < 0 ? -dy2_diff : dy2_diff);

                        // Lock-On Running Min Update (Melee <=72px, Gun Auto-Aim <=240px)
                        if (d1_m < best1_d) begin best1_valid <= 1'b1; best1_d <= d1_m; best1_x <= en_x[e_idx]; best1_y <= en_y[e_idx]; end
                        if (d2_m < best2_d) begin best2_valid <= 1'b1; best2_d <= d2_m; best2_x <= en_x[e_idx]; best2_y <= en_y[e_idx]; end
                        if (d1_m < gun1_d)  begin gun1_valid  <= 1'b1; gun1_d  <= d1_m; gun1_x  <= en_x[e_idx]; gun1_y  <= en_y[e_idx]; gun1_idx <= {1'b0, e_idx}; end
                        if (d2_m < gun2_d)  begin gun2_valid  <= 1'b1; gun2_d  <= d2_m; gun2_x  <= en_x[e_idx]; gun2_y  <= en_y[e_idx]; gun2_idx <= {1'b0, e_idx}; end

                        // Enemy AI Move & Ranged Bolt
                        if (world_tick) begin
                            if (p2_alive && (!p1_alive || d2_m < d1_m)) begin next_x = p2x; next_y = p2y; end
                            else                                         begin next_x = px;  next_y = py; end
                            if ((p2_alive && (!p1_alive || d2_m < d1_m) ? d2_m : d1_m) < 12'd420) begin
                                if ((en_type[e_idx] != 3'd1 && en_type[e_idx] != 3'd6) || (dx_diff > 12'sd90 || dx_diff < -12'sd90)) begin
                                    if (next_x > en_x[e_idx] + 2) en_x[e_idx] <= en_x[e_idx] + 11'd1;
                                    else if (next_x + 2 < en_x[e_idx]) en_x[e_idx] <= en_x[e_idx] - 11'd1;
                                    if (next_y > en_y[e_idx] + 2) en_y[e_idx] <= en_y[e_idx] + 10'd1;
                                    else if (next_y + 2 < en_y[e_idx]) en_y[e_idx] <= en_y[e_idx] - 10'd1;
                                end
                                if (en_type[e_idx] == 3'd1 || en_type[e_idx] == 3'd5 || en_type[e_idx] == 3'd6) begin
                                    if (en_cd[e_idx] == 0) begin
                                        en_cd[e_idx] <= (wave >= 4'd4) ? 8'd45 : 8'd65;
                                        if (!eb_active[0]) begin
                                            eb_active[0]<=1; eb_x[0]<=en_x[e_idx]; eb_y[0]<=en_y[e_idx];
                                            eb_vx[0]<=(next_x>en_x[e_idx]+12)?5'sd3:((next_x+12<en_x[e_idx])?-5'sd3:5'sd0);
                                            eb_vy[0]<=(next_y>en_y[e_idx]+12)?5'sd3:((next_y+12<en_y[e_idx])?-5'sd3:5'sd0);
                                        end else if (!eb_active[1]) begin
                                            eb_active[1]<=1; eb_x[1]<=en_x[e_idx]; eb_y[1]<=en_y[e_idx];
                                            eb_vx[1]<=(next_x>en_x[e_idx]+12)?5'sd3:((next_x+12<en_x[e_idx])?-5'sd3:5'sd0);
                                            eb_vy[1]<=(next_y>en_y[e_idx]+12)?5'sd3:((next_y+12<en_y[e_idx])?-5'sd3:5'sd0);
                                        end
                                    end else en_cd[e_idx] <= en_cd[e_idx] - 8'd1;
                                end
                            end
                        end

                        // Shared Melee Hitboxes + Pet Bolt + Orbit Swords + Contact Damage!
                        if (p1_alive && p1_slash_t > 4'd1 && !p1_hit_mask[e_idx] &&
                            ($signed({1'b0, en_x[e_idx]}) >= $signed({1'b0, p1_slash_x}) - $signed({1'b0, reach1_eff})) &&
                            ($signed({1'b0, en_x[e_idx]}) <= $signed({1'b0, p1_slash_x}) + $signed({1'b0, reach1_eff})) &&
                            ($signed({2'b00, en_y[e_idx]}) >= $signed({2'b00, p1_slash_y}) - $signed({2'b00, reach1_eff})) &&
                            ($signed({2'b00, en_y[e_idx]}) <= $signed({2'b00, p1_slash_y}) + $signed({2'b00, reach1_eff}))) begin
                            p1_hit_mask[e_idx] <= 1'b1; sfx_hit <= 1'b1;
                            if (combo_cnt < 7'd99) combo_cnt <= combo_cnt + 7'd1;
                            combo_timer <= 8'd180;
                            if (p1_nova) shake_mag <= 4'd4;
                            if (en_hp[e_idx] <= dmg1_eff) begin
                                en_alive[e_idx] <= 0; en_hp[e_idx] <= 0; add_score(10'd50);
                                if (!col_alive[col_slot_e]) begin
                                    col_alive[col_slot_e] <= 1; col_x[col_slot_e] <= en_x[e_idx]; col_y[col_slot_e] <= en_y[e_idx];
                                    col_type[col_slot_e]  <= ((hp <= 5'd10 || (p2_active && hp2 <= 5'd10)) && e_idx[2:0] == 3'd0 && frame_cnt[1:0] == 2'd0) ? 1'b1 : 1'b0;
                                end
                            end else begin
                                en_hp[e_idx] <= en_hp[e_idx] - dmg1_eff;
                                sx_tmp = $signed({2'b00, en_x[e_idx]}) + (p1_slash_dx * 13'sd9);
                                sy_tmp = $signed({3'b000, en_y[e_idx]}) + (p1_slash_dy * 13'sd9);
                                en_x[e_idx] <= (sx_tmp < 13'sd32) ? 11'd32 : ((sx_tmp > 13'sd2010) ? 11'd2010 : sx_tmp[10:0]);
                                en_y[e_idx] <= (sy_tmp < 13'sd32) ? 10'd32 : ((sy_tmp > 13'sd980)  ? 10'd980  : sy_tmp[9:0]);
                            end
                        end else if (p2_alive && p2_slash_t > 4'd1 && !p2_hit_mask[e_idx] &&
                            ($signed({1'b0, en_x[e_idx]}) >= $signed({1'b0, p2_slash_x}) - $signed({1'b0, reach2_eff})) &&
                            ($signed({1'b0, en_x[e_idx]}) <= $signed({1'b0, p2_slash_x}) + $signed({1'b0, reach2_eff})) &&
                            ($signed({2'b00, en_y[e_idx]}) >= $signed({2'b00, p2_slash_y}) - $signed({2'b00, reach2_eff})) &&
                            ($signed({2'b00, en_y[e_idx]}) <= $signed({2'b00, p2_slash_y}) + $signed({2'b00, reach2_eff}))) begin
                            p2_hit_mask[e_idx] <= 1'b1; sfx_hit <= 1'b1;
                            if (combo_cnt < 7'd99) combo_cnt <= combo_cnt + 7'd1;
                            combo_timer <= 8'd180;
                            if (p2_nova) shake_mag <= 4'd4;
                            if (en_hp[e_idx] <= dmg2_eff) begin
                                en_alive[e_idx] <= 0; en_hp[e_idx] <= 0; add_score(10'd50);
                                if (!col_alive[col_slot_e]) begin
                                    col_alive[col_slot_e] <= 1; col_x[col_slot_e] <= en_x[e_idx]; col_y[col_slot_e] <= en_y[e_idx];
                                    col_type[col_slot_e]  <= ((hp <= 5'd10 || (p2_active && hp2 <= 5'd10)) && e_idx[2:0] == 3'd0 && frame_cnt[1:0] == 2'd0) ? 1'b1 : 1'b0;
                                end
                            end else begin
                                en_hp[e_idx] <= en_hp[e_idx] - dmg2_eff;
                                sx_tmp = $signed({2'b00, en_x[e_idx]}) + (p2_slash_dx * 13'sd9);
                                sy_tmp = $signed({3'b000, en_y[e_idx]}) + (p2_slash_dy * 13'sd9);
                                en_x[e_idx] <= (sx_tmp < 13'sd32) ? 11'd32 : ((sx_tmp > 13'sd2010) ? 11'd2010 : sx_tmp[10:0]);
                                en_y[e_idx] <= (sy_tmp < 13'sd32) ? 10'd32 : ((sy_tmp > 13'sd980)  ? 10'd980  : sy_tmp[9:0]);
                            end
                        end else if (pet_b_act &&
                            ($signed({1'b0, en_x[e_idx]}) >= $signed({1'b0, pet_bx}) - 12'sd14) &&
                            ($signed({1'b0, en_x[e_idx]}) <= $signed({1'b0, pet_bx}) + 12'sd14) &&
                            ($signed({2'b00, en_y[e_idx]}) >= $signed({2'b00, pet_by}) - 12'sd14) &&
                            ($signed({2'b00, en_y[e_idx]}) <= $signed({2'b00, pet_by}) + 12'sd14)) begin
                            pet_b_act <= 0; sfx_hit <= 1;
                            if (en_hp[e_idx] <= 4'd1) begin
                                en_alive[e_idx] <= 0; en_hp[e_idx] <= 0; add_score(10'd50);
                                if (!col_alive[col_slot_e]) begin col_alive[col_slot_e]<=1; col_x[col_slot_e]<=en_x[e_idx]; col_y[col_slot_e]<=en_y[e_idx]; col_type[col_slot_e]<=0; end
                            end else en_hp[e_idx] <= en_hp[e_idx] - 4'd1;
                        end else if (blades_active && frame_cnt[4:0] == 5'd0 && (
                            (p1_alive && (
                                ((blade0_x+14 > en_x[e_idx] && blade0_x < en_x[e_idx]+14) && (blade0_y+14 > en_y[e_idx] && blade0_y < en_y[e_idx]+14)) ||
                                ((blade1_x+14 > en_x[e_idx] && blade1_x < en_x[e_idx]+14) && (blade1_y+14 > en_y[e_idx] && blade1_y < en_y[e_idx]+14)))) ||
                            (p2_alive && (
                                ((p2_blade0_x+14 > en_x[e_idx] && p2_blade0_x < en_x[e_idx]+14) && (p2_blade0_y+14 > en_y[e_idx] && p2_blade0_y < en_y[e_idx]+14)) ||
                                ((p2_blade1_x+14 > en_x[e_idx] && p2_blade1_x < en_x[e_idx]+14) && (p2_blade1_y+14 > en_y[e_idx] && p2_blade1_y < en_y[e_idx]+14)))))) begin
                            sfx_hit <= 1;
                            if (en_hp[e_idx] <= 4'd1) begin
                                en_alive[e_idx] <= 0; en_hp[e_idx] <= 0; add_score(10'd50);
                                if (!col_alive[col_slot_e]) begin col_alive[col_slot_e]<=1; col_x[col_slot_e]<=en_x[e_idx]; col_y[col_slot_e]<=en_y[e_idx]; col_type[col_slot_e]<=0; end
                            end else en_hp[e_idx] <= en_hp[e_idx] - 4'd1;
                        end else begin
                            // Player Blue Gun Bullets (pb_active[0..7]) vs Enemy (single hit resolution)
                            pb_hit_found = 1'b0; pb_hit_idx = 3'd0;
                            for (idx = 0; idx < 8; idx = idx + 1) begin
                                if (!pb_hit_found && pb_active[idx] &&
                                    ($signed({1'b0, en_x[e_idx]}) >= $signed({1'b0, pb_x[idx]}) - 12'sd14) &&
                                    ($signed({1'b0, en_x[e_idx]}) <= $signed({1'b0, pb_x[idx]}) + 12'sd14) &&
                                    ($signed({2'b00, en_y[e_idx]}) >= $signed({2'b00, pb_y[idx]}) - 12'sd14) &&
                                    ($signed({2'b00, en_y[e_idx]}) <= $signed({2'b00, pb_y[idx]}) + 12'sd14)) begin
                                    pb_hit_found = 1'b1;
                                    pb_hit_idx   = idx[2:0];
                                end
                            end
                            if (pb_hit_found) begin
                                pb_active[pb_hit_idx] <= 1'b0; sfx_hit <= 1'b1;
                                spawn_sparks(en_x[e_idx], en_y[e_idx]);
                                if (en_hp[e_idx] <= 4'd2) begin
                                    en_alive[e_idx] <= 0; en_hp[e_idx] <= 0; add_score(10'd50);
                                    if (!col_alive[col_slot_e]) begin
                                        col_alive[col_slot_e] <= 1; col_x[col_slot_e] <= en_x[e_idx]; col_y[col_slot_e] <= en_y[e_idx];
                                        col_type[col_slot_e]  <= ((hp <= 5'd12 || (p2_active && hp2 <= 5'd12)) && e_idx[0]) ? 1'b1 : 1'b0;
                                    end
                                end else en_hp[e_idx] <= en_hp[e_idx] - 4'd2;
                            end
                        end

                        if (game_state == ST_PLAY) begin
                            if (p1_alive && invuln_timer == 0 && (px+14 > en_x[e_idx] && px < en_x[e_idx]+14) && (py+14 > en_y[e_idx] && py < en_y[e_idx]+14))
                                tdmg1_acc <= 1'b1;
                            if (p2_alive && p2_invuln == 0 && (p2x+14 > en_x[e_idx] && p2x < en_x[e_idx]+14) && (p2y+14 > en_y[e_idx] && p2y < en_y[e_idx]+14))
                                tdmg2_acc <= 1'b1;
                        end
                    end

                    if (e_idx == 4'd15) step_state <= 6'd44;
                    else                e_idx      <= e_idx + 4'd1;
                end

                // ---- STEP 44: BOSS LOCK-ON, 3 UNIQUE BOSS AI, 10-WAVE PROGRESSION & DAMAGE ----
                6'd44: begin
                    // Compare Boss for Lock-On Reticle
                    if (boss_active && boss_hp > 0) begin
                        dx_diff  = $signed({1'b0, boss_x}) - $signed({1'b0, px});
                        dy_diff  = $signed({2'b00, boss_y}) - $signed({2'b00, py});
                        dx2_diff = $signed({1'b0, boss_x}) - $signed({1'b0, p2x});
                        dy2_diff = $signed({2'b00, boss_y}) - $signed({2'b00, p2y});
                        d1_m = (dx_diff < 0 ? -dx_diff : dx_diff) + (dy_diff < 0 ? -dy_diff : dy_diff);
                        d2_m = (dx2_diff < 0 ? -dx2_diff : dx2_diff) + (dy2_diff < 0 ? -dy2_diff : dy2_diff);
                        lock_valid <= p1_alive ? ((d1_m <= 12'd96 && d1_m < best1_d + 12'd16) || best1_valid) : ((d2_m <= 12'd96 && d2_m < best2_d + 12'd16) || best2_valid);
                        lock_x     <= p1_alive ? ((d1_m <= 12'd96 && d1_m < best1_d + 12'd16) ? boss_x : best1_x) : ((d2_m <= 12'd96 && d2_m < best2_d + 12'd16) ? boss_x : best2_x);
                        lock_y     <= p1_alive ? ((d1_m <= 12'd96 && d1_m < best1_d + 12'd16) ? boss_y : best1_y) : ((d2_m <= 12'd96 && d2_m < best2_d + 12'd16) ? boss_y : best2_y);
                        if (d1_m <= 12'd96 && d1_m < best1_d + 12'd16) begin best1_valid <= 1'b1; best1_x <= boss_x; best1_y <= boss_y; end
                        if (d2_m <= 12'd96 && d2_m < best2_d + 12'd16) begin best2_valid <= 1'b1; best2_x <= boss_x; best2_y <= boss_y; end
                        if (d1_m < gun1_d) begin gun1_valid <= 1'b1; gun1_d <= d1_m; gun1_x <= boss_x; gun1_y <= boss_y; gun1_idx <= 5'd16; end
                        if (d2_m < gun2_d) begin gun2_valid <= 1'b1; gun2_d <= d2_m; gun2_x <= boss_x; gun2_y <= boss_y; gun2_idx <= 5'd16; end
                    end else begin
                        lock_valid <= p1_alive ? best1_valid : best2_valid;
                        lock_x     <= p1_alive ? best1_x     : best2_x;
                        lock_y     <= p1_alive ? best1_y     : best2_y;
                    end

                    // Update 8 Enemy Bullets & 8 Player Gun Bullets (100% Single-Target Lock-On Homing!)
                    if (world_tick) begin
                        for (idx = 0; idx < 8; idx = idx + 1) begin
                            if (eb_active[idx]) begin
                                if (eb_x[idx] < 11'd80 || eb_x[idx] > 11'd560 || eb_y[idx] < 10'd80 || eb_y[idx] > 10'd368)
                                    eb_active[idx] <= 0;
                                else begin
                                    eb_x[idx] <= $signed({1'b0, eb_x[idx]}) + eb_vx[idx];
                                    eb_y[idx] <= $signed({1'b0, eb_y[idx]}) + eb_vy[idx];
                                end
                            end
                        end
                    end
                    for (idx = 0; idx < 8; idx = idx + 1) begin
                        if (pb_active[idx]) begin
                            if (pb_x[idx] < 11'd80 || pb_x[idx] > 11'd560 || pb_y[idx] < 10'd80 || pb_y[idx] > 10'd368) begin
                                pb_active[idx] <= 1'b0; pb_homing[idx] <= 1'b0;
                            end else if (pb_homing[idx] &&
                                         ((pb_tgt[idx] < 5'd16 && en_alive[pb_tgt[idx][3:0]]) ||
                                          (pb_tgt[idx] == 5'd16 && boss_active && boss_hp > 0))) begin
                                next_x = (pb_tgt[idx] == 5'd16) ? boss_x : en_x[pb_tgt[idx][3:0]];
                                next_y = (pb_tgt[idx] == 5'd16) ? boss_y : en_y[pb_tgt[idx][3:0]];
                                gdx = $signed({1'b0, next_x}) - $signed({1'b0, pb_x[idx]});
                                gdy = $signed({2'b00, next_y}) - $signed({2'b00, pb_y[idx]});
                                agx = (gdx < 0) ? -gdx : gdx;
                                agy = (gdy < 0) ? -gdy : gdy;
                                pb_x[idx] <= (agx <= 12'd6) ? next_x : ((gdx >= 0) ? (pb_x[idx] + 11'd6) : (pb_x[idx] - 11'd6));
                                pb_y[idx] <= (agy <= 12'd6) ? next_y : ((gdy >= 0) ? (pb_y[idx] + 10'd6) : (pb_y[idx] - 10'd6));
                                if (agx > (agy << 1))      pb_dir[idx] <= 2'd0;
                                else if (agy > (agx << 1)) pb_dir[idx] <= 2'd1;
                                else                       pb_dir[idx] <= ((gdx >= 0) == (gdy >= 0)) ? 2'd2 : 2'd3;
                            end else begin
                                pb_x[idx] <= $signed({1'b0, pb_x[idx]}) + pb_vx[idx];
                                pb_y[idx] <= $signed({1'b0, pb_y[idx]}) + pb_vy[idx];
                            end
                        end
                    end

                    // Boss AI (HARDCORE! Fast Dual-Axis Chase, Multi-Pattern Attacks, 8-Minion Summons!)
                    if (boss_active && boss_hp > 0) begin
                        if (world_tick) begin
                            boss_ai_timer <= boss_ai_timer + 8'd1;
                            next_x = p1_alive ? px : p2x;
                            next_y = p1_alive ? py : p2y;
                            if (p1_alive && p2_alive) begin
                                dx_diff  = $signed({1'b0, px})  - $signed({1'b0, boss_x});
                                dy_diff  = $signed({2'b00, py}) - $signed({2'b00, boss_y});
                                dx2_diff = $signed({1'b0, p2x}) - $signed({1'b0, boss_x});
                                dy2_diff = $signed({2'b00, p2y}) - $signed({2'b00, boss_y});
                                if (((dx2_diff < 0 ? -dx2_diff : dx2_diff) + (dy2_diff < 0 ? -dy2_diff : dy2_diff)) <
                                    ((dx_diff  < 0 ? -dx_diff  : dx_diff)  + (dy_diff  < 0 ? -dy_diff  : dy_diff))) begin
                                    next_x = p2x; next_y = p2y;
                                end
                            end

                            // Balanced Dual-Axis Chase (Form 0: 1 px, Form 1: 1..2 px, Form 2: 2 px!)
                            if (next_x > boss_x + 11'd3 && boss_x < 11'd528)
                                boss_x <= boss_x + ((boss_kind == 2'd2) ? (boss_enraged && frame_cnt[0] ? 11'd3 : 11'd2) : ((boss_kind == 2'd1 && boss_enraged) ? 11'd2 : (frame_cnt[0] || boss_kind == 2'd1 ? 11'd1 : 11'd0)));
                            else if (next_x + 11'd3 < boss_x && boss_x > 11'd100)
                                boss_x <= boss_x - ((boss_kind == 2'd2) ? (boss_enraged && frame_cnt[0] ? 11'd3 : 11'd2) : ((boss_kind == 2'd1 && boss_enraged) ? 11'd2 : (frame_cnt[0] || boss_kind == 2'd1 ? 11'd1 : 11'd0)));

                            if (next_y > boss_y + 10'd3 && boss_y < 10'd340)
                                boss_y <= boss_y + ((boss_kind == 2'd2) ? (boss_enraged && frame_cnt[0] ? 10'd3 : 10'd2) : ((boss_kind == 2'd1 && boss_enraged) ? 10'd2 : (frame_cnt[0] || boss_kind == 2'd1 ? 10'd1 : 10'd0)));
                            else if (next_y + 10'd3 < boss_y && boss_y > 10'd100)
                                boss_y <= boss_y - ((boss_kind == 2'd2) ? (boss_enraged && frame_cnt[0] ? 10'd3 : 10'd2) : ((boss_kind == 2'd1 && boss_enraged) ? 10'd2 : (frame_cnt[0] || boss_kind == 2'd1 ? 10'd1 : 10'd0)));

                            // Meteor Strike on Target Player
                            if ((boss_ai_timer == 8'd70 || boss_ai_timer == 8'd150 || boss_ai_timer == 8'd220 || (boss_enraged && boss_ai_timer == 8'd35)) && !drop_active[2]) begin
                                drop_active[2] <= 1'b1; drop_x[2] <= next_x; drop_y[2] <= next_y;
                                drop_z[2] <= 7'd55; drop_type[2] <= 2'd2; drop_boom[2] <= 5'd0;
                            end

                            // Boss Summons 8 Minions around the arena when empty!
                            if ((boss_ai_timer == 8'd80 || boss_ai_timer == 8'd190) && en_alive_vec == 16'b0) begin
                                set_en(0, 11'd140, 10'd110, 3'd3, 2'd3, 4'd10, 12);
                                set_en(1, 11'd140, 10'd330, 3'd7, 2'd3, 4'd10, 18);
                                set_en(2, 11'd500, 10'd110, 3'd1, 2'd3, 4'd10, 24);
                                set_en(3, 11'd500, 10'd330, 3'd5, 2'd3, 4'd10, 30);
                                set_en(4, 11'd320, 10'd105, 3'd6, 2'd3, 4'd10, 36);
                                set_en(5, 11'd320, 10'd335, 3'd4, 2'd3, 4'd10, 42);
                                set_en(6, 11'd160, 10'd224, 3'd2, 2'd3, 4'd10, 48);
                                set_en(7, 11'd480, 10'd224, 3'd0, 2'd3, 4'd10, 54);
                            end

                            // Multi-Pattern Rapid Barrages (Aimed + 8-Way + Cross)
                            if (boss_ai_timer == 8'd30 || boss_ai_timer == 8'd65 || boss_ai_timer == 8'd100 ||
                                boss_ai_timer == 8'd135 || boss_ai_timer == 8'd170 || boss_ai_timer == 8'd205 || boss_ai_timer == 8'd240) begin
                                eb_active[2]<=1; eb_x[2]<=boss_x; eb_y[2]<=boss_y;
                                eb_vx[2]<=(next_x>boss_x+10)?5'sd4:((next_x+10<boss_x)?-5'sd4:5'sd0);
                                eb_vy[2]<=(next_y>boss_y+10)?5'sd4:((next_y+10<boss_y)?-5'sd4:5'sd0);
                                eb_active[3]<=1; eb_x[3]<=boss_x-16; eb_y[3]<=boss_y; eb_vx[3]<=-5'sd3; eb_vy[3]<=-5'sd2;
                                eb_active[4]<=1; eb_x[4]<=boss_x-16; eb_y[4]<=boss_y; eb_vx[4]<=-5'sd3; eb_vy[4]<= 5'sd2;
                                eb_active[5]<=1; eb_x[5]<=boss_x; eb_y[5]<=boss_y; eb_vx[5]<=5'sd0; eb_vy[5]<=(next_y>boss_y)?5'sd4:-5'sd4;
                                eb_active[6]<=1; eb_x[6]<=boss_x+16; eb_y[6]<=boss_y; eb_vx[6]<=5'sd3; eb_vy[6]<=5'sd2;
                                eb_active[7]<=1; eb_x[7]<=boss_x+16; eb_y[7]<=boss_y; eb_vx[7]<=5'sd3; eb_vy[7]<=-5'sd2;
                            end

                            if (boss_kind >= 2'd1) begin
                                if (laser_state == 2'd0) begin
                                    if ((boss_enraged && (boss_ai_timer == 8'd55 || boss_ai_timer == 8'd140 || boss_ai_timer == 8'd215)) ||
                                        (!boss_enraged && (boss_ai_timer == 8'd90 || boss_ai_timer == 8'd190))) begin
                                        laser_state <= 2'd1; laser_timer <= (boss_kind == 2'd2 && boss_enraged) ? 8'd35 : 8'd50;
                                        laser_y <= next_y;
                                    end
                                end else if (laser_state == 2'd1) begin
                                    if (laser_timer > 0) laser_timer <= laser_timer - 8'd1;
                                    else begin laser_state <= 2'd2; laser_timer <= 8'd28; sfx_shoot <= 1; shake_mag <= 4'd4; end
                                end else begin
                                    if (laser_timer > 0) laser_timer <= laser_timer - 8'd1; else laser_state <= 2'd0;
                                end
                            end
                        end

                        // Heroes Melee vs Active Boss (with Anti-Spam Knockback + Stun!)
                        if (p1_alive && p1_slash_t > 4'd1 && !p1_boss_hit &&
                            ($signed({1'b0, boss_x}) >= $signed({1'b0, p1_slash_x}) - $signed({1'b0, reach1_eff}) - 12'sd20) &&
                            ($signed({1'b0, boss_x}) <= $signed({1'b0, p1_slash_x}) + $signed({1'b0, reach1_eff}) + 12'sd20) &&
                            ($signed({2'b00, boss_y}) >= $signed({2'b00, p1_slash_y}) - $signed({2'b00, reach1_eff}) - 12'sd20) &&
                            ($signed({2'b00, boss_y}) <= $signed({2'b00, p1_slash_y}) + $signed({2'b00, reach1_eff}) + 12'sd20)) begin
                            p1_boss_hit <= 1'b1; sfx_hit <= 1'b1; add_score(10'd25); shake_mag <= 4'd3;
                            if (combo_cnt < 7'd99) combo_cnt <= combo_cnt + 7'd1; combo_timer <= 8'd180;
                            p1_bmelee_rst <= 7'd90;
                            if (p1_boss_melee_cnt >= 3'd2) begin
                                p1_boss_melee_cnt <= 3'd0; p1_stun_t <= 6'd45; shake_mag <= 4'd8;
                                px <= (px >= boss_x) ? ((px > 11'd502) ? 11'd550 : (px + 11'd48)) : ((px < 11'd132) ? 11'd84 : (px - 11'd48));
                                py <= (py >= boss_y) ? ((py > 10'd326) ? 10'd358 : (py + 10'd32)) : ((py < 10'd116) ? 10'd84 : (py - 10'd32));
                            end else p1_boss_melee_cnt <= p1_boss_melee_cnt + 3'd1;
                            if (boss_hp <= {4'd0, dmg1_eff}) begin
                                boss_hp <= 0; boss_active <= 0; laser_state <= 0; shake_mag <= 4'd9;
                                add_score(10'd500); sfx_evolve <= 1'b1;
                                for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;
                                room_phase <= RP_BOSS; boss_trans_t <= 8'd160;
                            end else boss_hp <= boss_hp - {4'd0, dmg1_eff};
                        end else if (p2_alive && p2_slash_t > 4'd1 && !p2_boss_hit &&
                            ($signed({1'b0, boss_x}) >= $signed({1'b0, p2_slash_x}) - $signed({1'b0, reach2_eff}) - 12'sd20) &&
                            ($signed({1'b0, boss_x}) <= $signed({1'b0, p2_slash_x}) + $signed({1'b0, reach2_eff}) + 12'sd20) &&
                            ($signed({2'b00, boss_y}) >= $signed({2'b00, p2_slash_y}) - $signed({2'b00, reach2_eff}) - 12'sd20) &&
                            ($signed({2'b00, boss_y}) <= $signed({2'b00, p2_slash_y}) + $signed({2'b00, reach2_eff}) + 12'sd20)) begin
                            p2_boss_hit <= 1'b1; sfx_hit <= 1'b1; add_score(10'd25); shake_mag <= 4'd3;
                            if (combo_cnt < 7'd99) combo_cnt <= combo_cnt + 7'd1; combo_timer <= 8'd180;
                            p2_bmelee_rst <= 7'd90;
                            if (p2_boss_melee_cnt >= 3'd2) begin
                                p2_boss_melee_cnt <= 3'd0; p2_stun_t <= 6'd45; shake_mag <= 4'd8;
                                p2x <= (p2x >= boss_x) ? ((p2x > 11'd502) ? 11'd550 : (p2x + 11'd48)) : ((p2x < 11'd132) ? 11'd84 : (p2x - 11'd48));
                                p2y <= (p2y >= boss_y) ? ((p2y > 10'd326) ? 10'd358 : (p2y + 10'd32)) : ((p2y < 10'd116) ? 10'd84 : (p2y - 10'd32));
                            end else p2_boss_melee_cnt <= p2_boss_melee_cnt + 3'd1;
                            if (boss_hp <= {4'd0, dmg2_eff}) begin
                                boss_hp <= 0; boss_active <= 0; laser_state <= 0; shake_mag <= 4'd9;
                                add_score(10'd500); sfx_evolve <= 1'b1;
                                for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;
                                room_phase <= RP_BOSS; boss_trans_t <= 8'd160;
                            end else boss_hp <= boss_hp - {4'd0, dmg2_eff};
                        end else if (pet_b_act &&
                            ($signed({1'b0, boss_x}) >= $signed({1'b0, pet_bx}) - 12'sd28) &&
                            ($signed({1'b0, boss_x}) <= $signed({1'b0, pet_bx}) + 12'sd28) &&
                            ($signed({2'b00, boss_y}) >= $signed({2'b00, pet_by}) - 12'sd28) &&
                            ($signed({2'b00, boss_y}) <= $signed({2'b00, pet_by}) + 12'sd28)) begin
                            pet_b_act <= 0; sfx_hit <= 1;
                            if (boss_hp <= 8'd1) begin
                                boss_hp <= 0; boss_active <= 0; laser_state <= 0; shake_mag <= 4'd9;
                                add_score(10'd500); sfx_evolve <= 1'b1;
                                for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;
                                room_phase <= RP_BOSS; boss_trans_t <= 8'd160;
                            end else boss_hp <= boss_hp - 8'd1;
                        end else begin
                            pb_hit_found = 1'b0; pb_hit_idx = 3'd0;
                            for (idx = 0; idx < 8; idx = idx + 1) begin
                                if (!pb_hit_found && pb_active[idx] &&
                                    ($signed({1'b0, boss_x}) >= $signed({1'b0, pb_x[idx]}) - 12'sd26) &&
                                    ($signed({1'b0, boss_x}) <= $signed({1'b0, pb_x[idx]}) + 12'sd26) &&
                                    ($signed({2'b00, boss_y}) >= $signed({2'b00, pb_y[idx]}) - 12'sd26) &&
                                    ($signed({2'b00, boss_y}) <= $signed({2'b00, pb_y[idx]}) + 12'sd26)) begin
                                    pb_hit_found = 1'b1;
                                    pb_hit_idx   = idx[2:0];
                                end
                            end
                            if (pb_hit_found) begin
                                pb_active[pb_hit_idx] <= 1'b0; pb_homing[pb_hit_idx] <= 1'b0; sfx_hit <= 1'b1; add_score(10'd15);
                                spawn_sparks(boss_x, boss_y);
                                if (boss_hp <= 8'd2) begin
                                    boss_hp <= 0; boss_active <= 0; laser_state <= 0; shake_mag <= 4'd9;
                                    add_score(10'd500); sfx_evolve <= 1'b1;
                                    for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                    for (idx = 0; idx < 16; idx = idx + 1) en_alive[idx] <= 1'b0;
                                    room_phase <= RP_BOSS; boss_trans_t <= 8'd160;
                                end else boss_hp <= boss_hp - 8'd2;
                            end
                        end
                    end

                    // Player Damage from Enemy Bullets & Active Boss
                    tdmg1_now = tdmg1_acc;
                    tdmg2_now = tdmg2_acc;
                    if (game_state == ST_PLAY) begin
                        for (idx = 0; idx < 8; idx = idx + 1) begin
                            if (eb_active[idx]) begin
                                if (p1_alive && invuln_timer == 0 && (px+10 > eb_x[idx] && px < eb_x[idx]+10) && (py+10 > eb_y[idx] && py < eb_y[idx]+10)) begin
                                    tdmg1_now = 1'b1; eb_active[idx] <= 0;
                                end else if (p2_alive && p2_invuln == 0 && (p2x+10 > eb_x[idx] && p2x < eb_x[idx]+10) && (p2y+10 > eb_y[idx] && p2y < eb_y[idx]+10)) begin
                                    tdmg2_now = 1'b1; eb_active[idx] <= 0;
                                end
                            end
                        end
                        if (boss_active) begin
                            if (p1_alive && invuln_timer == 0 && (px+24 > boss_x && px < boss_x+24) && (py+24 > boss_y && py < boss_y+24)) tdmg1_now = 1'b1;
                            if (p2_alive && p2_invuln == 0 && (p2x+24 > boss_x && p2x < boss_x+24) && (p2y+24 > boss_y && p2y < boss_y+24)) tdmg2_now = 1'b1;
                            if (laser_state == 2'd2) begin
                                if (p1_alive && invuln_timer == 0 && (py+8 > laser_y && py < laser_y+8) && px < boss_x) tdmg1_now = 1'b1;
                                if (p2_alive && p2_invuln == 0 && (p2y+8 > laser_y && p2y < laser_y+8) && p2x < boss_x) tdmg2_now = 1'b1;
                            end
                        end
                    end

                    if (tdmg1_now) begin
                        invuln_timer <= 6'd60; p1_ooc_t <= 9'd0; p1_regen_div <= 6'd0;
                        sfx_hit <= 1'b1; shake_mag <= 4'd5; combo_cnt <= combo_cnt >> 1;
                        if (hp <= 5'd4) hp <= 5'd0; else hp <= hp - 5'd4;
                    end
                    if (tdmg2_now) begin
                        p2_invuln <= 6'd60; p2_ooc_t <= 9'd0; p2_regen_div <= 6'd0;
                        sfx_hit <= 1'b1; shake_mag <= 4'd5; combo_cnt <= combo_cnt >> 1;
                        if (hp2 <= 5'd4) hp2 <= 5'd0; else hp2 <= hp2 - 5'd4;
                    end

                    // Ironclad 1P/2P Death Check: if no alive players remain, ALWAYS enter ST_LOSE!
                    if (game_state == ST_PLAY &&
                        ((tdmg1_now ? (hp <= 5'd4) : (hp == 5'd0)) &&
                         (!p2_active || (tdmg2_now ? (hp2 <= 5'd4) : (hp2 == 5'd0))))) begin
                        game_state <= ST_LOSE; end_lockout <= 7'd90;
                    end else if (game_state == ST_PLAY) begin
                        if (room_phase == RP_FIGHT && wave < FINAL_WAVE && en_alive_vec == 16'b0 && !boss_active) begin
                            if (wave_sub < ((wave == 4'd1) ? 3'd2 : ((wave <= 4'd3) ? 3'd3 : 3'd4))) begin
                                wave_sub <= wave_sub + 3'd1;
                                spawn_wave_group(wave, wave_sub + 3'd1);
                                sfx_evolve <= 1'b1; shake_mag <= 4'd4;
                            end else begin
                                room_phase <= RP_CLEAR; sfx_pickup <= 1'b1;
                            end
                        end else if (room_phase == RP_CLEAR) begin
                            if ((p1_alive && px >= 11'd516 && py >= 10'd176 && py <= 10'd272) ||
                                (p2_alive && p2x >= 11'd516 && p2y >= 10'd176 && p2y <= 10'd272)) begin
                                room_phase <= RP_QUIZ;
                                quiz_gate <= (frame_cnt[2:0] >= 3'd6) ? (frame_cnt[2:0] - 3'd6) : frame_cnt[2:0];
                                quiz_ans_slot <= frame_cnt[1:0];
                                quiz_cursor <= 2'd0;
                                quiz_wrong_t <= 7'd0;
                                quiz_lockout <= 6'd30;
                                sfx_pickup <= 1'b1;
                            end
                        end else if (room_phase == RP_DOOR) begin
                            if ((p1_alive && px >= 11'd534 && py >= 10'd184 && py <= 10'd264) ||
                                (p2_alive && p2x >= 11'd534 && p2y >= 10'd184 && p2y <= 10'd264)) begin
                                wave <= wave + 4'd1;
                                if (p2_active && !p1_alive && p2_alive) hp <= 5'd12;
                                if (p2_active && !p2_alive && p1_alive) hp2 <= 5'd12;
                                px <= 11'd104; py <= 10'd224; mirror <= 1'b0;
                                p2x <= 11'd104; p2y <= 10'd252; p2_mirror <= 1'b0;
                                for (idx = 0; idx < 8; idx = idx + 1) eb_active[idx] <= 1'b0;
                                col_x[0] <= 11'd320; col_y[0] <= 10'd224; col_type[0] <= 1'b1; col_alive[0] <= 1'b1;
                                door_slam_t <= 6'd45; door_slide <= 5'd0;
                                shake_mag <= 4'd8; sfx_hit <= 1'b1;
                                outfit_cut_t <= 8'd120;
                                wave_banner_t <= 7'd90;
                                room_phase <= RP_BANNER;
                            end
                        end
                    end

                    step_state <= 6'd0;
                end

                default: step_state <= 6'd0;
            endcase
        end
    end
endmodule
