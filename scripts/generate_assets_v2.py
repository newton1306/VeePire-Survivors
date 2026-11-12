import os
import math
from collections import deque
from PIL import Image, ImageEnhance

BASE_DIR = r"D:\vivado_pj\DRAGO_NEXUS_V2"
OUT_DIR = os.path.join(BASE_DIR, "mem")
os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "rtl"), exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "constrs"), exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "sim"), exist_ok=True)
os.makedirs(os.path.join(BASE_DIR, "docs", "screenshots"), exist_ok=True)

# =========================================================================
# 1. DYNAMIC CHROMA & ENVIRONMENT PALETTES
# =========================================================================
HERO_CHROMAS = [
    (0x6FF, 0x2DF, 0x08D, 0x048,  0xFF6, 0xFA0, 0xB50, 0x620,  0xFFF, 0x2FF), # 0 Azure Cyber
    (0xFA4, 0xF42, 0xB11, 0x601,  0xFE4, 0xF90, 0xA40, 0x510,  0xFFF, 0xFE0), # 1 Crimson Inferno
    (0xFFF, 0xCDE, 0x78A, 0x457,  0xF33, 0xB12, 0x26D, 0x138,  0xFF2, 0x4FF), # 2 Gundam RX
    (0x668, 0x446, 0x223, 0x112,  0xF4C, 0xC18, 0x705, 0x403,  0xF36, 0xF8F), # 3 Shadow Magenta
    (0xFFF, 0xEEF, 0x9BD, 0x579,  0xFF6, 0xFD0, 0xC80, 0x740,  0x4FF, 0xFFF), # 4 Celestial Gold
    (0x9F6, 0x3E4, 0x192, 0x051,  0xC5F, 0x82C, 0x508, 0x305,  0xFF0, 0x7F7), # 5 Toxic Venom
    (0xDFF, 0x8EF, 0x3AD, 0x158,  0xEEF, 0x89F, 0x45C, 0x227,  0xFFF, 0x6FF), # 6 Frost Ice
    (0xFF8, 0xFC2, 0xE70, 0x930,  0xF53, 0xC11, 0x801, 0x401,  0xFFF, 0xFF6), # 7 Solar Phoenix
    (0xFDF, 0xF8C, 0xD48, 0x825,  0xFFF, 0xBEF, 0x69D, 0x359,  0x2FF, 0xFFF), # 8 Sakura Rose
    (0xC7F, 0x83E, 0x51A, 0x306,  0xFE4, 0xE90, 0x940, 0x520,  0xF25, 0xFD0), # 9 Void Amber
    (0x8FD, 0x2D9, 0x096, 0x053,  0xFF6, 0xDB0, 0x970, 0x530,  0xFFF, 0x6FF), # 10 Jade Emperor
    (0x99A, 0x667, 0x445, 0x223,  0xF23, 0xB01, 0x701, 0x400,  0xF44, 0xFF5), # 11 Blood Knight
    (0x7FF, 0x1EC, 0x098, 0x055,  0xFA4, 0xF60, 0xA30, 0x510,  0xFFF, 0x2FF), # 12 Plasma Teal
    (0xFFA, 0xFE3, 0xD90, 0x840,  0xFFF, 0xFAD, 0xA63, 0x631,  0x4FF, 0xFFF), # 13 Golden Titan
    (0xF6F, 0xE2C, 0x908, 0x505,  0x6FF, 0x0DF, 0x08B, 0x047,  0xFF4, 0xFFF), # 14 Synthwave
    (0x556, 0x334, 0x222, 0x111,  0xF32, 0xA01, 0x600, 0x300,  0xF22, 0xFA0), # 15 Dark Lord
]

# 4 Distinct High-Contrast Biome Palettes
ENV_THEMES = [
    # 0: Emerald Ancient Citadel (Waves 1..3)
    {1:0x354, 2:0x465, 3:0x243, 4:0x9BC, 5:0x68A, 6:0x357, 7:0x2AF, 8:0x8FF, 9:0xF63, 10:0xFD5, 11:0x001, 12:0x853, 13:0xF92, 14:0xFF5, 15:0x5FB},
    # 1: Twilight Neon Chasm (Waves 4..6)
    {1:0x325, 2:0x436, 3:0x214, 4:0x98C, 5:0x659, 6:0x326, 7:0x2CF, 8:0x9FF, 9:0xF4C, 10:0xF9F, 11:0x001, 12:0x745, 13:0xC5F, 14:0xFDF, 15:0x6DF},
    # 2: Chrono-Shift Time-Freeze Cyan
    {1:0x246, 2:0x358, 3:0x135, 4:0x8CF, 5:0x48C, 6:0x248, 7:0x6FF, 8:0xFFF, 9:0x5DF, 10:0xFFF, 11:0x002, 12:0x458, 13:0x5FF, 14:0xFFF, 15:0x9FF},
    # 3: Inferno Magma Forge & Boss Sanctum (Waves 7..10)
    {1:0x422, 2:0x532, 3:0x311, 4:0xB75, 5:0x843, 6:0x521, 7:0xF82, 8:0xFE5, 9:0xF32, 10:0xFF6, 11:0x100, 12:0x632, 13:0xF61, 14:0xFF5, 15:0xFC3},
]

FIXED_FG = {
    28: 0x5F6, 29: 0x1C3, 30: 0x072, 31: 0xCFA, # Green Slime / Steel
    32: 0xF34, 33: 0x912, 34: 0xFA4, 35: 0x422, # Crimson Imp / Magma
    36: 0xC6F, 37: 0x72C, 38: 0xFDF, 39: 0x305, # Void Phantom
    40: 0x78A, 41: 0xABC, 42: 0x345, 43: 0xF13, 44: 0xFD0, 45: 0x2FF, # Iron / Boss / Cyber
    46: 0xB73, 47: 0xE94, 48: 0x641, # Bronze / Wood / Gold
    49: 0xF24, 50: 0x2E6, 51: 0xF91, 52: 0xF21, 53: 0xFFE, # HUD / Lasers / Flames
    54: 0x223, 55: 0x446, 56: 0x2AF, 57: 0xAAA, 58: 0xFF0, 59: 0x0FF, # UI / Ice / Cyan
    60: 0xF5D, 61: 0x8F4, 62: 0xF70, 63: 0xFFF, # Sakura / Venom / Ember
}

