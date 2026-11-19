import base64
import glob
import os
import shutil
import subprocess

from PIL import Image

BASE = r"D:\vivado_pj\DRAGO_NEXUS_V2"
DOC_DIR = os.path.join(BASE, "doc")
OUT_DIR = os.path.join(DOC_DIR, "for_friend_2_progress")
DIAG_DIR = os.path.join(DOC_DIR, "diagrams")
SIM_DIR = os.path.join(BASE, "sim_work")
SCR_DIR = os.path.join(BASE, "docs", "screenshots")
EDGE_TMP = os.path.join(BASE, "vivado_tmp", "edge_prof")
EDGE_EXE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

os.makedirs(OUT_DIR, exist_ok=True)
os.makedirs(EDGE_TMP, exist_ok=True)


def convert_all_v5_ppms():
    for pat in ("rtl_v5_*.ppm", "rtl_v6_*.ppm"):
        for ppm in glob.glob(os.path.join(SIM_DIR, pat)):
            png = ppm[:-4] + ".png"
            if not os.path.exists(png) or os.path.getmtime(ppm) > os.path.getmtime(png):
                try:
                    Image.open(ppm).save(png)
                except Exception:
                    pass


CURATED_ASSETS = [
    ("01_title_2p_joy.png",        os.path.join(SIM_DIR, "rtl_v5_title_joy_2p.png"), None, "Slide 1 (หน้าปก) & Slide 4 (Joy 2P)"),
    ("02_title_1p_kb.png",         os.path.join(SIM_DIR, "rtl_v5_title_kb_1p.png"), None, "Slide 2 & Slide 4 (KB 1P Auto-Detect)"),
    ("03_guide_board_btns.png",    os.path.join(SIM_DIR, "rtl_v6_guide_p1.png"), os.path.join(SIM_DIR, "rtl_guide_p1.png"), "Slide 3 (Nexys A7 Btns + SW0/1 + SW15-11)"),
    ("04_guide_joystick.png",      os.path.join(SIM_DIR, "rtl_guide_p2.png"), None, "Slide 4 (Joystick Mapping Diagram)"),
    ("05_guide_keyboard.png",      os.path.join(SIM_DIR, "rtl_guide_p3.png"), None, "Slide 4 (Keyboard Keycaps Diagram)"),
    ("06_combat_sword_lunge.png",  os.path.join(SCR_DIR, "shot_combat_lunge.png"), None, "Slide 5 (Arena Combat + 360 Nova)"),
    ("07_sprite_preview.png",      os.path.join(BASE, "sprite_preview.png"), None, "Slide 6 (All 4 KMUTT Outfits + 6 Weapons + Boss)"),
    ("08_upgrade_cutscene.png",    os.path.join(SCR_DIR, "shot_upgrade_cutscene.png"), None, "Slide 6 (Upgrade Spotlight Cutscene)"),
    ("09_quiz_logic_gate.png",     os.path.join(SCR_DIR, "shot_coop_zoom.png"), None, "Slide 7 (Logic Gate Quiz Door)"),
    ("10_boss_ajarn_v.png",        os.path.join(SCR_DIR, "shot_boss_locked.png"), None, "Slide 7 (Boss Ajarn_V 3 Forms + Auto-Aim)"),
    ("11_diag_block.png",          os.path.join(DIAG_DIR, "diag_block.png"), None, "Slide 8 (System Hardware Block Diagram)"),
    ("12_diag_fsm.png",            os.path.join(DIAG_DIR, "diag_fsm.png"), None, "Slide 9 (Master & Room Sub-FSM Diagrams)"),
    ("13_diag_bridge.png",         os.path.join(DIAG_DIR, "diag_bridge.png"), None, "Slide 10 (5-Byte UART + PS/2 Bridge)"),
    ("14_pause_unified_guide.png", os.path.join(SIM_DIR, "rtl_v5_pause_p2_joy.png"), None, "Slide 4 (Unified Pause + [STR] RESUME)"),
    ("15_sonic_wave_2p.png",       os.path.join(SIM_DIR, "rtl_v6_sonic_2p.png"), os.path.join(SIM_DIR, "rtl_v5_sonic_2p.png"), "Slide 7 & Slide 12 (2P Cyan/Pink Sonic Ring)"),
]


def copy_assets_and_pdfs():
    copied = []
    for dst_name, src, fallback, target_slide in CURATED_ASSETS:
        chosen = src if os.path.exists(src) else fallback
        if chosen and os.path.exists(chosen):
            shutil.copy2(chosen, os.path.join(OUT_DIR, dst_name))
            copied.append((dst_name, os.path.join(OUT_DIR, dst_name), target_slide))
    for doc_pdf in ("VeePire_FSM_Specification.pdf", "VeePire_Game_Manual.pdf"):
        src_p = os.path.join(DOC_DIR, doc_pdf)
        if os.path.exists(src_p):
            shutil.copy2(src_p, os.path.join(OUT_DIR, doc_pdf))
    return copied


def b64_img(p):
    with open(p, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("ascii")


def wireframe_svg(title, blocks):
    rects = []
    for x, y, w, h, lbl, col in blocks:
        lines = lbl.split("\n")
        lh = 9.5
        sy = y + h / 2 - ((len(lines) - 1) * lh) / 2 + 2.5
        tspans = "".join(
            f'<tspan x="{x + w/2}" y="{sy + i*lh}">{ln}</tspan>'
            for i, ln in enumerate(lines)
        )
        rects.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{col}" fill-opacity="0.16" stroke="{col}" stroke-width="1.5"/>'
            f'<text text-anchor="middle" fill="#111827" font-size="6.8" font-weight="700">{tspans}</text>'
        )
    return f"""
    <svg viewBox="0 0 320 180" class="wf-svg" xmlns="http://www.w3.org/2000/svg">
      <rect x="1" y="1" width="318" height="178" rx="6" fill="#F8FAFC" stroke="#94A3B8" stroke-width="1.5"/>
      <rect x="1" y="1" width="318" height="22" rx="6" fill="#0F172A"/>
      <text x="12" y="15" fill="#38BDF8" font-size="8.5" font-weight="700">{title}</text>
      {''.join(rects)}
    </svg>"""


