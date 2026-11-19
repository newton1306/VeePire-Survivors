import os
import re

print("Starting RTL updates...")

# -------------------------------------------------------------
# 1. Update game_engine_v2.v
# -------------------------------------------------------------
ge_path = r'D:\vivado_pj\DRAGO_NEXUS_V2\rtl\game_engine_v2.v'
with open(ge_path, 'r', encoding='utf-8') as f:
    ge_code = f.read()

# Port declarations
old_ge_port = """    output reg  [1:0]  stage         = 2'd0,
    output reg  [15:0] score_bcd     = 16'd0,
    output reg  [6:0]  chrono_energy = 7'd100,"""

new_ge_port = """    output reg  [1:0]  stage         = 2'd0,
    output reg  [23:0] score_bcd     = 24'd0,
    output reg  [1:0]  hero_sel_l    = 2'd0,
    output reg  [1:0]  hero_sel_r    = 2'd1,
    output reg  [2:0]  p1_weapon     = 3'd0,
    output reg  [2:0]  p2_weapon     = 3'd1,
    output reg         hero_cursor   = 1'b0,
    output reg  [6:0]  chrono_energy = 7'd100,"""

assert old_ge_port in ge_code, "old_ge_port not found"
ge_code = ge_code.replace(old_ge_port, new_ge_port)

# Solid check
old_solid = "4'd4:  is_solid = ~chr_on;   // Shadow Bridge"
new_solid = "4'd4:  is_solid = 1'b0;      // Shadow Bridge (Passable)"
assert old_solid in ge_code, "old_solid not found"
ge_code = ge_code.replace(old_solid, new_solid)

# Add score task
old_add_score = """    task automatic add_score;
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
    endtask"""

new_add_score = """    task automatic add_score;
        input [15:0] pts;
        reg [4:0] d0, d1, d2, d3, d4, d5;
        begin
            d0 = {1'b0, score_bcd[3:0]};   d1 = {1'b0, score_bcd[7:4]};
            d2 = {1'b0, score_bcd[11:8]};  d3 = {1'b0, score_bcd[15:12]};
            d4 = {1'b0, score_bcd[19:16]}; d5 = {1'b0, score_bcd[23:20]};

            if      (pts == 16'd10)   d1 = d1 + 5'd1;
            else if (pts == 16'd15)  begin d0 = d0 + 5'd5; d1 = d1 + 5'd1; end
            else if (pts == 16'd25)  begin d0 = d0 + 5'd5; d1 = d1 + 5'd2; end
            else if (pts == 16'd50)   d1 = d1 + 5'd5;
            else if (pts == 16'd100)  d2 = d2 + 5'd1;
            else if (pts == 16'd250) begin d1 = d1 + 5'd5; d2 = d2 + 5'd2; end
            else if (pts == 16'd500)  d2 = d2 + 5'd5;
            else if (pts == 16'd1000) d3 = d3 + 5'd1;
            else                      d1 = d1 + 5'd1;

            if (d0 >= 5'd10) begin d0 = d0 - 5'd10; d1 = d1 + 5'd1; end
            if (d1 >= 5'd10) begin d1 = d1 - 5'd10; d2 = d2 + 5'd1; end
            if (d2 >= 5'd10) begin d2 = d2 - 5'd10; d3 = d3 + 5'd1; end
            if (d3 >= 5'd10) begin d3 = d3 - 5'd10; d4 = d4 + 5'd1; end
            if (d4 >= 5'd10) begin d4 = d4 - 5'd10; d5 = d5 + 5'd1; end
            if (d5 >= 5'd10) begin d5 = 5'd9; d4 = 5'd9; d3 = 5'd9; d2 = 5'd9; d1 = 5'd9; d0 = 5'd9; end

            score_bcd <= {d5[3:0], d4[3:0], d3[3:0], d2[3:0], d1[3:0], d0[3:0]};
        end
    endtask"""

assert old_add_score in ge_code, "old_add_score not found"
ge_code = ge_code.replace(old_add_score, new_add_score)

# Score reset in init_game
ge_code = ge_code.replace("score_bcd <= 16'd0;", "score_bcd <= 24'd0;")

