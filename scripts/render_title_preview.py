"""
DRAGO-NEXUS V2 - Pixel-Exact Software Preview Renderer (1:1 with vga_renderer_v2.v)
Renders:
  - preview_title_joy_1p.png  (Mode 0: 1P Joystick, centered hero, NO boss, animated '3' button + [SEL] GUIDE)
  - preview_title_kb_1p.png   (Mode 1: 1P Keyboard, centered hero, NO boss, animated [SPACE] + [ESC] GUIDE)
  - preview_title_joy_2p.png  (Mode 2: 2P Dual Joy, 2 heroes symmetrically centered, NO boss)
  - preview_title_cta.gif     (Animated CTA bouncing + pressing GIF preview!)
  - preview_guide_board.png   (Page 1/3: Real [SEL] EXIT + [DPAD-R] NEXT, no PREV)
  - preview_guide_joy.png     (Page 2/3: Colored real_joystick art, pixel-exact pointer lines, NO button names, [DPAD-L] [SEL] [DPAD-R])
  - preview_guide_kb.png      (Page 3/3: Keyboard controls, [A] PREV + [ESC] EXIT, NO NEXT!)
"""
import os
from PIL import Image

BASE_DIR = "D:/vivado_pj/DRAGO_NEXUS_V2"

def load_hex_bytes(fname, size):
    arr = [0] * size
    with open(os.path.join(BASE_DIR, fname), "r") as f:
        idx = 0
        for line in f:
            line = line.strip()
            if not line or line.startswith("//"):
                continue
            for b in line.split():
                if idx < size:
                    arr[idx] = int(b, 16)
                    idx += 1
    return arr

font_data   = load_hex_bytes("font.mem", 2048)
logo_data   = load_hex_bytes("title_logo.mem", 8192)
joy_data    = load_hex_bytes("joy_pixel.mem", 3072)
pal_fg      = load_hex_bytes("pal_fg.mem", 64)
ui_data     = load_hex_bytes("ui_icons.mem", 16384)
player_data = load_hex_bytes("player_sprites.mem", 16384)

def lch(c):
    c = c.upper()
    if '0' <= c <= '9': return ord(c) - ord('0')
    if 'A' <= c <= 'Z': return ord(c) - ord('A') + 10
    if c == ':': return 37
    if c == '-': return 38
    if c == '!': return 39
    if c == '/': return 41
    if c == '<': return 42
    if c == '>': return 43
    if c == '+': return 44
    return 36

def get_font_pixel(char_code, row, col):
    if char_code >= 64: return 0
    b = font_data[char_code * 8 + (row & 7)]
    return (b >> (7 - (col & 7))) & 1

def pal_to_rgb(rgb12):
    return (((rgb12 >> 8) & 0xF) * 17, ((rgb12 >> 4) & 0xF) * 17, (rgb12 & 0xF) * 17)

def pal_idx_rgb(idx):
    return pal_to_rgb(pal_fg[idx & 0x3F])

def joy_palette(idx):
    lut = [
        0x000, 0xFFF, 0xCDD, 0x2E6, 0xCCD, 0xF44, 0x3BF, 0x9AB,
        0x679, 0x456, 0xE5B, 0x222, 0x334, 0x212, 0x122, 0x111
    ]
    return pal_to_rgb(lut[idx & 0xF])

def hero_body_rgb(px_x, py_y):
    """Exact replica of Wave 1 Uniform body in vga_renderer_v2.v (y=27..45)."""
    if py_y == 27 and 14 <= px_x <= 17:
        return pal_to_rgb(0xECA)
    if 28 <= py_y <= 37 and 10 <= px_x <= 21:
        if py_y == 37:
            return pal_to_rgb(0xCCC if px_x in (15, 16) else 0x111)
        elif 15 <= px_x <= 16 and py_y <= 35:
            return pal_to_rgb(0x223)
        else:
            return pal_to_rgb(0xCCD if px_x in (10, 21) else 0xFFF)
    if (7 <= px_x <= 9 or 22 <= px_x <= 24) and (29 <= py_y <= 36):
        return pal_to_rgb(0xECA if py_y >= 35 else 0xEEE)
    if 38 <= py_y < 46:
        if (11 <= px_x <= 14) or (17 <= px_x <= 20):
            return pal_to_rgb(0x334 if py_y >= 44 else 0x112)
    return None

