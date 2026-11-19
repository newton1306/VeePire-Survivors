import os
from PIL import Image, ImageDraw

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
    words = []
    with open(path, "r") as f:
        for raw in f:
            line = raw.split("//")[0].strip()
            if not line:
                continue
            for tok in line.split():
                words.append(int(tok, 16))
    return words


def render_hero_v6(player_words, body_words, hero_id, stage_id, walk_frame=1):
    # Matches vga_renderer_v2.v exact BRAM addressing:
    # - u_player_rom addr = {hero_id[1:0], 2'b00, y[4:0], x[4:0]} -> 1024 words/pose, 4096 words/hero
    # - u_hero_body_rom addr = {stage[1:0], walk_frame[1:0], body_y[4:0], x[4:0]} -> 1024 words/frame
    img = Image.new("RGBA", (32, 48), (0, 0, 0, 0))
    px = img.load()
    h_off = hero_id * 4 * 1024
    b_off = (stage_id * 4 + walk_frame) * 1024

    bob = 1 if walk_frame in (0, 2) else 0
    for y in range(25):
        for x in range(32):
            c = player_words[h_off + y * 32 + x]
            if c != 0 and (y + bob) < 48:
                px[x, y + bob] = hex12_to_rgb(c)

    for by in range(24):
        for bx in range(32):
            c = body_words[b_off + by * 32 + bx]
            if c != 0:
                px[bx, 24 + by] = hex12_to_rgb(c)
    return img


def render_weapon_v6(ui_words, wpn_id):
    # Slots 7..9 hold 6 weapons (each 32x32, 2 per 64x32 slot = 2048 words/slot)
    slot = 7 + (wpn_id // 2)
    ox = (wpn_id % 2) * 32
    base = slot * 2048
    img = Image.new("RGBA", (32, 32), (0, 0, 0, 0))
    px = img.load()
    for y in range(32):
        for x in range(32):
            v = ui_words[base + y * 64 + ox + x]
            if v != 0:
                px[x, y] = hex12_to_rgb(v)
    return img


def render_enemy_grunt(enemy_words, mon_id=0):
    img = Image.new("RGBA", (32, 46), (0, 0, 0, 0))
    px = img.load()
    off = mon_id * 2 * 1024
    for y in range(28):
        for x in range(32):
            c = enemy_words[off + y * 32 + x]
            if c != 0:
                px[x, y] = hex12_to_rgb(c)
    for x in range(14, 18):
        px[x, 27] = hex12_to_rgb(0xECA)
    for y in range(28, 38):
        for x in range(10, 22):
            if 14 <= x <= 17 and y <= 34 and (y <= 30 or (15 <= x <= 16)):
                col = 0xA12 if (15 <= x <= 16 and y >= 30) else 0xFFF
            else:
                col = 0x111 if (x == 10 or x == 21) else 0x223
            px[x, y] = hex12_to_rgb(col)
    for y in range(29, 37):
        for x in range(7, 10):
            px[x, y] = hex12_to_rgb(0xECA if y >= 35 else 0x112)
        for x in range(22, 25):
            px[x, y] = hex12_to_rgb(0xECA if y >= 35 else 0x112)
    for y in range(38, 46):
        for x in range(11, 15):
            px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)
        for x in range(17, 21):
            px[x, y] = hex12_to_rgb(0x334 if y >= 44 else 0x112)
    return img


def render_boss(boss_words, b_id):
    img = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    px = img.load()
    off = b_id * 2 * 4096
    for y in range(64):
        for x in range(64):
            c = boss_words[off + y * 64 + x]
            if c != 0:
                px[x, y] = hex12_to_rgb(c)
    return img