# Remove enemy slowdown
old_chrono_tick = """                        if (chrono_active) begin
                            chrono_div <= (chrono_div >= 2'd2) ? 2'd0 : chrono_div + 2'd1;
                            world_tick <= (chrono_div == 2'd0);
                            if (frame_cnt[0] && chrono_energy > 0) chrono_energy <= chrono_energy - 7'd1;
                        end else begin
                            chrono_div <= 2'd0; world_tick <= 1'b1;
                            if (frame_cnt[2:0] == 3'b000 && chrono_energy < 7'd100) chrono_energy <= chrono_energy + 7'd1;
                        end"""

new_chrono_tick = """                        // Fast fluid 60fps action always (no enemy slow down!)
                        chrono_div <= 2'd0;
                        world_tick <= 1'b1;
                        if (frame_cnt[2:0] == 3'b000 && chrono_energy < 7'd100) chrono_energy <= chrono_energy + 7'd1;"""

assert old_chrono_tick in ge_code, "old_chrono_tick not found"
ge_code = ge_code.replace(old_chrono_tick, new_chrono_tick)

# Input mappings
old_p2_act = """    wire use_joy   = 1'b1;
    assign p2_active = (control_mode == 2'd1);
    assign zoom_out  = (zoom_lvl > 7'd0);

    wire p1_alive = (hp > 5'd0);
    wire p2_alive = p2_active && (hp2 > 5'd0);

    wire signed [2:0] kb_p1_dx = kb_right ? 3'sd1 : (kb_left ? -3'sd1 : 3'sd0);
    wire signed [2:0] kb_p1_dy = kb_down ? 3'sd1 : (kb_up ? -3'sd1 : 3'sd0);
    wire signed [2:0] p1_in_dx = (kb_p1_dx != 3'sd0) ? kb_p1_dx : j1_dx;
    wire signed [2:0] p1_in_dy = (kb_p1_dy != 3'sd0) ? kb_p1_dy : j1_dy;"""

new_p2_act = """    wire use_joy   = 1'b1;
    // Modes: 0=1P Joystick, 1=1P Keyboard, 2=2P Dual Joy, 3=2P Co-op (Joy + Keyboard)
    assign p2_active = (control_mode == 2'd2 || control_mode == 2'd3);
    assign zoom_out  = (zoom_lvl > 7'd0);

    wire p1_alive = (hp > 5'd0);
    wire p2_alive = p2_active && (hp2 > 5'd0);

    wire signed [2:0] kb_p1_dx = kb_right ? 3'sd1 : (kb_left ? -3'sd1 : 3'sd0);
    wire signed [2:0] kb_p1_dy = kb_down ? 3'sd1 : (kb_up ? -3'sd1 : 3'sd0);
    wire signed [2:0] p1_in_dx = (control_mode == 2'd3) ? j1_dx : ((kb_p1_dx != 3'sd0) ? kb_p1_dx : j1_dx);
    wire signed [2:0] p1_in_dy = (control_mode == 2'd3) ? j1_dy : ((kb_p1_dy != 3'sd0) ? kb_p1_dy : j1_dy);
    wire signed [2:0] p2_in_dx = (control_mode == 2'd3) ? kb_p1_dx : j2_dx;
    wire signed [2:0] p2_in_dy = (control_mode == 2'd3) ? kb_p1_dy : j2_dy;"""

assert old_p2_act in ge_code, "old_p2_act not found"
ge_code = ge_code.replace(old_p2_act, new_p2_act)

ge_code = ge_code.replace("if (p2_alive && (j2_dx != 0 || j2_dy != 0)) begin", "if (p2_alive && (p2_in_dx != 0 || p2_in_dy != 0)) begin")
ge_code = ge_code.replace("if (j2_dx < 0) begin p2_face_dx <= -3'sd1;", "if (p2_in_dx < 0) begin p2_face_dx <= -3'sd1;")
ge_code = ge_code.replace("else if (j2_dx > 0) begin p2_face_dx <= 3'sd1;", "else if (p2_in_dx > 0) begin p2_face_dx <= 3'sd1;")
ge_code = ge_code.replace("if (j2_dy < 0) p2_face_dy <= -3'sd1; else if (j2_dy > 0) p2_face_dy <= 3'sd1;", "if (p2_in_dy < 0) p2_face_dy <= -3'sd1; else if (p2_in_dy > 0) p2_face_dy <= 3'sd1;")

ge_code = ge_code.replace("move_dx = (stage >= 2'd1 && j2_dx != 0) ? (j2_dx > 0 ? j2_dx + 5'sd1 : j2_dx - 5'sd1) : j2_dx;",
                          "move_dx = (stage >= 2'd1 && p2_in_dx != 0) ? (p2_in_dx > 0 ? p2_in_dx + 5'sd1 : p2_in_dx - 5'sd1) : p2_in_dx;")
