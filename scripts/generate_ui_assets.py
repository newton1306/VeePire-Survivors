"""
DRAGO-NEXUS V2 - UI Button Asset Generator (oOiEki.gif Pixel-Art Style + Real Joystick Colors)
Generates:
  1. ui_icons.mem (16384 x 12-bit RGB444 BRAM):
     - Slot 0/1 (64x32): Animated Joystick CTA (1,2,3,4 diamond + pressing Blue '3' button)
     - Slot 2/3 (64x32): Animated Keyboard CTA (pressing Emerald 'SPACE' keycap)
     - Slot 4 (64x32):   Title Guide mini-buttons ([SEL] GUIDE / [ESC] GUIDE)
     - Slot 5 (64x32):   Guide Footer Joy icons (DPAD-L, DPAD-R, SELECT, START)
     - Slot 6 (64x32):   Guide Footer KB icons ([A], [D], [ESC], [ENT])
  2. Updates joy_palette.vh & joy_pixel.mem so Guide Page 2 shows real_joystick colors (1=Green, 2=Red, 3=Blue, 4=Pink) + SEL/STR center pills.
"""
import os
from PIL import Image

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MEM_DIR = os.path.join(BASE_DIR, "mem")
os.makedirs(MEM_DIR, exist_ok=True)

# ---------------------------------------------------------------------------
# Crisp 5x7 & 3x5 Pixel Font bitmaps for numbers/letters inside buttons
# ---------------------------------------------------------------------------
GLYPHS_5x7 = {
    '1': ["  #  ", " ##  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "],
    '2': [" ### ", "#   #", "    #", "  ## ", " #   ", "#    ", "#####"],
    '3': [" ### ", "#   #", "    #", " ### ", "    #", "#   #", " ### "],
    '4': ["   # ", "  ## ", " # # ", "#  # ", "#####", "   # ", "   # "],
    'S': [" ### ", "#    ", "#    ", " ### ", "    #", "    #", "#### "],
    'P': ["#### ", "#   #", "#   #", "#### ", "#    ", "#    ", "#    "],
    'A': [" ### ", "#   #", "#   #", "#####", "#   #", "#   #", "#   #"],
    'C': [" ### ", "#   #", "#    ", "#    ", "#    ", "#   #", " ### "],
    'E': ["#####", "#    ", "#    ", "#### ", "#    ", "#    ", "#####"],
    'G': [" ### ", "#    ", "#    ", "#  ##", "#   #", "#   #", " ### "],
    'U': ["#   #", "#   #", "#   #", "#   #", "#   #", "#   #", " ### "],
    'I': [" ### ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", " ### "],
    'D': ["#### ", "#   #", "#   #", "#   #", "#   #", "#   #", "#### "],
    'L': ["#    ", "#    ", "#    ", "#    ", "#    ", "#    ", "#####"],
    'N': ["#   #", "##  #", "# # #", "#  ##", "#   #", "#   #", "#   #"],
    'T': ["#####", "  #  ", "  #  ", "  #  ", "  #  ", "  #  ", "  #  "],
    'R': ["#### ", "#   #", "#   #", "#### ", "#  # ", "#   #", "#   #"],
}

GLYPHS_3x5 = {
    '1': [" # ", "## ", " # ", " # ", "###"],
    '2': ["## ", "  #", " # ", "#  ", "###"],
    '3': ["## ", "  #", " # ", "  #", "## "],
    '4': ["# #", "# #", "###", "  #", "  #"],
    'S': [" ##", "#  ", " # ", "  #", "## "],
    'E': ["###", "#  ", "## ", "#  ", "###"],
    'L': ["#  ", "#  ", "#  ", "#  ", "###"],
    'C': [" ##", "#  ", "#  ", "#  ", " ##"],
    'T': ["###", " # ", " # ", " # ", " # "],
    'A': [" # ", "# #", "###", "# #", "# #"],
    'D': ["## ", "# #", "# #", "# #", "## "],
    'G': [" ##", "#  ", "# #", "# #", " ##"],
    'U': ["# #", "# #", "# #", "# #", "###"],
    'I': ["###", " # ", " # ", " # ", "###"],
    'P': ["## ", "# #", "## ", "#  ", "#  "],
    'N': ["#  #", "## #", "# ##", "#  #", "#  #"],
    'R': ["## ", "# #", "## ", "# #", "# #"],
}