with open(os.path.join(OUT_DIR, "pal_env.mem"), "w") as f:
    f.write("\n".join(f"{th.get(i, 0):03X}" for th in ENV_THEMES for i in range(16)) + "\n")

fg_lines = [f"{0:03X}"] * 64
fg_lines[16] = "112"
fg_lines[17] = "FFF"
for idx, val in FIXED_FG.items():
    fg_lines[idx] = f"{val:03X}"
for k, v in enumerate(HERO_CHROMAS[0]):
    fg_lines[18+k] = f"{v:03X}"
with open(os.path.join(OUT_DIR, "pal_fg.mem"), "w") as f:
    f.write("\n".join(fg_lines) + "\n")

chroma_lines = []
for ch in HERO_CHROMAS:
    chroma_lines.append("112")
    chroma_lines.append("FFF")
    for v in ch:
        chroma_lines.append(f"{v:03X}")
    for _ in range(4):
        chroma_lines.append("FFF")
with open(os.path.join(OUT_DIR, "hero_chroma.mem"), "w") as f:
    f.write("\n".join(chroma_lines) + "\n")

# =========================================================================
# 2. TILE GRAPHICS (16 tiles x 16x16)
# =========================================================================
def make_tile(fn):
    return [[fn(x, y) for x in range(16)] for y in range(16)]

def t_floor_a(x, y):
    if (x == 0 or y == 0) and ((x + y) % 4 == 0): return 3
    if (x*7 + y*13) % 29 == 0: return 2
    return 1

def t_floor_b(x, y):
    if x in (0, 15) or y in (0, 15): return 3
    if 4 <= x <= 11 and 4 <= y <= 11 and (x in (4,11) or y in (4,11)): return 2
    return 1

def t_wall(x, y):
    if y < 4: return 4
    if y == 4 or y == 15 or (x == 0 and y >= 4) or (x == 8 and y >= 10) or y == 10: return 6
    return 5

def t_light_bridge(x, y):
    if y in (0, 15): return 11
    if y in (1, 14) or x in (0, 15): return 8
    return 8 if ((x + y) % 4 == 0) else 7

def t_shadow_bridge(x, y):
    if y in (0, 15): return 11
    if y in (1, 14) or x in (0, 15): return 15
    return 15 if ((x + y) % 4 == 0 or (x - y) % 4 == 0) else 6

def t_torch(x, y):
    dx, dy = abs(x - 7.5), abs(y - 5.5)
    if dy < 3.5 and dx < 3.0: return 14 if (dx + dy < 2.2) else 13
    if 5 <= x <= 10 and 8 <= y <= 14: return 6 if x in (5, 10) or y == 14 else 12
    return t_floor_a(x, y)

def t_shrine(x, y):
    d = math.hypot(x - 7.5, y - 7.5)
    if 5.5 <= d <= 7.0: return 6
    if 3.2 <= d < 5.5: return 15
    if d < 3.2: return 14 if (x+y)%2==0 else 15
    return t_floor_b(x, y)

def t_vault_floor(x, y):
    if x in (1, 14) or y in (1, 14): return 15
    if 5 <= x <= 10 and 5 <= y <= 10: return 2
    return 1

def t_boss_floor(x, y):
    if x == 0 or y == 0: return 6
    if (x in (3, 12) and y in (3, 12)): return 15
    if (x + y) % 8 == 0: return 3
    return 2 if (4 <= x <= 11 and 4 <= y <= 11) else 1

def t_laser_barrier(x, y):
    if x in (0, 15) or y in (0, 15): return 6
    if x % 3 == 0: return 10
    if y % 4 == 0: return 9
    return 4

def t_abyss(x, y):
    if (x*3 + y*5) % 19 == 0: return 3
    return 11

def t_lava(x, y):
    if (x*5 + y*3) % 11 == 0: return 14
    if (x + y) % 4 == 0: return 13
    return 9

def t_magma_bridge(x, y):
    if x in (0, 15): return 6
    if y in (1, 14): return 13
    return 15 if (x + y) % 6 == 0 else 5

def t_gold_rune(x, y):
    if x in (2, 13) or y in (2, 13): return 10
    if 6 <= x <= 9 and 6 <= y <= 9: return 14
    return t_boss_floor(x, y)

tiles = [
    make_tile(t_floor_a),       # 0: Floor A
    make_tile(t_floor_b),       # 1: Floor B
    make_tile(t_wall),          # 2: Solid Brick Wall
    make_tile(t_light_bridge),  # 3: Light Bridge
    make_tile(t_shadow_bridge), # 4: Shadow Bridge (Chrono reveals)
    make_tile(t_torch),         # 5: Torch Pillar (Solid)
    make_tile(t_shrine),        # 6: Healing Shrine
    make_tile(t_vault_floor),   # 7: Bright Path Runner
    make_tile(t_boss_floor),    # 8: Boss Floor
    make_tile(t_laser_barrier), # 9: Final Omega Boss Gate (Locked Red in W10)
    make_tile(t_abyss),         # 10: Abyss Void (Solid)
    make_tile(t_laser_barrier), # 11: Zone 1 Gate (Opens W2)
    make_tile(t_lava),          # 12: Lava Channel (Solid)
    make_tile(t_laser_barrier), # 13: Biome 2/3 Sector Gate (Opens W4 / W7)
    make_tile(t_magma_bridge),  # 14: Obsidian Bridge
    make_tile(t_gold_rune),     # 15: Boss Arena Emblem Tile
]

