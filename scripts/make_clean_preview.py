import os
import sys
from PIL import Image, ImageDraw, ImageFont

BASE_DIR = r"D:\vivado_pj\DRAGO_NEXUS_V2"

def hex12_to_rgb(h):
    if h == 0:
        return (0, 0, 0, 0)
    r = ((h >> 8) & 0xF) * 17
    g = ((h >> 4) & 0xF) * 17
    b = (h & 0xF) * 17
    return (r, g, b, 255)

def load_mem_words(filename):
    path = os.path.join(BASE_DIR, filename)
    with open(path, "r") as f:
        return [int(line.strip(), 16) for line in f if line.strip()]

def get_player_head(words, hero_id):
    # Each hero has 4 frames of 32x32 = 1024 words per frame
    offset = hero_id * 4 * 1024
    grid = [[0]*32 for _ in range(32)]
    for y in range(32):
        for x in range(32):
            grid[y][x] = words[offset + y * 32 + x]
    return grid

def get_enemy_head(words, mon_id):
    offset = mon_id * 2 * 1024
    grid = [[0]*32 for _ in range(32)]
    for y in range(32):
        for x in range(32):
            grid[y][x] = words[offset + y * 32 + x]
    return grid

def get_boss_sprite(words, boss_kind):
    offset = boss_kind * 2 * 4096
    grid = [[0]*64 for _ in range(64)]
    for y in range(64):
        for x in range(64):
            grid[y][x] = words[offset + y * 64 + x]
    return grid

def render_hero_full(head_grid, wave=1, slash_phase=0):
    # Returns 32x46 RGBA image matching vga_renderer_v2.v
    img = Image.new("RGBA", (32, 46), (0, 0, 0, 0))
    px = img.load()

    # 1. Head (y=0..27)
    for y in range(28):
        for x in range(32):
            c = head_grid[y][x]
            if c != 0:
                px[x, y] = hex12_to_rgb(c)

    # 2. Neck (y=27)
    for x in range(14, 18):
        px[x, 27] = hex12_to_rgb(0xECA)

    # 3. Torso (y=28..37, x=10..21)
    for y in range(28, 38):
        for x in range(10, 22):
            if wave == 1:
                # White Student Shirt + Dark Tie + Black Belt
                if y == 37:
                    col = 0xCCC if (x == 15 or x == 16) else 0x111
                elif 15 <= x <= 16 and y <= 35:
                    col = 0x223 # Tie
                else:
                    col = 0xCCD if (x == 10 or x == 21) else 0xFFF
            elif wave == 2:
                # KMUTT CPE Workshop (#405F73 = 12'h467) + Inner V-Shirt + Pocket
                if y == 37:
                    col = 0x111
                elif 14 <= x <= 17 and y <= 32 and (y <= 29 or (15 <= x <= 16)):
                    col = 0xFFF
                elif 31 <= y <= 33 and 18 <= x <= 20:
                    col = 0x345
                else:
                    col = 0x345 if (x == 10 or x == 21) else 0x467
            else:
                # KMUTT Graduation Gown
                if x in (12, 13, 18, 19):
                    col = 0xFD2 if x in (13, 18) else 0xF61
                elif 14 <= x <= 17 and y <= 33:
                    col = 0xFFF
                else:
                    col = 0x111 if (x == 10 or x == 21) else 0x223

            px[x, y] = hex12_to_rgb(col)

    # 4. Arms & Animated Sword Pose
    arm_col = 0xEEE if wave == 1 else (0x467 if wave == 2 else 0x223)
    if slash_phase == 1: # Anticipation
        for y in range(23, 31):
            for x in range(7, 10):
                px[x, y] = hex12_to_rgb(0xECA if y <= 24 else arm_col)
        for y in range(29, 34):
            for x in range(21, 25):
                px[x, y] = hex12_to_rgb(0xECA if x == 24 else arm_col)
    elif slash_phase == 2: # Smear 1
        for y in range(27, 32):
            for x in range(21, 28):
                px[x, y] = hex12_to_rgb(0xECA if x >= 26 else arm_col)
        for y in range(29, 35):
            for x in range(7, 10):
                px[x, y] = hex12_to_rgb(arm_col)
    elif slash_phase == 3: # Hit
        for y in range(30, 34):
            for x in range(22, 30):
                px[x, y] = hex12_to_rgb(0xECA if x >= 28 else arm_col)
    elif slash_phase == 4: # Follow Through
        for y in range(32, 36):
            for x in range(21, 29):
                px[x, y] = hex12_to_rgb(0xECA if x >= 27 else arm_col)
    else: # Idle
        for y in range(29, 37):
            for x in range(7, 10):
                px[x, y] = hex12_to_rgb(0xECA if y >= 35 else arm_col)
            for x in range(22, 25):
                px[x, y] = hex12_to_rgb(0xECA if y >= 35 else arm_col)

    # 5. Legs / Gown Skirt (y=38..45)
    if wave >= 3:
        for y in range(38, 44):
            for x in range(8, 24):
                if x in (12, 19): col = 0xF61
                elif x in (13, 18): col = 0xFD2
                elif x in (8, 23): col = 0x111
                else: col = 0x223
                px[x, y] = hex12_to_rgb(col)
        # Shoes
        for y in range(44, 46):
            for x in range(11, 15): px[x, y] = hex12_to_rgb(0x334)
            for x in range(17, 21): px[x, y] = hex12_to_rgb(0x334)
    else:
        for y in range(38, 46):
            for x in range(11, 15):
                px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)
            for x in range(17, 21):
                px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)

    return img

