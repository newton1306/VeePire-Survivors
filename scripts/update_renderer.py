import os

print("Updating vga_renderer_v2.v...")
ren_path = r'D:\vivado_pj\DRAGO_NEXUS_V2\rtl\vga_renderer_v2.v'
with open(ren_path, 'r', encoding='utf-8') as f:
    ren_code = f.read()

# 1. Include joy_palette.vh at top of file
if '`include "joy_palette.vh"' not in ren_code:
    ren_code = '`include "joy_palette.vh"\n' + ren_code

# 2. Module ports: score_bcd to 24 bits, add weapon & cursor inputs
old_ren_port = """    input  wire [15:0] score_bcd,
    input  wire [6:0]  chrono_energy,"""

new_ren_port = """    input  wire [23:0] score_bcd,
    input  wire [2:0]  p1_weapon, p2_weapon,
    input  wire        hero_cursor,
    input  wire [6:0]  chrono_energy,"""

assert old_ren_port in ren_code, "old_ren_port not found"
ren_code = ren_code.replace(old_ren_port, new_ren_port)

# 3. Add joy_pixel ROM instantiation in Stage 0
old_logo_rom = """    wire [5:0] logo_pix_1;
    rom_1p #(.DW(6), .AW(13), .DEPTH(8192), .FILE("title_logo.mem")) u_logo_rom (
        .clk(clk), .addr(logo_addr), .q(logo_pix_1)
    );"""

new_joy_rom = """    wire [5:0] logo_pix_1;
    rom_1p #(.DW(6), .AW(13), .DEPTH(8192), .FILE("title_logo.mem")) u_logo_rom (
        .clk(clk), .addr(logo_addr), .q(logo_pix_1)
    );

    // 96x64 4-bit DualShock Joystick Pixel Art ROM (3072 bytes)
    wire in_joy_box = (game_state == 3'd0 && help_page == 2'd2) && (gx >= 9'd112 && gx < 9'd208 && gy >= 9'd56 && gy < 9'd120);
    wire [11:0] joy_rom_addr = in_joy_box ? ((gy - 9'd56) * 6'd48 + ((gx - 9'd112) >> 1)) : 12'd0;
    wire [7:0] joy_rom_byte_1;
    rom_1p #(.DW(8), .AW(12), .DEPTH(3072), .FILE("joy_pixel.mem")) u_joy_rom (
        .clk(clk), .addr(joy_rom_addr), .q(joy_rom_byte_1)
    );"""

assert old_logo_rom in ren_code, "old_logo_rom not found"
ren_code = ren_code.replace(old_logo_rom, new_joy_rom)

# 4. Pipeline registers: Stage 1 on_joy_1, joy_x0_1
old_st1_reg = """        on_ghost_1 <= on_ghost; on_b_1 <= on_boss_box; on_mon_1 <= on_mon_box; on_item_1 <= on_item_box; on_logo_1 <= in_logo_box;"""
new_st1_reg = """        on_ghost_1 <= on_ghost; on_b_1 <= on_boss_box; on_mon_1 <= on_mon_box; on_item_1 <= on_item_box; on_logo_1 <= in_logo_box;
        on_joy_1 <= in_joy_box; joy_x0_1 <= gx[0];"""
assert old_st1_reg in ren_code, "old_st1_reg not found"
ren_code = ren_code.replace(old_st1_reg, new_st1_reg)

# Stage 1 signal declarations
if 'reg on_joy_1=0, joy_x0_1=0;' not in ren_code:
    ren_code = ren_code.replace("reg on_p_1=0, sel_p2_1=0, on_aura_1=0, on_ghost_1=0, on_b_1=0, on_mon_1=0, on_item_1=0, on_logo_1=0;",
                                "reg on_p_1=0, sel_p2_1=0, on_aura_1=0, on_ghost_1=0, on_b_1=0, on_mon_1=0, on_item_1=0, on_logo_1=0;\n    reg on_joy_1=0, joy_x0_1=0;")

# Stage 2 signal declarations
if 'reg on_joy_2=0; reg [3:0] joy_nib_2=0;' not in ren_code:
    ren_code = ren_code.replace("reg on_p_2=0, sel_p2_2=0, on_aura_2=0, on_ghost_2=0, on_b_2=0, on_mon_2=0, on_item_2=0, on_logo_2=0;",
                                "reg on_p_2=0, sel_p2_2=0, on_aura_2=0, on_ghost_2=0, on_b_2=0, on_mon_2=0, on_item_2=0, on_logo_2=0;\n    reg on_joy_2=0; reg [3:0] joy_nib_2=0;")