with open(os.path.join(OUT_DIR, "tiles.mem"), "w") as f:
    f.write("\n".join(f"{t[y][x]:02X}" for t in tiles for y in range(16) for x in range(16)) + "\n")

# =========================================================================
# 3. SINGLE RECTANGULAR ARENA ROOM (tx=4..35, ty=4..23 -> 512 x 320 px)
#    Exterior is pure void in vga_renderer_v2; right wall has sliding door!
# =========================================================================
W_T, H_T = 128, 64
wmap = [[0]*W_T for _ in range(H_T)]

for y in range(4, 24):
    for x in range(4, 36):
        if x == 4 or x == 35 or y == 4 or y == 23:
            wmap[y][x] = 2 # Arena Perimeter Wall
        else:
            wmap[y][x] = 1 if (x + y) % 2 == 0 else 0

# Clean central arena walkway & emblem (non-blocking floor tiles)
for x in range(6, 34):
    wmap[13][x] = 7; wmap[14][x] = 7
for y in range(6, 22):
    wmap[y][19] = 7; wmap[y][20] = 7
for y in range(11, 17):
    for x in range(17, 23):
        wmap[y][x] = 15 if (18 <= x <= 21 and 12 <= y <= 15) else 8
# Corner torches (visual accents, far from spawn & door)
wmap[6][6] = 5; wmap[6][33] = 5; wmap[21][6] = 5; wmap[21][33] = 5
# Right-wall doorway opening (handled dynamically as sliding door in renderer/engine)
for y in range(12, 16):
    wmap[y][35] = 7

with open(os.path.join(OUT_DIR, "tilemap.mem"), "w") as f:
    f.write("\n".join(f"{wmap[y][x]:01X}" for y in range(64) for x in range(128)) + "\n")

# =========================================================================
# 4. 32x32 HERO SKINS (8 Models x 4 Anim Frames: Walk0, Walk1, Lunge, Apex!)
# =========================================================================
def blank(w=32, h=32):
    return [[0]*w for _ in range(h)]

def put_px(g, x, y, c):
    if 0 <= x < len(g[0]) and 0 <= y < len(g):
        g[y][x] = c

def fill_ellipse(g, cx, cy, rx, ry, c):
    for y in range(len(g)):
        for x in range(len(g[0])):
            if ((x - cx)/rx)**2 + ((y - cy)/ry)**2 <= 1.0:
                g[y][x] = c

def add_outline(g, outline_col=16):
    h, w = len(g), len(g[0])
    out = [row[:] for row in g]
    for y in range(h):
        for x in range(w):
            if g[y][x] == 0:
                for dx, dy in ((-1,0),(1,0),(0,-1),(0,1)):
                    nx, ny = x+dx, y+dy
                    if 0 <= nx < w and 0 <= ny < h and g[ny][nx] != 0:
                        out[y][x] = outline_col
                        break
    return out

SPACE_SRC = r"D:\vivado_pj\Space_Shooter\Space_shooter_source"
BOSS_SRC  = os.path.join(BASE_DIR, "image_source")

def rgb_to_hex12(r, g, b):
    c = ((r >> 4) << 8) | ((g >> 4) << 4) | (b >> 4)
    return 0x111 if c == 0 else c

def hex12_to_rgb(h):
    return (((h >> 8) & 0xF)*17, ((h >> 4) & 0xF)*17, (h & 0xF)*17)

def remove_bg_bfs(im, mode="white", protect_box=None, step_tol=26):
    """Pure-PIL flood-fill background remover from image borders."""
    im = im.convert("RGB")
    w, h = im.size
    px = im.load()
    bg = [[False]*w for _ in range(h)]
    q = deque()
    c0 = px[0, 0]
    c1 = px[w-1, 0]

    def is_bg_pixel(x, y, ref_rgb):
        r, g, b = px[x, y]
        if protect_box is not None:
            px0, py0, px1, py1 = protect_box
            if px0 <= x <= px1 and py0 <= y <= py1:
                return False
        if mode == "teal":
            return (g > r + 20) and (g > b + 12)
        elif mode == "white":
            lum = (r + g + b) // 3
            sat = max(r, g, b) - min(r, g, b)
            return (lum >= 165 and sat <= 32)
        elif mode == "wall":
            sat = max(r, g, b) - min(r, g, b)
            lum = (r + g + b) // 3
            dr = abs(r - ref_rgb[0]); dg = abs(g - ref_rgb[1]); db = abs(b - ref_rgb[2])
            d_corner = min(
                abs(r - c0[0]) + abs(g - c0[1]) + abs(b - c0[2]),
                abs(r - c1[0]) + abs(g - c1[1]) + abs(b - c1[2])
            )
            return (sat <= 26 and lum >= 135 and max(dr, dg, db) <= step_tol and d_corner <= 125)
        return False

    seeds = [(x, 0) for x in range(w)] + [(x, h-1) for x in range(w)] + [(0, y) for y in range(h)] + [(w-1, y) for y in range(h)]
    for sx, sy in seeds:
        if not bg[sy][sx] and is_bg_pixel(sx, sy, px[sx, sy]):
            bg[sy][sx] = True
            q.append((sx, sy))

    while q:
        cx, cy = q.popleft()
        ref = px[cx, cy]
        for dx, dy in ((-1,0), (1,0), (0,-1), (0,1)):
            nx, ny = cx + dx, cy + dy
            if 0 <= nx < w and 0 <= ny < h and not bg[ny][nx]:
                if is_bg_pixel(nx, ny, ref):
                    bg[ny][nx] = True
                    q.append((nx, ny))

    rgba = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rp = rgba.load()
    for y in range(h):
        for x in range(w):
            if not bg[y][x]:
                r, g, b = px[x, y]
                rp[x, y] = (r, g, b, 255)
    return rgba