def draw_text(pixels, txt, x0, y0, rgb):
    for i, ch in enumerate(txt):
        code = lch(ch)
        for ry in range(8):
            for rx in range(8):
                if get_font_pixel(code, ry, rx):
                    gx, gy = x0 + i * 8 + rx, y0 + ry
                    if 0 <= gx < 320 and 0 <= gy < 240:
                        pixels[gx, gy] = rgb

def draw_ui_sprite(pixels, slot, sx, sy, sw, sh, dst_x, dst_y):
    for dy in range(sh):
        for dx in range(sw):
            v = ui_data[slot * 2048 + (sy + dy) * 64 + (sx + dx)]
            if v != 0:
                gx, gy = dst_x + dx, dst_y + dy
                if 0 <= gx < 320 and 0 <= gy < 240:
                    pixels[gx, gy] = pal_to_rgb(v)

def draw_hline(pixels, x1, x2, y, rgb):
    lo, hi = min(x1, x2), max(x1, x2)
    for x in range(lo, hi + 1):
        pixels[x, y] = rgb

def draw_vline(pixels, x, y1, y2, rgb):
    lo, hi = min(y1, y2), max(y1, y2)
    for y in range(lo, hi + 1):
        pixels[x, y] = rgb

def draw_dot(pixels, cx, cy, rgb):
    for dy in (-1, 0, 1):
        for dx in (-1, 0, 1):
            pixels[cx + dx, cy + dy] = rgb