def render_enemy_grunt(head_grid):
    # Returns 32x46 RGBA image matching vga_renderer_v2.v
    img = Image.new("RGBA", (32, 46), (0, 0, 0, 0))
    px = img.load()

    # Head
    for y in range(28):
        for x in range(32):
            c = head_grid[y][x]
            if c != 0:
                px[x, y] = hex12_to_rgb(c)

    # Neck
    for x in range(14, 18):
        px[x, 27] = hex12_to_rgb(0xECA)

    # Torso (Black suit + white inner + red tie)
    for y in range(28, 38):
        for x in range(10, 22):
            if 14 <= x <= 17 and y <= 34 and (y <= 30 or (15 <= x <= 16)):
                col = 0xA12 if (15 <= x <= 16 and y >= 30) else 0xFFF
            else:
                col = 0x111 if (x == 10 or x == 21) else 0x223
            px[x, y] = hex12_to_rgb(col)

    # Sleeves & Hands
    for y in range(29, 37):
        for x in range(7, 10):
            px[x, y] = hex12_to_rgb(0xECA if y >= 35 else 0x112)
        for x in range(22, 25):
            px[x, y] = hex12_to_rgb(0xECA if y >= 35 else 0x112)

    # Pants & Shoes
    for y in range(38, 46):
        for x in range(11, 15):
            px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)
        for x in range(17, 21):
            px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)

    return img

def draw_sword_slash_vfx(stage):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    px = img.load()
    cx, cy = 20, 36 # player center inside canvas

    for wy in range(64):
        for wx in range(64):
            bx_d = wx - cx
            by_d = wy - cy
            ax_d = abs(bx_d)
            ay_d = abs(by_d)
            oct_d = ax_d + (ay_d >> 1) if ax_d >= ay_d else ay_d + (ax_d >> 1)
            dot_d = bx_d
            sw_up = -by_d

            col = None
            if stage == 1: # Anticipation
                if 6 <= sw_up <= 28 and -12 <= dot_d <= -1 and -6 <= dot_d + (sw_up >> 2) <= -2:
                    col = 0xFFF if (dot_d + (sw_up >> 2) >= -4) else 0xCCD
            elif stage == 2: # Shear
                if sw_up >= -4 and 16 <= oct_d <= 34 and (dot_d >= -6 or sw_up >= 10) and (dot_d + sw_up >= 8):
                    col = 0xFFF if (oct_d >= 25 or dot_d >= 20) else 0xCCD
            elif stage == 3: # Hit
                if dot_d >= 6 and -12 <= sw_up <= 20 and 16 <= oct_d <= 32 and dot_d >= abs(sw_up) + 2:
                    col = 0xFFF if (oct_d >= 23 or sw_up >= 8) else 0xCCD
            elif stage == 4: # Follow Through
                if 8 <= dot_d <= 34 and -2 <= sw_up <= 1:
                    col = 0xFFF if (sw_up == 0 or dot_d >= 22) else 0xCCD

            if col:
                px[wx, wy] = hex12_to_rgb(col)

    return img