def extract_face_32(filename, crop_frac, bg_mode="wall", rim_rgb=(17, 17, 34), boost_b=1.08, boost_c=1.18):
    im = Image.open(os.path.join(SPACE_SRC, filename)).convert("RGB")
    w, h = im.size
    x0, y0, x1, y1 = int(w*crop_frac[0]), int(h*crop_frac[1]), int(w*crop_frac[2]), int(h*crop_frac[3])
    crop = im.crop((x0, y0, x1, y1))
    crop = ImageEnhance.Brightness(crop).enhance(boost_b)
    crop = ImageEnhance.Contrast(crop).enhance(boost_c)
    crop = crop.resize((96, 96), Image.Resampling.LANCZOS)
    rgba = remove_bg_bfs(crop, mode=bg_mode, step_tol=28)
    rp = rgba.load()
    for y in range(96):
        for x in range(96):
            if ((x - 48.0)/40.0)**2 + ((y - 47.0)/44.0)**2 > 1.0:
                rp[x, y] = (0, 0, 0, 0)
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)
    bw, bh = rgba.size
    scale = min(28.0 / max(1, bw), 28.0 / max(1, bh))
    nw, nh = max(1, int(round(bw*scale))), max(1, int(round(bh*scale)))
    small = rgba.resize((nw, nh), Image.Resampling.LANCZOS)
    grid = blank(32, 32)
    ox, oy = (32 - nw) // 2, (32 - nh) // 2
    sp = small.load()
    for y in range(nh):
        for x in range(nw):
            r, g, b, a = sp[x, y]
            if a > 120:
                grid[oy + y][ox + x] = rgb_to_hex12(r, g, b)
    return add_outline(grid, rgb_to_hex12(*rim_rgb))

BASE_HEROES = [
    extract_face_32("pf.jpg",    (0.08, 0.07, 0.79, 0.82), "wall", (64, 160, 255), 1.18, 1.24),# 0: PF (SW0)
    extract_face_32("ppuen.jpg", (0.14, 0.03, 0.86, 0.82), "white",(48, 224, 144), 1.06, 1.15),# 1: PPuen (SW1)
    extract_face_32("ppeem.jpg", (0.18, 0.11, 0.80, 0.77), "wall", (255, 192, 48), 1.08, 1.16),# 2: PPeem (SW2)
    extract_face_32("pping.jpg", (0.10, 0.13, 0.86, 0.82), "wall", (255, 80, 180), 1.06, 1.16),# 3: PPing (SW3)
]

def draw_hero(model_id, frame):
    base = BASE_HEROES[model_id % 4]
    g = blank(32, 32)
    bob = -1 if frame == 1 else (1 if frame == 2 else 0)
    lean = 2 if frame == 2 else 0
    for y in range(32):
        for x in range(32):
            c = base[y][x]
            if c != 0:
                nx, ny = x + lean, y + bob
                if 0 <= nx < 32 and 0 <= ny < 32:
                    g[ny][nx] = c
    if frame == 3:
        # Apex Golden/Cyan Power Sparkles!
        for sx, sy in ((2,3),(29,3),(2,28),(29,28),(15,1),(16,1)):
            put_px(g, sx, sy, 0xFF4)
    return g

player_frames = [draw_hero(mid, fr) for mid in range(4) for fr in range(4)]
# 4 * 4 * 1024 = 16,384 entries (12-bit RGB444)!
with open(os.path.join(OUT_DIR, "player_sprites.mem"), "w") as f:
    f.write("\n".join(f"{fg[y][x]:03X}" for fg in player_frames for y in range(32) for x in range(32)) + "\n")

# =========================================================================
# 5. HUMAN-FACE 32x32 ENEMIES (8 Archetypes x 2 Frames = 16,384 x 12-bit!)
#    Only human faces (ajv.png clones with distinct enemy armor/rims)!
# =========================================================================
AJV_BASE = extract_face_32("ajv.png", (0.05, 0.02, 0.95, 0.90), "white", (255, 48, 64), 1.05, 1.18)

ENEMY_RIMS = [
    (0xF34, 0x912, 0xFF4), # 0: Crimson Recruit
    (0xC4F, 0x619, 0xF8F), # 1: Void Striker
    (0x3E5, 0x172, 0xAF4), # 2: Toxic Bruiser
    (0xFD2, 0xA60, 0xFFF), # 3: Gold Elite
    (0xF61, 0x820, 0xFF6), # 4: Magma Raider
    (0x2DF, 0x169, 0xFFF), # 5: Cyber Clone
    (0x6AF, 0x259, 0xDFF), # 6: Frost Mage
    (0xF26, 0x702, 0xFE0), # 7: Abyssal Guard
]

def draw_monster_32(kind, frame):
    g = blank(32, 32)
    b = 1 if frame else 0
    rim, dark, accent = ENEMY_RIMS[kind % 8]
    # Copy human face (shifted slightly by walk bob)
    for y in range(28):
        for x in range(32):
            c = AJV_BASE[y][x]
            if c != 0:
                ny = y + b
                if 0 <= ny < 32:
                    # Tint subtle outer rim pixels with enemy color
                    if c == 0xF34:
                        g[ny][x] = rim
                    else:
                        g[ny][x] = c
    # Enemy shoulder armor + glowing horns/visor so they look clearly hostile
    for y in range(26 + b, min(32, 30 + b)):
        for x in range(7, 25):
            if g[y][x] == 0:
                g[y][x] = rim if (x < 11 or x > 20) else dark
    if kind in (1, 5):
        # Cyber/Void glowing visor strip across eyes
        for x in range(11, 21):
            put_px(g, x, 13 + b, accent)
    elif kind in (3, 7):
        # Horns / Crown spikes
        for h in range(3):
            put_px(g, 9 - h, 4 - h + b, accent)
            put_px(g, 22 + h, 4 - h + b, accent)
    return g