GLYPHS_BOLD_7x11 = {
    '3': [
        " ##### ",
        "#######",
        "##   ##",
        "    ## ",
        "  ###  ",
        "  ###  ",
        "    ## ",
        "     ##",
        "##   ##",
        "#######",
        " ##### ",
    ]
}

def draw_glyph(buf, bw, bh, x0, y0, ch, col, font=GLYPHS_5x7):
    rows = font.get(ch)
    if not rows:
        return
    for dy, row in enumerate(rows):
        for dx, c in enumerate(row):
            if c == '#':
                px, py = x0 + dx, y0 + dy
                if 0 <= px < bw and 0 <= py < bh:
                    buf[py * bw + px] = col

def draw_text(buf, bw, bh, x0, y0, text, col, font=GLYPHS_3x5, spacing=4):
    cx = x0
    for ch in text:
        if ch != ' ':
            draw_glyph(buf, bw, bh, cx, y0, ch, col, font)
        w_ch = len(font[ch][0]) if (ch in font) else (spacing - 1)
        cx += max(spacing, w_ch + 1)

def set_px(buf, bw, bh, x, y, col):
    if 0 <= x < bw and 0 <= y < bh:
        buf[y * bw + x] = col

def add_sticker_outline(buf, bw, bh, rim_col=0xFFF, dark_col=0x111):
    """Adds a crisp 1px white sticker rim around non-zero pixels (like oOiEki.gif!)."""
    orig = list(buf)
    for y in range(bh):
        for x in range(bw):
            if orig[y * bw + x] == 0:
                # Check 4-neighbors
                has_fg = False
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and orig[ny * bw + nx] != 0:
                        has_fg = True
                        break
                if has_fg:
                    buf[y * bw + x] = rim_col