ge_code = ge_code.replace("move_dy = (stage >= 2'd1 && j2_dy != 0) ? (j2_dy > 0 ? j2_dy + 5'sd1 : j2_dy - 5'sd1) : j2_dy;",
                          "move_dy = (stage >= 2'd1 && p2_in_dy != 0) ? (p2_in_dy > 0 ? p2_in_dy + 5'sd1 : p2_in_dy - 5'sd1) : p2_in_dy;")

# Remove board buttons from dash in ST_PLAY
old_dash = "if (p1_alive && p1_stun_t == 0 && (btnu_edge || (use_joy && j1_dash_edge)) && dash_cd == 0) begin"
new_dash = "if (p1_alive && p1_stun_t == 0 && ((control_mode == 2'd3) ? j1_dash_edge : (j1_dash_edge || kb_skill)) && dash_cd == 0) begin"
assert old_dash in ge_code, "old_dash not found"
ge_code = ge_code.replace(old_dash, new_dash)

old_dash2 = "if (p2_alive && p2_stun_t == 0 && j2_dash_edge && p2_dash_cd == 0) begin"
new_dash2 = "if (p2_alive && p2_stun_t == 0 && ((control_mode == 2'd3) ? kb_skill : j2_dash_edge) && p2_dash_cd == 0) begin"
assert old_dash2 in ge_code, "old_dash2 not found"
ge_code = ge_code.replace(old_dash2, new_dash2)

# Remove board buttons from attack in ST_PLAY
old_fire_poll = """                if (p1_alive && j1_btn[2] && !j1f_prev_clk)
                    fire_req <= 1'b1;
                if (p2_alive && j2_btn[2] && !j2f_prev_clk)
                    p2_fire_req <= 1'b1;"""

new_fire_poll = """                if (control_mode == 2'd3) begin
                    if (p1_alive && j1_btn[2] && !j1f_prev_clk) fire_req <= 1'b1;
                    if (p2_alive && kb_attack && !kb_atk_prev) p2_fire_req <= 1'b1;
                end else begin
                    if (p1_alive && ((j1_btn[2] && !j1f_prev_clk) || (kb_attack && !kb_atk_prev))) fire_req <= 1'b1;
                    if (p2_alive && j2_btn[2] && !j2f_prev_clk) p2_fire_req <= 1'b1;
                end"""
assert old_fire_poll in ge_code, "old_fire_poll not found"
ge_code = ge_code.replace(old_fire_poll, new_fire_poll)

# ST_TITLE lobby customization
old_st_title = """                    end else if (game_state == ST_TITLE) begin
                        if (help_page == 2'd0) begin
                            if (any_right_edge || any_left_edge) begin
                                control_mode <= (control_mode == 2'd0) ? 2'd1 : 2'd0; sfx_pickup <= 1'b1;
                            end else if (real_start_edge) begin
                                help_page <= 2'd1; sfx_pickup <= 1'b1; // Open Board Controls Guide
                            end else if (any_action_edge) begin
                                init_game(); game_state <= ST_PLAY; sfx_evolve <= 1'b1; // Start Game immediately
                            end
                        end else if (help_page == 2'd1) begin
                            // Page 1: Board Controls -> Next to Joy Controls
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                help_page <= 2'd2; sfx_pickup <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd0; sfx_pickup <= 1'b1; // Back to Title
                            end
                        end else if (help_page == 2'd2) begin
                            // Page 2: Joystick Controls -> Next to Keyboard Controls
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                help_page <= 2'd3; sfx_pickup <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd1; sfx_pickup <= 1'b1; // Back to Board Controls
                            end
                        end else if (help_page == 2'd3) begin
                            // Page 3: Keyboard Controls -> Start Game!
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                init_game(); help_page <= 2'd0; game_state <= ST_PLAY; sfx_evolve <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd2; sfx_pickup <= 1'b1; // Back to Joy Controls
                            end
                        end
                    end else if (game_state == ST_CUTSCENE) begin"""