monster_frames = [draw_monster_32(k, fr) for k in range(8) for fr in range(2)]
with open(os.path.join(OUT_DIR, "enemy_sprites.mem"), "w") as f:
    f.write("\n".join(f"{m[y][x]:03X}" for m in monster_frames for y in range(32) for x in range(32)) + "\n")

# =========================================================================
# 6. 16x16 PICKUPS, CRATES, METEORS, PETS, ORBIT SWORDS (16 frames -> 4096)
# =========================================================================
def draw_item_16(fid):
    g = blank(16, 16)
    f = fid & 1
    kind = fid >> 1
    if kind == 0: # Blue Evo Gem (frame 0/1 pulse!)
        fill_ellipse(g, 8, 8, 4.5 + f*0.4, 5.4, 59)
        fill_ellipse(g, 8, 7, 2.6, 3.4, 17)
        put_px(g, 8, 8, 58)
    elif kind in (1, 2, 3): # Heart ONLY (no mushroom/crate!)
        fill_ellipse(g, 5, 6, 2.5, 2.5, 49); fill_ellipse(g, 10, 6, 2.5, 2.5, 49)
        for y in range(6, 13):
            for x in range(8 - (12-y), 9 + (12-y)):
                if 3 <= x <= 12: put_px(g, x, y, 49)
        put_px(g, 5, 5, 17)
    elif kind == 4: # Flaming Meteor
        for y in range(2, 7):
            for x in range(6, 11):
                if (x+y+f)%2==0: put_px(g, x, y, 51)
        fill_ellipse(g, 8, 10, 4.5, 4.5, 52); fill_ellipse(g, 8, 10, 2.5, 2.5, 58)
    elif kind == 5: # Orbiting Storm Sword
        for y in range(2, 13): put_px(g, 8, y, 17 if y<8 else 44); put_px(g, 7, y, 59 if y<8 else 44)
        for x in range(5, 12): put_px(g, x, 9, 44)
    elif kind == 6: # Companion Pet Drone (P1 Cyan / P2 Sakura)
        col_main = 60 if f else 59
        fill_ellipse(g, 8, 8, 4.0, 4.0, col_main)
        fill_ellipse(g, 8, 8, 2.0, 2.0, 17)
        put_px(g, 3, 6, 58); put_px(g, 13, 6, 58)
        put_px(g, 4, 7, 58); put_px(g, 12, 7, 58)
    else: # Golden Relic Chest
        for y in range(5, 14):
            for x in range(3, 14): put_px(g, x, y, 44 if (y==8 or x in (3,13)) else 46)
        put_px(g, 8, 9, 59)
    return add_outline(g, 16)

item_frames = [draw_item_16(fid) for fid in range(16)]
with open(os.path.join(OUT_DIR, "obj_sprites.mem"), "w") as f:
    f.write("\n".join(f"{it[y][x]:02X}" for it in item_frames for y in range(16) for x in range(16)) + "\n")

# =========================================================================
# 7. 3 UNIQUE 64x64 BOSSES FROM image_source + AJARN_V THANOS (12-bit RGB444)
# =========================================================================
def image_to_boss_64(filename, bg_mode="white", protect_frac=None, rim_col=0x112, boost_c=1.18):
    im = Image.open(os.path.join(BOSS_SRC, filename)).convert("RGB")
    im = ImageEnhance.Contrast(im).enhance(boost_c)
    w, h = im.size
    scale = min(160.0 / w, 160.0 / h)
    nw, nh = max(1, int(round(w*scale))), max(1, int(round(h*scale)))
    work = im.resize((nw, nh), Image.Resampling.LANCZOS)
    pbox = None
    if protect_frac is not None:
        pbox = (int(nw*protect_frac[0]), int(nh*protect_frac[1]), int(nw*protect_frac[2]), int(nh*protect_frac[3]))
    rgba = remove_bg_bfs(work, mode=bg_mode, protect_box=pbox, step_tol=22)
    bbox = rgba.getbbox()
    if bbox:
        rgba = rgba.crop(bbox)
    bw, bh = rgba.size
    fit = min(60.0 / max(1, bw), 60.0 / max(1, bh))
    fw, fh = max(1, int(round(bw*fit))), max(1, int(round(bh*fit)))
    small = rgba.resize((fw, fh), Image.Resampling.LANCZOS)
    g = blank(64, 64)
    ox, oy = (64 - fw) // 2, (64 - fh) // 2
    sp = small.load()
    for y in range(fh):
        for x in range(fw):
            r, g_c, b, a = sp[x, y]
            if a > 120:
                g[oy + y][ox + x] = rgb_to_hex12(r, g_c, b)
    return add_outline(g, rim_col)