SLIDES = [
    ("Slide 1 — หน้าปก (Title Slide)", "0:00 – 0:20", "คนที่ 1",
     wireframe_svg("SLIDE 1: TITLE COVER", [(14,34,148,128,"ชื่อเกม + โลโก้\nPure Verilog FPGA\n+ ชื่อสมาชิก 5 คน","#0284C7"), (172,34,134,128,"01_title_2p_joy.png\nหน้าปก 2P + 6 Weapons","#DB2777")]),
     [
         "<b>รูปที่ใช้:</b> <code>01_title_2p_joy.png</code> (วางใหญ่ฝั่งขวา)",
         "<b>หัวข้อใหญ่:</b> <code>VeePire Survivors: DRAGO-NEXUS V2</code>",
         "<b>หัวข้อรอง:</b> 2D Co-op Action RPG on Digilent Nexys A7-100T FPGA (Pure Verilog • Zero CPU)",
         "<b>ด้านล่างซ้าย:</b> CPE222 Digital Logic Design | กลุ่มที่ ... | ชื่อ-รหัสสมาชิก 5 คน"
     ],
     "ชี้ให้ดูว่าหน้าจอนี้รันขึ้นจอ VGA จริงจากชิป FPGA และเลือกอาวุธ 6 แบบได้ตั้งแต่หน้าแรก"),

    ("Slide 2 — แนวคิดเกม & วัตถุประสงค์ (Objectives & Auto-Input)", "0:20 – 0:50", "คนที่ 1",
     wireframe_svg("SLIDE 2: OBJECTIVES & CONCEPT", [(14,34,142,128,"Project Objectives\nPure Verilog + VGA\n+ FSM + 46-Cycle VBlank","#0284C7"), (164,34,142,128,"Dead Cells Auto-Detect\n& 02_title_1p_kb.png","#16A34A")]),
     [
         "<b>รูปที่ใช้:</b> <code>02_title_1p_kb.png</code> (วางมุมขวาเทียบโหมด Keyboard 1P)",
         "<b>Objectives:</b> ออกแบบวงจรเกม Real-time 100% ด้วย Verilog (ไม่ใช้ CPU MicroBlaze), สร้างสัญญาณ VGA 640x480@60Hz + เสียง 3-Ch PWM, คุมระบบด้วย FSM + เซนเซอร์จริง",
         "<b>Core Concept:</b> เกมตะลุยด่านห้องสี่เหลี่ยม 6 Waves — แตะคีย์บอร์ดหรือจอยเกมเปลี่ยน UI ทันทีแบบ Dead Cells + ควิซ Logic Gate + บอส Ajarn_V 3 ร่าง"
     ],
     "เล่าให้ชัดว่านี่คือวงจรฮาร์ดแวร์ล้วนๆ อัปเดตใน 46 clock cycles ช่วง VBlank ภาพจึงไม่ขาด"),

    ("Slide 3 — ฮาร์ดแวร์และพอร์ต Nexys A7-100T (Hardware Specs & I/O)", "0:50 – 1:15", "คนที่ 1",
     wireframe_svg("SLIDE 3: HARDWARE & I/O", [(14,34,126,128,"03_guide_board_btns.png\n5 Btns + SW0/1 + SW15-11","#D97706"), (150,34,156,128,"VGA 12-bit + AUD_PWM\nSW15-11: Mute/BGM/SFX/Vol\nSW0 Fever / SW1 7-Seg C","#7C3AED")]),
     [
         "<b>รูปที่ใช้:</b> <code>03_guide_board_btns.png</code> (วางฝั่งซ้ายโชว์ปุ่มกด 5 ปุ่ม + ผังสวิตช์ V6 บนบอร์ด)",
         "<b>Board UI (5ms Debouncer):</b> <code>BTNL/BTNR</code> เลื่อนเคอร์เซอร์ P1/P2, <code>BTNC</code> เปลี่ยนหน้าตัวละคร 4 แบบ, <code>BTNU/BTND</code> เปลี่ยนอาวุธ 6 แบบ",
         "<b>Switches V6 &amp; Sensors:</b> <code>SW[15:11]</code> คุมระบบเสียง (15 Master Mute, 14 BGM, 13 SFX, 12:11 Vol), <code>SW[0]</code> Thermal Fever, <code>SW[1]</code> 7-Seg Celsius + <code>ADT7420</code> + <code>ADMP421</code>"
     ],
     "ชี้ให้ดูสวิตช์ที่จัดกลุ่มใหม่ชัดเจน: SW15-11 คุมเสียงล้วนๆ ส่วน SW0/SW1 คุมระบบอุณหภูมิและ 7-Segment"),

    ("Slide 4 — ระบบควบคุมอัตโนมัติ & Unified Pause Guide", "1:15 – 1:55", "คนที่ 2",
     wireframe_svg("SLIDE 4: DEAD CELLS & PAUSE", [(14,34,142,60,"KB Touched -> 1P Solo\nJoy Touched -> 1P / 2P","#0284C7"), (164,34,142,60,"04_guide_joystick.png +\n05_guide_keyboard.png","#16A34A"), (14,104,292,58,"Unified Pause Guide: 14_pause_unified_guide.png (START / ENT / ESC Resume)","#EA580C")]),
     [
         "<b>รูปที่ใช้:</b> <code>04_guide_joystick.png</code>, <code>05_guide_keyboard.png</code>, <code>14_pause_unified_guide.png</code> (หรือ <code>02_title_1p_kb.png</code>)",
         "<b>Dead Cells Auto-Detect:</b> แตะคีย์บอร์ดที่หน้า Title -> ซ่อนแถบ 1P/2P บังคับเล่นเดี่ยวทันที! แตะจอย -> เปิดเลือก <code>&lt; 1 PLAYER &gt; / &lt; 2 PLAYERS &gt;</code>",
         "<b>In-Game Hybrid + Unified Pause:</b> ในเกม Joy 1 + KB บังคับ P1 ได้พร้อมกัน! กด <code>START/ENTER/ESC</code> เปิดหน้าคู่มือเดียวกับ Title พร้อมปุ่ม <code>[STR]/[ENT] RESUME</code>"
     ],
     "เปรียบเทียบภาพ 01_title_2p_joy กับ 02_title_1p_kb และภาพ Pause ให้เห็นว่า UI เปลี่ยนปุ่มให้อัตโนมัติ"),

    ("Slide 5 — การต่อสู้ 6 อาวุธ, Auto-Aim & Dynamic Zoom", "1:55 – 2:35", "คนที่ 2",
     wireframe_svg("SLIDE 5: COMBAT & 6 WEAPONS", [(14,34,148,128,"6 Weapons (SWORD..SCYTH)\n3-Hit Combo + 360 Nova\nAuto-Aim <= 240 px\nOut-of-Combat Regen","#0284C7"), (170,34,136,128,"06_combat_sword_lunge.png\nฉากต่อสู้จริง","#DB2777")]),
     [
         "<b>รูปที่ใช้:</b> <code>06_combat_sword_lunge.png</code> (วางใหญ่ฝั่งขวา)",
         "<b>6 Melee Weapons:</b> <code>SWORD, SABER, FISTS, B-AXE, SPEAR, SCYTH</code> + คอมโบ 3 จังหวะปล่อย <code>360° Nova</code> + <code>Shadow Dash</code>",
         "<b>Auto-Aim & Dynamic Zoom:</b> ปืน Plasma ล็อคเป้าศัตรูในระยะ <code>240 px</code> อัตโนมัติ, กล้องซูมลื่น <code>320..520 px</code>, พักรบ <code>6 วิ</code> (360f) ฟื้นเลือดอัตโนมัติ"
     ],
     "ชี้วงคลื่นฟัน 360° และการล็อคเป้าศัตรูในกรอบห้องสี่เหลี่ยมเดี่ยว"),

    ("Slide 6 — วิวัฒนาการชุด มจธ. 4 ขั้น & กราฟิก BRAM", "2:35 – 3:15", "คนที่ 3",
     wireframe_svg("SLIDE 6: KMUTT EVOLUTION", [(14,34,160,128,"07_sprite_preview.png\nนักศึกษา->ช็อป->ครุย->เกราะทอง","#7C3AED"), (182,34,124,128,"08_upgrade_cutscene.png\nSpotlight Morph (Stage<3)","#D97706")]),
     [
         "<b>รูปที่ใช้:</b> <code>07_sprite_preview.png</code> (ซ้าย) คู่กับ <code>08_upgrade_cutscene.png</code> (ขวา)",
         "<b>KMUTT 4-Stage Evolution:</b> <code>Stage 0</code> นักศึกษา (30px/2dmg) &rarr; <code>Stage 1</code> เสื้อช็อป CPE (+Speed &amp; Pet) &rarr; <code>Stage 2</code> ชุดครุยแดง (+Orbit Blades) &rarr; <code>Stage 3</code> <b>เกราะทองขั้นสุดท้าย</b> (50px/4dmg, หยุดเล่นคัตซีนซ้ำอัตโนมัติ!)",
         "<b>Custom BRAM Assets:</b> ใบหน้าเพื่อน 4 แบบ + อนิเมชันเดิน 16 เฟรม + ศัตรูสูทดำ + บอส Ajarn_V 3 ร่าง"
     ],
     "ชี้รูป sprite_preview กับคัตซีนสปอตไลท์ และย้ำว่าเมื่อได้เกราะทอง Stage 3 แล้วเกมจะไม่ฉายซ้ำให้เสียเวลา"),

    ("Slide 7 — Creative Features: ควิซ, เซนเซอร์ 2P & บอส 3 ร่าง", "3:15 – 4:00", "คนที่ 3",
     wireframe_svg("SLIDE 7: CREATIVE FEATURES", [(14,34,92,128,"09_quiz_logic_gate\nAND..XOR Quiz\n+ GO RETAKE !!","#9333EA"), (114,34,94,128,"15_sonic_wave_2p\n2P Cyan/Pink Ring\n+ ADT7420 Fever","#0891B2"), (216,34,90,128,"10_boss_ajarn_v\nAjarn_V 3 Forms\n+ 220px Knockback","#DC2626")]),
     [
         "<b>รูปที่ใช้:</b> <code>09_quiz_logic_gate.png</code>, <code>15_sonic_wave_2p.png</code>, <code>10_boss_ajarn_v.png</code>",
         "<b>Logic Gate Quiz:</b> ตอบผิดขึ้น <code>\"F\" + CAUTION: GO RETAKE !!</code> เล่น Wave เดิมซ้ำ!",
         "<b>Sensors &amp; Boss:</b> ไมค์ <code>ADMP421</code> ปล่อยคลื่นกระแทก <b>ทั้ง P1 (Cyan) และ P2 (Pink)</b>, เซนเซอร์ความร้อน <code>ADT7420</code> ให้ <code>+2 DMG</code>, บอส Ajarn_V 3 ร่าง (<code>105&rarr;145&rarr;190 HP</code>) ผลัก <code>220 px</code> กันสแปมดาบ"
     ],
     "โชว์จุดขาย Creative ของกลุ่ม: วิชา Logic -> เกม, ฮาร์ดแวร์เซนเซอร์ 2 คนจริง, บอสมี anti-spam"),

    ("Slide 8 — สถาปัตยกรรมระบบ & ไปป์ไลน์ 46 รอบ (Block Diagram)", "4:00 – 4:35", "คนที่ 4",
     wireframe_svg("SLIDE 8: BLOCK DIAGRAM", [(14,34,292,128,"ใส่ภาพใหญ่ 11_diag_block.png กลางสไลด์\nInputs -> game_engine_v2 (46 clks/frame) -> VGA 4-Stage + Audio + LEDs","#7C3AED")]),
     [
         "<b>รูปที่ใช้:</b> <code>11_diag_block.png</code> (วางใหญ่เต็มกลางสไลด์)",
         "<b>46-Cycle Engine TDM:</b> ประมวลผลชนกำแพง, AI ศัตรู 16 ตัว (1 ตัว/clk), Lock-on และ Boss จบใน 46 clocks (<code>&lt;0.015%</code> ของเวลาเฟรม 60 Hz)",
         "<b>VGA 4-Stage Pipeline:</b> ตัดคอขวด Critical Path ที่ <code>25 MHz</code> ภาพคมชัดไม่กระตุก"
     ],
     "ชี้ไล่จากซ้าย (UART/PS2/Sensors) -> กลาง (46-Cycle Engine) -> ขวา (VGA/Audio/7-Seg)"),

    ("Slide 9 — ผังสถานะเกมและด่าน (Master & Room Sub-FSM)", "4:35 – 5:10", "คนที่ 4",
     wireframe_svg("SLIDE 9: FSM DIAGRAMS", [(14,34,292,128,"ใส่ภาพใหญ่ 12_diag_fsm.png กลางสไลด์\nDiagram 1.1: Master FSM  |  Diagram 2.1: Room & Quiz Sub-FSM","#2563EB")]),
     [
         "<b>รูปที่ใช้:</b> <code>12_diag_fsm.png</code> (วางใหญ่เต็มสไลด์)",
         "<b>Master FSM:</b> <code>ST_TITLE &rarr; ST_PLAY (&harr; PAUSED 3-Page Guide) &rarr; ST_WIN / ST_LOSE</code>",
         "<b>Room Sub-FSM:</b> <code>RP_BANNER &rarr; RP_FIGHT &rarr; RP_CLEAR &rarr; RP_QUIZ &rarr; RP_DOOR</code> (ผิดวนกลับ Banner) + <code>RP_BOSS</code> + 2P Partner Revive <code>12 HP</code>"
     ],
     "ใช้ภาพ 12_diag_fsm.png ไล่ชี้ตามลูกศรทีละสถานะได้เลย"),

    ("Slide 10 — สะพานเชื่อม 5 ไบต์ (PC-to-FPGA UART + PS/2 Bridge)", "5:10 – 5:40", "คนที่ 4",
     wireframe_svg("SLIDE 10: UART + PS/2 BRIDGE", [(14,34,292,128,"ใส่ภาพใหญ่ 13_diag_bridge.png กลางสไลด์\nWinMM Joy1/2 + KB -> 5-Byte Serial @ 115,200 bps -> FPGA OR PS/2 (F4/B2)","#0D9488")]),
     [
         "<b>รูปที่ใช้:</b> <code>13_diag_bridge.png</code> (วางใหญ่เต็มสไลด์)",
         "<b>5-Byte Protocol @ 115,200 bps:</b> ส่ง Joy 1, Joy 2 และ PC Keyboard พร้อมบิต Sync <code>B0[7]=1</code>, Watchdog <code>1 วิ</code> และ <code>b4[6]</code> Quiz/Esc/Enter Mux",
         "<b>Dual Path:</b> ใช้คู่กับคีย์บอร์ด USB-HID/PS2 ที่เสียบตรงเข้าพอร์ต <code>F4/B2</code> บนบอร์ดได้ทันที"
     ],
     "โชว์การแก้ปัญหาฮาร์ดแวร์ด้วยโปรโตคอล 5 ไบต์ไร้ดีเลย์ พร้อม Watchdog กันสัญญาณค้าง"),

    ("Slide 11 — สรุปความครบครันเพื่อเกณฑ์ Ranking: 8 Inputs & Feature 1, 2, 3.1–3.16 FSMs", "5:40 – 6:20", "คนที่ 5",
     wireframe_svg("SLIDE 11: RANKING INVENTORY", [(14,34,136,128,"8 Input Channels\nDual Joy, UART/PS2 KB\n5 Btns, SW15-11 & SW0-1\nTemp / Mic / ACL / Reset","#0284C7"), (158,34,148,128,"18 Features (18 FSMs!)\nFeat 1: Player & Combat\nFeat 2: Evolutions & Skins\nFeat 3.1 .. 3.16 Ranked","#16A34A")]),
     [
         "<b>รูปที่ใช้:</b> <code>07_sprite_preview.png</code> คู่กับตัวเลขใหญ่ <b>8 Inputs</b> | <b>Feature 1, 2 + 3.1..3.16 (18 Sub-FSMs)</b> (ดูตาราง Section 4 ด้านล่างก๊อปใส่สไลด์ได้เลย!)",
         "<b>Mandatory Features 1–2:</b> <code>Feat 1</code> Movable Player &amp; Arena Combat FSM (3-Hit Combo+Nova, Shadow Dash, 6 Weapons, Auto-Aim 240px) &amp; <code>Feat 2</code> Sprite Evolutions &amp; Skins FSM (Stage 0–3 Gold Cap + 4 Heads + 16f Walk BRAM)",
         "<b>Expansion Ranking Features 3.1–3.16:</b> <code>3.1</code> Auto-Detect Input &bull; <code>3.2</code> Unified 3-Pg Pause &bull; <code>3.3</code> Room Wave &bull; <code>3.4</code> Logic Quiz &bull; <code>3.5</code> 3-Form Boss &bull; <code>3.6</code> Zoom+2P Revive &bull; <code>3.7</code> PDM 2P Sonic &bull; <code>3.8</code> ADT7420 Fever &bull; <code>3.9</code> 5B UART &bull; <code>3.10</code> PS/2 KB &bull; <code>3.11</code> ADXL362 SPI &bull; <code>3.12</code> OOC Regen+Gems &bull; <code>3.13</code> Pet+Orbit &bull; <code>3.14</code> SW15-11 Audio &bull; <code>3.15</code> 46-Clk TDM+VGA &bull; <code>3.16</code> LED/7-Seg"
     ],
     "ย้ำเลข 8 Inputs + ฟีเจอร์บังคับ 1–2 และฟีเจอร์เสริม 3.1–3.16 รวม 18 FSMs จาก Section 4 เพื่อคะแนน Ranking สูงสุด!"),

    ("Slide 12 — ผลการทดสอบ, แบ่งงาน 5 คน & แผน Demo สด", "6:20 – 7:00", "คนที่ 5",
     wireframe_svg("SLIDE 12: RESULTS & DEMO", [(14,34,158,128,"RTL Sim V6 PASS\nVivado Bitstream + Flash OK\nตารางหน้าที่สมาชิก 5 คน","#16A34A"), (180,34,126,128,"15_sonic_wave_2p.png\nหรือ 01_title_2p_joy.png","#0284C7")]),
     [
         "<b>รูปที่ใช้:</b> <code>15_sonic_wave_2p.png</code> (หรือ <code>01_title_2p_joy.png</code>) คู่กับ Checklist สีเขียว + ตารางงาน 5 คน",
         "<b>การแบ่งงาน 5 คน:</b> 1) VGA/Debounce/7-Seg | 2) Game Engine/Quiz/Zoom | 3) Renderer/Sprites/UI Guide | 4) Bridge/Audio/Sensors | 5) Testbench/Vivado/Slide &amp; Report",
         "<b>สถานะพร้อม Demo:</b> เอกสาร V6 ครบ (FSM Spec, Game Manual, Slide Plan) + ทดสอบบอร์ดจริง <code>xc7a100t</code> พร้อมแฟลชสาธิตสดครับ"
     ],
     "สรุปผลทดสอบจริงทั้งหมดอย่างมั่นใจและเชิญอาจารย์ชมการ Demo ครับ")
]