def draw_round_button(buf, bw, bh, cx, cy, r, face_hi, face_mid, face_lip, label, pressed=False, sticker=True, font=GLYPHS_3x5):
    """Draws an oOiEki.gif-style glossy 3D pixel-art circular gamepad button."""
    tmp = [0] * (bw * bh)
    dy_press = 2 if pressed else 0
    lip_h = 1 if pressed else 3
    # Bottom 3D lip + inner black outline
    for y in range(cy - r - 1, cy + r + lip_h + 2):
        for x in range(cx - r - 1, cx + r + 2):
            dx = x - cx
            # Top cap y shifted down if pressed
            dy_cap = y - (cy + dy_press)
            dy_bot = y - (cy + lip_h)
            in_cap = (dx * dx + dy_cap * dy_cap) <= (r * r)
            in_bot = (dx * dx + dy_bot * dy_bot) <= (r * r) and (y >= cy + dy_press)
            if in_cap:
                if (dx * dx + dy_cap * dy_cap) >= (r - 1) * (r - 1) + 1:
                    col = 0x111
                elif dy_cap <= -r + 2 or (dx + dy_cap <= -r + 2):
                    col = face_hi
                else:
                    col = face_mid
                set_px(tmp, bw, bh, x, y, col)
            elif in_bot:
                if (dx * dx + dy_bot * dy_bot) >= (r - 1) * (r - 1) + 1 or y == cy + r + lip_h:
                    col = 0x111
                else:
                    col = face_lip
                set_px(tmp, bw, bh, x, y, col)
    # Dark outer ring around cap/bot
    snap = list(tmp)
    for y in range(bh):
        for x in range(bw):
            if snap[y * bw + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and snap[ny * bw + nx] != 0:
                        tmp[y * bw + x] = 0x111
                        break
    # Label inside cap
    if label:
        if font is GLYPHS_BOLD_7x11:
            draw_glyph(tmp, bw, bh, cx - 3, cy - 5 + dy_press, label, 0xFFF, GLYPHS_BOLD_7x11)
        elif font is GLYPHS_5x7:
            draw_glyph(tmp, bw, bh, cx - 2, cy - 3 + dy_press, label, 0xFFF, GLYPHS_5x7)
        else:
            draw_glyph(tmp, bw, bh, cx - 1, cy - 2 + dy_press, label, 0xFFF, GLYPHS_3x5)
    if sticker:
        add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def draw_keycap(buf, bw, bh, x0, y0, w, h, face_hi, face_mid, face_lip, text, text_col=0xFFF, pressed=False, font=GLYPHS_3x5, spacing=4):
    """Draws an oOiEki.gif-style 3D pixel-art keyboard keycap."""
    tmp = [0] * (bw * bh)
    dy_p = 2 if pressed else 0
    lip = 1 if pressed else 3
    for y in range(y0 + dy_p, y0 + h + lip):
        for x in range(x0, x0 + w):
            # Rounded corners cut
            is_corner = ((x == x0 or x == x0 + w - 1) and (y == y0 + dy_p or y == y0 + h + lip - 1))
            if is_corner:
                continue
            if y == y0 + dy_p or y == y0 + h + lip - 1 or x == x0 or x == x0 + w - 1:
                col = 0x111
            elif y >= y0 + h - 1 + dy_p:
                if y == y0 + h - 1 + dy_p:
                    col = 0x111
                else:
                    col = face_lip
            elif y <= y0 + dy_p + 2 or x <= x0 + 2:
                col = face_hi
            else:
                col = face_mid
            set_px(tmp, bw, bh, x, y, col)
    tw = len(text) * spacing - 1
    fh = 7 if font is GLYPHS_5x7 else 5
    tx = x0 + (w - tw) // 2
    ty = y0 + dy_p + (h - fh) // 2
    draw_text(tmp, bw, bh, tx, ty, text, text_col, font, spacing)
    add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def draw_dpad_icon(buf, bw, bh, cx, cy, lit_dir):
    """Draws a crisp 18x16 oOiEki.gif-style dark D-pad with Left or Right arm lit cyan."""
    tmp = [0] * (bw * bh)
    # Cross arms: horizontal (cx-6..cx+6, cy-2..cy+2), vertical (cx-2..cx+2, cy-5..cy+5)
    for y in range(cy - 5, cy + 7):
        for x in range(cx - 6, cx + 7):
            in_h = (abs(y - cy) <= 2) and (abs(x - cx) <= 6)
            in_v = (abs(x - cx) <= 2) and (abs(y - cy) <= 5)
            in_lip = (abs(x - cx) <= 2 and y == cy + 6) or (abs(x - cx) <= 6 and y == cy + 3)
            if in_h or in_v:
                col = 0x346
                if lit_dir == 'L' and x <= cx - 2 and abs(y - cy) <= 1:
                    col = 0x3FF
                elif lit_dir == 'R' and x >= cx + 2 and abs(y - cy) <= 1:
                    col = 0x3FF
                elif abs(x - cx) <= 1 and abs(y - cy) <= 1:
                    col = 0x223
                set_px(tmp, bw, bh, x, y, col)
            elif in_lip:
                set_px(tmp, bw, bh, x, y, 0x112)
    # Black border around cross
    snap = list(tmp)
    for y in range(bh):
        for x in range(bw):
            if snap[y * bw + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and snap[ny * bw + nx] != 0:
                        tmp[y * bw + x] = 0x111
                        break
    # Bright center directional pip
    if lit_dir == 'L':
        set_px(tmp, bw, bh, cx - 5, cy, 0xFFF)
        set_px(tmp, bw, bh, cx - 4, cy - 1, 0xFFF)
        set_px(tmp, bw, bh, cx - 4, cy + 1, 0xFFF)
    elif lit_dir == 'R':
        set_px(tmp, bw, bh, cx + 5, cy, 0xFFF)
        set_px(tmp, bw, bh, cx + 4, cy - 1, 0xFFF)
        set_px(tmp, bw, bh, cx + 4, cy + 1, 0xFFF)
    add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def draw_pill_btn(buf, bw, bh, x0, y0, w, h, text, hi_col=0x568, mid_col=0x346, lip_col=0x223):
    tmp = [0] * (bw * bh)
    for y in range(y0, y0 + h):
        for x in range(x0, x0 + w):
            if (x == x0 or x == x0 + w - 1) and (y == y0 or y == y0 + h - 1):
                continue
            if y == y0 or y == y0 + h - 1 or x == x0 or x == x0 + w - 1:
                col = 0x111
            elif y >= y0 + h - 2:
                col = lip_col
            elif y <= y0 + 2:
                col = hi_col
            else:
                col = mid_col
            set_px(tmp, bw, bh, x, y, col)
    tw = len(text) * 4 - 1
    draw_text(tmp, bw, bh, x0 + (w - tw) // 2, y0 + (h - 5) // 2, text, 0xFFF, GLYPHS_3x5, 4)
    add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

# ---------------------------------------------------------------------------
# Build 8 slots of 64x32 sprites (16384 words total)
# ---------------------------------------------------------------------------
slots = [[0] * (64 * 32) for _ in range(8)]

# Slot 0 & 1: Joystick CTA (64x32)
# Left side: real_joystick 1-2-3-4 diamond (1=Green top, 2=Red right, 3=Blue bottom, 4=Pink left)
# Right side: Big glossy 3D Blue Button '3' pressing down in Slot 1
for f_idx, pressed in [(0, False), (1, True)]:
    s = slots[f_idx]
    # Mini diamond cluster at x=16, y=13 (shows clearly it's from the joystick, unclipped rims)
    draw_round_button(s, 64, 32, 16, 6,  4, 0x3B5, 0x183, 0x142, '1', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 24, 13, 4, 0xD55, 0xA22, 0x611, '2', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 8,  13, 4, 0xC5A, 0x927, 0x514, '4', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 16, 21, 4, 0x7EF, 0x2AF, 0x15B, '3', pressed=pressed, sticker=True)
    # Big Hero Button '3' on right side (x=47, y=14) in full oOiEki.gif 3D press style!
    draw_round_button(s, 64, 32, 47, 14, 11, 0x7EF, 0x29F, 0x14A, '3', pressed=pressed, sticker=True, font=GLYPHS_BOLD_7x11)
    # Press sparkle rays on frame 1
    if pressed:
        for sx, sy in [(33, 4), (32, 14), (60, 4), (61, 14)]:
            set_px(s, 64, 32, sx, sy, 0xFF0)
            set_px(s, 64, 32, sx+1, sy, 0xFFF)

# Slot 2 & 3: Keyboard CTA (64x32) - Emerald 3D [ SPACE ] Keycap
for f_idx, pressed in [(2, False), (3, True)]:
    s = slots[f_idx]
    draw_keycap(s, 64, 32, 5, 5, 54, 20, 0x5FB, 0x2B7, 0x164, "SPACE", text_col=0xFFF, pressed=pressed, font=GLYPHS_5x7, spacing=7)
    if pressed:
        for sx, sy in [(2, 14), (61, 14), (32, 2)]:
            set_px(s, 64, 32, sx, sy, 0xFF0)

# Slot 4: Title Guide Mini-Buttons (Top y=0..15: [SEL] GUIDE, Bot y=16..31: [ESC] GUIDE)
# Slot 4: Title Guide Mini-Buttons (Top y=0..15: [SEL] GUIDE, Bot y=16..31: [ESC] GUIDE)
# Ensure strict gap at y=14..15 so bottom rim of [SEL] & top rim of [ESC] NEVER bleed!
draw_pill_btn(slots[4], 64, 32, 2,  1,  22, 11, "SEL", hi_col=0x78A, mid_col=0x457, lip_col=0x224)
draw_text(slots[4], 64, 32, 27, 4, "GUIDE", 0xEE8, GLYPHS_3x5, 4)
draw_keycap(slots[4], 64, 32, 2, 18, 22, 9, 0x78A, 0x457, 0x224, "ESC", text_col=0xFFF, pressed=False)
draw_text(slots[4], 64, 32, 27, 21, "GUIDE", 0xEE8, GLYPHS_3x5, 4)

# Slot 5: Guide Footer Joy Icons (4 quadrants of 32x16)
draw_dpad_icon(slots[5], 64, 32, 16, 7, 'L')
draw_dpad_icon(slots[5], 64, 32, 48, 7, 'R')
draw_pill_btn(slots[5], 64, 32, 4, 17, 24, 11, "SEL", hi_col=0x88A, mid_col=0x557, lip_col=0x224)
draw_pill_btn(slots[5], 64, 32, 36, 17, 24, 11, "STR", hi_col=0x88A, mid_col=0x557, lip_col=0x224)

# Slot 6: Guide Footer KB Icons (4 quadrants of 32x16)
draw_keycap(slots[6], 64, 32, 6,  1, 20, 11, 0x6EF, 0x29D, 0x148, "A")
draw_keycap(slots[6], 64, 32, 38, 1, 20, 11, 0x6EF, 0x29D, 0x148, "D")
draw_keycap(slots[6], 64, 32, 4,  17, 24, 10, 0xFA5, 0xC62, 0x731, "ESC")
draw_keycap(slots[6], 64, 32, 35, 17, 26, 10, 0x88A, 0x557, 0x224, "ENT", spacing=4)

# Write ui_icons.mem
mem_path = os.path.join(MEM_DIR, "ui_icons.mem")
with open(mem_path, "w") as f:
    for s_idx, buf in enumerate(slots):
        f.write(f"// Slot {s_idx}\n")
        for i in range(0, len(buf), 16):
            f.write(" ".join(f"{v:03X}" for v in buf[i:i+16]) + "\n")
print("[OK] Wrote ui_icons.mem (16384 words)")

# Save visual preview sheet of ui_icons.mem
os.makedirs(os.path.join(BASE_DIR, "sim_work"), exist_ok=True)
sheet = Image.new("RGB", (64 * 4, 32 * 2), (18, 20, 36))
px = sheet.load()
for s_idx, buf in enumerate(slots):
    ox = (s_idx % 4) * 64
    oy = (s_idx // 4) * 32
    for y in range(32):
        for x in range(64):
            v = buf[y * 64 + x]
            if v != 0:
                px[ox + x, oy + y] = (((v >> 8) & 0xF) * 17, ((v >> 4) & 0xF) * 17, (v & 0xF) * 17)
sheet.resize((64 * 4 * 3, 32 * 2 * 3), Image.NEAREST).save(os.path.join(BASE_DIR, "sim_work", "ui_icons_preview.png"))
print("[OK] Saved sim_work/ui_icons_preview.png")

# ---------------------------------------------------------------------------
# Update joy_palette.vh & joy_pixel.mem with real_joystick.webp button colors
# ---------------------------------------------------------------------------
# Palette:
# 0:000(trans), 1:FFF, 2:CDD, 3:2E6(Green Btn1), 4:CCD, 5:F44(Red Btn2),
# 6:3BF(Blue Btn3), 7:9AB, 8:679, 9:456, 10:E5B(Pink Btn4), 11:222,
# 12:334(Dark Pill), 13:212, 14:122, 15:111
pal_vh = """// Auto-generated 16-color 12-bit palette for joy_pixel (with real_joystick button colors)
function [11:0] joy_palette;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  joy_palette = 12'h000;
            4'd1:  joy_palette = 12'hFFF;
            4'd2:  joy_palette = 12'hCDD;
            4'd3:  joy_palette = 12'h2E6; // Button 1: Green
            4'd4:  joy_palette = 12'hCCD;
            4'd5:  joy_palette = 12'hF44; // Button 2: Red
            4'd6:  joy_palette = 12'h3BF; // Button 3: Blue
            4'd7:  joy_palette = 12'h9AB;
            4'd8:  joy_palette = 12'h679;
            4'd9:  joy_palette = 12'h456;
            4'd10: joy_palette = 12'hE5B; // Button 4: Pink
            4'd11: joy_palette = 12'h222;
            4'd12: joy_palette = 12'h334; // Dark Select/Start
            4'd13: joy_palette = 12'h212;
            4'd14: joy_palette = 12'h122;
            4'd15: joy_palette = 12'h111;
            default: joy_palette = 12'h000;
        endcase
    end
endfunction
"""
with open(os.path.join(BASE_DIR, "rtl/joy_palette.vh"), "w") as f:
    f.write(pal_vh)

# Load existing joy_pixel.mem nibbles (clean old duplicate 3/5/6/10 -> 4/2/11 first!)
joy_src = os.path.join(MEM_DIR, "joy_pixel.mem")
with open(joy_src, "r") as f:
    toks = [t for l in f if l.strip() and not l.strip().startswith("//") for t in l.strip().split()]

grid = [[0]*96 for _ in range(64)]
for y in range(64):
    for xb in range(48):
        b = int(toks[y*48 + xb], 16)
        n0, n1 = (b >> 4) & 0xF, b & 0xF
        for dx, n in [(0, n0), (1, n1)]:
            # Remap old gray aliases (3->4, 5->4, 6->4, 10->11, 12->11) before painting vivid buttons
            if n in (3, 5, 6):
                n = 4
            elif n in (10, 12):
                n = 11
            grid[y][xb*2 + dx] = n

# Paint 4 vivid colored face buttons matching real_joystick.webp!
# Btn 1 Top (Green idx=3): center (75.5, 15)
for y in range(14, 17):
    for x in range(74, 78):
        grid[y][x] = 3
# Btn 2 Right (Red idx=5): center (82.5, 21)
for y in range(20, 23):
    for x in range(81, 85):
        grid[y][x] = 5
# Btn 3 Bottom (Blue idx=6): center (75.5, 27)
for y in range(26, 29):
    for x in range(74, 78):
        grid[y][x] = 6
# Btn 4 Left (Pink idx=10): center (68.5, 21)
for y in range(20, 23):
    for x in range(67, 71):
        grid[y][x] = 10

# Paint SEL (left x=40..44, y=26..28) & STR (right x=50..54, y=26..28) dark pill buttons in center!
for y in range(26, 29):
    for x in range(40, 45):
        grid[y][x] = 15 if (y in (26, 28) and x in (40, 44)) else 12
    for x in range(50, 55):
        grid[y][x] = 15 if (y in (26, 28) and x in (50, 54)) else 12

with open(joy_src, "w") as f:
    f.write("// 96x64 4-bit Joystick Pixel Art (with real_joystick colored face buttons + SEL/STR)\n")
    for y in range(64):
        row_bytes = []
        for xb in range(48):
            b = ((grid[y][xb*2] & 0xF) << 4) | (grid[y][xb*2 + 1] & 0xF)
            row_bytes.append(f"{b:02X}")
        f.write(" ".join(row_bytes) + "\n")
print("[OK] Updated joy_palette.vh and joy_pixel.mem")