def build_ajarn_v_thanos(enraged=False):
    g = blank(64, 64)
    # 1. Golden-Purple Thanos Titan Armor Body & Shoulder Pauldrons
    c_purp_lt = 0x94D if not enraged else 0xC5F
    c_purp_dk = 0x518 if not enraged else 0x71A
    c_gold_lt = 0xFE3
    c_gold_md = 0xC80
    c_gold_dk = 0x740

    # Shoulder Pauldrons + Chestplate
    for y in range(25, 50):
        for x in range(14, 51):
            dx = abs(x - 32.0)
            if y <= 33 and dx >= 10:
                g[y][x] = c_gold_lt if (y < 29 or dx > 15) else c_gold_md
            elif dx <= (17 - (y - 25)//4):
                if (y in (30, 31) and dx <= 11) or (abs(x - 32) <= 2 and y >= 32):
                    g[y][x] = c_gold_lt if (x + y) % 2 == 0 else c_gold_md
                else:
                    g[y][x] = c_purp_lt if (x + y) % 3 == 0 else c_purp_dk
    # Legs / Boots
    for y in range(50, 62):
        for x in list(range(20, 29)) + list(range(36, 45)):
            g[y][x] = c_gold_md if y >= 57 else c_purp_dk
    # Right Arm (Purple + Gold Vambrace)
    for y in range(30, 48):
        for x in range(47, 56):
            g[y][x] = c_gold_lt if y >= 40 else c_purp_lt

    # 2. Giant Golden INFINITY GAUNTLET on Left Hand (x=3..17, y=20..42)
    for y in range(22, 42):
        for x in range(4, 17):
            if y < 27 and x in (4, 16): continue
            g[y][x] = c_gold_lt if (x < 9 or y < 28) else (c_gold_md if x < 14 else c_gold_dk)
    # 6 Glowing Infinity Stones on Gauntlet!
    stones = [(7,26,0xF22), (10,25,0x28F), (13,26,0xF80), (15,29,0xB2F), (6,31,0x2F4), (10,33,0xFF2)]
    for sx, sy, scol in stones:
        for dy in (-1, 0, 1):
            for dx in (-1, 0, 1):
                if abs(dx) + abs(dy) <= (1 if not enraged else 2):
                    put_px(g, sx+dx, sy+dy, 0xFFF if (dx==0 and dy==0) else scol)

    # 3. Ajarn_V Head mounted into Thanos Helmet/Collar!
    im = Image.open(os.path.join(BOSS_SRC, "Ajarn_V_2.png")).convert("RGB")
    w, h = im.size
    head_crop = im.crop((int(w*0.24), int(h*0.12), int(w*0.62), int(h*0.39)))
    head_crop = head_crop.resize((64, 64), Image.Resampling.LANCZOS)
    head_rgba = remove_bg_bfs(head_crop, mode="wall", step_tol=32)
    bbox = head_rgba.getbbox()
    if bbox:
        head_rgba = head_rgba.crop(bbox)
    head_small = head_rgba.resize((22, 22), Image.Resampling.LANCZOS)
    hp = head_small.load()
    for y in range(22):
        for x in range(22):
            r, g_c, b, a = hp[x, y]
            if a > 120 and not (r > 200 and g_c > 200 and b > 200):
                # Subtle Thanos Titan purple skin tint while keeping Ajarn V's likeness!
                tr = min(255, int(r*0.76 + 44))
                tg = min(255, int(g_c*0.54 + 12))
                tb = min(255, int(b*0.88 + 54))
                g[5 + y][21 + x] = rgb_to_hex12(tr, tg, tb)
    # Golden Thanos Helmet Crown & Cheek Guards hugging his head!
    for x in range(24, 41):
        put_px(g, x, 6, c_gold_lt if x % 2 == 0 else c_gold_md)
        put_px(g, x, 7, c_gold_md)
    for y in range(7, 25):
        put_px(g, 22, y, c_gold_md); put_px(g, 41, y, c_gold_md)
    for ex, ey in ((28, 15), (29, 15), (34, 15), (35, 15)):
        put_px(g, ex, ey, 0xF4F if enraged else 0xC6F)
    if enraged:
        # Blazing Infinity Snap Aura!
        for ang_i in range(0, 16):
            ax = int(32 + 29*math.cos(ang_i*math.pi/8))
            ay = int(32 + 29*math.sin(ang_i*math.pi/8))
            put_px(g, ax, ay, 0xF4F if ang_i%2==0 else 0xFF4)
    return add_outline(g, 0xF3F if enraged else 0xFD0)

def gen_boss(kind, enraged=False):
    if kind == 0:
        return image_to_boss_64("Ajarn_V_1.png", bg_mode="wall", protect_frac=(0.24, 0.46, 0.42, 0.88),
                                rim_col=(0xF42 if enraged else 0xFA0), boost_c=1.18)
    elif kind == 1:
        return image_to_boss_64("Ajarn_V_2.png", bg_mode="white", protect_frac=None,
                                rim_col=(0xF24 if enraged else 0x2DF), boost_c=1.16)
    else:
        return build_ajarn_v_thanos(enraged=enraged)

boss_frames = [gen_boss(k, enr) for k in range(3) for enr in (False, True)]
while len(boss_frames) < 8:
    boss_frames.append(blank(64, 64))
with open(os.path.join(OUT_DIR, "boss_sprites.mem"), "w") as f:
    f.write("\n".join(f"{b[y][x]:03X}" for b in boss_frames for y in range(64) for x in range(64)) + "\n")

# =========================================================================
# 8. 8x8 FONT ROM (Including Bold Arrows 42/43 + '+', '*', '%')
# =========================================================================
FONT_DATA = {
    0:[0x3C,0x66,0x6E,0x76,0x66,0x66,0x3C,0], 1:[0x18,0x38,0x18,0x18,0x18,0x18,0x7E,0],
    2:[0x3C,0x66,0x06,0x1C,0x30,0x60,0x7E,0], 3:[0x3C,0x66,0x06,0x1C,0x06,0x66,0x3C,0],
    4:[0x0C,0x1C,0x3C,0x6C,0x7E,0x0C,0x0C,0], 5:[0x7E,0x60,0x7C,0x06,0x06,0x66,0x3C,0],
    6:[0x3C,0x60,0x7C,0x66,0x66,0x66,0x3C,0], 7:[0x7E,0x06,0x0C,0x18,0x30,0x30,0x30,0],
    8:[0x3C,0x66,0x66,0x3C,0x66,0x66,0x3C,0], 9:[0x3C,0x66,0x66,0x3E,0x06,0x0C,0x38,0],
    10:[0x18,0x3C,0x66,0x66,0x7E,0x66,0x66,0], 11:[0x7C,0x66,0x66,0x7C,0x66,0x66,0x7C,0],
    12:[0x3C,0x66,0x60,0x60,0x60,0x66,0x3C,0], 13:[0x78,0x6C,0x66,0x66,0x66,0x6C,0x78,0],
    14:[0x7E,0x60,0x60,0x7C,0x60,0x60,0x7E,0], 15:[0x7E,0x60,0x60,0x7C,0x60,0x60,0x60,0],
    16:[0x3C,0x66,0x60,0x6E,0x66,0x66,0x3E,0], 17:[0x66,0x66,0x66,0x7E,0x66,0x66,0x66,0],
    18:[0x3C,0x18,0x18,0x18,0x18,0x18,0x3C,0], 19:[0x1E,0x0C,0x0C,0x0C,0x6C,0x6C,0x38,0],
    20:[0x66,0x6C,0x78,0x70,0x78,0x6C,0x66,0], 21:[0x60,0x60,0x60,0x60,0x60,0x60,0x7E,0],
    22:[0x63,0x77,0x7F,0x6B,0x63,0x63,0x63,0], 23:[0x66,0x76,0x7E,0x7E,0x6E,0x66,0x66,0],
    24:[0x3C,0x66,0x66,0x66,0x66,0x66,0x3C,0], 25:[0x7C,0x66,0x66,0x7C,0x60,0x60,0x60,0],
    26:[0x3C,0x66,0x66,0x66,0x6A,0x6C,0x36,0], 27:[0x7C,0x66,0x66,0x7C,0x6C,0x66,0x66,0],
    28:[0x3C,0x66,0x60,0x3C,0x06,0x66,0x3C,0], 29:[0x7E,0x18,0x18,0x18,0x18,0x18,0x18,0],
    30:[0x66,0x66,0x66,0x66,0x66,0x66,0x3C,0], 31:[0x66,0x66,0x66,0x66,0x66,0x3C,0x18,0],
    32:[0x63,0x63,0x63,0x6B,0x7F,0x77,0x63,0], 33:[0x66,0x66,0x3C,0x18,0x3C,0x66,0x66,0],
    34:[0x66,0x66,0x66,0x3C,0x18,0x18,0x18,0], 35:[0x7E,0x06,0x0C,0x18,0x30,0x60,0x7E,0],
    36:[0,0,0,0,0,0,0,0], 37:[0,0x18,0x18,0,0x18,0x18,0,0], 38:[0,0,0,0x7E,0,0,0,0],
    39:[0x18,0x18,0x18,0x18,0x18,0,0x18,0], 40:[0,0x66,0xFF,0xFF,0x7E,0x3C,0x18,0],
    41:[0x06,0x0C,0x18,0x30,0x60,0,0,0],
    42:[0x08,0x18,0x38,0x78,0x38,0x18,0x08,0], # < Left Arrow
    43:[0x10,0x18,0x1C,0x1E,0x1C,0x18,0x10,0], # > Right Arrow
    44:[0x00,0x18,0x18,0x7E,0x18,0x18,0x00,0], # +
    45:[0x00,0x24,0x66,0x3C,0x66,0x24,0x00,0], # x combo
}
with open(os.path.join(OUT_DIR, "font.mem"), "w") as f:
    f.write("\n".join(f"{FONT_DATA.get(ch, [0]*8)[r]:02X}" for ch in range(64) for r in range(8)) + "\n")

# =========================================================================
# 9. PIXEL-ART METALLIC ARCADE TITLE LOGO ROM (160 x 48 -> padded 8,192 x 6-bit)
# =========================================================================
logo = blank(160, 48)
# Decorative glowing cyber wing brackets on left/right of logo
for y in range(6, 42):
    for d in range(3):
        put_px(logo, 4 + abs(y-24)//3 + d, y, 59 if d==1 else 56)
        put_px(logo, 155 - abs(y-24)//3 - d, y, 59 if d==1 else 56)

# Render crisp 2x metallic beveled letters for "VEEPIRE" centered on row 8..23
title_str = "VEEPIRE"
sx0 = 160 // 2 - (len(title_str) * 12) // 2
for ci, ch in enumerate(title_str):
    if 'A' <= ch <= 'Z': code = ord(ch) - ord('A') + 10
    elif ch == '-': code = 38
    else: code = 36
    glyph = FONT_DATA[code]
    gx_base = sx0 + ci * 12
    for r in range(8):
        rowbits = glyph[r]
        for c in range(8):
            if (rowbits >> (7 - c)) & 1:
                for dy in range(2):
                    for dx in range(2):
                        px_l, py_l = gx_base + c*2 + dx, 8 + r*2 + dy
                        # Metallic gradient: top bright white/gold -> mid gold/amber -> orange bottom!
                        col = 53 if r < 2 else (58 if r < 5 else 51)
                        put_px(logo, px_l, py_l, col)
                        put_px(logo, px_l + 1, py_l + 1, 52 if (r>=5) else col) # drop shadow edge

# Second line: "SURVIVORS" centered at row 31..38 in bright cyan!
sub_str = "SURVIVORS"
sx1 = 160 // 2 - (len(sub_str) * 8) // 2
for ci, ch in enumerate(sub_str):
    if 'A' <= ch <= 'Z': code = ord(ch) - ord('A') + 10
    elif '0' <= ch <= '9': code = ord(ch) - ord('0')
    else: code = 36
    glyph = FONT_DATA[code]
    gx_base = sx1 + ci * 8
    for r in range(8):
        for c in range(8):
            if (glyph[r] >> (7 - c)) & 1:
                put_px(logo, gx_base + c, 31 + r, 53 if r < 3 else 59)

logo = add_outline(logo, 16)
logo_flat = [logo[y][x] for y in range(48) for x in range(160)]
while len(logo_flat) < 8192:
    logo_flat.append(0)
with open(os.path.join(OUT_DIR, "title_logo.mem"), "w") as f:
    f.write("\n".join(f"{v:02X}" for v in logo_flat) + "\n")

# =========================================================================
# 10. BRAM CHIPTUNE MUSIC SEQUENCER ROM (4 Songs x 256 Steps = 1,024 x 16-bit)
#     Word format: {lead_note[5:0], bass_note[5:0], drum_bits[3:0]}
#     Notes: 0=Rest, 1..32=Scale index (C3..G5 Pentatonic/Minor Heroic!)
# =========================================================================
# Song 0: Heroic Title & Adventure Groove
# Song 1: High-Energy Action Combat
# Song 2: Intense Boss Battle Arpeggio
# Song 3: Victory Celebration Fanfare
bgm_words = []
S0_LEAD = [15,0,17,0,19,0,22,22, 24,0,22,0,19,17,15,0, 17,0,19,0,22,0,26,26, 24,22,19,17,15,0,12,0]
S0_BASS = [ 3,3, 0,3, 5,5, 0,5,  7,7, 0,7, 5,5, 3,0,  5,5, 0,5, 7,7, 0,7,  8,8, 7,7, 5,0, 3,0]
S1_LEAD = [15,19,22,27, 22,19,15,19, 17,22,24,29, 24,22,17,0, 19,22,26,29, 26,22,19,22, 27,26,24,22, 19,17,15,0]
S1_BASS = [ 3,0, 3,3,  5,0, 5,5,  7,0, 7,7,  8,0, 7,5,  5,0, 5,5,  7,0, 7,7,  10,0,8,0,  7,5, 3,0]
S2_LEAD = [15,16,19,16, 22,24,22,19, 15,16,19,22, 27,24,22,19, 14,15,18,15, 22,25,22,18, 27,26,24,22, 19,18,15,0]
S2_BASS = [ 3,3, 3,3,  6,6, 6,6,   3,3, 4,4,  6,6, 7,7,   2,2, 2,2,  6,6, 8,8,  10,10,8,8, 6,4, 3,3]
S3_LEAD = [15,0,19,0,22,0,27,27, 27,0,24,0,27,0,30,30, 29,27,24,22,24,27,22,0, 27,27,27,0,30,0,30,0]
S3_BASS = [ 3,0, 7,0, 10,0,15,0,  8,0, 12,0,15,0,15,0, 7,0, 10,0, 12,0,15,0, 15,0,15,0,15,0,15,0]

for song_id, (ld, bs) in enumerate([(S0_LEAD, S0_BASS), (S1_LEAD, S1_BASS), (S2_LEAD, S2_BASS), (S3_LEAD, S3_BASS)]):
    for step in range(256):
        idx = step % 32
        bar = step // 32
        l_n = ld[idx]
        if l_n > 0 and (bar % 4 == 2): l_n = min(31, l_n + 2) # Musical B-section lift!
        b_n = bs[idx]
        drum = 0
        if (step % 4 == 0): drum |= 1   # Kick on beat
        if (step % 8 == 4): drum |= 2   # Snare on 2 & 4
        if (step % 2 == 1) and song_id in (1, 2): drum |= 4 # Driving 16th hi-hat!
        word = ((l_n & 0x3F) << 10) | ((b_n & 0x3F) << 4) | (drum & 0xF)
        bgm_words.append(f"{word:04X}")

with open(os.path.join(OUT_DIR, "bgm_rom.mem"), "w") as f:
    f.write("\n".join(bgm_words) + "\n")

# =========================================================================
# 11. EXPORT PREVIEW PNGS (12-bit RGB444 Human Heroes, Enemies & Bosses)
# =========================================================================
prev = Image.new("RGB", (680, 330), (16, 22, 36))
for i in range(4):
    spr = player_frames[i*4]
    ox, oy = 14 + i*82, 12
    for y in range(32):
        for x in range(32):
            c = spr[y][x]
            if c == 0: continue
            rgb = hex12_to_rgb(c)
            for dy in range(2):
                for dx in range(2): prev.putpixel((ox + x*2 + dx, oy + y*2 + dy), rgb)

# 8 Human-Face Enemies row (12-bit RGB444!)
for i in range(8):
    spr = monster_frames[i*2]
    ox, oy = 14 + i*82, 92
    for y in range(32):
        for x in range(32):
            c = spr[y][x]
            if c == 0: continue
            rgb = hex12_to_rgb(c)
            for dy in range(2):
                for dx in range(2): prev.putpixel((ox + x*2 + dx, oy + y*2 + dy), rgb)

# 3 Bosses row (12-bit RGB444)!
for b_id in range(3):
    spr = boss_frames[b_id*2]
    ox, oy = 24 + b_id*160, 178
    for y in range(64):
        for x in range(64):
            c = spr[y][x]
            if c == 0: continue
            rgb = hex12_to_rgb(c)
            for dy in range(2):
                for dx in range(2): prev.putpixel((ox + x*2 + dx, oy + y*2 + dy), rgb)

# Pickups
for i, fid in enumerate([0, 2, 4, 6, 8, 10, 12, 14]):
    spr = item_frames[fid]
    ox, oy = 520 + (i % 4)*38, 196 + (i // 4)*48
    for y in range(16):
        for x in range(16):
            c = spr[y][x]
            if c == 0: continue
            col = 0x112 if c==16 else (0xFFF if c==17 else FIXED_FG.get(c, 0xFFF))
            rgb = hex12_to_rgb(col)
            for dy in range(2):
                for dx in range(2): prev.putpixel((ox + x*2 + dx, oy + y*2 + dy), rgb)

prev.save(os.path.join(BASE_DIR, "sprite_preview.png"))
print("Generated V4 KMUTT Edition Assets & sprite_preview.png cleanly!")