# Stage 2 register assignments
old_st2_reg = """        on_ghost_2 <= on_ghost_1; on_b_2 <= on_b_1; on_mon_2 <= on_mon_1; on_item_2 <= on_item_1; on_logo_2 <= on_logo_1;"""
new_st2_reg = """        on_ghost_2 <= on_ghost_1; on_b_2 <= on_b_1; on_mon_2 <= on_mon_1; on_item_2 <= on_item_1; on_logo_2 <= on_logo_1;
        on_joy_2 <= on_joy_1; joy_nib_2 <= (joy_x0_1 == 1'b0) ? joy_rom_byte_1[7:4] : joy_rom_byte_1[3:0];"""
assert old_st2_reg in ren_code, "old_st2_reg not found"
ren_code = ren_code.replace(old_st2_reg, new_st2_reg)

# Stage 2 Compositor for joy_pixel
old_comp_logo = """        else if (on_logo_2 && logo_pix_2 != 6'd0) final_idx_2 = logo_pix_2;"""
new_comp_logo = """        else if (on_logo_2 && logo_pix_2 != 6'd0) final_idx_2 = logo_pix_2;
        else if (on_joy_2 && joy_nib_2 != 4'd0) begin
            use_direct_rgb_2 = 1'b1;
            direct_rgb_2     = joy_palette(joy_nib_2);
        end"""
assert old_comp_logo in ren_code, "old_comp_logo not found"
ren_code = ren_code.replace(old_comp_logo, new_comp_logo)

# 5. Replace slash animations for P1 and P2 with 6 weapon custom animations
old_slashes = """            // P1 Clear 12-px Crescent Slash + Sword Beam OR 360 Double-Ring Nova!
            // Longer 4-Phase Pixel-Art Sword Swing Animation (reach ~34px, clean white/silver!)
            if (p1_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, px});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, py});
                if (bx_d >= -12'sd36 && bx_d <= 12'sd36 && by_d >= -12'sd36 && by_d <= 12'sd36) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p1_slash_dx == 0) ? 12'sd0 : ((p1_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p1_slash_dy == 0) ? 12'sd0 : ((p1_slash_dy > 0) ? by_d : -by_d));
                    sw_up = (p1_slash_dy == 0) ? -by_d : ((p1_slash_dx == 0) ? bx_d : -by_d);
                    if (p1_nova) begin
                        if (oct_d >= 12'sd22 && oct_d <= 12'sd31) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd27) ? 6'd17 : 6'd55;
                        end
                    end else if (p1_slash_t >= 4'd10) begin
                        // Phase 1: Anticipation (long blade cocked up-back)
                        if (sw_up >= 12'sd6 && sw_up <= 12'sd28 && dot_d >= -12'sd12 && dot_d <= -12'sd1 &&
                            (dot_d + (sw_up >> 2) >= -12'sd6) && (dot_d + (sw_up >> 2) <= -12'sd2)) begin
                            on_pb_0 = 1; pb_col_0 = (dot_d + (sw_up >> 2) >= -12'sd4) ? 6'd17 : 6'd55;
                        end
                    end else if (p1_slash_t >= 4'd7) begin
                        // Phase 2: Smear 1 (long sweeping white arc from overhead-back to front)
                        if (sw_up >= -12'sd4 && oct_d >= 12'sd16 && oct_d <= 12'sd34 &&
                            (dot_d >= -12'sd6 || sw_up >= 12'sd10) && (dot_d + sw_up >= 12'sd8)) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd25 || dot_d >= 12'sd20) ? 6'd17 : 6'd55;
                        end
                    end else if (p1_slash_t >= 4'd4) begin
                        // Phase 3: Hit (long sharp hooked white crescent in front)
                        if (dot_d >= 12'sd6 && sw_up >= -12'sd12 && sw_up <= 12'sd20 &&
                            oct_d >= 12'sd16 && oct_d <= 12'sd32 && (dot_d >= (sw_up < 0 ? -sw_up : sw_up) + 12'sd2)) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd23 || sw_up >= 12'sd8) ? 6'd17 : 6'd55;
                        end
                    end else begin
                        // Phase 4: Follow Through (long forward extended blade)
                        if (dot_d >= 12'sd8 && dot_d <= 12'sd34 && sw_up >= -12'sd2 && sw_up <= 12'sd1) begin
                            on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || dot_d >= 12'sd22) ? 6'd17 : 6'd55;
                        end
                    end
                end
            end

            if (p2_active && p2_slash_t > 0) begin
                bx_d = $signed({1'b0, wx}) - $signed({1'b0, p2x});
                by_d = $signed({2'b00, wy}) - $signed({2'b00, p2y});
                if (bx_d >= -12'sd36 && bx_d <= 12'sd36 && by_d >= -12'sd36 && by_d <= 12'sd36) begin
                    ax_d  = (bx_d < 0) ? -bx_d : bx_d; ay_d = (by_d < 0) ? -by_d : by_d;
                    oct_d = (ax_d >= ay_d) ? (ax_d + (ay_d >> 1)) : (ay_d + (ax_d >> 1));
                    dot_d = ((p2_slash_dx == 0) ? 12'sd0 : ((p2_slash_dx > 0) ? bx_d : -bx_d)) +
                            ((p2_slash_dy == 0) ? 12'sd0 : ((p2_slash_dy > 0) ? by_d : -by_d));
                    sw_up = (p2_slash_dy == 0) ? -by_d : ((p2_slash_dx == 0) ? bx_d : -by_d);
                    if (p2_nova) begin
                        if (oct_d >= 12'sd22 && oct_d <= 12'sd31) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd27) ? 6'd17 : 6'd55;
                        end
                    end else if (p2_slash_t >= 4'd10) begin
                        if (sw_up >= 12'sd6 && sw_up <= 12'sd28 && dot_d >= -12'sd12 && dot_d <= -12'sd1 &&
                            (dot_d + (sw_up >> 2) >= -12'sd6) && (dot_d + (sw_up >> 2) <= -12'sd2)) begin
                            on_pb_0 = 1; pb_col_0 = (dot_d + (sw_up >> 2) >= -12'sd4) ? 6'd17 : 6'd55;
                        end
                    end else if (p2_slash_t >= 4'd7) begin
                        if (sw_up >= -12'sd4 && oct_d >= 12'sd16 && oct_d <= 12'sd34 &&
                            (dot_d >= -12'sd6 || sw_up >= 12'sd10) && (dot_d + sw_up >= 12'sd8)) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd25 || dot_d >= 12'sd20) ? 6'd17 : 6'd55;
                        end
                    end else if (p2_slash_t >= 4'd4) begin
                        if (dot_d >= 12'sd6 && sw_up >= -12'sd12 && sw_up <= 12'sd20 &&
                            oct_d >= 12'sd16 && oct_d <= 12'sd32 && (dot_d >= (sw_up < 0 ? -sw_up : sw_up) + 12'sd2)) begin
                            on_pb_0 = 1; pb_col_0 = (oct_d >= 12'sd23 || sw_up >= 12'sd8) ? 6'd17 : 6'd55;
                        end
                    end else begin
                        if (dot_d >= 12'sd8 && dot_d <= 12'sd34 && sw_up >= -12'sd2 && sw_up <= 12'sd1) begin
                            on_pb_0 = 1; pb_col_0 = (sw_up == 12'sd0 || dot_d >= 12'sd22) ? 6'd17 : 6'd55;
                        end
                    end
                end
            end"""

