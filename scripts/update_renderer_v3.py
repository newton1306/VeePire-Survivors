"""
Update vga_renderer_v2.v declaring wires outside always @(*)
"""

path = "D:/vivado_pj/DRAGO_NEXUS_V2/rtl/vga_renderer_v2.v"
with open(path, "r") as f:
    code = f.read()

start_marker = "    reg [5:0] hud_char_code, hud_text_color, hud_bg_color;"
end_marker = "        end else if (game_state == 3'd1) begin"

idx1 = code.find(start_marker)
idx2 = code.find(end_marker)

if idx1 == -1 or idx2 == -1:
    print(f"ERROR: markers not found! idx1={idx1}, idx2={idx2}")
    exit(1)

new_code_block = """    reg [5:0] hud_char_code, hud_text_color, hud_bg_color;
    reg [2:0] hud_char_row, hud_char_col;
    reg       hud_text_en, hud_bg_en;
    wire [5:0] col_1x = gx[8:3];

    // Precomputed Title Screen Wires (Outside procedural always block)
    wire [8:0] tri_y_base = 9'd94 + (anim_cnt[23:22]==2'd1||anim_cnt[23:22]==2'd2 ? 9'd2 : 9'd0);
    wire [8:0] cur_cx = hero_cursor ? 9'd220 : 9'd100;
    wire [8:0] tri_dx = (gx >= cur_cx) ? (gx - cur_cx) : (cur_cx - gx);
    wire [3:0] tri_row = gy - tri_y_base;
    wire [3:0] tri_hw = (tri_row <= 4'd1) ? 4'd4 : ((tri_row <= 4'd3) ? 4'd3 : ((tri_row <= 4'd5) ? 4'd2 : ((tri_row <= 4'd7) ? 4'd1 : 4'd0)));

    wire [8:0] btn_b_off = (anim_cnt[23:21] < 3'd4 ? {6'd0, anim_cnt[23:21]} : {6'd0, 3'd7 - anim_cnt[23:21]});
    wire [8:0] b_top = 9'd178 - btn_b_off;
    wire [8:0] b_bot = b_top + 9'd32;
    wire is_b_edge = (gx == 9'd104 || gx == 9'd215 || gy == b_top || gy == b_bot - 9'd1);
    wire is_b_hi   = (gx <= 9'd106 || gy <= b_top + 9'd2);
    wire is_b_sh   = (gx >= 9'd213 || gy >= b_bot - 9'd3);
    wire is_kb_mode = (control_mode == 2'd1 || control_mode == 2'd3);

    always @(*) begin
        hud_char_code = C_SP; hud_char_row = gy[2:0]; hud_char_col = gx[2:0];
        hud_text_color = 6'd17; hud_text_en = 0; hud_bg_en = 0; hud_bg_color = 6'd54;

        if (game_state == 3'd0) begin
            if (help_page == 2'd0) begin
                // -------------------------------------------------------------
                // 1. Mode Selector Banner (gy=62..78, gx=44..276)
                // -------------------------------------------------------------
                if (gy >= 9'd62 && gy <= 9'd78 && gx >= 9'd44 && gx < 9'd276) begin
                    hud_bg_en = 1; hud_bg_color = (gy==9'd62||gy==9'd78||gx==9'd44||gx==9'd275) ? 6'd58 : 6'd54;
                    if (gy >= 9'd66 && gy < 9'd74 && col_1x >= 6'd6 && col_1x <= 6'd33) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd66;
                        if (col_1x == 6'd6)       begin hud_char_code = C_LARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                        else if (col_1x == 6'd33) begin hud_char_code = C_RARW; hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17; end
                        else begin
                            hud_text_color = (control_mode == 2'd0) ? 6'd59 : ((control_mode == 2'd1) ? 6'd58 : ((control_mode == 2'd2) ? 6'd51 : 6'd60));
                            case (control_mode)
                                2'd0: case (col_1x - 6'd8)
                                    0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("D"); 3:hud_char_code=lch("E");
                                    4:hud_char_code=C_COL;    5:hud_char_code=C_SP;     6:hud_char_code=lch("1"); 7:hud_char_code=lch("P");
                                    8:hud_char_code=C_SP;     9:hud_char_code=lch("J"); 10:hud_char_code=lch("O"); 11:hud_char_code=lch("Y");
                                    12:hud_char_code=lch("S"); 13:hud_char_code=lch("T"); 14:hud_char_code=lch("I"); 15:hud_char_code=lch("C");
                                    16:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                                endcase
                                2'd1: case (col_1x - 6'd8)
                                    0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("D"); 3:hud_char_code=lch("E");
                                    4:hud_char_code=C_COL;    5:hud_char_code=C_SP;     6:hud_char_code=lch("1"); 7:hud_char_code=lch("P");
                                    8:hud_char_code=C_SP;     9:hud_char_code=lch("K"); 10:hud_char_code=lch("E"); 11:hud_char_code=lch("Y");
                                    12:hud_char_code=lch("B"); 13:hud_char_code=lch("O"); 14:hud_char_code=lch("A"); 15:hud_char_code=lch("R");
                                    16:hud_char_code=lch("D"); default:hud_char_code=C_SP;
                                endcase
                                2'd2: case (col_1x - 6'd8)
                                    0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("D"); 3:hud_char_code=lch("E");
                                    4:hud_char_code=C_COL;    5:hud_char_code=C_SP;     6:hud_char_code=lch("2"); 7:hud_char_code=lch("P");
                                    8:hud_char_code=C_SP;     9:hud_char_code=lch("D"); 10:hud_char_code=lch("U"); 11:hud_char_code=lch("A");
                                    12:hud_char_code=lch("L"); 13:hud_char_code=C_SP;    14:hud_char_code=lch("J"); 15:hud_char_code=lch("O");
                                    16:hud_char_code=lch("Y"); default:hud_char_code=C_SP;
                                endcase
                                2'd3: case (col_1x - 6'd8)
                                    0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("D"); 3:hud_char_code=lch("E");
                                    4:hud_char_code=C_COL;    5:hud_char_code=C_SP;     6:hud_char_code=lch("2"); 7:hud_char_code=lch("P");
                                    8:hud_char_code=C_SP;     9:hud_char_code=lch("C"); 10:hud_char_code=lch("O"); 11:hud_char_code=C_DSH;
                                    12:hud_char_code=lch("O"); 13:hud_char_code=lch("P"); 14:hud_char_code=C_SP;    15:hud_char_code=lch("J");
                                    16:hud_char_code=lch("+"); 17:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                                endcase
                            endcase
                        end
                    end
                // -------------------------------------------------------------
                // 2. Inverted Triangle Cursor (▼) pointing down at selected character
                //    P1 center gx=100, P2 center gx=220; gy=94..102 (bouncing)
                // -------------------------------------------------------------
                end else if (gy >= tri_y_base && gy < tri_y_base + 9'd9) begin
                    if (tri_dx <= tri_hw) begin
                        hud_bg_en = 1;
                        hud_bg_color = (tri_dx == tri_hw || tri_row == 4'd0) ? 6'd17 : 6'd58;
                    end
                // -------------------------------------------------------------
                // 3. Weapon Names under characters (gy=146..154)
                //    P1 under gx=100 (col_1x=9..16), P2 under gx=220 (col_1x=24..31)
                // -------------------------------------------------------------
                end else if (gy >= 9'd146 && gy < 9'd154 && col_1x >= 6'd9 && col_1x < 6'd17) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd146;
                    hud_text_color = (hero_cursor == 1'b0) ? 6'd58 : 6'd60;
                    case (col_1x - 6'd9)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("1"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p1_weapon, 3'd0); 4:hud_char_code=wname_ch(p1_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p1_weapon, 3'd2); 6:hud_char_code=wname_ch(p1_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p1_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                end else if (gy >= 9'd146 && gy < 9'd154 && col_1x >= 6'd24 && col_1x < 6'd32) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd146;
                    hud_text_color = (hero_cursor == 1'b1) ? 6'd58 : 6'd60;
                    case (col_1x - 6'd24)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("2"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p2_weapon, 3'd0); 4:hud_char_code=wname_ch(p2_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p2_weapon, 3'd2); 6:hud_char_code=wname_ch(p2_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p2_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                // -------------------------------------------------------------
                // 4. Hardware Pushbutton Instruction Line (gy=162..170, col_1x=2..37)
                // -------------------------------------------------------------
                end else if (gy >= 9'd162 && gy < 9'd170 && col_1x >= 6'd2 && col_1x < 6'd38) begin
                    hud_text_en = 1; hud_text_color = 6'd60; hud_char_row = gy - 9'd162;
                    case (col_1x - 6'd2)
                        0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("L");
                        4:hud_char_code=lch("/"); 5:hud_char_code=lch("R"); 6:hud_char_code=C_COL;    7:hud_char_code=lch("P");
                        8:hud_char_code=lch("1"); 9:hud_char_code=lch("/"); 10:hud_char_code=lch("2"); 11:hud_char_code=C_SP;
                        12:hud_char_code=C_SP;    13:hud_char_code=lch("B"); 14:hud_char_code=lch("T"); 15:hud_char_code=lch("N");
                        16:hud_char_code=lch("C"); 17:hud_char_code=C_COL;   18:hud_char_code=lch("H"); 19:hud_char_code=lch("E");
                        20:hud_char_code=lch("A"); 21:hud_char_code=lch("D"); 22:hud_char_code=C_SP;   23:hud_char_code=C_SP;
                        24:hud_char_code=lch("B"); 25:hud_char_code=lch("T"); 26:hud_char_code=lch("N"); 27:hud_char_code=lch("U");
                        28:hud_char_code=lch("/"); 29:hud_char_code=lch("D"); 30:hud_char_code=C_COL;   31:hud_char_code=lch("W");
                        32:hud_char_code=lch("E"); 33:hud_char_code=lch("A"); 34:hud_char_code=lch("P"); 35:hud_char_code=lch("O");
                        36:hud_char_code=lch("N"); default:hud_char_code=C_SP;
                    endcase
                // -------------------------------------------------------------
                // 5. Bouncing Graphical CTA Button (gx=104..216, gy=178..210)
                //    NO "PRESS...TO PLAY" TEXT, NO TEXT BELOW!
                // -------------------------------------------------------------
                end else if (gx >= 9'd104 && gx < 9'd216 && gy >= b_top && gy < b_bot) begin
                    // Inside Text inside Button Face:
                    if (gy >= b_top + 9'd12 && gy < b_top + 9'd20) begin
                        hud_text_en = 1; hud_char_row = gy - (b_top + 9'd12);
                        hud_text_color = 6'd17;
                        if (is_kb_mode) begin
                            // "S P A C E" (col_1x=17..22)
                            case (col_1x - 6'd17)
                                0:hud_char_code=lch("S"); 1:hud_char_code=lch("P"); 2:hud_char_code=lch("A");
                                3:hud_char_code=lch("C"); 4:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                            endcase
                        end else begin
                            // "F I R E" (col_1x=18..21)
                            case (col_1x - 6'd18)
                                0:hud_char_code=lch("F"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("R");
                                3:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                            endcase
                        end
                    end

                    // Button Background Bevel / Fill:
                    hud_bg_en = 1;
                    if (is_kb_mode) begin
                        // Emerald / Cyber Green Keycap
                        hud_bg_color = is_b_edge ? 6'd28 : (is_b_hi ? 6'd17 : (is_b_sh ? 6'd24 : 6'd26));
                    end else begin
                        // Crimson / Golden Arcade Button
                        hud_bg_color = is_b_edge ? 6'd58 : (is_b_hi ? 6'd17 : (is_b_sh ? 6'd32 : 6'd36));
                    end
                end
            end else begin
                // =============================================================
                // CONTROLS GUIDE TERMINAL (PAGES 1, 2, 3)
                // =============================================================
                if (gx >= 9'd24 && gx < 9'd296 && gy >= 9'd16 && gy < 9'd228) begin
                    hud_bg_en = 1;
                    hud_bg_color = (gx == 9'd24 || gx == 9'd295 || gy == 9'd16 || gy == 9'd227 || gy == 9'd42 || gy == 9'd196) ?
                                   ((help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd28)) : 6'd54;
                end
                // Header (gy=24..32)
                if (gy >= 9'd24 && gy < 9'd32 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd24;
                    hud_text_color = (help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd28);
                    if (help_page == 2'd1) begin
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_SP;     2:hud_char_code=lch("1"); 3:hud_char_code=lch("/"); 4:hud_char_code=lch("3");
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("B"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("A"); 9:hud_char_code=lch("R");
                            10:hud_char_code=lch("D"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("H"); 13:hud_char_code=lch("A"); 14:hud_char_code=lch("R");
                            15:hud_char_code=lch("D"); 16:hud_char_code=lch("W"); 17:hud_char_code=lch("A"); 18:hud_char_code=lch("R"); 19:hud_char_code=lch("E");
                            20:hud_char_code=C_SP;    21:hud_char_code=C_RARW; default:hud_char_code=C_SP;
                        endcase
                    end else if (help_page == 2'd2) begin
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_SP;     2:hud_char_code=lch("2"); 3:hud_char_code=lch("/"); 4:hud_char_code=lch("3");
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("J"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("Y"); 9:hud_char_code=lch("S");
                            10:hud_char_code=lch("T"); 11:hud_char_code=lch("I"); 12:hud_char_code=lch("C"); 13:hud_char_code=lch("K"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("C"); 16:hud_char_code=lch("O"); 17:hud_char_code=lch("N"); 18:hud_char_code=lch("T"); 19:hud_char_code=lch("R");
                            20:hud_char_code=lch("O"); 21:hud_char_code=lch("L"); 22:hud_char_code=lch("S"); 23:hud_char_code=C_SP;   24:hud_char_code=C_RARW;
                            default:hud_char_code=C_SP;
                        endcase
                    end else begin
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_SP;     2:hud_char_code=lch("3"); 3:hud_char_code=lch("/"); 4:hud_char_code=lch("3");
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("K"); 7:hud_char_code=lch("E"); 8:hud_char_code=lch("Y"); 9:hud_char_code=lch("B");
                            10:hud_char_code=lch("O"); 11:hud_char_code=lch("A"); 12:hud_char_code=lch("R"); 13:hud_char_code=lch("D"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("C"); 16:hud_char_code=lch("O"); 17:hud_char_code=lch("N"); 18:hud_char_code=lch("T"); 19:hud_char_code=lch("R");
                            20:hud_char_code=lch("O"); 21:hud_char_code=lch("L"); 22:hud_char_code=lch("S"); 23:hud_char_code=C_SP;   24:hud_char_code=C_RARW;
                            default:hud_char_code=C_SP;
                        endcase
                    end
                end

                // PAGE 1: BOARD HARDWARE TERMINAL
                if (help_page == 2'd1) begin
                    if (gy >= 9'd52 && gy < 9'd60 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd52; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("L"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("R"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("S"); 9:hud_char_code=lch("E");
                            10:hud_char_code=lch("L"); 11:hud_char_code=lch("E"); 12:hud_char_code=lch("C"); 13:hud_char_code=lch("T"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("P"); 16:hud_char_code=lch("1"); 17:hud_char_code=C_SP;   18:hud_char_code=lch("/"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("P"); 21:hud_char_code=lch("2"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd66 && gy < 9'd74 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd66; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("C"); 4:hud_char_code=C_COL;
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("C"); 7:hud_char_code=lch("Y"); 8:hud_char_code=lch("C"); 9:hud_char_code=lch("L");
                            10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("H"); 13:hud_char_code=lch("E"); 14:hud_char_code=lch("A");
                            15:hud_char_code=lch("D"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("S"); 18:hud_char_code=lch("T"); 19:hud_char_code=lch("Y");
                            20:hud_char_code=lch("L"); 21:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd80 && gy < 9'd88 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd80; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("U"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("D"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("C"); 9:hud_char_code=lch("Y");
                            10:hud_char_code=lch("C"); 11:hud_char_code=lch("L"); 12:hud_char_code=lch("E"); 13:hud_char_code=C_SP;   14:hud_char_code=lch("6");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("E"); 18:hud_char_code=lch("A"); 19:hud_char_code=lch("P");
                            20:hud_char_code=lch("O"); 21:hud_char_code=lch("N"); 22:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd102 && gy < 9'd110 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd102; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("C"); 3:hud_char_code=C_SP;     4:hud_char_code=lch("R");
                            5:hud_char_code=lch("O"); 6:hud_char_code=lch("A"); 7:hud_char_code=lch("R"); 8:hud_char_code=C_COL;    9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("O"); 12:hud_char_code=lch("N"); 13:hud_char_code=lch("I"); 14:hud_char_code=lch("C");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("A"); 18:hud_char_code=lch("V"); 19:hud_char_code=lch("E");
                            20:hud_char_code=C_SP;    21:hud_char_code=lch("P"); 22:hud_char_code=lch("U"); 23:hud_char_code=lch("S"); 24:hud_char_code=lch("H");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd116 && gy < 9'd124 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd116; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("T"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("M"); 3:hud_char_code=lch("P"); 4:hud_char_code=C_SP;
                            5:hud_char_code=lch("C"); 6:hud_char_code=lch("H"); 7:hud_char_code=lch("I"); 8:hud_char_code=lch("P"); 9:hud_char_code=C_COL;
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("T"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("U"); 14:hud_char_code=lch("C");
                            15:hud_char_code=lch("H"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("F"); 18:hud_char_code=lch("L"); 19:hud_char_code=lch("A");
                            20:hud_char_code=lch("M"); 21:hud_char_code=lch("E"); 22:hud_char_code=C_SP;   23:hud_char_code=lch("A"); 24:hud_char_code=lch("U");
                            25:hud_char_code=lch("R"); 26:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd130 && gy < 9'd138 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd130; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("9"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("F"); 6:hud_char_code=lch("E"); 7:hud_char_code=lch("V"); 8:hud_char_code=lch("E"); 9:hud_char_code=lch("R");
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("D"); 12:hud_char_code=lch("E"); 13:hud_char_code=lch("M"); 14:hud_char_code=lch("O");
                            15:hud_char_code=C_SP;   16:hud_char_code=lch("F"); 17:hud_char_code=lch("O"); 18:hud_char_code=lch("R"); 19:hud_char_code=lch("C");
                            20:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd144 && gy < 9'd152 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd144; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("8"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("7"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("E"); 8:hud_char_code=lch("G"); 9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("H"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("W"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("L"); 16:hud_char_code=lch("I"); 17:hud_char_code=lch("V"); 18:hud_char_code=lch("E"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("T"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("M"); 23:hud_char_code=lch("P"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd158 && gy < 9'd166 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd158; hud_text_color = 6'd28;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("A"); 1:hud_char_code=lch("N"); 2:hud_char_code=C_COL;    3:hud_char_code=C_SP;     4:hud_char_code=lch("6");
                            5:hud_char_code=C_DSH;    6:hud_char_code=lch("D"); 7:hud_char_code=lch("I"); 8:hud_char_code=lch("G"); 9:hud_char_code=lch("I");
                            10:hud_char_code=lch("T"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("S"); 13:hud_char_code=lch("C"); 14:hud_char_code=lch("O");
                            15:hud_char_code=lch("R"); 16:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end
                // PAGE 2: JOYSTICK TERMINAL (PIXEL ART & LABELS)
                end else if (help_page == 2'd2) begin
                    // Left Pointer Line for D-PAD (gx=116..126, gy=74)
                    if (gy == 9'd74 && gx >= 9'd116 && gx < 9'd126) begin
                        hud_bg_en = 1; hud_bg_color = 6'd59;
                    // Right Pointer Lines for Action Buttons
                    end else if (gy == 9'd60 && gx >= 9'd190 && gx < 9'd212) begin
                        hud_bg_en = 1; hud_bg_color = 6'd36; // 1/A Attack (Red)
                    end else if (gy == 9'd74 && gx >= 9'd195 && gx < 9'd212) begin
                        hud_bg_en = 1; hud_bg_color = 6'd58; // 2/B Dash (Orange)
                    end else if (gy == 9'd88 && gx >= 9'd192 && gx < 9'd212) begin
                        hud_bg_en = 1; hud_bg_color = 6'd51; // 3/X Nova (Purple)
                    end else if (gy == 9'd102 && gx >= 9'd188 && gx < 9'd212) begin
                        hud_bg_en = 1; hud_bg_color = 6'd28; // 4/Y Bullet (Green)
                    // D-PAD: MOVE Text (col_1x=4..13, gy=70..78)
                    end else if (gy >= 9'd70 && gy < 9'd78 && col_1x >= 6'd4 && col_1x < 6'd14) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd70; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("D"); 1:hud_char_code=C_DSH;    2:hud_char_code=lch("P"); 3:hud_char_code=lch("A"); 4:hud_char_code=lch("D");
                            5:hud_char_code=C_COL;    6:hud_char_code=lch("M"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("V"); 9:hud_char_code=lch("E");
                            default:hud_char_code=C_SP;
                        endcase
                    // 1/A: ATTACK Text (col_1x=26..35, gy=56..64)
                    end else if (gy >= 9'd56 && gy < 9'd64 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd56; hud_text_color = 6'd36;
                        case (col_1x - 6'd26)
                            0:hud_char_code=lch("1"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("A"); 3:hud_char_code=C_COL;
                            4:hud_char_code=lch("A"); 5:hud_char_code=lch("T"); 6:hud_char_code=lch("T"); 7:hud_char_code=lch("A");
                            8:hud_char_code=lch("C"); 9:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                        endcase
                    // 2/B: DASH Text (col_1x=26..35, gy=70..78)
                    end else if (gy >= 9'd70 && gy < 9'd78 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd70; hud_text_color = 6'd58;
                        case (col_1x - 6'd26)
                            0:hud_char_code=lch("2"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("B"); 3:hud_char_code=C_COL;
                            4:hud_char_code=lch("D"); 5:hud_char_code=lch("A"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("H");
                            default:hud_char_code=C_SP;
                        endcase
                    // 3/X: NOVA Text (col_1x=26..35, gy=84..92)
                    end else if (gy >= 9'd84 && gy < 9'd92 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd84; hud_text_color = 6'd51;
                        case (col_1x - 6'd26)
                            0:hud_char_code=lch("3"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("X"); 3:hud_char_code=C_COL;
                            4:hud_char_code=lch("N"); 5:hud_char_code=lch("O"); 6:hud_char_code=lch("V"); 7:hud_char_code=lch("A");
                            default:hud_char_code=C_SP;
                        endcase
                    // 4/Y: BULLET Text (col_1x=26..35, gy=98..106)
                    end else if (gy >= 9'd98 && gy < 9'd106 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd98; hud_text_color = 6'd28;
                        case (col_1x - 6'd26)
                            0:hud_char_code=lch("4"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("Y"); 3:hud_char_code=C_COL;
                            4:hud_char_code=lch("B"); 5:hud_char_code=lch("U"); 6:hud_char_code=lch("L"); 7:hud_char_code=lch("L");
                            8:hud_char_code=lch("E"); 9:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    // Center START:PAUSE/GUIDE   SELECT:RESET (gy=136..144)
                    end else if (gy >= 9'd136 && gy < 9'd144 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd136; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("A"); 3:hud_char_code=lch("R");
                            4:hud_char_code=lch("T"); 5:hud_char_code=C_COL;    6:hud_char_code=lch("G"); 7:hud_char_code=lch("U");
                            8:hud_char_code=lch("I"); 9:hud_char_code=lch("D"); 10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;
                            12:hud_char_code=C_SP;   13:hud_char_code=lch("S"); 14:hud_char_code=lch("E"); 15:hud_char_code=lch("L");
                            16:hud_char_code=lch("E"); 17:hud_char_code=lch("C"); 18:hud_char_code=lch("T"); 19:hud_char_code=C_COL;
                            20:hud_char_code=lch("R"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("S"); 23:hud_char_code=lch("E");
                            24:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    end
                // PAGE 3: KEYBOARD CONTROLS TERMINAL
                end else begin
                    if (gy >= 9'd56 && gy < 9'd64 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd56; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("W"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("A"); 3:hud_char_code=lch("/");
                            4:hud_char_code=lch("S"); 5:hud_char_code=lch("/"); 6:hud_char_code=lch("D"); 7:hud_char_code=C_COL;
                            8:hud_char_code=C_SP;     9:hud_char_code=lch("M"); 10:hud_char_code=lch("O"); 11:hud_char_code=lch("V");
                            12:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd70 && gy < 9'd78 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd70; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("P"); 2:hud_char_code=lch("A"); 3:hud_char_code=lch("C");
                            4:hud_char_code=lch("E"); 5:hud_char_code=lch("/"); 6:hud_char_code=lch("J"); 7:hud_char_code=C_COL;
                            8:hud_char_code=C_SP;     9:hud_char_code=lch("A"); 10:hud_char_code=lch("T"); 11:hud_char_code=lch("T");
                            12:hud_char_code=lch("A"); 13:hud_char_code=lch("C"); 14:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd84 && gy < 9'd92 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd84; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("K"); 1:hud_char_code=C_COL;    2:hud_char_code=C_SP;     3:hud_char_code=lch("D");
                            4:hud_char_code=lch("A"); 5:hud_char_code=lch("S"); 6:hud_char_code=lch("H"); 7:hud_char_code=C_SP;
                            8:hud_char_code=lch("B"); 9:hud_char_code=lch("U"); 10:hud_char_code=lch("R"); 11:hud_char_code=lch("S");
                            12:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd98 && gy < 9'd106 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd98; hud_text_color = 6'd51;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("3"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("L"); 3:hud_char_code=C_COL;
                            4:hud_char_code=C_SP;     5:hud_char_code=lch("3"); 6:hud_char_code=lch("6"); 7:hud_char_code=lch("0");
                            8:hud_char_code=C_SP;     9:hud_char_code=lch("N"); 10:hud_char_code=lch("O"); 11:hud_char_code=lch("V");
                            12:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd112 && gy < 9'd120 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd112; hud_text_color = 6'd28;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("4"); 1:hud_char_code=lch("/"); 2:hud_char_code=lch("U"); 3:hud_char_code=C_COL;
                            4:hud_char_code=C_SP;     5:hud_char_code=lch("B"); 6:hud_char_code=lch("U"); 7:hud_char_code=lch("L");
                            8:hud_char_code=lch("L"); 9:hud_char_code=lch("E"); 10:hud_char_code=lch("T"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd126 && gy < 9'd134 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd126; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("1"); 1:hud_char_code=C_DSH;    2:hud_char_code=lch("4"); 3:hud_char_code=C_COL;
                            4:hud_char_code=C_SP;     5:hud_char_code=lch("Q"); 6:hud_char_code=lch("U"); 7:hud_char_code=lch("I");
                            8:hud_char_code=lch("Z"); 9:hud_char_code=C_SP;     10:hud_char_code=lch("D"); 11:hud_char_code=lch("O");
                            12:hud_char_code=lch("O"); 13:hud_char_code=lch("R"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd140 && gy < 9'd148 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd140; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("E"); 1:hud_char_code=lch("N"); 2:hud_char_code=lch("T"); 3:hud_char_code=lch("E");
                            4:hud_char_code=lch("R"); 5:hud_char_code=C_COL;    6:hud_char_code=C_SP;     7:hud_char_code=lch("S");
                            8:hud_char_code=lch("T"); 9:hud_char_code=lch("A"); 10:hud_char_code=lch("R"); 11:hud_char_code=lch("T");
                            12:hud_char_code=C_SP;   13:hud_char_code=lch("/"); 14:hud_char_code=C_SP;   15:hud_char_code=lch("P");
                            16:hud_char_code=lch("A"); 17:hud_char_code=lch("U"); 18:hud_char_code=lch("S"); 19:hud_char_code=lch("E");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd154 && gy < 9'd162 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd154; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("E"); 1:hud_char_code=lch("S"); 2:hud_char_code=lch("C"); 3:hud_char_code=C_COL;
                            4:hud_char_code=C_SP;     5:hud_char_code=lch("G"); 6:hud_char_code=lch("U"); 7:hud_char_code=lch("I");
                            8:hud_char_code=lch("D"); 9:hud_char_code=lch("E"); 10:hud_char_code=C_SP;   11:hud_char_code=lch("/");
                            12:hud_char_code=C_SP;   13:hud_char_code=lch("B"); 14:hud_char_code=lch("A"); 15:hud_char_code=lch("C");
                            16:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                        endcase
                    end
                end

                // Footer Navigation Line (gy=204..212)
                if (gy >= 9'd204 && gy < 9'd212 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd204;
                    hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17;
                    if (help_page < 2'd3) begin
                        case (col_1x - 6'd5)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("N"); 2:hud_char_code=lch("E"); 3:hud_char_code=lch("X"); 4:hud_char_code=lch("T");
                            5:hud_char_code=C_COL;    6:hud_char_code=lch("S"); 7:hud_char_code=lch("T"); 8:hud_char_code=lch("A"); 9:hud_char_code=lch("R");
                            10:hud_char_code=lch("T"); 11:hud_char_code=C_RARW; 12:hud_char_code=C_SP;   13:hud_char_code=C_SP;    14:hud_char_code=C_LARW;
                            15:hud_char_code=lch("B"); 16:hud_char_code=lch("A"); 17:hud_char_code=lch("C"); 18:hud_char_code=lch("K"); 19:hud_char_code=C_COL;
                            20:hud_char_code=lch("L"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("F"); 23:hud_char_code=lch("T"); 24:hud_char_code=C_RARW;
                            default:hud_char_code=C_SP;
                        endcase
                    end else begin
                        case (col_1x - 6'd4)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("P"); 2:hud_char_code=lch("L"); 3:hud_char_code=lch("A"); 4:hud_char_code=lch("Y");
                            5:hud_char_code=C_COL;    6:hud_char_code=lch("E"); 7:hud_char_code=lch("N"); 8:hud_char_code=lch("T"); 9:hud_char_code=lch("E");
                            10:hud_char_code=lch("R"); 11:hud_char_code=C_RARW; 12:hud_char_code=C_SP;   13:hud_char_code=C_SP;    14:hud_char_code=C_LARW;
                            15:hud_char_code=lch("B"); 16:hud_char_code=lch("A"); 17:hud_char_code=lch("C"); 18:hud_char_code=lch("K"); 19:hud_char_code=C_COL;
                            20:hud_char_code=lch("L"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("F"); 23:hud_char_code=lch("T"); 24:hud_char_code=C_RARW;
                            default:hud_char_code=C_SP;
                        endcase
                    end
                end
            end
        end"""

updated_code = code[:idx1] + new_code_block + "\n" + code[idx2:]
with open(path, "w") as f:
    f.write(updated_code)

print("Successfully updated vga_renderer_v2.v with clean wire declarations!")