def draw_item_icon(kind):
    # Returns 16x16 RGBA
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "heart":
        # Pixel-art heart
        draw.ellipse([(3, 3), (8, 8)], fill=(242, 33, 33, 255))
        draw.ellipse([(8, 3), (13, 8)], fill=(242, 33, 33, 255))
        draw.polygon([(3, 6), (14, 6), (8.5, 13)], fill=(242, 33, 33, 255))
        img.putpixel((5, 5), (255, 255, 255, 255))
    elif kind == "gem":
        # Blue Evo Gem
        draw.polygon([(8, 2), (13, 8), (8, 14), (3, 8)], fill=(0, 255, 255, 255), outline=(17, 17, 34, 255))
        draw.polygon([(8, 4), (11, 8), (8, 12), (5, 8)], fill=(255, 255, 255, 255))
    elif kind == "orbit":
        # Orbiting Storm Sword
        for y in range(2, 14):
            img.putpixel((8, y), (255, 255, 255, 255) if y < 9 else (187, 119, 51, 255))
            img.putpixel((7, y), (0, 255, 255, 255) if y < 9 else (187, 119, 51, 255))
        for x in range(5, 11):
            img.putpixel((x, 9), (255, 218, 0, 255))
    elif kind == "bullet":
        # Blue gun plasma bullet
        draw.ellipse([(4, 4), (11, 11)], fill=(0, 255, 255, 255))
        draw.ellipse([(6, 6), (9, 9)], fill=(255, 255, 255, 255))
    return img

