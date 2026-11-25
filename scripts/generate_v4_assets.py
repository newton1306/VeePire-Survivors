"""
DRAGO-NEXUS V2 - V4 High-Detail Asset Generator
Generates:
  1. ui_icons.mem (32768 words = 16 slots x 64x32 x 12-bit RGB444):
     - Slots 0..1 : Animated Joy CTA (1,2,3,4 diamond + pressing Blue '3')
     - Slots 2..3 : Animated KB CTA (pressing REAL WHITE [ SPACE ] mechanical keycap!)
     - Slot  4    : Title Guide Mini-Buttons ([SEL] GUIDE / REAL WHITE [ESC] GUIDE)
     - Slot  5    : Guide Footer Joy Icons (DPAD-L, DPAD-R, SEL, STR)
     - Slot  6    : Guide Footer KB Icons (REAL WHITE [A], [D], [ESC], [ENT] keycaps)
     - Slots 7..9 : 6 Detailed 32x32 Pixel-Art Weapon Icons (SWORD, SABER, FISTS, B-AXE, SPEAR, SCYTH)
  2. hero_body.mem (16384 words = 4 outfits x 4 walk frames x 32x24 x 12-bit RGB444):
     - High-detail character bodies with 4-frame smooth walk cycle (walk_ref.gif style:
       bent swinging arms, shaded back limbs, sneaker soles, torso bounce) while keeping
       the exact 4 outfits intact (Student Uniform, KMUTT Blue Workshop, KMUTT Red Gown, Gold Armor).
  3. kb_guide.mem (18432 bytes = 256x144 x 4-bit) & rtl/kb_palette.vh:
     - Full real white mechanical keyboard keycaps layout for Guide Page 3!
"""
import os
from PIL import Image

BASE_DIR = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
MEM_DIR = os.path.join(BASE_DIR, "mem")
PREVIEW_DIR = os.path.join(BASE_DIR, "sim_work")
os.makedirs(MEM_DIR, exist_ok=True)
os.makedirs(PREVIEW_DIR, exist_ok=True)

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
}