new_st_title = """                    end else if (game_state == ST_TITLE) begin
                        if (help_page == 2'd0) begin
                            // Board 5 Pushbuttons for character & weapon customization:
                            if (btnl_edge) begin
                                hero_cursor <= 1'b0; sfx_pickup <= 1'b1;
                            end else if (btnr_edge) begin
                                hero_cursor <= 1'b1; sfx_pickup <= 1'b1;
                            end else if (btnc_edge) begin
                                if (!hero_cursor) hero_sel_l <= hero_sel_l + 2'd1;
                                else              hero_sel_r <= hero_sel_r + 2'd1;
                                sfx_pickup <= 1'b1;
                            end else if (btnu_edge) begin
                                if (!hero_cursor) p1_weapon <= (p1_weapon >= 3'd5) ? 3'd0 : (p1_weapon + 3'd1);
                                else              p2_weapon <= (p2_weapon >= 3'd5) ? 3'd0 : (p2_weapon + 3'd1);
                                sfx_pickup <= 1'b1;
                            end else if (btnd_edge) begin
                                if (!hero_cursor) p1_weapon <= (p1_weapon == 3'd0) ? 3'd5 : (p1_weapon - 3'd1);
                                else              p2_weapon <= (p2_weapon == 3'd0) ? 3'd5 : (p2_weapon - 3'd1);
                                sfx_pickup <= 1'b1;
                            // Mode Selection via Joystick D-pad or Keyboard:
                            end else if (j1_right_edge || j2_right_edge || kb_r_e || j1_down_edge || j2_down_edge || kb_d_e) begin
                                control_mode <= control_mode + 2'd1; sfx_pickup <= 1'b1;
                            end else if (j1_left_edge || j2_left_edge || kb_l_e || j1_up_edge || j2_up_edge || kb_u_e) begin
                                control_mode <= control_mode - 2'd1; sfx_pickup <= 1'b1;
                            // Controls Guide:
                            end else if (real_start_edge || joy_select) begin
                                help_page <= 2'd1; sfx_pickup <= 1'b1;
                            // Start Game:
                            end else if (j1_fire_edge || j2_fire_edge || kb_atk_e || kb_star_e) begin
                                init_game(); game_state <= ST_PLAY; sfx_evolve <= 1'b1;
                            end
                        end else if (help_page == 2'd1) begin
                            // Page 1: Board Hardware Controls -> Next to Joy Controls
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                help_page <= 2'd2; sfx_pickup <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd0; sfx_pickup <= 1'b1;
                            end
                        end else if (help_page == 2'd2) begin
                            // Page 2: Joystick Controls -> Next to Keyboard Controls
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                help_page <= 2'd3; sfx_pickup <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd1; sfx_pickup <= 1'b1;
                            end
                        end else if (help_page == 2'd3) begin
                            // Page 3: Keyboard Controls -> Start Game!
                            if (real_start_edge || any_action_edge || any_right_edge || any_down_edge) begin
                                init_game(); help_page <= 2'd0; game_state <= ST_PLAY; sfx_evolve <= 1'b1;
                            end else if (any_left_edge || joy_select) begin
                                help_page <= 2'd2; sfx_pickup <= 1'b1;
                            end
                        end
                    end else if (game_state == ST_CUTSCENE) begin"""

assert old_st_title in ge_code, "old_st_title not found"
ge_code = ge_code.replace(old_st_title, new_st_title)

with open(ge_path, 'w', encoding='utf-8') as f:
    f.write(ge_code)
print("Updated game_engine_v2.v!")

# -------------------------------------------------------------
# 2. Update board_io_v2.v
# -------------------------------------------------------------
bio_path = r'D:\vivado_pj\DRAGO_NEXUS_V2\rtl\board_io_v2.v'
with open(bio_path, 'r', encoding='utf-8') as f:
    bio_code = f.read()

# score_bcd to 24 bits
bio_code = bio_code.replace("input  wire [15:0] score_bcd,", "input  wire [23:0] score_bcd,")

# 7-segment display logic: 6 digits of score on Digits 5..0, Wave on Digits 7..6
old_seg_mux = """        case (dig_sel)
            3'd7: char_code = show_temp ? {1'b0, temp_bcd[11:8]} : 5'd14; // Tens or 'E'
            3'd6: begin
                char_code = show_temp ? {1'b0, temp_bcd[7:4]} : {3'd0, stage};
                dp_val = 1'b0; // Decimal point for temp or stage
            end
            3'd5: char_code = show_temp ? {1'b0, temp_bcd[3:0]} : 5'd17; // Fraction or 'H'
            3'd4: begin
                char_code = show_temp ? 5'd12 : {2'd0, hp[4:2]}; // 'C' (Celsius) or HP
                dp_val = show_temp ? 1'b1 : 1'b0;
            end
            3'd3: char_code = {1'b0, score_bcd[15:12]};
            3'd2: char_code = {1'b0, score_bcd[11:8]};
            3'd1: char_code = {1'b0, score_bcd[7:4]};
            3'd0: char_code = {1'b0, score_bcd[3:0]};
        endcase"""