def main():
    print("Loading ROM data...")
    player_words = load_mem_words("player_sprites.mem")
    enemy_words  = load_mem_words("enemy_sprites.mem")
    boss_words   = load_mem_words("boss_sprites.mem")

    # 4 Heroes
    hero_heads = [get_player_head(player_words, i) for i in range(4)]
    hero_names = ["PF (SW0)", "PPuen (SW1)", "PPeem (SW2)", "PPing (SW3)"]

    # Grunt enemy
    grunt_head = get_enemy_head(enemy_words, 0)

    # 3 Bosses
    boss_imgs = []
    for b_id in range(3):
        b_grid = get_boss_sprite(boss_words, b_id)
        b_im = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
        b_px = b_im.load()
        for y in range(64):
            for x in range(64):
                c = b_grid[y][x]
                if c != 0:
                    b_px[x, y] = hex12_to_rgb(c)
        boss_imgs.append(b_im)

    # Canvas Setup: Modern Dark Theme
    CANVAS_W = 820
    CANVAS_H = 880
    canvas = Image.new("RGB", (CANVAS_W, CANVAS_H), (13, 17, 23)) # Dark GitHub slate
    draw = ImageDraw.Draw(canvas)

    # Title Banner
    draw.rectangle([(0, 0), (CANVAS_W, 52)], fill=(22, 27, 34))
    draw.line([(0, 52), (CANVAS_W, 52)], fill=(48, 54, 61), width=1)
    draw.text((24, 16), "DRAGO NEXUS V2 - SPRITE & ASSET SHOWCASE", fill=(240, 246, 252))
    draw.text((540, 16), "FPGA 60FPS V4 KMUTT EDITION", fill=(88, 166, 255))

    def paste_scaled(im, x, y, scale=2):
        w, h = im.size
        sw = int(round(w * scale))
        sh = int(round(h * scale))
        up = im.resize((sw, sh), Image.Resampling.NEAREST)
        canvas.paste(up, (x, y), up)

    # =========================================================================
    # Section 1: Human Heroes Across 3 KMUTT Progression Outfits
    # =========================================================================
    # Row 1: Wave 1 - Student Uniform
    draw.text((24, 68), "1. HEROES - WAVE 1: STUDENT UNIFORM (WHITE SHIRT, BLACK TIE, TROUSERS)", fill=(139, 148, 158))
    for i in range(4):
        h_im = render_hero_full(hero_heads[i], wave=1)
        ox = 45 + i * 190
        oy = 90
        paste_scaled(h_im, ox, oy, 2)
        draw.text((ox + 2, oy + 46*2 + 6), hero_names[i], fill=(201, 209, 217))

    # Row 2: Wave 2 - KMUTT CPE Shop Shirt (#405F73)
    draw.text((24, 202), "2. HEROES - WAVE 2: KMUTT CPE WORKSHOP SHIRT (#405F73 / WHITE INNER)", fill=(139, 148, 158))
    for i in range(4):
        h_im = render_hero_full(hero_heads[i], wave=2)
        ox = 45 + i * 190
        oy = 224
        paste_scaled(h_im, ox, oy, 2)
        draw.text((ox + 2, oy + 46*2 + 6), hero_names[i], fill=(201, 209, 217))

    # Row 3: Wave 3+ - KMUTT Graduation Gown
    draw.text((24, 336), "3. HEROES - WAVE 3+: KMUTT GRADUATION GOWN (ORANGE & GOLD SASH)", fill=(139, 148, 158))
    for i in range(4):
        h_im = render_hero_full(hero_heads[i], wave=3)
        ox = 45 + i * 190
        oy = 358
        paste_scaled(h_im, ox, oy, 2)
        draw.text((ox + 2, oy + 46*2 + 6), hero_names[i], fill=(201, 209, 217))

    # Divider
    draw.line([(24, 470), (CANVAS_W - 24, 470)], fill=(48, 54, 61), width=1)

    # =========================================================================
    # Section 2: Black Suit Grunt + 4 Sword Attack Combo Stages
    # =========================================================================
    draw.text((24, 482), "4. SUIT ENEMY GRUNT & 4-PHASE MELEE SWORD ATTACK COMBO", fill=(139, 148, 158))

    # Black Suit Grunt
    g_im = render_enemy_grunt(grunt_head)
    paste_scaled(g_im, 45, 506, 2)
    draw.text((32, 506 + 46*2 + 6), "Black Suit Grunt", fill=(248, 81, 73))

    # 4 Sword Combo Stages
    stages = ["Phase 1: Stance", "Phase 2: Shear", "Phase 3: Hit", "Phase 4: Follow-Thru"]
    for s_idx in range(4):
        h_slash = render_hero_full(hero_heads[0], wave=2, slash_phase=s_idx+1)
        vfx = draw_sword_slash_vfx(s_idx+1)
        combo = Image.new("RGBA", (70, 52), (0, 0, 0, 0))
        combo.paste(h_slash, (6, 6), h_slash)
        combo.paste(vfx, (0, 0), vfx)
        ox = 185 + s_idx * 155
        oy = 502
        paste_scaled(combo, ox, oy, 2)
        draw.text((ox + 10, 506 + 46*2 + 6), stages[s_idx], fill=(201, 209, 217))

    # Divider
    draw.line([(24, 630), (CANVAS_W - 24, 630)], fill=(48, 54, 61), width=1)

    # =========================================================================
    # Section 3: 3 Bosses & Essential Combat Items
    # =========================================================================
    draw.text((24, 642), "5. 3 BOSS FORMS (AJARN_V 1, 2, THANOS) & ESSENTIAL COMBAT ITEMS", fill=(139, 148, 158))

    boss_titles = ["Ajarn_V (Wave 1)", "Ajarn_V Iron (Wave 2)", "Ajarn_V Thanos (Final)"]
    for b_id in range(3):
        ox = 40 + b_id * 185
        oy = 665
        paste_scaled(boss_imgs[b_id], ox, oy, 2)
        draw.text((ox + 6, oy + 64*2 + 6), boss_titles[b_id], fill=(210, 168, 255))

    # Essential Items (Heart, Orbiting Storm Sword, Blue Evo Gem, Plasma Bullet)
    items_ox = 600
    draw.text((items_ox, 665), "Combat Items & Upgrades", fill=(240, 246, 252))

    items = [
        ("heart", "Health Heart (+1 HP)", (242, 80, 80)),
        ("orbit", "Orbiting Storm Sword", (255, 218, 0)),
        ("gem",   "EXP / Evo Gem", (0, 255, 255)),
        ("bullet","Auto-Lock Plasma Bullet", (88, 166, 255)),
    ]

    for idx, (ikind, iname, icol) in enumerate(items):
        i_im = draw_item_icon(ikind)
        iy = 698 + idx * 36
        paste_scaled(i_im, items_ox, iy, 2)
        draw.text((items_ox + 42, iy + 6), iname, fill=icol)

    # Save to D:\vivado_pj\DRAGO_NEXUS_V2\sprite_preview.png
    out_path = os.path.join(BASE_DIR, "sprite_preview.png")
    canvas.save(out_path)
    print(f"Successfully generated clean sprite preview at {out_path} ({CANVAS_W}x{CANVAS_H})!")

if __name__ == "__main__":
    main()