GLYPHS_3x5 = {
    '0': ["###", "# #", "# #", "# #", "###"],
    '1': [" # ", "## ", " # ", " # ", "###"],
    '2': ["## ", "  #", " # ", "#  ", "###"],
    '3': ["## ", "  #", " # ", "  #", "## "],
    '4': ["# #", "# #", "###", "  #", "  #"],
    '6': [" ##", "#  ", "###", "# #", "###"],
    'A': [" # ", "# #", "###", "# #", "# #"],
    'B': ["## ", "# #", "## ", "# #", "## "],
    'C': [" ##", "#  ", "#  ", "#  ", " ##"],
    'D': ["## ", "# #", "# #", "# #", "## "],
    'E': ["###", "#  ", "## ", "#  ", "###"],
    'G': [" ##", "#  ", "# #", "# #", " ##"],
    'H': ["# #", "# #", "###", "# #", "# #"],
    'I': ["###", " # ", " # ", " # ", "###"],
    'J': ["  #", "  #", "  #", "# #", " # "],
    'K': ["# #", "# #", "## ", "# #", "# #"],
    'L': ["#  ", "#  ", "#  ", "#  ", "###"],
    'M': ["#   #", "## ##", "# # #", "#   #", "#   #"],
    'N': ["#  #", "## #", "# ##", "#  #", "#  #"],
    'O': ["###", "# #", "# #", "# #", "###"],
    'P': ["## ", "# #", "## ", "#  ", "#  "],
    'Q': [" ## ", "#  #", "#  #", "# ##", " ###"],
    'R': ["## ", "# #", "## ", "# #", "# #"],
    'S': [" ##", "#  ", " # ", "  #", "## "],
    'T': ["###", " # ", " # ", " # ", " # "],
    'U': ["# #", "# #", "# #", "# #", "###"],
    'V': ["# #", "# #", "# #", "# #", " # "],
    'W': ["# #", "# #", "###", "###", "# #"],
    'X': ["# #", "# #", " # ", "# #", "# #"],
    'Y': ["# #", "# #", " # ", " # ", " # "],
    'Z': ["###", "  #", " # ", "#  ", "###"],
    '-': ["   ", "   ", "###", "   ", "   "],
    '/': ["  #", "  #", " # ", "#  ", "#  "],
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

def set_px(buf, bw, bh, x, y, col):
    if 0 <= x < bw and 0 <= y < bh:
        buf[y * bw + x] = col

def draw_glyph(buf, bw, bh, x0, y0, ch, col, font=GLYPHS_3x5):
    rows = font.get(ch)
    if not rows:
        return
    for dy, row in enumerate(rows):
        for dx, c in enumerate(row):
            if c == '#':
                set_px(buf, bw, bh, x0 + dx, y0 + dy, col)

def draw_text(buf, bw, bh, x0, y0, text, col, font=GLYPHS_3x5, spacing=4):
    cx = x0
    for ch in text:
        if ch != ' ':
            draw_glyph(buf, bw, bh, cx, y0, ch, col, font)
        w_ch = len(font[ch][0]) if (ch in font) else (spacing - 1)
        cx += max(spacing, w_ch + 1)

def text_width(text, font=GLYPHS_3x5, spacing=4):
    w = 0
    for i, ch in enumerate(text):
        w_ch = len(font[ch][0]) if (ch in font) else (spacing - 1)
        step = max(spacing, w_ch + 1)
        w += w_ch if i == len(text) - 1 else step
    return w

def add_sticker_outline(buf, bw, bh, rim_col=0xFFF):
    orig = list(buf)
    for y in range(bh):
        for x in range(bw):
            if orig[y * bw + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and orig[ny * bw + nx] != 0:
                        buf[y * bw + x] = rim_col
                        break

def draw_round_button(buf, bw, bh, cx, cy, r, face_hi, face_mid, face_lip, label, pressed=False, sticker=True, font=GLYPHS_3x5):
    tmp = [0] * (bw * bh)
    dy_press = 2 if pressed else 0
    lip_h = 1 if pressed else 3
    for y in range(cy - r - 1, cy + r + lip_h + 2):
        for x in range(cx - r - 1, cx + r + 2):
            dx = x - cx
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
    snap = list(tmp)
    for y in range(bh):
        for x in range(bw):
            if snap[y * bw + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and snap[ny * bw + nx] != 0:
                        tmp[y * bw + x] = 0x111
                        break
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

def draw_keycap(buf, bw, bh, x0, y0, w, h, face_hi, face_mid, face_lip, text, text_col=0x112, pressed=False, font=GLYPHS_3x5, spacing=4, sticker_col=0xFFF):
    tmp = [0] * (bw * bh)
    dy_p = 2 if pressed else 0
    lip = 1 if pressed else 3
    for y in range(y0 + dy_p, y0 + h + lip):
        for x in range(x0, x0 + w):
            is_corner = ((x == x0 or x == x0 + w - 1) and (y == y0 + dy_p or y == y0 + h + lip - 1))
            if is_corner:
                continue
            if y == y0 + dy_p or y == y0 + h + lip - 1 or x == x0 or x == x0 + w - 1:
                col = 0x223
            elif y >= y0 + h - 1 + dy_p:
                col = 0x223 if y == y0 + h - 1 + dy_p else face_lip
            elif y <= y0 + dy_p + 1 or x <= x0 + 1:
                col = face_hi
            elif x >= x0 + w - 2 or y >= y0 + h - 2 + dy_p:
                col = face_lip
            else:
                col = face_mid
            set_px(tmp, bw, bh, x, y, col)
    tw = text_width(text, font, spacing)
    fh = 7 if font is GLYPHS_5x7 else 5
    tx = x0 + (w - tw) // 2
    ty = y0 + dy_p + (h - fh) // 2
    draw_text(tmp, bw, bh, tx, ty, text, text_col, font, spacing)
    if sticker_col:
        add_sticker_outline(tmp, bw, bh, sticker_col)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def draw_dpad_icon(buf, bw, bh, cx, cy, lit_dir):
    tmp = [0] * (bw * bh)
    for y in range(cy - 5, cy + 7):
        for x in range(cx - 6, cx + 7):
            in_h = (abs(y - cy) <= 2) and (abs(x - cx) <= 6)
            in_v = (abs(x - cx) <= 2) and (abs(y - cy) <= 5)
            in_lip = (abs(x - cx) <= 2 and y == cy + 6) or (abs(x - cx) <= 6 and y == cy + 3)
            if in_h or in_v:
                col = 0x346
                if 'L' in lit_dir and x <= cx - 2 and abs(y - cy) <= 1:
                    col = 0x3FF
                elif 'R' in lit_dir and x >= cx + 2 and abs(y - cy) <= 1:
                    col = 0x3FF
                elif 'U' in lit_dir and y <= cy - 2 and abs(x - cx) <= 1:
                    col = 0x3FF
                elif 'D' in lit_dir and y >= cy + 2 and abs(x - cx) <= 1:
                    col = 0x3FF
                elif abs(x - cx) <= 1 and abs(y - cy) <= 1:
                    col = 0x223
                set_px(tmp, bw, bh, x, y, col)
            elif in_lip:
                set_px(tmp, bw, bh, x, y, 0x112)
    snap = list(tmp)
    for y in range(bh):
        for x in range(bw):
            if snap[y * bw + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < bw and 0 <= ny < bh and snap[ny * bw + nx] != 0:
                        tmp[y * bw + x] = 0x111
                        break
    if 'L' in lit_dir:
        set_px(tmp, bw, bh, cx - 5, cy, 0xFFF)
        set_px(tmp, bw, bh, cx - 4, cy - 1, 0xFFF)
        set_px(tmp, bw, bh, cx - 4, cy + 1, 0xFFF)
    if 'R' in lit_dir:
        set_px(tmp, bw, bh, cx + 5, cy, 0xFFF)
        set_px(tmp, bw, bh, cx + 4, cy - 1, 0xFFF)
        set_px(tmp, bw, bh, cx + 4, cy + 1, 0xFFF)
    if 'U' in lit_dir:
        set_px(tmp, bw, bh, cx, cy - 4, 0xFFF)
        set_px(tmp, bw, bh, cx - 1, cy - 3, 0xFFF)
        set_px(tmp, bw, bh, cx + 1, cy - 3, 0xFFF)
    if 'D' in lit_dir:
        set_px(tmp, bw, bh, cx, cy + 4, 0xFFF)
        set_px(tmp, bw, bh, cx - 1, cy + 3, 0xFFF)
        set_px(tmp, bw, bh, cx + 1, cy + 3, 0xFFF)
    add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def draw_pill_btn(buf, bw, bh, x0, y0, w, h, text, hi_col=0x78A, mid_col=0x457, lip_col=0x224):
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
    tw = text_width(text, GLYPHS_3x5, 4)
    draw_text(tmp, bw, bh, x0 + (w - tw) // 2, y0 + (h - 5) // 2, text, 0xFFF, GLYPHS_3x5, 4)
    add_sticker_outline(tmp, bw, bh, 0xFFF)
    for i, v in enumerate(tmp):
        if v != 0:
            buf[i] = v

def paint_line(buf, bw, bh, x0, y0, x1, y1, col, thickness=1):
    dx = abs(x1 - x0)
    dy = abs(y1 - y0)
    sx = 1 if x0 < x1 else -1
    sy = 1 if y0 < y1 else -1
    err = dx - dy
    x, y = x0, y0
    while True:
        for oy in range(-(thickness // 2), thickness - (thickness // 2)):
            for ox in range(-(thickness // 2), thickness - (thickness // 2)):
                set_px(buf, bw, bh, x + ox, y + oy, col)
        if x == x1 and y == y1:
            break
        e2 = 2 * err
        if e2 > -dy:
            err -= dy
            x += sx
        if e2 < dx:
            err += dx
            y += sy

def draw_weapon_32x32(wid):
    """Draws crisp 32x32 pixel-art weapon icon with dark outline + metallic/plasma shading."""
    w = [0] * (32 * 32)
    if wid == 0:
        # 0: Dragon Slayer Greatsword (Diagonal broad blade + gold crossguard)
        for i in range(18):
            x, y = 8 + i, 22 - i
            set_px(w, 32, 32, x, y, 0xFFF)
            set_px(w, 32, 32, x+1, y, 0xDDE)
            set_px(w, 32, 32, x, y+1, 0x9AB)
            set_px(w, 32, 32, x+1, y+1, 0x679)
        set_px(w, 32, 32, 26, 4, 0xFFF)
        set_px(w, 32, 32, 26, 5, 0xDDE)
        # Gold crossguard
        for i in range(-4, 5):
            set_px(w, 32, 32, 10 + i, 20 + i, 0xFD2)
            set_px(w, 32, 32, 11 + i, 20 + i, 0xD91)
        # Hilt & pommel
        for i in range(1, 5):
            set_px(w, 32, 32, 9 - i, 21 + i, 0x742)
            set_px(w, 32, 32, 10 - i, 21 + i, 0x521)
        set_px(w, 32, 32, 5, 26, 0xFD2)
        set_px(w, 32, 32, 4, 26, 0xFD2)
    elif wid == 1:
        # 1: Plasma Lightsaber (Cyan laser beam + detailed silver/black hilt)
        for i in range(17):
            x, y = 10 + i, 20 - i
            for ox, oy in [(-1,0),(0,-1),(1,0),(0,1)]:
                set_px(w, 32, 32, x+ox, y+oy, 0x2DF)
            set_px(w, 32, 32, x, y, 0xFFF)
        for i in range(6):
            x, y = 9 - i, 21 + i
            set_px(w, 32, 32, x, y, 0xCCD)
            set_px(w, 32, 32, x+1, y, 0x334)
            set_px(w, 32, 32, x, y+1, 0x678)
        set_px(w, 32, 32, 10, 20, 0xF44)
    elif wid == 2:
        # 2: Titan Boxing Fists (Dual crimson & gold boxing glove!)
        for y in range(8, 23):
            for x in range(8, 24):
                dx, dy = x - 16, y - 14
                if dx*dx + dy*dy <= 56:
                    if dy < -3 or dx < -3:
                        col = 0xF65
                    elif dy > 4:
                        col = 0x911
                    else:
                        col = 0xE22
                    set_px(w, 32, 32, x, y, col)
        # Thumb bulge
        for y in range(15, 21):
            for x in range(7, 12):
                set_px(w, 32, 32, x, y, 0xF54 if y < 18 else 0xA11)
        # Gold wrist cuff
        for y in range(21, 26):
            for x in range(11, 21):
                set_px(w, 32, 32, x, y, 0xFD2 if y < 23 else 0xC81)
        # White specular highlight
        set_px(w, 32, 32, 12, 10, 0xFFF); set_px(w, 32, 32, 13, 10, 0xFFF); set_px(w, 32, 32, 12, 11, 0xFFF)
    elif wid == 3:
        # 3: Titan Battleaxe (Crimson & silver double crescent blade)
        paint_line(w, 32, 32, 7, 26, 23, 7, 0x642, thickness=2)
        set_px(w, 32, 32, 23, 6, 0xFD2)
        # Axe blade top-right & bottom-left arcs around (20, 10)
        for y in range(5, 19):
            for x in range(14, 27):
                dx, dy = x - 19, y - 11
                d2 = dx*dx + dy*dy
                if 16 <= d2 <= 52 and (dx + dy >= -2):
                    if d2 >= 40:
                        set_px(w, 32, 32, x, y, 0xFFF)
                    elif d2 >= 28:
                        set_px(w, 32, 32, x, y, 0xF44)
                    else:
                        set_px(w, 32, 32, x, y, 0x812)
    elif wid == 4:
        # 4: Plasma Spear (Diagonal long shaft + glowing gold/cyan spearhead)
        paint_line(w, 32, 32, 5, 26, 20, 11, 0x852, thickness=2)
        for i in range(-2, 3):
            set_px(w, 32, 32, 19 + i, 11 + i, 0xFD2)
        for y in range(4, 14):
            for x in range(18, 28):
                # Spear diamond point toward (26, 5)
                u = (x - 19) + (12 - y)
                v = abs((x - 19) - (12 - y))
                if 0 <= u <= 11 and v <= (4 if u < 5 else (11 - u)):
                    set_px(w, 32, 32, x, y, 0xFFF if v == 0 else (0x5DF if v <= 1 else 0x29D))
    else:
        # 5: Reaper Scythe (Dark staff + curved glowing violet crescent blade)
        paint_line(w, 32, 32, 7, 27, 22, 7, 0x435, thickness=2)
        for y in range(4, 18):
            for x in range(7, 24):
                # Crescent curving left from top (21, 6)
                dx, dy = x - 17, y - 13
                d2 = dx*dx + dy*dy
                if 36 <= d2 <= 86 and y <= 14 and (x <= 22):
                    if d2 >= 72:
                        set_px(w, 32, 32, x, y, 0xFFF)
                    elif d2 >= 54:
                        set_px(w, 32, 32, x, y, 0xE5F)
                    else:
                        set_px(w, 32, 32, x, y, 0x82B)
    # Crisp dark outline + subtle white sticker highlight
    snap = list(w)
    for y in range(32):
        for x in range(32):
            if snap[y*32 + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 32 and 0 <= ny < 32 and snap[ny*32 + nx] != 0:
                        w[y*32 + x] = 0x112
                        break
    return w

# ---------------------------------------------------------------------------
# 1. Build ui_icons.mem (16 slots of 64x32 = 32768 words)
# ---------------------------------------------------------------------------
slots = [[0] * (64 * 32) for _ in range(16)]

# Slots 0..1: Joy CTA (1-2-3-4 diamond + Big Blue '3' pressing)
for f_idx, pressed in [(0, False), (1, True)]:
    s = slots[f_idx]
    draw_round_button(s, 64, 32, 16, 6,  4, 0x3B5, 0x183, 0x142, '1', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 24, 13, 4, 0xD55, 0xA22, 0x611, '2', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 8,  13, 4, 0xC5A, 0x927, 0x514, '4', pressed=False, sticker=True)
    draw_round_button(s, 64, 32, 16, 21, 4, 0x7EF, 0x2AF, 0x15B, '3', pressed=pressed, sticker=True)
    draw_round_button(s, 64, 32, 47, 14, 11, 0x7EF, 0x29F, 0x14A, '3', pressed=pressed, sticker=True, font=GLYPHS_BOLD_7x11)
    if pressed:
        for sx, sy in [(33, 4), (32, 14), (60, 4), (61, 14)]:
            set_px(s, 64, 32, sx, sy, 0xFF0)
            set_px(s, 64, 32, sx+1, sy, 0xFFF)

# Slots 2..3: Keyboard CTA -> REAL WHITE [ SPACE ] mechanical keycap!
for f_idx, pressed in [(2, False), (3, True)]:
    s = slots[f_idx]
    draw_keycap(s, 64, 32, 5, 5, 54, 20, 0xFFF, 0xEEE, 0x9AB, "SPACE", text_col=0x112, pressed=pressed, font=GLYPHS_5x7, spacing=7, sticker_col=0x3FE)
    if pressed:
        for sx, sy in [(2, 14), (61, 14), (32, 2)]:
            set_px(s, 64, 32, sx, sy, 0xFF0)

# Slot 4: Title Guide Mini-Buttons (Top: [SEL] GUIDE, Bot: REAL WHITE [ESC] GUIDE)
draw_pill_btn(slots[4], 64, 32, 2,  1,  22, 11, "SEL", hi_col=0x78A, mid_col=0x457, lip_col=0x224)
draw_text(slots[4], 64, 32, 27, 4, "GUIDE", 0xEE8, GLYPHS_3x5, 4)
draw_keycap(slots[4], 64, 32, 2, 18, 22, 9, 0xFFF, 0xEEE, 0x9AB, "ESC", text_col=0x112, pressed=False, sticker_col=0x78A)
draw_text(slots[4], 64, 32, 27, 21, "GUIDE", 0xEE8, GLYPHS_3x5, 4)

# Slot 5: Guide Footer Joy Icons
draw_dpad_icon(slots[5], 64, 32, 16, 7, 'L')
draw_dpad_icon(slots[5], 64, 32, 48, 7, 'R')
draw_pill_btn(slots[5], 64, 32, 4, 17, 24, 11, "SEL", hi_col=0x88A, mid_col=0x557, lip_col=0x224)
draw_pill_btn(slots[5], 64, 32, 36, 17, 24, 11, "STR", hi_col=0x88A, mid_col=0x557, lip_col=0x224)

# Slot 6: Guide Footer KB Icons (ALL REAL WHITE KEYBOARD KEYCAPS!)
draw_keycap(slots[6], 64, 32, 6,  1, 20, 11, 0xFFF, 0xEEE, 0x9AB, "A",   text_col=0x112, sticker_col=0x3FF)
draw_keycap(slots[6], 64, 32, 38, 1, 20, 11, 0xFFF, 0xEEE, 0x9AB, "D",   text_col=0x112, sticker_col=0x3FF)
draw_keycap(slots[6], 64, 32, 4,  17, 24, 10, 0xFFF, 0xEEE, 0x9AB, "ESC", text_col=0xC22, sticker_col=0xFD2)
draw_keycap(slots[6], 64, 32, 35, 17, 26, 10, 0xFFF, 0xEEE, 0x9AB, "ENT", text_col=0x112, sticker_col=0x9AB)

# Slots 7..9: 6 Pixel-Art Weapons (each 32x32, 2 per slot)
for wid in range(6):
    wbuf = draw_weapon_32x32(wid)
    slot_idx = 7 + (wid // 2)
    ox = (wid % 2) * 32
    for y in range(32):
        for x in range(32):
            if wbuf[y * 32 + x] != 0:
                slots[slot_idx][y * 64 + ox + x] = wbuf[y * 32 + x]

# Slot 10: Game Over / Victory Prompt Icons (4 quadrants of 32x16)
# TL (0..31, 0..15): Joy Blue '(3)' button | TR (32..63, 0..15): Joy D-Pad L/R
# BL (0..31,16..31): KB White [SPC] keycap | BR (32..63,16..31): KB White [A][D] dual keycaps
draw_round_button(slots[10], 64, 32, 16, 6, 4, 0x7EF, 0x29F, 0x14A, '3', pressed=False, sticker=True, font=GLYPHS_3x5)
draw_dpad_icon(slots[10], 64, 32, 48, 7, 'LR')
draw_keycap(slots[10], 64, 32, 4,  17, 24, 10, 0xFFF, 0xEEE, 0x9AB, "SPC", text_col=0x112, sticker_col=0x3FE)
draw_keycap(slots[10], 64, 32, 33, 17, 13, 10, 0xFFF, 0xEEE, 0x9AB, "A",   text_col=0x112, sticker_col=0xFD2)
draw_keycap(slots[10], 64, 32, 48, 17, 13, 10, 0xFFF, 0xEEE, 0x9AB, "D",   text_col=0x112, sticker_col=0xFD2)

# Slot 11: Logic Gate Quiz Prompt Icons (4 quadrants of 32x16)
# TL (0..31, 0..15): Joy D-Pad U/D | TR (32..63, 0..15): Joy Blue '(3)' button
# BL (0..31,16..31): KB White [1]-[4] | BR (32..63,16..31): KB White [SPC]
draw_dpad_icon(slots[11], 64, 32, 16, 7, 'UD')
draw_round_button(slots[11], 64, 32, 48, 6, 4, 0x7EF, 0x29F, 0x14A, '3', pressed=False, sticker=True, font=GLYPHS_3x5)
draw_keycap(slots[11], 64, 32, 3,  17, 12, 10, 0xFFF, 0xEEE, 0x9AB, "1",   text_col=0x112, sticker_col=0xFD2)
draw_keycap(slots[11], 64, 32, 17, 17, 12, 10, 0xFFF, 0xEEE, 0x9AB, "4",   text_col=0x112, sticker_col=0xFD2)
draw_keycap(slots[11], 64, 32, 36, 17, 24, 10, 0xFFF, 0xEEE, 0x9AB, "SPC", text_col=0x112, sticker_col=0x3FE)

with open(os.path.join(MEM_DIR, "ui_icons.mem"), "w") as f:
    for s_idx, buf in enumerate(slots):
        f.write(f"// Slot {s_idx}\n")
        for i in range(0, len(buf), 16):
            f.write(" ".join(f"{v:03X}" for v in buf[i:i+16]) + "\n")
print("[OK] Wrote mem/ui_icons.mem (32768 words)")

# Preview ui_icons.mem (slots 0..9)
ui_prev = Image.new("RGB", (64 * 5, 32 * 2), (18, 20, 36))
upx = ui_prev.load()
for s_idx in range(10):
    ox = (s_idx % 5) * 64
    oy = (s_idx // 5) * 32
    for y in range(32):
        for x in range(64):
            v = slots[s_idx][y * 64 + x]
            if v != 0:
                upx[ox + x, oy + y] = (((v>>8)&0xF)*17, ((v>>4)&0xF)*17, (v&0xF)*17)
ui_prev.resize((64 * 5 * 3, 32 * 2 * 3), Image.NEAREST).save(os.path.join(PREVIEW_DIR, "ui_icons_preview.png"))

# ---------------------------------------------------------------------------
# 2. Build hero_body.mem (4 outfits x 4 walk frames x 32x24 -> 16384 words)
#    walk_ref.gif-inspired detailed stride, arm swing, shaded back limbs, sneaker soles!
# ---------------------------------------------------------------------------
OUTFITS = [
    # 0: Student Uniform (White shirt, dark tie, black pants, sneakers w/ white soles)
    {"hi": 0xFFF, "mid": 0xEEF, "sh": 0xCCD, "accent": 0x223, "pants_f": 0x223, "pants_b": 0x112, "shoe": 0x334, "sole": 0xFFF, "gown": False},
    # 1: KMUTT CPE Workshop (#405F73, white inner, dark pants)
    {"hi": 0x579, "mid": 0x467, "sh": 0x345, "accent": 0xFFF, "pants_f": 0x223, "pants_b": 0x112, "shoe": 0x334, "sole": 0xFFF, "gown": False},
    # 2: KMUTT Red Graduation Gown (#C12 red, gold-orange sash)
    {"hi": 0xE23, "mid": 0xC12, "sh": 0x811, "accent": 0xFD2, "pants_f": 0xC12, "pants_b": 0x811, "shoe": 0x334, "sole": 0xFFF, "gown": True},
    # 3: Transcended Gold Armor (Gold plates + cyan energy core)
    {"hi": 0xFF6, "mid": 0xFE1, "sh": 0xBA0, "accent": 0x0FF, "pants_f": 0xBA0, "pants_b": 0x870, "shoe": 0x0CC, "sole": 0xFFF, "gown": False},
]

def draw_rect(buf, x0, y0, x1, y1, col):
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            set_px(buf, 32, 24, x, y, col)

def build_body_sprite(outfit_idx, walk_f):
    """Creates a detailed 32x24 body sprite (corresponds to psy = 24..47)."""
    o = OUTFITS[outfit_idx]
    b = [0] * (32 * 24)
    # Vertical bounce like walk_ref.gif: stride frames (0,2) sit 1px lower, passing frames (1,3) sit 1px higher!
    bob = 1 if walk_f in (0, 2) else 0

    # --- BACK ARM (drawn behind torso, darker shading!) ---
    if walk_f == 0:
        # Back arm swings backward-left
        draw_rect(b, 6, 4 + bob, 9, 7 + bob, o["sh"])
        draw_rect(b, 5, 7 + bob, 8, 10 + bob, 0xD97) # Back hand darker skin
    elif walk_f == 2:
        # Back arm swings forward-right
        draw_rect(b, 21, 5 + bob, 25, 8 + bob, o["sh"])
        draw_rect(b, 24, 6 + bob, 26, 9 + bob, 0xD97)
    else:
        draw_rect(b, 7, 4 + bob, 9, 9 + bob, o["sh"])
        draw_rect(b, 7, 9 + bob, 9, 11 + bob, 0xD97)

    # --- LEGS & SNEAKERS (y = 13..22) ---
    # Walk_ref style: separated front & back legs with sneaker & white sole!
    if walk_f == 0:
        # Back leg (left) trailing & lifted behind with sole visible
        draw_rect(b, 8, 13 + bob, 11, 17 + bob, o["pants_b"])
        draw_rect(b, 6, 16 + bob, 9, 19 + bob, o["shoe"])
        draw_rect(b, 5, 16 + bob, 6, 19 + bob, o["sole"])
        # Front leg (right) striding forward with heel down
        draw_rect(b, 16, 13 + bob, 20, 19 + bob, o["pants_f"])
        draw_rect(b, 17, 19 + bob, 22, 21 + bob, o["shoe"])
        draw_rect(b, 17, 21 + bob, 22, 22 + bob, o["sole"])
    elif walk_f == 1:
        # Passing upright: legs near center
        draw_rect(b, 11, 13 + bob, 14, 19 + bob, o["pants_b"])
        draw_rect(b, 11, 19 + bob, 14, 21 + bob, o["shoe"])
        draw_rect(b, 11, 21 + bob, 15, 22 + bob, o["sole"])
        draw_rect(b, 16, 13 + bob, 19, 18 + bob, o["pants_f"])
        draw_rect(b, 16, 18 + bob, 20, 20 + bob, o["shoe"])
        draw_rect(b, 16, 20 + bob, 21, 21 + bob, o["sole"])
    elif walk_f == 2:
        # Front leg (left) striding forward, back leg (right) kicking behind
        draw_rect(b, 11, 13 + bob, 15, 19 + bob, o["pants_f"])
        draw_rect(b, 10, 19 + bob, 15, 21 + bob, o["shoe"])
        draw_rect(b, 10, 21 + bob, 15, 22 + bob, o["sole"])
        draw_rect(b, 18, 13 + bob, 22, 17 + bob, o["pants_b"])
        draw_rect(b, 21, 16 + bob, 24, 19 + bob, o["shoe"])
        draw_rect(b, 24, 16 + bob, 25, 19 + bob, o["sole"])
    else:
        # Passing 2
        draw_rect(b, 12, 13 + bob, 15, 18 + bob, o["pants_f"])
        draw_rect(b, 11, 18 + bob, 15, 20 + bob, o["shoe"])
        draw_rect(b, 11, 20 + bob, 15, 21 + bob, o["sole"])
        draw_rect(b, 16, 13 + bob, 19, 19 + bob, o["pants_b"])
        draw_rect(b, 16, 19 + bob, 20, 21 + bob, o["shoe"])
        draw_rect(b, 16, 21 + bob, 21, 22 + bob, o["sole"])

    # --- TORSO & GOWN SKIRT ---
    # Neck
    draw_rect(b, 14, 2 + bob, 17, 3 + bob, 0xECA)
    # Torso chest (x=10..21, y=4..13)
    draw_rect(b, 10, 4 + bob, 21, 13 + bob, o["mid"])
    draw_rect(b, 10, 4 + bob, 11, 13 + bob, o["hi"])   # Left highlight
    draw_rect(b, 20, 4 + bob, 21, 13 + bob, o["sh"])   # Right shadow

    if outfit_idx == 0:
        # Tie & Belt
        draw_rect(b, 15, 4 + bob, 16, 11 + bob, 0x223)
        draw_rect(b, 10, 13 + bob, 21, 13 + bob, 0x111)
        set_px(b, 32, 24, 15, 13 + bob, 0xCCC); set_px(b, 32, 24, 16, 13 + bob, 0xCCC)
    elif outfit_idx == 1:
        # White V-collar & pocket
        draw_rect(b, 14, 4 + bob, 17, 5 + bob, 0xFFF)
        draw_rect(b, 15, 6 + bob, 16, 7 + bob, 0xFFF)
        draw_rect(b, 18, 7 + bob, 20, 9 + bob, 0x345)
        draw_rect(b, 10, 13 + bob, 21, 13 + bob, 0x111)
    elif outfit_idx == 2:
        # KMUTT Red Graduation Gown Skirt & Gold/Orange Sash
        draw_rect(b, 9, 12 + bob, 22, 18 + bob, o["mid"])
        draw_rect(b, 9, 12 + bob, 10, 18 + bob, o["sh"])
        draw_rect(b, 21, 12 + bob, 22, 18 + bob, o["sh"])
        draw_rect(b, 14, 4 + bob, 17, 8 + bob, 0xFFF)
        draw_rect(b, 12, 4 + bob, 12, 18 + bob, 0xF61)
        draw_rect(b, 13, 4 + bob, 13, 18 + bob, 0xFD2)
        draw_rect(b, 18, 4 + bob, 18, 18 + bob, 0xFD2)
        draw_rect(b, 19, 4 + bob, 19, 18 + bob, 0xF61)
    else:
        # Transcended Gold Armor + Cyan Reactor Core
        draw_rect(b, 12, 4 + bob, 13, 14 + bob, 0xFFF)
        draw_rect(b, 18, 4 + bob, 19, 14 + bob, 0xFFF)
        draw_rect(b, 15, 6 + bob, 16, 9 + bob, 0x0FF)

    # --- FRONT ARM (bent elbow swinging smoothly like walk_ref.gif!) ---
    if walk_f == 0:
        # Front arm (left-side/front) bent forward-right
        draw_rect(b, 19, 5 + bob, 23, 8 + bob, o["hi"])
        draw_rect(b, 22, 6 + bob, 25, 9 + bob, 0xECA)
    elif walk_f == 2:
        # Front arm swings back-left
        draw_rect(b, 7, 5 + bob, 10, 9 + bob, o["hi"])
        draw_rect(b, 5, 8 + bob, 8, 11 + bob, 0xECA)
    else:
        # Neutral bent elbow at side
        draw_rect(b, 20, 4 + bob, 23, 9 + bob, o["hi"])
        draw_rect(b, 21, 9 + bob, 23, 11 + bob, 0xECA)

    # Crisp dark outline around body silhouette
    snap = list(b)
    for y in range(24):
        for x in range(32):
            if snap[y*32 + x] == 0:
                for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < 32 and 0 <= ny < 24 and snap[ny*32 + nx] != 0:
                        b[y*32 + x] = 0x112
                        break
    return b

hero_mem = [0] * (16384)
for out_i in range(4):
    for wf_i in range(4):
        sp = build_body_sprite(out_i, wf_i)
        base = ((out_i * 4) + wf_i) * 1024
        for y in range(24):
            for x in range(32):
                hero_mem[base + y * 32 + x] = sp[y * 32 + x]

with open(os.path.join(MEM_DIR, "hero_body.mem"), "w") as f:
    for i in range(0, 16384, 16):
        f.write(" ".join(f"{v:03X}" for v in hero_mem[i:i+16]) + "\n")
print("[OK] Wrote mem/hero_body.mem (16384 words)")

# Preview hero_body.mem (4 outfits x 4 walk frames)
hb_prev = Image.new("RGB", (32 * 4, 24 * 4), (20, 24, 38))
hpx = hb_prev.load()
for out_i in range(4):
    for wf_i in range(4):
        base = ((out_i * 4) + wf_i) * 1024
        for y in range(24):
            for x in range(32):
                v = hero_mem[base + y * 32 + x]
                if v != 0:
                    hpx[wf_i * 32 + x, out_i * 24 + y] = (((v>>8)&0xF)*17, ((v>>4)&0xF)*17, (v&0xF)*17)
hb_prev.resize((32 * 4 * 4, 24 * 4 * 4), Image.NEAREST).save(os.path.join(PREVIEW_DIR, "hero_body_preview.png"))

# ---------------------------------------------------------------------------
# 3. Build kb_guide.mem (256x144 x 4-bit) & rtl/kb_palette.vh (Real White Keys!)
# ---------------------------------------------------------------------------
KB_PAL = [
    0x000, # 0: Transparent
    0xFFF, # 1: Pure White keycap highlight
    0xEEE, # 2: Real Crisp White keycap top face
    0xCCD, # 3: Real White keycap bevel/shadow
    0x89A, # 4: Real White keycap 3D bottom wall
    0x112, # 5: Keycap dark outline & crisp key legends
    0x2DF, # 6: Cyan label (MOVE / DASH)
    0xFD2, # 7: Gold label (ATTACK / QUIZ / EXIT)
    0x4F6, # 8: Green label (BULLET)
    0xF5B, # 9: Pink/Magenta label (NOVA)
    0xF54, # 10: Red accent
    0xCCD, # 11: Light silver/white label (PAUSE)
    0x234, # 12: Sub-box / divider
    0x457, # 13: Dark slate key accent
    0x58B, # 14: Dim border
    0x000, # 15: Reserved
]

kb_vh = """// Auto-generated 16-color 12-bit palette for Guide Page 3 Real White Keyboard Keycaps
function [11:0] kb_palette;
    input [3:0] idx;
    begin
        case (idx)
            4'd0:  kb_palette = 12'h000;
            4'd1:  kb_palette = 12'hFFF;
            4'd2:  kb_palette = 12'hEEE;
            4'd3:  kb_palette = 12'hCCD;
            4'd4:  kb_palette = 12'h89A;
            4'd5:  kb_palette = 12'h112;
            4'd6:  kb_palette = 12'h2DF;
            4'd7:  kb_palette = 12'hFD2;
            4'd8:  kb_palette = 12'h4F6;
            4'd9:  kb_palette = 12'hF5B;
            4'd10: kb_palette = 12'hF54;
            4'd11: kb_palette = 12'hCCD;
            4'd12: kb_palette = 12'h234;
            4'd13: kb_palette = 12'h457;
            4'd14: kb_palette = 12'h58B;
            default: kb_palette = 12'h000;
        endcase
    end
endfunction
"""
with open(os.path.join(BASE_DIR, "rtl/kb_palette.vh"), "w") as f:
    f.write(kb_vh)

kb_buf = [0] * (256 * 144)

def draw_white_key(x0, y0, w, h, label):
    for y in range(y0, y0 + h + 3):
        for x in range(x0, x0 + w):
            if (x == x0 or x == x0 + w - 1) and (y == y0 or y == y0 + h + 2):
                continue
            if y == y0 or y == y0 + h + 2 or x == x0 or x == x0 + w - 1:
                col = 5
            elif y >= y0 + h:
                col = 4
            elif y == y0 + h - 1:
                col = 5
            elif y <= y0 + 1 or x <= x0 + 1:
                col = 1
            elif x >= x0 + w - 2 or y >= y0 + h - 2:
                col = 3
            else:
                col = 2
            set_px(kb_buf, 256, 144, x, y, col)
    tw = text_width(label, GLYPHS_3x5, 4)
    draw_text(kb_buf, 256, 144, x0 + (w - tw) // 2, y0 + (h - 5) // 2, label, 5, GLYPHS_3x5, 4)

# Left Column (x=6..126): WASD Cluster, SPACE / J, K / E, 3 / L
# 1. WASD Real White Keycaps Cluster -> MOVE
draw_white_key(22, 4,  15, 13, "W")
draw_white_key(6,  19, 15, 13, "A")
draw_white_key(22, 19, 15, 13, "S")
draw_white_key(38, 19, 15, 13, "D")
draw_text(kb_buf, 256, 144, 62, 17, "MOVE", 6)

# 2. Real White SPACEBAR + J -> ATTACK
draw_white_key(6,  42, 42, 13, "SPACE")
draw_white_key(52, 42, 14, 13, "J")
draw_text(kb_buf, 256, 144, 72, 46, "ATTACK", 7)

# 3. Real White K / E -> DASH
draw_white_key(6,  66, 16, 13, "K")
draw_white_key(26, 66, 16, 13, "E")
draw_text(kb_buf, 256, 144, 52, 70, "DASH", 6)

# 4. Real White 3 / L -> NOVA
draw_white_key(6,  90, 16, 13, "3")
draw_white_key(26, 90, 16, 13, "L")
draw_text(kb_buf, 256, 144, 52, 94, "360 NOVA", 9)

# 5. Real White 4 / U -> BULLET
draw_white_key(6,  114, 16, 13, "4")
draw_white_key(26, 114, 16, 13, "U")
draw_text(kb_buf, 256, 144, 52, 118, "BULLET", 8)

# Right Column (x=134..250): Quiz 1-4, ENTER, ESC
# 6. Real White 1 2 3 4 -> QUIZ DOOR
draw_white_key(136, 10, 14, 13, "1")
draw_white_key(151, 10, 14, 13, "2")
draw_white_key(166, 10, 14, 13, "3")
draw_white_key(181, 10, 14, 13, "4")
draw_text(kb_buf, 256, 144, 202, 14, "QUIZ", 7)

# 7. Real White ENTER -> PAUSE
draw_white_key(136, 42, 36, 13, "ENTER")
draw_text(kb_buf, 256, 144, 180, 46, "PAUSE", 11)

# 8. Real White ESC -> EXIT GUIDE
draw_white_key(136, 74, 26, 13, "ESC")
draw_text(kb_buf, 256, 144, 170, 78, "EXIT", 7)

# Write kb_guide.mem (18432 bytes = 128 bytes/row x 144 rows)
with open(os.path.join(MEM_DIR, "kb_guide.mem"), "w") as f:
    f.write("// 256x144 4-bit Real White Keyboard Controls Guide\n")
    for y in range(144):
        row_bytes = []
        for xb in range(128):
            b = ((kb_buf[y * 256 + xb * 2] & 0xF) << 4) | (kb_buf[y * 256 + xb * 2 + 1] & 0xF)
            row_bytes.append(f"{b:02X}")
        f.write(" ".join(row_bytes) + "\n")
print("[OK] Wrote mem/kb_guide.mem (18432 bytes)")

# Preview kb_guide.mem
kb_prev = Image.new("RGB", (256, 144), (20, 24, 38))
kpx = kb_prev.load()
for y in range(144):
    for x in range(256):
        v = kb_buf[y * 256 + x]
        if v != 0:
            c = KB_PAL[v]
            kpx[x, y] = (((c>>8)&0xF)*17, ((c>>4)&0xF)*17, (c&0xF)*17)
kb_prev.resize((512, 288), Image.NEAREST).save(os.path.join(PREVIEW_DIR, "kb_guide_preview.png"))
print("[OK] Saved previews in sim_work/")