def render_screen(help_page=0, control_mode=0, hero_cursor=0, p1_weapon=0, p2_weapon=1, p1_head=0, p2_head=1, anim_phase=0):
    img = Image.new("RGB", (320, 240), (10, 10, 20))
    pixels = img.load()

    p2_active = control_mode in (2, 3)
    is_kb_mode = control_mode in (1, 3)

    # Background Grid
    for gy in range(240):
        for gx in range(320):
            pixels[gx, gy] = (20, 24, 40) if (gx % 16 == 0 or gy % 16 == 0) else (12, 12, 24)

    cta_bounce = anim_phase if anim_phase < 4 else (7 - anim_phase)
    cta_pressed = (anim_phase >= 5)
    cta_top = 172 - cta_bounce
    guide_top = 213 - (1 if (anim_phase & 2) else 0)

    if help_page == 0:
        # 1. Logo (gx=80..239, gy=4..51)
        for gy in range(4, 52):
            for gx in range(80, 240):
                pidx = logo_data[(gy - 4) * 160 + (gx - 80)]
                if pidx > 0:
                    pixels[gx, gy] = pal_idx_rgb(pidx)

        # 2. Mode Selector (gx=44..275, gy=56..72)
        for gy in range(56, 73):
            for gx in range(44, 276):
                pixels[gx, gy] = pal_idx_rgb(58) if (gy in (56, 72) or gx in (44, 275)) else pal_idx_rgb(54)
        modes = ["MODE: 1P JOYSTICK", "MODE: 1P KEYBOARD", "MODE: 2P DUAL JOY", "MODE: 2P CO-OP J+K"]
        mcol = [pal_idx_rgb(59), pal_idx_rgb(58), pal_idx_rgb(51), pal_idx_rgb(60)][control_mode]
        draw_text(pixels, "<", 48, 60, pal_idx_rgb(58))
        draw_text(pixels, modes[control_mode], 64, 60, mcol)
        draw_text(pixels, ">", 264, 60, pal_idx_rgb(58))

        # 3. Centered Hero(es) — NO BOSS!
        hero_list = [(112, p1_head), (208, p2_head)] if p2_active else [(160, p1_head)]
        for cx, head_id in hero_list:
            x0, y0 = cx - 16, 114 - 16
            for py_y in range(46):
                for px_x in range(32):
                    col = None
                    if py_y < 32:
                        v = player_data[(head_id * 4 + 0) * 1024 + py_y * 32 + px_x]
                        if v != 0:
                            col = pal_to_rgb(v)
                    if col is None and py_y >= 27:
                        col = hero_body_rgb(px_x, py_y)
                    if col is not None:
                        pixels[x0 + px_x, y0 + py_y] = col

        # 4. Inverted Triangle Cursor
        cur_cx = (208 if hero_cursor else 112) if p2_active else 160
        tri_y0 = 82 + (2 if (anim_phase in (2, 3, 4, 5)) else 0)
        for r in range(9):
            hw = max(0, 4 - r // 2)
            for dx in range(-hw, hw + 1):
                pixels[cur_cx + dx, tri_y0 + r] = pal_idx_rgb(17 if (abs(dx) == hw or r == 0) else 58)

        # 5. Weapon Names
        wpn_names = ["SWORD", "SABER", "FISTS", "B-AXE", "SPEAR", "SCYTH"]
        if not p2_active:
            draw_text(pixels, "P1:" + wpn_names[p1_weapon], 128, 144, pal_idx_rgb(58))
            draw_text(pixels, "BTNC:HEAD   BTNU/D:WEAPON", 48, 156, pal_idx_rgb(60))
        else:
            draw_text(pixels, "P1:" + wpn_names[p1_weapon], 80, 144, pal_idx_rgb(58 if hero_cursor == 0 else 60))
            draw_text(pixels, "P2:" + wpn_names[p2_weapon], 176, 144, pal_idx_rgb(58 if hero_cursor == 1 else 60))
            draw_text(pixels, "BTNL/R:P1/2  BTNC:HEAD  BTNU/D:WPN", 16, 156, pal_idx_rgb(60))

        # 6. Animated Pixel-Art Bouncing CTA Button (from ui_icons.mem!)
        cta_slot = (3 if cta_pressed else 2) if is_kb_mode else (1 if cta_pressed else 0)
        draw_ui_sprite(pixels, cta_slot, 0, 0, 64, 32, 128, cta_top)

        # 7. Smaller Bouncing Guide Pill
        draw_ui_sprite(pixels, 4, 0, 16 if is_kb_mode else 0, 64, 16, 128, guide_top)

    else:
        # Terminal Box (24..295, 16..227)
        bcol = [pal_idx_rgb(58), pal_idx_rgb(59), pal_idx_rgb(28)][help_page - 1]
        for gy in range(16, 228):
            for gx in range(24, 296):
                pixels[gx, gy] = bcol if (gx in (24, 295) or gy in (16, 227, 42, 196)) else pal_idx_rgb(54)

        # Header (NO < > arrows)
        if help_page == 1:
            draw_text(pixels, "1/3 BOARD HARDWARE", 88, 24, bcol)
            lines_p1 = [
                ("BTNL/R: SELECT P1 / P2", 59),
                ("BTNC: CYCLE HEAD STYLE", 59),
                ("BTNU/D: CYCLE 6 WEAPONS", 59),
                ("MIC ROAR: SONIC WAVE PUSH", 58),
                ("TEMP CHIP: TOUCH FLAME AURA", 58),
                ("SW9: FEVER DEMO FORCE", 60),
                ("SW8: 7SEG SHOW LIVE TEMP", 60),
                ("AN: 6-DIGIT SCORE", 28),
            ]
            for i, (t, ci) in enumerate(lines_p1):
                draw_text(pixels, t, 32, 52 + i * 14 + (8 if i >= 3 else 0), pal_idx_rgb(ci))
        elif help_page == 2:
            draw_text(pixels, "2/3 JOYSTICK CONTROLS", 72, 24, bcol)
            # Joystick Pixel Art (gx=96..191, gy=58..121)
            for jy in range(64):
                for jx in range(96):
                    raw = joy_data[jy * 48 + (jx >> 1)]
                    nib = (raw >> 4) if (jx & 1) == 0 else (raw & 0xF)
                    if nib != 0:
                        pixels[96 + jx, 58 + jy] = joy_palette(nib)

            # Accurate pointer lines (NO button names!)
            draw_hline(pixels, 68, 116, 78, pal_idx_rgb(59)); draw_dot(pixels, 116, 78, pal_idx_rgb(59))
            draw_text(pixels, "MOVE", 32, 74, pal_idx_rgb(59))

            draw_hline(pixels, 161, 164, 79, pal_idx_rgb(51)); draw_vline(pixels, 161, 50, 79, pal_idx_rgb(51)); draw_hline(pixels, 161, 228, 50, pal_idx_rgb(51)); draw_dot(pixels, 164, 79, pal_idx_rgb(51))
            draw_text(pixels, "NOVA", 232, 46, pal_idx_rgb(51))

            draw_vline(pixels, 171, 65, 73, pal_idx_rgb(28)); draw_hline(pixels, 171, 228, 65, pal_idx_rgb(28)); draw_dot(pixels, 171, 73, pal_idx_rgb(28))
            draw_text(pixels, "BULLET", 232, 61, pal_idx_rgb(28))

            draw_hline(pixels, 178, 228, 79, pal_idx_rgb(52)); draw_dot(pixels, 178, 79, pal_idx_rgb(52))
            draw_text(pixels, "DASH", 232, 75, pal_idx_rgb(52))

            draw_hline(pixels, 171, 194, 85, pal_idx_rgb(59)); draw_vline(pixels, 194, 85, 96, pal_idx_rgb(59)); draw_hline(pixels, 194, 228, 96, pal_idx_rgb(59)); draw_dot(pixels, 171, 85, pal_idx_rgb(59))
            draw_text(pixels, "ATTACK", 232, 92, pal_idx_rgb(59))

            draw_vline(pixels, 138, 85, 138, pal_idx_rgb(58)); draw_hline(pixels, 84, 138, 138, pal_idx_rgb(58)); draw_dot(pixels, 138, 85, pal_idx_rgb(58))
            draw_text(pixels, "EXIT", 48, 134, pal_idx_rgb(58))

            draw_vline(pixels, 148, 85, 138, pal_idx_rgb(17)); draw_hline(pixels, 148, 196, 138, pal_idx_rgb(17)); draw_dot(pixels, 148, 85, pal_idx_rgb(17))
            draw_text(pixels, "PAUSE", 200, 134, pal_idx_rgb(17))
        else:
            draw_text(pixels, "3/3 KEYBOARD CONTROLS", 72, 24, bcol)
            lines_p3 = [
                ("W/A/S/D: MOVE", 17),
                ("SPACE/J: ATTACK", 58),
                ("K/E: DASH", 59),
                ("3/L: 360 NOVA", 51),
                ("4/U: BULLET", 28),
                ("1-4: QUIZ DOOR", 58),
                ("ENTER: PAUSE", 60),
                ("ESC: EXIT GUIDE", 58),
            ]
            for i, (t, ci) in enumerate(lines_p3):
                draw_text(pixels, t, 32, 56 + i * 14, pal_idx_rgb(ci))

        # Footer Real Button Icons (NO arrows!)
        nav_slot = 6 if is_kb_mode else 5
        if help_page > 1:
            draw_ui_sprite(pixels, nav_slot, 0, 0, 32, 16, 36, 199)
            draw_text(pixels, "PREV", 72, 203, pal_idx_rgb(59))
        draw_ui_sprite(pixels, nav_slot, 0, 16, 32, 16, 122, 199)
        draw_text(pixels, "EXIT", 160, 203, pal_idx_rgb(58))
        if help_page < 3:
            draw_ui_sprite(pixels, nav_slot, 32, 0, 32, 16, 212, 199)
            draw_text(pixels, "NEXT", 248, 203, pal_idx_rgb(59))

    return img

def save_2x(img, path):
    img.resize((640, 480), Image.NEAREST).save(path)

save_2x(render_screen(0, 0, 0, anim_phase=0), os.path.join(BASE_DIR, "preview_title_joy_1p.png"))
save_2x(render_screen(0, 1, 0, anim_phase=6), os.path.join(BASE_DIR, "preview_title_kb_1p.png"))
save_2x(render_screen(0, 2, 0, anim_phase=0), os.path.join(BASE_DIR, "preview_title_joy_2p.png"))
save_2x(render_screen(1, 0), os.path.join(BASE_DIR, "preview_guide_board.png"))
save_2x(render_screen(2, 0), os.path.join(BASE_DIR, "preview_guide_joy.png"))
save_2x(render_screen(3, 1), os.path.join(BASE_DIR, "preview_guide_kb.png"))

frames = [render_screen(0, 0, 0, anim_phase=p).resize((640, 480), Image.NEAREST) for p in range(8)]
frames[0].save(os.path.join(BASE_DIR, "preview_title_cta.gif"), save_all=True, append_images=frames[1:], duration=120, loop=0)
print("[DONE] All 2x previews + animated CTA GIF saved!")
