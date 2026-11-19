import os

print("Updating vga_renderer_v2.v Part 2 (Title & Guide Overhaul)...")
ren_path = r'D:\vivado_pj\DRAGO_NEXUS_V2\rtl\vga_renderer_v2.v'
with open(ren_path, 'r', encoding='utf-8') as f:
    code = f.read()

# Locate the start and end of ST_TITLE in vga_renderer_v2.v
start_marker = "        if (game_state == 3'd0) begin"
end_marker = "        end else if (game_state == 3'd1) begin"

idx_start = code.find(start_marker)
idx_end = code.find(end_marker)

assert idx_start != -1, "start_marker not found"
assert idx_end != -1, "end_marker not found"

new_title_guide_block = """        if (game_state == 3'd0) begin
            if (help_page == 2'd0) begin
                // Mode Selector Banner (gy=64..80)
                if (gy >= 9'd64 && gy <= 9'd80 && gx >= 9'd44 && gx < 9'd276) begin
                    hud_bg_en = 1; hud_bg_color = (gy==9'd64||gy==9'd80||gx==9'd44||gx==9'd275) ? 6'd58 : 6'd54;
                    if (gy >= 9'd68 && gy < 9'd76 && col_1x >= 6'd6 && col_1x <= 6'd33) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd68;
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
                end else if (gy >= 9'd84 && gy < 9'd92 && col_1x >= 6'd10 && col_1x < 6'd30) begin
                    hud_text_en = 1; hud_text_color = joy_link_ok ? 6'd28 : 6'd57; hud_char_row = gy - 9'd84;
                    case (col_1x - 6'd10)
                        0:hud_char_code=lch("U"); 1:hud_char_code=lch("S"); 2:hud_char_code=lch("B"); 3:hud_char_code=C_SP;
                        4:hud_char_code=lch("J"); 5:hud_char_code=lch("O"); 6:hud_char_code=lch("Y"); 7:hud_char_code=C_COL; 8:hud_char_code=C_SP;
                        9:hud_char_code=lch("O"); 10:hud_char_code=joy_link_ok?lch("N"):lch("F"); 11:hud_char_code=joy_link_ok?lch("L"):lch("F");
                        12:hud_char_code=joy_link_ok?lch("I"):lch("L"); 13:hud_char_code=joy_link_ok?lch("N"):lch("I");
                        14:hud_char_code=joy_link_ok?lch("E"):lch("N"); 15:hud_char_code=joy_link_ok?lch("!"):lch("E"); default:hud_char_code=C_SP;
                    endcase
                // Cursor Indicator above P1 (gx=124..132) or P2 (gx=220..228)
                end else if (gy >= 9'd94 && gy <= 9'd100 &&
                             ((hero_cursor == 1'b0 && gx >= 9'd120 && gx <= 9'd136) ||
                              (hero_cursor == 1'b1 && gx >= 9'd216 && gx <= 9'd232))) begin
                    if (anim_cnt[23]) begin
                        hud_bg_en = 1; hud_bg_color = 6'd58;
                    end
                // Weapon Name for P1 (col_1x=12..20, gy=154..162)
                end else if (gy >= 9'd154 && gy < 9'd162 && col_1x >= 6'd12 && col_1x < 6'd21) begin
                    hud_text_en = 1; hud_text_color = 6'd58; hud_char_row = gy - 9'd154;
                    case (col_1x - 6'd12)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("1"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p1_weapon, 3'd0); 4:hud_char_code=wname_ch(p1_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p1_weapon, 3'd2); 6:hud_char_code=wname_ch(p1_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p1_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                // Weapon Name for P2 (col_1x=24..32, gy=154..162)
                end else if (gy >= 9'd154 && gy < 9'd162 && col_1x >= 6'd24 && col_1x < 6'd33) begin
                    hud_text_en = 1; hud_text_color = 6'd59; hud_char_row = gy - 9'd154;
                    case (col_1x - 6'd24)
                        0:hud_char_code=lch("P"); 1:hud_char_code=lch("2"); 2:hud_char_code=C_COL;
                        3:hud_char_code=wname_ch(p2_weapon, 3'd0); 4:hud_char_code=wname_ch(p2_weapon, 3'd1);
                        5:hud_char_code=wname_ch(p2_weapon, 3'd2); 6:hud_char_code=wname_ch(p2_weapon, 3'd3);
                        7:hud_char_code=wname_ch(p2_weapon, 3'd4); default:hud_char_code=C_SP;
                    endcase
                // Hardware Pushbutton Instruction Line (gy=172..180, col_1x=3..37)
                end else if (gy >= 9'd172 && gy < 9'd180 && col_1x >= 6'd3 && col_1x < 6'd37) begin
                    hud_text_en = 1; hud_text_color = 6'd60; hud_char_row = gy - 9'd172;
                    case (col_1x - 6'd3)
                        0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("L");
                        4:hud_char_code=lch("/"); 5:hud_char_code=lch("R"); 6:hud_char_code=C_COL;    7:hud_char_code=lch("P");
                        8:hud_char_code=lch("1"); 9:hud_char_code=lch("/"); 10:hud_char_code=lch("2"); 11:hud_char_code=C_SP;
                        12:hud_char_code=lch("B"); 13:hud_char_code=lch("T"); 14:hud_char_code=lch("N"); 15:hud_char_code=lch("C");
                        16:hud_char_code=C_COL;   17:hud_char_code=lch("H"); 18:hud_char_code=lch("E"); 19:hud_char_code=lch("A");
                        20:hud_char_code=lch("D"); 21:hud_char_code=C_SP;   22:hud_char_code=lch("B"); 23:hud_char_code=lch("T");
                        24:hud_char_code=lch("N"); 25:hud_char_code=lch("U"); 26:hud_char_code=lch("/"); 27:hud_char_code=lch("D");
                        28:hud_char_code=C_COL;   29:hud_char_code=lch("W"); 30:hud_char_code=lch("E"); 31:hud_char_code=lch("A");
                        32:hud_char_code=lch("P"); 33:hud_char_code=lch("O"); 34:hud_char_code=lch("N"); default:hud_char_code=C_SP;
                    endcase
                // Animated Bouncing Action Button (gy=198..214)
                end else if (gy >= (9'd200 - (anim_cnt[22:20] < 3'd4 ? anim_cnt[22:20] : (3'd7 - anim_cnt[22:20]))) &&
                             gy <  (9'd208 - (anim_cnt[22:20] < 3'd4 ? anim_cnt[22:20] : (3'd7 - anim_cnt[22:20]))) &&
                             col_1x >= 6'd6 && col_1x <= 6'd33) begin
                    hud_text_en = 1; hud_char_row = gy[2:0];
                    hud_text_color = anim_cnt[23] ? 6'd58 : 6'd17;
                    if (control_mode == 2'd1 || control_mode == 2'd3) begin
                        // Keyboard mode: Bouncing << PRESS SPACE TO PLAY! >>
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_LARW;   2:hud_char_code=C_SP;     3:hud_char_code=lch("P");
                            4:hud_char_code=lch("R"); 5:hud_char_code=lch("E"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("S");
                            8:hud_char_code=C_SP;     9:hud_char_code=lch("S"); 10:hud_char_code=lch("P"); 11:hud_char_code=lch("A");
                            12:hud_char_code=lch("C"); 13:hud_char_code=lch("E"); 14:hud_char_code=C_SP;   15:hud_char_code=lch("T");
                            16:hud_char_code=lch("O"); 17:hud_char_code=C_SP;   18:hud_char_code=lch("P"); 19:hud_char_code=lch("L");
                            20:hud_char_code=lch("A"); 21:hud_char_code=lch("Y"); 22:hud_char_code=lch("!"); 23:hud_char_code=C_SP;
                            24:hud_char_code=C_RARW;  25:hud_char_code=C_RARW;  default:hud_char_code=C_SP;
                        endcase
                    end else begin
                        // Joystick mode: Bouncing << PRESS FIRE TO PLAY! >>
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_LARW;   2:hud_char_code=C_SP;     3:hud_char_code=lch("P");
                            4:hud_char_code=lch("R"); 5:hud_char_code=lch("E"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("S");
                            8:hud_char_code=C_SP;     9:hud_char_code=lch("F"); 10:hud_char_code=lch("I"); 11:hud_char_code=lch("R");
                            12:hud_char_code=lch("E"); 13:hud_char_code=C_SP;    14:hud_char_code=lch("T"); 15:hud_char_code=lch("O");
                            16:hud_char_code=C_SP;    17:hud_char_code=lch("P"); 18:hud_char_code=lch("L"); 19:hud_char_code=lch("A");
                            20:hud_char_code=lch("Y"); 21:hud_char_code=lch("!"); 22:hud_char_code=C_SP;   23:hud_char_code=C_RARW;
                            24:hud_char_code=C_RARW;  default:hud_char_code=C_SP;
                        endcase
                    end
                // Bouncing Guide Prompt Button (gy=220..228)
                end else if (gy >= (9'd220 - (anim_cnt[22:21] ? 9'd1 : 9'd0)) &&
                             gy <  (9'd228 - (anim_cnt[22:21] ? 9'd1 : 9'd0)) &&
                             col_1x >= 6'd6 && col_1x <= 6'd33) begin
                    hud_text_en = 1; hud_text_color = 6'd50; hud_char_row = gy[2:0];
                    case (col_1x - 6'd6)
                        0:hud_char_code=lch("["); 1:hud_char_code=lch("S"); 2:hud_char_code=lch("T"); 3:hud_char_code=lch("A");
                        4:hud_char_code=lch("R"); 5:hud_char_code=lch("T"); 6:hud_char_code=lch("/"); 7:hud_char_code=lch("B");
                        8:hud_char_code=lch("T"); 9:hud_char_code=lch("N"); 10:hud_char_code=lch("U"); 11:hud_char_code=C_COL;
                        12:hud_char_code=C_SP;    13:hud_char_code=lch("G"); 14:hud_char_code=lch("U"); 15:hud_char_code=lch("I");
                        16:hud_char_code=lch("D"); 17:hud_char_code=lch("E"); 18:hud_char_code=C_SP;   19:hud_char_code=lch("M");
                        20:hud_char_code=lch("E"); 21:hud_char_code=lch("N"); 22:hud_char_code=lch("U"); 23:hud_char_code=lch("]");
                        default:hud_char_code=C_SP;
                    endcase
                end
            end else begin
                // =============================================================
                // CONTROLS GUIDE TERMINAL (PAGES 1, 2, 3)
                // =============================================================
                if (gx >= 9'd24 && gx < 9'd296 && gy >= 9'd16 && gy < 9'd228) begin
                    hud_bg_en = 1;
                    hud_bg_color = (gx == 9'd24 || gx == 9'd295 || gy == 9'd16 || gy == 9'd227 || gy == 9'd42 || gy == 9'd196) ?
                                   ((help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd60)) : 6'd54;
                end
                // Header (gy=24..31)
                if (gy >= 9'd24 && gy < 9'd32 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd24;
                    hud_text_color = (help_page == 2'd1) ? 6'd58 : ((help_page == 2'd2) ? 6'd59 : 6'd60);
                    if (help_page == 2'd1) begin
                        case (col_1x - 6'd6)
                            0:hud_char_code=C_LARW;   1:hud_char_code=C_SP;     2:hud_char_code=lch("1"); 3:hud_char_code=lch("/"); 4:hud_char_code=lch("3");
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("B"); 7:hud_char_code=lch("O"); 8:hud_char_code=lch("A"); 9:hud_char_code=lch("R");
                            10:hud_char_code=lch("D"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("C"); 13:hud_char_code=lch("O"); 14:hud_char_code=lch("N");
                            15:hud_char_code=lch("T"); 16:hud_char_code=lch("R"); 17:hud_char_code=lch("O"); 18:hud_char_code=lch("L"); 19:hud_char_code=lch("S");
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

                // ---------------- PAGE 1: NEXYS BOARD ----------------
                if (help_page == 2'd1) begin
                    if (gy >= 9'd50 && gy < 9'd58 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd50; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("5"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("B"); 3:hud_char_code=lch("O"); 4:hud_char_code=lch("A");
                            5:hud_char_code=lch("R"); 6:hud_char_code=lch("D"); 7:hud_char_code=C_SP;     8:hud_char_code=lch("B"); 9:hud_char_code=lch("U");
                            10:hud_char_code=lch("T"); 11:hud_char_code=lch("T"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("N"); 14:hud_char_code=lch("S");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("("); 17:hud_char_code=lch("L"); 18:hud_char_code=lch("O"); 19:hud_char_code=lch("B");
                            20:hud_char_code=lch("B"); 21:hud_char_code=lch("Y"); 22:hud_char_code=lch(")"); 23:hud_char_code=C_COL;   default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd64 && gy < 9'd72 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd64; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("L"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("R"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("S"); 9:hud_char_code=lch("E");
                            10:hud_char_code=lch("L"); 11:hud_char_code=lch("E"); 12:hud_char_code=lch("C"); 13:hud_char_code=lch("T"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("P"); 16:hud_char_code=lch("1"); 17:hud_char_code=lch("/"); 18:hud_char_code=lch("2"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("H"); 21:hud_char_code=lch("E"); 22:hud_char_code=lch("R"); 23:hud_char_code=lch("O"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd76 && gy < 9'd84 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd76; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("C"); 4:hud_char_code=C_COL;
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("C"); 7:hud_char_code=lch("Y"); 8:hud_char_code=lch("C"); 9:hud_char_code=lch("L");
                            10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("H"); 13:hud_char_code=lch("E"); 14:hud_char_code=lch("A");
                            15:hud_char_code=lch("D"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("("); 18:hud_char_code=lch("4"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("S"); 21:hud_char_code=lch("T"); 22:hud_char_code=lch("Y"); 23:hud_char_code=lch("L"); 24:hud_char_code=lch(")");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd88 && gy < 9'd96 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd88; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("B"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("N"); 3:hud_char_code=lch("U"); 4:hud_char_code=lch("/");
                            5:hud_char_code=lch("D"); 6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("C"); 9:hud_char_code=lch("Y");
                            10:hud_char_code=lch("C"); 11:hud_char_code=lch("L"); 12:hud_char_code=lch("E"); 13:hud_char_code=C_SP;   14:hud_char_code=lch("6");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("E"); 18:hud_char_code=lch("A"); 19:hud_char_code=lch("P");
                            20:hud_char_code=lch("O"); 21:hud_char_code=lch("N"); 22:hud_char_code=lch("S"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd106 && gy < 9'd114 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd106; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("I"); 1:hud_char_code=lch("N"); 2:hud_char_code=C_DSH;    3:hud_char_code=lch("G"); 4:hud_char_code=lch("A");
                            5:hud_char_code=lch("M"); 6:hud_char_code=lch("E"); 7:hud_char_code=C_SP;     8:hud_char_code=lch("H"); 9:hud_char_code=lch("A");
                            10:hud_char_code=lch("R"); 11:hud_char_code=lch("D"); 12:hud_char_code=lch("W"); 13:hud_char_code=lch("A"); 14:hud_char_code=lch("R");
                            15:hud_char_code=lch("E"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("S"); 18:hud_char_code=lch("E"); 19:hud_char_code=lch("N");
                            20:hud_char_code=lch("S"); 21:hud_char_code=lch("O"); 22:hud_char_code=lch("R"); 23:hud_char_code=lch("S"); 24:hud_char_code=C_COL;
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd120 && gy < 9'd128 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd120; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("I"); 2:hud_char_code=lch("C"); 3:hud_char_code=C_SP;     4:hud_char_code=lch("R");
                            5:hud_char_code=lch("O"); 6:hud_char_code=lch("A"); 7:hud_char_code=lch("R"); 8:hud_char_code=C_COL;    9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("O"); 12:hud_char_code=lch("N"); 13:hud_char_code=lch("I"); 14:hud_char_code=lch("C");
                            15:hud_char_code=C_SP;    16:hud_char_code=lch("W"); 17:hud_char_code=lch("A"); 18:hud_char_code=lch("V"); 19:hud_char_code=lch("E");
                            20:hud_char_code=C_SP;    21:hud_char_code=lch("P"); 22:hud_char_code=lch("U"); 23:hud_char_code=lch("S"); 24:hud_char_code=lch("H");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd132 && gy < 9'd140 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd132; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("T"); 1:hud_char_code=lch("E"); 2:hud_char_code=lch("M"); 3:hud_char_code=lch("P"); 4:hud_char_code=C_SP;
                            5:hud_char_code=lch("C"); 6:hud_char_code=lch("H"); 7:hud_char_code=lch("I"); 8:hud_char_code=lch("P"); 9:hud_char_code=C_COL;
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("T"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("U"); 14:hud_char_code=lch("C");
                            15:hud_char_code=lch("H"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("F"); 18:hud_char_code=lch("L"); 19:hud_char_code=lch("A");
                            20:hud_char_code=lch("M"); 21:hud_char_code=lch("E"); 22:hud_char_code=C_SP;   23:hud_char_code=lch("A"); 24:hud_char_code=lch("U");
                            25:hud_char_code=lch("R"); 26:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd144 && gy < 9'd152 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd144; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("9"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("F"); 6:hud_char_code=lch("E"); 7:hud_char_code=lch("V"); 8:hud_char_code=lch("E"); 9:hud_char_code=lch("R");
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("D"); 12:hud_char_code=lch("E"); 13:hud_char_code=lch("M"); 14:hud_char_code=lch("O");
                            15:hud_char_code=C_SP;   16:hud_char_code=lch("F"); 17:hud_char_code=lch("O"); 18:hud_char_code=lch("R"); 19:hud_char_code=lch("C");
                            20:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd156 && gy < 9'd164 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd156; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("8"); 3:hud_char_code=C_COL;    4:hud_char_code=C_SP;
                            5:hud_char_code=lch("7"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("E"); 8:hud_char_code=lch("G"); 9:hud_char_code=C_SP;
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("H"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("W"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("T"); 16:hud_char_code=lch("E"); 17:hud_char_code=lch("M"); 18:hud_char_code=lch("P"); 19:hud_char_code=C_SP;
                            20:hud_char_code=lch("C"); default:hud_char_code=C_SP;
                        endcase
                    end
                end

                // ---------------- PAGE 2: JOYSTICK ----------------
                else if (help_page == 2'd2) begin
                    // Left of joystick callouts (col_1x=4..13)
                    if (gy >= 9'd66 && gy < 9'd74 && col_1x >= 6'd4 && col_1x < 6'd14) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd66; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("["); 1:hud_char_code=lch("D"); 2:hud_char_code=C_DSH;    3:hud_char_code=lch("P"); 4:hud_char_code=lch("A");
                            5:hud_char_code=lch("D"); 6:hud_char_code=lch("]"); 7:hud_char_code=C_SP;     8:hud_char_code=C_RARW;   default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd78 && gy < 9'd86 && col_1x >= 6'd4 && col_1x < 6'd14) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd78; hud_text_color = 6'd59;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("L"); 1:hud_char_code=C_DSH;    2:hud_char_code=lch("S"); 3:hud_char_code=lch("T"); 4:hud_char_code=lch("I");
                            5:hud_char_code=lch("C"); 6:hud_char_code=lch("K"); 7:hud_char_code=C_SP;     8:hud_char_code=C_RARW;   default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd90 && gy < 9'd98 && col_1x >= 6'd4 && col_1x < 6'd14) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd90; hud_text_color = 6'd17;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("M"); 1:hud_char_code=lch("O"); 2:hud_char_code=lch("V"); 3:hud_char_code=lch("E"); 4:hud_char_code=C_SP;
                            5:hud_char_code=lch("H"); 6:hud_char_code=lch("E"); 7:hud_char_code=lch("R"); 8:hud_char_code=lch("O"); default:hud_char_code=C_SP;
                        endcase
                    // Right of joystick callouts (col_1x=26..36)
                    end else if (gy >= 9'd56 && gy < 9'd64 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd56; hud_text_color = 6'd58;
                        case (col_1x - 6'd26)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("1"); 2:hud_char_code=lch("/"); 3:hud_char_code=lch("A"); 4:hud_char_code=C_COL;
                            5:hud_char_code=lch("A"); 6:hud_char_code=lch("T"); 7:hud_char_code=lch("T"); 8:hud_char_code=lch("A"); 9:hud_char_code=lch("C");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd70 && gy < 9'd78 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd70; hud_text_color = 6'd58;
                        case (col_1x - 6'd26)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("2"); 2:hud_char_code=lch("/"); 3:hud_char_code=lch("B"); 4:hud_char_code=C_COL;
                            5:hud_char_code=lch("D"); 6:hud_char_code=lch("A"); 7:hud_char_code=lch("S"); 8:hud_char_code=lch("H"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd84 && gy < 9'd92 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd84; hud_text_color = 6'd58;
                        case (col_1x - 6'd26)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("3"); 2:hud_char_code=lch("/"); 3:hud_char_code=lch("X"); 4:hud_char_code=C_COL;
                            5:hud_char_code=lch("N"); 6:hud_char_code=lch("O"); 7:hud_char_code=lch("V"); 8:hud_char_code=lch("A"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd98 && gy < 9'd106 && col_1x >= 6'd26 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd98; hud_text_color = 6'd58;
                        case (col_1x - 6'd26)
                            0:hud_char_code=C_LARW;   1:hud_char_code=lch("4"); 2:hud_char_code=lch("/"); 3:hud_char_code=lch("Y"); 4:hud_char_code=C_COL;
                            5:hud_char_code=lch("B"); 6:hud_char_code=lch("U"); 7:hud_char_code=lch("L"); 8:hud_char_code=lch("L"); 9:hud_char_code=lch("T");
                            default:hud_char_code=C_SP;
                        endcase
                    // Center bottom
                    end else if (gy >= 9'd132 && gy < 9'd140 && col_1x >= 6'd6 && col_1x < 6'd34) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd132; hud_text_color = 6'd17;
                        case (col_1x - 6'd6)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("T"); 2:hud_char_code=lch("A"); 3:hud_char_code=lch("R"); 4:hud_char_code=lch("T");
                            5:hud_char_code=C_COL;    6:hud_char_code=lch("P"); 7:hud_char_code=lch("A"); 8:hud_char_code=lch("U"); 9:hud_char_code=lch("S");
                            10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;   12:hud_char_code=C_SP;    13:hud_char_code=lch("S"); 14:hud_char_code=lch("E");
                            15:hud_char_code=lch("L"); 16:hud_char_code=lch("E"); 17:hud_char_code=lch("C"); 18:hud_char_code=lch("T"); 19:hud_char_code=C_COL;
                            20:hud_char_code=lch("G"); 21:hud_char_code=lch("U"); 22:hud_char_code=lch("I"); 23:hud_char_code=lch("D"); 24:hud_char_code=lch("E");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd148 && gy < 9'd156 && col_1x >= 6'd6 && col_1x < 6'd34) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd148; hud_text_color = 6'd60;
                        case (col_1x - 6'd6)
                            0:hud_char_code=lch("T"); 1:hud_char_code=lch("W"); 2:hud_char_code=lch("I"); 3:hud_char_code=lch("N"); 4:hud_char_code=C_SP;
                            5:hud_char_code=lch("U"); 6:hud_char_code=lch("S"); 7:hud_char_code=lch("B"); 8:hud_char_code=C_SP;     9:hud_char_code=lch("D");
                            10:hud_char_code=lch("U"); 11:hud_char_code=lch("A"); 12:hud_char_code=lch("L"); 13:hud_char_code=lch("S"); 14:hud_char_code=lch("H");
                            15:hud_char_code=lch("O"); 16:hud_char_code=lch("C"); 17:hud_char_code=lch("K"); 18:hud_char_code=C_SP;   19:hud_char_code=lch("O");
                            20:hud_char_code=lch("K"); 21:hud_char_code=lch("!"); default:hud_char_code=C_SP;
                        endcase
                    end
                end

                // ---------------- PAGE 3: KEYBOARD ----------------
                else begin
                    if (gy >= 9'd52 && gy < 9'd60 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd52; hud_text_color = 6'd59;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("W"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("A"); 3:hud_char_code=C_SP;     4:hud_char_code=lch("S");
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("D"); 7:hud_char_code=C_SP;     8:hud_char_code=C_COL;    9:hud_char_code=C_SP;
                            10:hud_char_code=lch("M"); 11:hud_char_code=lch("O"); 12:hud_char_code=lch("V"); 13:hud_char_code=lch("E"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("H"); 16:hud_char_code=lch("E"); 17:hud_char_code=lch("R"); 18:hud_char_code=lch("O"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd68 && gy < 9'd76 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd68; hud_text_color = 6'd17;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("S"); 1:hud_char_code=lch("P"); 2:hud_char_code=lch("A"); 3:hud_char_code=lch("C"); 4:hud_char_code=lch("E");
                            5:hud_char_code=C_SP;     6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("W"); 9:hud_char_code=lch("E");
                            10:hud_char_code=lch("A"); 11:hud_char_code=lch("P"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("N"); 14:hud_char_code=C_SP;
                            15:hud_char_code=lch("A"); 16:hud_char_code=lch("T"); 17:hud_char_code=lch("T"); 18:hud_char_code=lch("A"); 19:hud_char_code=lch("C");
                            20:hud_char_code=lch("K"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd84 && gy < 9'd92 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd84; hud_text_color = 6'd17;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("K"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("K"); 3:hud_char_code=lch("E"); 4:hud_char_code=lch("Y");
                            5:hud_char_code=C_SP;     6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("D"); 9:hud_char_code=lch("A");
                            10:hud_char_code=lch("S"); 11:hud_char_code=lch("H"); 12:hud_char_code=C_SP;   13:hud_char_code=lch("E"); 14:hud_char_code=lch("V");
                            15:hud_char_code=lch("A"); 16:hud_char_code=lch("D"); 17:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd100 && gy < 9'd108 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd100; hud_text_color = 6'd17;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("1"); 1:hud_char_code=C_DSH;    2:hud_char_code=lch("4"); 3:hud_char_code=C_SP;     4:hud_char_code=lch("K");
                            5:hud_char_code=lch("E"); 6:hud_char_code=lch("Y"); 7:hud_char_code=lch("S"); 8:hud_char_code=C_SP;     9:hud_char_code=C_COL;
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("L"); 12:hud_char_code=lch("O"); 13:hud_char_code=lch("G"); 14:hud_char_code=lch("I");
                            15:hud_char_code=lch("C"); 16:hud_char_code=C_SP;   17:hud_char_code=lch("Q"); 18:hud_char_code=lch("U"); 19:hud_char_code=lch("I");
                            20:hud_char_code=lch("Z"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd116 && gy < 9'd124 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd116; hud_text_color = 6'd17;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("E"); 1:hud_char_code=lch("N"); 2:hud_char_code=lch("T"); 3:hud_char_code=lch("E"); 4:hud_char_code=lch("R");
                            5:hud_char_code=C_SP;     6:hud_char_code=C_COL;    7:hud_char_code=C_SP;     8:hud_char_code=lch("S"); 9:hud_char_code=lch("T");
                            10:hud_char_code=lch("A"); 11:hud_char_code=lch("R"); 12:hud_char_code=lch("T"); 13:hud_char_code=C_SP;   14:hud_char_code=lch("G");
                            15:hud_char_code=lch("A"); 16:hud_char_code=lch("M"); 17:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd132 && gy < 9'd140 && col_1x >= 6'd5 && col_1x < 6'd35) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd132; hud_text_color = 6'd17;
                        case (col_1x - 6'd5)
                            0:hud_char_code=lch("E"); 1:hud_char_code=lch("S"); 2:hud_char_code=lch("C"); 3:hud_char_code=C_SP;     4:hud_char_code=C_COL;
                            5:hud_char_code=C_SP;     6:hud_char_code=lch("P"); 7:hud_char_code=lch("A"); 8:hud_char_code=lch("U"); 9:hud_char_code=lch("S");
                            10:hud_char_code=lch("E"); 11:hud_char_code=C_SP;   12:hud_char_code=lch("/"); 13:hud_char_code=C_SP;    14:hud_char_code=lch("G");
                            15:hud_char_code=lch("U"); 16:hud_char_code=lch("I"); 17:hud_char_code=lch("D"); 18:hud_char_code=lch("E"); default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd152 && gy < 9'd160 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd152; hud_text_color = 6'd58;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("*"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("W"); 3:hud_char_code=lch("I"); 4:hud_char_code=lch("R");
                            5:hud_char_code=lch("E"); 6:hud_char_code=lch("L"); 7:hud_char_code=lch("E"); 8:hud_char_code=lch("S"); 9:hud_char_code=lch("S");
                            10:hud_char_code=C_SP;   11:hud_char_code=lch("K"); 12:hud_char_code=lch("B"); 13:hud_char_code=C_COL;   14:hud_char_code=C_SP;
                            15:hud_char_code=lch("J"); 16:hud_char_code=lch("O"); 17:hud_char_code=lch("Y"); 18:hud_char_code=C_DSH;   19:hud_char_code=lch("B");
                            20:hud_char_code=lch("R"); 21:hud_char_code=lch("I"); 22:hud_char_code=lch("D"); 23:hud_char_code=lch("G"); 24:hud_char_code=lch("E");
                            default:hud_char_code=C_SP;
                        endcase
                    end else if (gy >= 9'd166 && gy < 9'd174 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                        hud_text_en = 1; hud_char_row = gy - 9'd166; hud_text_color = 6'd60;
                        case (col_1x - 6'd4)
                            0:hud_char_code=lch("*"); 1:hud_char_code=C_SP;     2:hud_char_code=lch("W"); 3:hud_char_code=lch("I"); 4:hud_char_code=lch("R");
                            5:hud_char_code=lch("E"); 6:hud_char_code=lch("D"); 7:hud_char_code=C_SP;     8:hud_char_code=lch("K"); 9:hud_char_code=lch("B");
                            10:hud_char_code=C_COL;   11:hud_char_code=C_SP;    12:hud_char_code=lch("D"); 13:hud_char_code=lch("I"); 14:hud_char_code=lch("R");
                            15:hud_char_code=lch("E"); 16:hud_char_code=lch("C"); 17:hud_char_code=lch("T"); 18:hud_char_code=C_SP;   19:hud_char_code=lch("H");
                            20:hud_char_code=lch("I"); 21:hud_char_code=lch("D"); default:hud_char_code=C_SP;
                        endcase
                    end
                end

                // Footer Navigation (gy=206..213)
                if (gy >= 9'd206 && gy < 9'd214 && col_1x >= 6'd4 && col_1x < 6'd36) begin
                    hud_text_en = 1; hud_char_row = gy - 9'd206;
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

code = code[:idx_start] + new_title_guide_block + code[idx_end:]

with open(ren_path, 'w', encoding='utf-8') as f:
    f.write(code)

print("Part 2 of vga_renderer_v2.v complete!")