def build_pdf(copied_assets):
    html_path = os.path.join(DOC_DIR, "for_friend_2_progress", "VeePire_Slide_Plan_For_Friend.html")
    pdf_path = os.path.join(OUT_DIR, "VeePire_Slide_Plan_For_Friend.pdf")

    asset_rows = []
    for dst_name, full_p, target_slide in copied_assets:
        asset_rows.append(
            f'<div class="asset-box"><img src="{b64_img(full_p)}"/><div class="asset-cap"><code>{dst_name}</code><br/><span>{target_slide}</span></div></div>'
        )

    cards = []
    for stitle, stime, speaker, wf, bullets, tip in SLIDES:
        blist = "".join(f"<li>{b}</li>" for b in bullets)
        cards.append(f"""
        <div class="slide-card">
          <div class="slide-hdr">
            <span class="slide-title">{stitle}</span>
            <span class="badge">{speaker} · {stime}</span>
          </div>
          <div class="slide-grid">
            <div class="wf-col">{wf}</div>
            <div class="txt-col">
              <ul>{blist}</ul>
              <div class="tip"><b>ทริคตอนพูด:</b> {tip}</div>
            </div>
          </div>
        </div>""")

    html = f"""<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8"/>
<title>VeePire Survivors V5 - Slide Plan For Friends</title>
<style>
  @page {{ size: A4; margin: 13mm 14mm 14mm 14mm; }}
  * {{ box-sizing: border-box; }}
  body {{ font-family: "Leelawadee UI", "Segoe UI", "Noto Sans Thai", sans-serif; color: #0F172A; margin: 0; line-height: 1.48; font-size: 10.5pt; }}
  .hero {{ background: linear-gradient(135deg, #0D1117 0%, #1E293B 60%, #0369A1 100%); color: #F8FAFC; padding: 18px 22px; border-radius: 12px; margin-bottom: 12px; }}
  .hero h1 {{ margin: 0 0 4px 0; font-size: 19pt; color: #38BDF8; font-weight: 900; }}
  .hero p {{ margin: 2px 0; font-size: 10pt; color: #CBD5E1; }}
  h2 {{ font-size: 13pt; color: #0369A1; border-left: 5px solid #0284C7; padding-left: 10px; margin: 14px 0 8px 0; }}
  table {{ width: 100%; border-collapse: collapse; margin-bottom: 12px; font-size: 9.5pt; }}
  th, td {{ border: 1px solid #CBD5E1; padding: 6px 8px; text-align: left; vertical-align: top; }}
  th {{ background: #E0F2FE; color: #0C4A6E; font-weight: 800; }}
  code {{ background: #F1F5F9; padding: 1px 4px; border-radius: 4px; font-family: Consolas, monospace; font-size: 9pt; color: #BE185D; font-weight: 700; }}
  .asset-grid {{ display: grid; grid-template-columns: repeat(3, 1fr); gap: 7px; margin-bottom: 10px; }}
  .asset-box {{ border: 1px solid #CBD5E1; border-radius: 7px; padding: 5px; background: #0D1117; text-align: center; page-break-inside: avoid; }}
  .asset-box img {{ width: 100%; height: 92px; object-fit: contain; border-radius: 4px; background: #0D1117; display: block; }}
  .asset-cap {{ font-size: 7.8pt; font-weight: 700; color: #E2E8F0; margin-top: 3px; line-height: 1.25; }}
  .asset-cap code {{ background: #1E293B; color: #38BDF8; font-size: 7.8pt; }}
  .slide-card {{ border: 1.5px solid #CBD5E1; border-radius: 10px; padding: 10px 12px; margin-bottom: 10px; page-break-inside: avoid; background: #FFFFFF; }}
  .slide-hdr {{ display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E2E8F0; padding-bottom: 5px; margin-bottom: 7px; }}
  .slide-title {{ font-size: 11.5pt; font-weight: 800; color: #0F172A; }}
  .badge {{ background: #0284C7; color: #FFFFFF; padding: 2px 9px; border-radius: 12px; font-size: 8.8pt; font-weight: 700; }}
  .slide-grid {{ display: grid; grid-template-columns: 215px 1fr; gap: 11px; align-items: start; }}
  .wf-svg {{ width: 100%; height: auto; display: block; }}
  .txt-col ul {{ margin: 0 0 6px 0; padding-left: 16px; font-size: 9.3pt; }}
  .txt-col li {{ margin-bottom: 3px; }}
  .tip {{ background: #FEF9C3; border-left: 4px solid #EAB308; padding: 4px 8px; font-size: 8.8pt; border-radius: 4px; color: #713F12; }}
  .page-break {{ page-break-before: always; }}
</style>
</head>
<body>
  <div class="hero">
    <h1>Slide Plan ฉบับเพื่อน (V6 Final — Ranking Edition) — VeePire Survivors</h1>
    <p>คู่มือจัดทำสไลด์ 12 หน้าพร้อมภาพประกอบและบทพูด 5 คน / 7 นาที | ไฟล์ทั้งหมดอยู่ใน <code>doc/for_friend_2_progress/</code></p>
  </div>

  <h2>1. คู่มือจับคู่รูปภาพ (ลากไฟล์ PNG จากโฟลเดอร์นี้ใส่สไลด์ตามตารางได้เลย)</h2>
  <div class="asset-grid">{''.join(asset_rows)}</div>

  <h2>2. พจนานุกรมศัพท์เทคนิค 1 นาที &amp; ตารางแบ่งเวลาพูด 7 นาที (5 คน)</h2>
  <table>
    <tr><th style="width:27%">คำศัพท์ในสไลด์</th><th>คำอธิบายภาษาคนทั่วไป (สำหรับพูดตอบคำถาม)</th></tr>
    <tr><td><b>Pure Verilog FPGA</b></td><td>วงจรดิจิทัลบนชิป Nexys A7-100T ทั้งหมด 100% ไม่ได้แอบใช้ CPU สำเร็จรูป (MicroBlaze)</td></tr>
    <tr><td><b>46-Cycle VBlank TDM</b></td><td>คำนวณฟิสิกส์/AI ทั้งด่านเสร็จใน 46 รอบนาฬิกา (&lt;0.015% ของเวลาเฟรม 60Hz) ช่วงพักวาดจอ ภาพจึงไม่ฉีก</td></tr>
    <tr><td><b>Dead Cells Auto-Detect</b></td><td>แตะคีย์บอร์ด -> ซ่อนโหมด 2P บังคับเล่นเดี่ยวพร้อมไอคอนขาว / แตะจอย -> เปิดเลือก 1P/2P Co-op อัตโนมัติ</td></tr>
    <tr><td><b>PDM Mic &amp; I2C Temp</b></td><td>ไมค์ ADMP421 ปล่อยคลื่นกระแทก 2P (ฟ้า+ชมพู) | ชิปอุณหภูมิ ADT7420 เพิ่ม +2 Melee DMG</td></tr>
    <tr><td><b>5-Byte UART + PS/2 Bridge</b></td><td>โปรโตคอลส่งสัญญาณจากจอยคู่+KB ผ่าน USB @ 115,200 bps พร้อมพอร์ต PS/2 (F4/B2) บนบอร์ดโดยตรง</td></tr>
  </table>
  <table>
    <tr><th>สมาชิก</th><th>สไลด์</th><th>เวลาพูด</th><th>หัวข้อที่รับผิดชอบ</th></tr>
    <tr><td><b>คนที่ 1</b></td><td>Slide 1–3</td><td>1:15 (0:00–1:15)</td><td>หน้าปก, Objectives/Auto-Input, Hardware Specs &amp; Board Pushbuttons</td></tr>
    <tr><td><b>คนที่ 2</b></td><td>Slide 4–5</td><td>1:20 (1:15–2:35)</td><td>Dead Cells Mode + Unified Pause Guide, Combat 6 อาวุธ &amp; Dynamic Zoom</td></tr>
    <tr><td><b>คนที่ 3</b></td><td>Slide 6–7</td><td>1:25 (2:35–4:00)</td><td>วิวัฒนาการชุด มจธ. 4 ขั้น, ควิซ Logic Gate, เซนเซอร์ 2P &amp; บอส 3 ร่าง</td></tr>
    <tr><td><b>คนที่ 4</b></td><td>Slide 8–10</td><td>1:40 (4:00–5:40)</td><td>Block Diagram, Master/Room FSM Diagrams, 5-Byte UART + PS/2 Bridge</td></tr>
    <tr><td><b>คนที่ 5</b></td><td>Slide 11–12</td><td>1:20 (5:40–7:00)</td><td>Ranking Inventory (8 Inputs / 18 Sub-Features), ผลทดสอบ &amp; แผน Demo</td></tr>
  </table>

  <div class="page-break"></div>
  <h2>3. โครงสร้างหน้าสไลด์ทั้ง 12 หน้า (ข้อความ + ภาพประกอบ + ทริคตอนพูด)</h2>
  {''.join(cards)}

  <div class="page-break"></div>
  <h2>4. ตาราง Feature-by-Feature FSM (สำหรับ Ranking: Feature 1, Feature 2 &amp; Feature 3.1–3.16)</h2>
  <p style="font-size:9pt; margin:0 0 6px;">เพื่อนสามารถนำผังชื่อ Feature และสถานะ FSM ด้านล่างไปใส่ใน <b>Slide 9 / Slide 11</b> เพื่อโชว์ความละเอียดของ Pure Verilog RTL ทั้ง <b>18 Sub-FSMs</b> (อ้างอิงรายละเอียดเต็มจาก <code>VeePire_FSM_Specification.pdf</code> Section 8):</p>
  <table style="font-size:8.4pt;">
    <tr><th style="width:12%">Feature #</th><th style="width:27%">ชื่อฟีเจอร์ &amp; รีจิสเตอร์หลัก</th><th style="width:25%">State Flow (FSM)</th><th style="width:36%">เงื่อนไขการเปลี่ยนสถานะ (RTL Transitions)</th></tr>
    <tr><td><b>Feature 1</b><br><i>(บังคับ)</i></td><td><b>Movable Player &amp; Arena Combat</b><br><code>p1_combo_step, dash_timer, pb</code></td><td><code>COMBO 0&rarr;1&rarr;2(Nova)</code><br><code>DASH IDLE&rarr;ACTIVE&rarr;CD</code></td><td>6 อาวุธ (<code>BTNU/D</code>); ฟัน 3 จังหวะปล่อย 360&deg; Nova; Dash อมตะ <code>36f</code>; ปืน Auto-Aim สแกนเป้า <code>&le;240 px</code> (<code>step 42..44</code>)</td></tr>
    <tr><td><b>Feature 2</b><br><i>(บังคับ)</i></td><td><b>Sprite Evolutions &amp; Skins</b><br><code>stage[1:0], outfit_cut_t, hero_sel</code></td><td><code>0:Student&rarr;1:Shop&rarr;2:Gown&rarr;3:Gold</code><br>+ <code>4 Peers &amp; 16f Walk BRAM</code></td><td>Quiz Pass เลื่อน <code>stage+1</code> + <code>outfit_cut_t=120f</code> (เมื่อถึง <code>stage==3</code> Gold หยุดฉายซ้ำ!); หน้าแรกสลับ 4 หน้าฮีโร่ด้วย <code>BTNC</code></td></tr>
    <tr><td><b>Feat 3.1</b></td><td><b>Dead Cells Auto-Input Detect</b><br><code>control_mode[1:0]</code></td><td><code>00:Idle | 01:KB 1P | 10:Joy 1P/2P</code></td><td>แตะ KB บน Title ซ่อน 2P บังคับเล่นเดี่ยว; แตะ Joy เปิด 1P/2P; ในเกม <code>KB | J1</code> บังคับ P1 พร้อมกัน</td></tr>
    <tr><td><b>Feat 3.2</b></td><td><b>Unified 3-Pg Pause &amp; Guide</b><br><code>help_page[1:0], paused</code></td><td><code>0:Off &harr; 1:Board &harr; 2:Joy &harr; 3:KB</code></td><td>ใช้หน้าคู่มือ 3 หน้าเดียวกับ Title เปิดได้ระหว่างเกม + ปุ่มกลาง <code>[STR]/[ENT] RESUME</code> เปลี่ยนตามอุปกรณ์</td></tr>
    <tr><td><b>Feat 3.3</b></td><td><b>Room Wave Spawner</b><br><code>room_phase[2:0], wave_sub</code></td><td><code>BANNER(0)&rarr;FIGHT(1)&rarr;CLEAR(2)</code></td><td><code>90f</code> แบนเนอร์ + <code>45f</code> Door Slam; สปอว์น Sub-waves (30..80 ตัว); หมดห้องเปิดลูกศรประตูขวา</td></tr>
    <tr><td><b>Feat 3.4</b></td><td><b>Logic Gate Quiz Door</b><br><code>RP_QUIZ(3)&rarr;RP_DOOR(4)</code></td><td><code>Gates 0..5 (AND..XOR)</code></td><td>30f anti-mash; ตอบถูกสไลด์ประตู <code>0..31</code>; ตอบผิดขึ้น <code>"F: GO RETAKE !!" (105f)</code> รีเซ็ตด่านเดิม</td></tr>
    <tr><td><b>Feat 3.5</b></td><td><b>3-Form Boss Ajarn_V</b><br><code>RP_BOSS(5), boss_kind[1:0]</code></td><td><code>F0(105)&rarr;Portal(160f)&rarr;F1(145)&rarr;F2(190)</code></td><td>Wave 6: ร่างสุดท้าย <code>HP&le;95</code> เข้า Enraged; ฟันรัว 3 ครั้งปล่อย Barrier ผลัก <code>220 px</code> + สตั๊น <code>60f</code></td></tr>
    <tr><td><b>Feat 3.6</b></td><td><b>Brawlhalla Zoom &amp; 2P Revive</b><br><code>zoom_lvl[6:0], p2_active</code></td><td><code>view_w 320..520</code> + <code>Revive 12HP</code></td><td>วัดระยะ <code>dx_sep/dy_sep</code> ซูมลื่น; เข้า <code>RP_BANNER</code> ชุบเพื่อนที่ล้มอัตโนมัติ (<code>12 HP</code>)</td></tr>
    <tr><td><b>Feat 3.7</b></td><td><b>PDM Mic 2P Sonic Wave</b><br><code>mic_roar, sonic_wave_t</code></td><td><code>LISTEN&rarr;ROAR(320ms)&rarr;EXPAND</code></td><td><code>2.5 MHz</code> 128-sample PDM (<code>raw_dev&ge;28</code>) ปล่อยวง P1 Cyan + P2 Pink (<code>100/140/180 px</code>)</td></tr>
    <tr><td><b>Feat 3.8</b></td><td><b>ADT7420 I2C Thermal Fever</b><br><code>i2c state[4:0] (0..9)</code></td><td><code>S_IDLE..WR_ADDR..RD..UPDATE</code></td><td>อ่าน <code>0x4B</code> ทุก <code>100ms</code>; <code>(temp&ge;base+1C)||(temp&ge;35C)||SW[0]</code> บวก <code>+2 DMG</code>; <code>SW[1]</code> โชว์บน 7-Seg</td></tr>
    <tr><td><b>Feat 3.9</b></td><td><b>5-Byte UART + Quiz Mux</b><br><code>u_state[1:0], pkt_state[2:0]</code></td><td><code>U_IDLE..STOP</code> + <code>B0..B4</code></td><td><code>115,200 bps</code> ซิงค์ <code>B0[7]=1</code>, ส่ง J1/J2/KB + <code>b4[6]</code> Quiz/Esc/Ent Mux + Watchdog <code>1 วิ</code></td></tr>
    <tr><td><b>Feat 3.10</b></td><td><b>Direct PS/2 KB Decoder</b><br><code>ps2_keyboard.v</code> Frame</td><td><code>11-bit RX</code> + <code>F0 Break / E0 Ext</code></td><td>ต่อคีย์บอร์ดตรงเข้าบอร์ด (<code>F4/B2</code>) กรอง 8-sample &amp; OR รวมกับ UART KB</td></tr>
    <tr><td><b>Feat 3.11</b></td><td><b>ADXL362 SPI Accelerometer</b><br><code>acl_tilt.v state[3:0]</code></td><td><code>S_PWRUP(0)..S_RD(7)..WAIT10(8)</code></td><td><code>1.04 MHz SPI</code> ตั้งค่า Measurement mode และอ่านแกน <code>XL/XH/YL/YH</code> ทุก <code>10 ms</code></td></tr>
    <tr><td><b>Feat 3.12</b></td><td><b>OOC Regen, Gems &amp; Sky Drop</b><br><code>regen_wait, col_alive, drop_z</code></td><td><code>COMBAT&rarr;WAIT(360f)&rarr;REGEN</code></td><td>พักรบ <code>6 วิ</code> ฟื้นเลือด <code>+1/90f</code>; Gem ดูด <code>76 px</code> (เต็ม 60 รีฟูล); กล่องเสบียงตกตามแรงโน้มถ่วง <code>drop_z</code></td></tr>
    <tr><td><b>Feat 3.13</b></td><td><b>Pet Auto-Bolt &amp; Orbit Blades</b><br><code>pet_active, blade_ang[3:0]</code></td><td><code>Stage&ge;1 Pet</code> | <code>Stage&ge;2 Blades</code></td><td>สัตว์เลี้ยงยิงนำวิถีอัตโนมัติ (<code>Stage&ge;1</code>); ดาบหมุนคู่หมุนรอบตัวด้วย LUT Cos/Sin 16 ขั้น (<code>Stage&ge;2</code>)</td></tr>
    <tr><td><b>Feat 3.14</b></td><td><b>SW[15:11] Audio Mixer FSM</b><br><code>audio_synth_v2.v</code></td><td><code>4 Songs</code> + <code>SFX</code> + <code>SW[15:11]</code></td><td><code>SW15</code> Mute ทั้งระบบ, <code>SW14</code> ปิด BGM, <code>SW13</code> ปิด SFX, <code>SW[12:11]</code> ลดเสียง <code>100/50/25/12.5%</code></td></tr>
    <tr><td><b>Feat 3.15</b></td><td><b>46-Cycle VBlank TDM &amp; VGA</b><br><code>step_state[5:0] (0..44)</code></td><td><code>VBlank&rarr;P1&rarr;P2&rarr;Cam&rarr;En[0..15]</code></td><td>ประมวลผล AI ทั้งหมดใน 46 clks ส่งต่อ <code>vga_renderer_v2</code> (4-Stage Pipeline) ภาพลื่น 60Hz</td></tr>
    <tr><td><b>Feat 3.16</b></td><td><b>Board LED / RGB / 7-Seg Mux</b><br><code>board_io_v2.v</code></td><td><code>LED Mode (EXP/Fever/Mic)</code> + <code>AN[7:0]</code></td><td>Debounce 5ms; ขับ 16 LEDs, Dual RGB (<code>LED16</code> Temp / <code>LED17</code> Mic/Audio), 7-Seg Score หรือ <code>SW[1]</code> Celsius</td></tr>
  </table>
</body>
</html>"""
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)

    url = "file:///" + html_path.replace("\\", "/")
    env = os.environ.copy()
    tmp_d = os.path.join(BASE, "vivado_tmp")
    os.makedirs(tmp_d, exist_ok=True)
    env["TEMP"] = tmp_d
    env["TMP"] = tmp_d
    subprocess.run([
        EDGE_EXE, "--headless", "--disable-gpu", f"--user-data-dir={EDGE_TMP}",
        "--no-pdf-header-footer", "--run-all-compositor-stages-before-draw",
        f"--print-to-pdf={pdf_path}", url
    ], env=env, check=True)
    # Remove intermediate HTML from for_friend_2_progress so folder contains clean deliverables + PNGs
    if os.path.exists(html_path):
        os.remove(html_path)
    print(f"[OK] Built Slide Plan PDF: {pdf_path} ({os.path.getsize(pdf_path)} bytes)")


if __name__ == "__main__":
    convert_all_v5_ppms()
    copied = copy_assets_and_pdfs()
    print(f"[OK] Copied {len(copied)} images + FSM/Manual PDFs to {OUT_DIR}")
    build_pdf(copied)