def draw_item_icon(kind):
    img = Image.new("RGBA", (16, 16), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    if kind == "heart":
        draw.ellipse([(3, 3), (8, 8)], fill=(242, 33, 33, 255))
        draw.ellipse([(8, 3), (13, 8)], fill=(242, 33, 33, 255))
        draw.polygon([(3, 6), (14, 6), (8.5, 13)], fill=(242, 33, 33, 255))
        img.putpixel((5, 5), (255, 255, 255, 255))
    elif kind == "gem":
        draw.polygon([(8, 2), (13, 8), (8, 14), (3, 8)], fill=(0, 255, 255, 255), outline=(17, 17, 34, 255))
        draw.polygon([(8, 4), (11, 8), (8, 12), (5, 8)], fill=(255, 255, 255, 255))
    elif kind == "orbit":
        for y in range(2, 14):
            img.putpixel((8, y), (255, 255, 255, 255) if y < 9 else (187, 119, 51, 255))
            img.putpixel((7, y), (0, 255, 255, 255) if y < 9 else (187, 119, 51, 255))
        for x in range(5, 11):
            img.putpixel((x, 9), (255, 218, 0, 255))
    elif kind == "bullet":
        draw.ellipse([(4, 4), (11, 11)], fill=(0, 255, 255, 255))
        draw.ellipse([(6, 6), (9, 9)], fill=(255, 255, 255, 255))
    return img


def main():
    player_words = load_mem_words("player_sprites.mem")
    body_words   = load_mem_words("hero_body.mem")
    ui_words     = load_mem_words("ui_icons.mem")
    enemy_words  = load_mem_words("enemy_sprites.mem")
    boss_words   = load_mem_words("boss_sprites.mem")

    W, H = 960, 1055
    canvas = Image.new("RGB", (W, H), (13, 17, 23))
    draw = ImageDraw.Draw(canvas)

    def paste_sc(im, x, y, sc=2):
        up = im.resize((int(im.width * sc), int(im.height * sc)), Image.Resampling.NEAREST)
        canvas.paste(up, (x, y), up)

    # Header
    draw.rectangle([(0, 0), (W, 52)], fill=(22, 27, 34))
    draw.line([(0, 52), (W, 52)], fill=(56, 189, 248), width=2)
    draw.text((24, 17), "DRAGO-NEXUS V2 - COMPLETE BRAM SPRITE, OUTFIT & WEAPON SHOWCASE", fill=(248, 250, 252))
    draw.text((710, 17), "PURE VERILOG | 640x480 VGA", fill=(56, 189, 248))

    # Section 1: 4 Heroes x 4 KMUTT Outfits (Stage 0..3)
    draw.text((24, 66), "1. 4 PLAYABLE HEROES (BTNC) x 4 KMUTT EVOLUTION OUTFITS (hero_body.mem)", fill=(250, 204, 21))
    hero_names = ["Hero 0 (PF)", "Hero 1 (PPuen)", "Hero 2 (PPeem)", "Hero 3 (PPing)"]
    stage_names = [
        ("Stage 0: Student", (226, 232, 240)),
        ("Stage 1: CPE Shop", (96, 165, 250)),
        ("Stage 2: Red Gown", (248, 113, 113)),
        ("Stage 3: Gold Armor", (250, 204, 21)),
    ]

    for c_h in range(4):
        draw.text((195 + c_h * 190, 92), hero_names[c_h], fill=(56, 189, 248))

    for st_i, (st_lbl, st_col) in enumerate(stage_names):
        ry = 116 + st_i * 108
        draw.rounded_rectangle([(24, ry), (W - 24, ry + 100)], radius=8, fill=(22, 27, 34), outline=(48, 54, 61))
        draw.text((38, ry + 38), st_lbl, fill=st_col)
        for h_i in range(4):
            spr = render_hero_v6(player_words, body_words, h_i, st_i, walk_frame=1)
            paste_sc(spr, 200 + h_i * 190, ry + 4, sc=2)

    # Section 2: 6 Melee Weapons (BTNU/BTND) from ui_icons.mem
    wy0 = 562
    draw.text((24, wy0), "2. 6 SELECTABLE MELEE WEAPONS (BTNU / BTND) FROM ui_icons.mem", fill=(56, 189, 248))
    wpn_names = [
        ("0: SWORD", (226, 232, 240)),
        ("1: LIGHT SABER", (34, 211, 238)),
        ("2: TITAN FISTS", (248, 113, 113)),
        ("3: BATTLE AXE", (251, 146, 60)),
        ("4: PLASMA SPEAR", (74, 222, 128)),
        ("5: REAPER SCYTHE", (192, 132, 252)),
    ]
    for w_i, (wn, wc) in enumerate(wpn_names):
        bx = 24 + w_i * 154
        draw.rounded_rectangle([(bx, wy0 + 24), (bx + 144, wy0 + 142)], radius=8, fill=(22, 27, 34), outline=(48, 54, 61))
        wim = render_weapon_v6(ui_words, w_i)
        paste_sc(wim, bx + 24, wy0 + 30, sc=3)
        draw.text((bx + 16, wy0 + 122), wn, fill=wc)

    # Section 3: Walk Stride 4 Frames & Suit Enemy Grunt
    sy0 = 720
    draw.text((24, sy0), "3. WALK CYCLE ANIMATION (4 BRAM FRAMES) & SUIT ENEMY GRUNT", fill=(56, 189, 248))
    draw.rounded_rectangle([(24, sy0 + 22), (W - 24, sy0 + 150)], radius=8, fill=(22, 27, 34), outline=(48, 54, 61))
    for wf in range(4):
        spr = render_hero_v6(player_words, body_words, 0, 3, walk_frame=wf)
        paste_sc(spr, 65 + wf * 150, sy0 + 28, sc=2)
        draw.text((55 + wf * 150, sy0 + 130), f"Frame {wf} (Gold)", fill=(250, 204, 21))
    grunt = render_enemy_grunt(enemy_words, 0)
    paste_sc(grunt, 730, sy0 + 30, sc=2)
    draw.text((705, sy0 + 130), "Black Suit Grunt", fill=(248, 81, 73))

    # Section 4: 3 Boss Forms + Items
    by0 = 884
    draw.text((24, by0), "4. FINAL BOSS AJARN_V (3 PORTAL FORMS) & COMBAT ITEMS", fill=(244, 114, 182))
    boss_names = ["Ajarn_V Form 0 (105 HP)", "Ajarn_V Form 1 (145 HP)", "Ajarn_V Form 2 (190 HP)"]
    for b_id in range(3):
        bx = 42 + b_id * 215
        bim = render_boss(boss_words, b_id)
        paste_sc(bim, bx, by0 + 20, sc=1.8)
        draw.text((bx - 12, by0 + 136), boss_names[b_id], fill=(216, 180, 254))

    ix = 700
    draw.text((ix, by0 + 24), "Drops & Projectiles", fill=(240, 246, 252))
    for i, (ik, iname, icol) in enumerate([
        ("heart", "Health Heart (+8 HP)", (248, 113, 113)),
        ("orbit", "Stage 2+ Orbit Blade", (250, 204, 21)),
        ("gem",   "Blue EXP Gem (+5 EXP)", (34, 211, 238)),
        ("bullet","Auto-Aim Bolt (<=240px)", (96, 165, 250)),
    ]):
        iy = by0 + 48 + i * 28
        paste_sc(draw_item_icon(ik), ix, iy, sc=1.6)
        draw.text((ix + 34, iy + 4), iname, fill=icol)

    out_path = os.path.join(BASE_DIR, "sprite_preview.png")
    canvas.save(out_path)
    print(f"[OK] Generated V6 complete sprite_preview.png at {out_path} ({W}x{H})")


if __name__ == "__main__":
    main()