new_seg_mux = """        case (dig_sel)
            3'd7: char_code = show_temp ? {1'b0, temp_bcd[11:8]} : 5'd14; // 'E' or Temp Tens
            3'd6: begin
                char_code = show_temp ? {1'b0, temp_bcd[7:4]} : {1'b0, wave}; // Wave 1..10 or Temp Ones
                dp_val = 1'b0; // Decimal point separator
            end
            3'd5: char_code = show_temp ? {1'b0, temp_bcd[3:0]} : {1'b0, score_bcd[23:20]}; // 100k digit or Temp Frac
            3'd4: begin
                char_code = show_temp ? 5'd12 : {1'b0, score_bcd[19:16]}; // 10k digit or 'C'
                dp_val = show_temp ? 1'b1 : 1'b1;
            end
            3'd3: char_code = {1'b0, score_bcd[15:12]}; // 1k digit
            3'd2: char_code = {1'b0, score_bcd[11:8]};  // 100 digit
            3'd1: char_code = {1'b0, score_bcd[7:4]};   // 10 digit
            3'd0: char_code = {1'b0, score_bcd[3:0]};   // 1 digit
        endcase"""

assert old_seg_mux in bio_code, "old_seg_mux not found"
bio_code = bio_code.replace(old_seg_mux, new_seg_mux)

with open(bio_path, 'w', encoding='utf-8') as f:
    f.write(bio_code)
print("Updated board_io_v2.v!")

# -------------------------------------------------------------
# 3. Update drago_nexus_v2_top.v
# -------------------------------------------------------------
top_path = r'D:\vivado_pj\DRAGO_NEXUS_V2\rtl\drago_nexus_v2_top.v'
with open(top_path, 'r', encoding='utf-8') as f:
    top_code = f.read()

# Change score_bcd to 24 bits
top_code = top_code.replace("wire [15:0] score_bcd;", "wire [23:0] score_bcd;")

# Replace switch-based hero_sel with engine-driven wires
old_top_hero = """    // SW[15:12] = Left Character (P1), SW[3:0] = Right Character (P2)
    wire [1:0] hero_sel_l = sw_sync[15] ? 2'd3 :
                            sw_sync[14] ? 2'd2 :
                            sw_sync[13] ? 2'd1 : 2'd0;
    wire [1:0] hero_sel_r = sw_sync[3]  ? 2'd3 :
                            sw_sync[2]  ? 2'd2 :
                            sw_sync[1]  ? 2'd1 : 2'd0;"""

new_top_hero = """    // Character and Weapon Customization driven by Engine & Board 5 Pushbuttons
    wire [1:0] hero_sel_l, hero_sel_r;
    wire [2:0] p1_weapon, p2_weapon;
    wire       hero_cursor;"""

assert old_top_hero in top_code, "old_top_hero not found"
top_code = top_code.replace(old_top_hero, new_top_hero)

# Hook up hero_sel, p1/p2_weapon, hero_cursor to engine
old_eng_inst = """.temp_fever(eff_temp_fever), .mic_roar(mic_roar), .sound_level(sound_level),"""
new_eng_inst = """.hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r),
        .p1_weapon(p1_weapon), .p2_weapon(p2_weapon), .hero_cursor(hero_cursor),
        .temp_fever(eff_temp_fever), .mic_roar(mic_roar), .sound_level(sound_level),"""
assert old_eng_inst in top_code, "old_eng_inst not found"
top_code = top_code.replace(old_eng_inst, new_eng_inst)

# Hook up weapon and hero_cursor to renderer
old_rend_inst = """.hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r), .room_phase(room_phase),"""
new_rend_inst = """.hero_sel_l(hero_sel_l), .hero_sel_r(hero_sel_r),
        .p1_weapon(p1_weapon), .p2_weapon(p2_weapon), .hero_cursor(hero_cursor),
        .room_phase(room_phase),"""
assert old_rend_inst in top_code, "old_rend_inst not found"
top_code = top_code.replace(old_rend_inst, new_rend_inst)

with open(top_path, 'w', encoding='utf-8') as f:
    f.write(top_code)
print("Updated drago_nexus_v2_top.v!")

print("All base RTL updates complete!")