new_slashes = """            // =========================================================================
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
            end"""

assert old_slashes in ren_code, "old_slashes not found"
ren_code = ren_code.replace(old_slashes, new_slashes)

# 6. Update HUD Score in in_game play to 6 digits SC:xxxxxx
old_hud_score = """                    end else if (col_1x >= 6'd20 && col_1x <= 6'd26) begin
                        hud_text_en = 1; hud_text_color = 6'd17;
                        case (col_1x - 6'd20)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=C_COL;
                            3:hud_char_code={2'd0,score_bcd[15:12]}; 4:hud_char_code={2'd0,score_bcd[11:8]};
                            5:hud_char_code={2'd0,score_bcd[7:4]};   6:hud_char_code={2'd0,score_bcd[3:0]};
                        endcase"""

new_hud_score = """                    end else if (col_1x >= 6'd19 && col_1x <= 6'd27) begin
                        hud_text_en = 1; hud_text_color = 6'd17;
                        case (col_1x - 6'd19)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("C"); 2:hud_char_code=C_COL;
                            3:hud_char_code={2'd0,score_bcd[23:20]}; 4:hud_char_code={2'd0,score_bcd[19:16]};
                            5:hud_char_code={2'd0,score_bcd[15:12]}; 6:hud_char_code={2'd0,score_bcd[11:8]};
                            7:hud_char_code={2'd0,score_bcd[7:4]};   8:hud_char_code={2'd0,score_bcd[3:0]};
                        endcase"""

assert old_hud_score in ren_code, "old_hud_score not found"
ren_code = ren_code.replace(old_hud_score, new_hud_score)

# 7. Helper functions for weapon names (SWORD, SABER, FISTS, B-AXE, SPEAR, SCYTH)
weapon_func = """    function automatic [5:0] wname_ch;
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
"""
if 'function automatic [5:0] wname_ch;' not in ren_code:
    ren_code = ren_code.replace("function automatic [5:0] lch;", weapon_func + "    function automatic [5:0] lch;")

with open(ren_path, 'w', encoding='utf-8') as f:
    f.write(ren_code)

print("Part 1 of vga_renderer_v2.v complete!")
