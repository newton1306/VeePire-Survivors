import base64
import os
import subprocess

BASE = r"D:\vivado_pj\DRAGO_NEXUS_V2"
DOC_DIR = os.path.join(BASE, "doc")
os.makedirs(DOC_DIR, exist_ok=True)

def img_b64(rel_path):
    p = os.path.join(BASE, rel_path)
    with open(p, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("ascii")

IMG_SPRITES = img_b64("sprite_preview.png")
IMG_TITLE   = img_b64(r"docs\screenshots\shot_title.png")
IMG_COMBAT  = img_b64(r"docs\screenshots\shot_combat_lunge.png")
IMG_QUIZ    = img_b64(r"docs\screenshots\shot_coop_zoom.png")
IMG_BOSS    = img_b64(r"docs\screenshots\shot_boss_locked.png")

def wireframe_svg(title, blocks):
    # blocks: list of (x, y, w, h, label, color) in 320x180 16:9 canvas
    rects = []
    for x, y, w, h, lbl, col in blocks:
        lines = lbl.split("\n")
        line_h = 9.5
        start_y = y + h / 2 - ((len(lines) - 1) * line_h) / 2 + 2.5
        tspans = "".join(
            f'<tspan x="{x + w/2}" y="{start_y + i*line_h}">{ln}</tspan>'
            for i, ln in enumerate(lines)
        )
        rects.append(
            f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="4" fill="{col}" fill-opacity="0.16" stroke="{col}" stroke-width="1.5"/>'
            f'<text text-anchor="middle" fill="#111827" font-size="6.8" font-weight="700">{tspans}</text>'
        )
    return f'''
    <svg viewBox="0 0 320 180" class="wf-svg" xmlns="http://www.w3.org/2000/svg">
      <rect x="1" y="1" width="318" height="178" rx="6" fill="#F8FAFC" stroke="#94A3B8" stroke-width="1.5"/>
      <rect x="1" y="1" width="318" height="22" rx="6" fill="#0F172A"/>
      <text x="12" y="15" fill="#38BDF8" font-size="8.5" font-weight="700">{title}</text>
      {''.join(rects)}
    </svg>'''

BLOCK_DIAGRAM_SVG = '''
<svg viewBox="0 0 760 270" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arr" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#0284C7"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="756" height="266" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <!-- Left: Inputs -->
  <rect x="18" y="24" width="165" height="58" rx="7" fill="#E0F2FE" stroke="#0284C7" stroke-width="1.8"/>
  <text x="100" y="47" text-anchor="middle" font-size="12" font-weight="700" fill="#0369A1">Twin USB Joysticks</text>
  <text x="100" y="65" text-anchor="middle" font-size="10" fill="#334155">PC Bridge (joy_bridge.py)</text>

  <rect x="18" y="102" width="165" height="58" rx="7" fill="#FEF3C7" stroke="#D97706" stroke-width="1.8"/>
  <text x="100" y="125" text-anchor="middle" font-size="12" font-weight="700" fill="#92400E">uart_joy_rx.v</text>
  <text x="100" y="143" text-anchor="middle" font-size="10" fill="#334155">115200 baud + Pause Bit</text>

  <rect x="18" y="180" width="165" height="62" rx="7" fill="#DCFCE7" stroke="#16A34A" stroke-width="1.8"/>
  <text x="100" y="203" text-anchor="middle" font-size="12" font-weight="700" fill="#166534">board_io_v2.v</text>
  <text x="100" y="220" text-anchor="middle" font-size="10" fill="#334155">SW[3:0] Skins + 5ms Debounce</text>

  <!-- Center: Game Engine -->
  <rect x="245" y="45" width="215" height="175" rx="10" fill="#EDE9FE" stroke="#7C3AED" stroke-width="2.2"/>
  <text x="352" y="75" text-anchor="middle" font-size="14" font-weight="800" fill="#5B21B6">game_engine_v2.v</text>
  <text x="352" y="96" text-anchor="middle" font-size="11" fill="#334155">Main FSM &amp; Room Sub-FSM</text>
  <text x="352" y="116" text-anchor="middle" font-size="10" fill="#475569">• 60 Hz VBlank Tick Update</text>
  <text x="352" y="134" text-anchor="middle" font-size="10" fill="#475569">• 16-Enemy Time-Multiplex</text>
  <text x="352" y="152" text-anchor="middle" font-size="10" fill="#475569">• Lunge + 360° Nova + Zoom</text>
  <text x="352" y="170" text-anchor="middle" font-size="10" fill="#475569">• Logic Gate Quiz &amp; Door</text>
  <text x="352" y="188" text-anchor="middle" font-size="10" fill="#475569">• 3-Form Boss Portal AI</text>
  <text x="352" y="206" text-anchor="middle" font-size="10" fill="#475569">• Start-Button Pause</text>

  <!-- Right: Outputs -->
  <rect x="520" y="24" width="218" height="72" rx="7" fill="#FCE7F3" stroke="#DB2777" stroke-width="1.8"/>
  <text x="629" y="47" text-anchor="middle" font-size="12" font-weight="700" fill="#9D174D">vga_renderer_v2.v + BRAM</text>
  <text x="629" y="65" text-anchor="middle" font-size="10" fill="#334155">5-Stage Pipeline (0 Bottleneck)</text>
  <text x="629" y="81" text-anchor="middle" font-size="10" fill="#334155">VGA 640×480 @ 60 Hz (12-bit)</text>

  <rect x="520" y="112" width="218" height="58" rx="7" fill="#FFEDD5" stroke="#EA580C" stroke-width="1.8"/>
  <text x="629" y="135" text-anchor="middle" font-size="12" font-weight="700" fill="#9A3412">audio_synth_v2.v</text>
  <text x="629" y="153" text-anchor="middle" font-size="10" fill="#334155">3-Ch BRAM Chiptune + SFX (PWM)</text>

  <rect x="520" y="186" width="218" height="56" rx="7" fill="#E2E8F0" stroke="#475569" stroke-width="1.8"/>
  <text x="629" y="209" text-anchor="middle" font-size="12" font-weight="700" fill="#1E293B">Board LEDs &amp; 7-Segment</text>
  <text x="629" y="227" text-anchor="middle" font-size="10" fill="#334155">Score (BCD), Wave, HP, Stage</text>

  <!-- Arrows -->
  <line x1="100" y1="82" x2="100" y2="100" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
  <line x1="183" y1="131" x2="243" y2="131" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
  <line x1="183" y1="211" x2="243" y2="175" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
  <line x1="460" y1="95" x2="518" y2="60" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
  <line x1="460" y1="141" x2="518" y2="141" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
  <line x1="460" y1="185" x2="518" y2="214" stroke="#0284C7" stroke-width="2" marker-end="url(#arr)"/>
</svg>
'''

FSM_DIAGRAM_SVG = '''
<svg viewBox="0 0 760 310" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arr2" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#334155"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="756" height="306" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>

  <!-- Left Panel: Main Game FSM -->
  <rect x="14" y="14" width="228" height="282" rx="8" fill="#EFF6FF" stroke="#3B82F6" stroke-width="1.5"/>
  <text x="128" y="34" text-anchor="middle" font-size="12" font-weight="800" fill="#1D4ED8">1. Main Game FSM (game_state)</text>

  <rect x="64" y="48" width="128" height="36" rx="18" fill="#DBEAFE" stroke="#2563EB" stroke-width="1.8"/>
  <text x="128" y="70" text-anchor="middle" font-size="11" font-weight="700" fill="#1E3A8A">ST_TITLE (0)</text>

  <rect x="54" y="114" width="148" height="44" rx="10" fill="#DCFCE7" stroke="#16A34A" stroke-width="2"/>
  <text x="128" y="134" text-anchor="middle" font-size="11" font-weight="700" fill="#14532D">ST_PLAY (2)</text>
  <text x="128" y="149" text-anchor="middle" font-size="9.5" fill="#166534">Start Button ↔ PAUSED</text>

  <rect x="24" y="206" width="96" height="38" rx="14" fill="#FEF9C3" stroke="#CA8A04" stroke-width="1.8"/>
  <text x="72" y="229" text-anchor="middle" font-size="10.5" font-weight="700" fill="#713F12">ST_WIN (3)</text>

  <rect x="136" y="206" width="96" height="38" rx="14" fill="#FEE2E2" stroke="#DC2626" stroke-width="1.8"/>
  <text x="184" y="229" text-anchor="middle" font-size="10.5" font-weight="700" fill="#7F1D1D">ST_LOSE (4)</text>

  <text x="128" y="274" text-anchor="middle" font-size="9.5" fill="#475569">Fire = Retry | Left/Right = Title</text>

  <line x1="128" y1="84" x2="128" y2="112" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <text x="134" y="102" font-size="9" fill="#334155">Fire / Start</text>
  <line x1="100" y1="158" x2="75" y2="204" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <text x="42" y="185" font-size="9" fill="#15803D">Boss 3 ตาย</text>
  <line x1="156" y1="158" x2="181" y2="204" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <text x="172" y="185" font-size="9" fill="#B91C1C">HP = 0</text>

  <!-- Right Panel: Room & Boss Sub-FSM -->
  <rect x="256" y="14" width="490" height="282" rx="8" fill="#FAF5FF" stroke="#9333EA" stroke-width="1.5"/>
  <text x="501" y="34" text-anchor="middle" font-size="12" font-weight="800" fill="#6B21A8">2. Room &amp; Boss Sub-FSM (room_phase ภายใน ST_PLAY)</text>

  <rect x="274" y="54" width="136" height="46" rx="8" fill="#E0F2FE" stroke="#0284C7" stroke-width="1.8"/>
  <text x="342" y="74" text-anchor="middle" font-size="10.5" font-weight="700" fill="#0369A1">RP_BANNER (0)</text>
  <text x="342" y="90" text-anchor="middle" font-size="9" fill="#334155">ล็อคประตูปั้ง! + WAVE X</text>

  <rect x="444" y="54" width="136" height="46" rx="8" fill="#DCFCE7" stroke="#16A34A" stroke-width="1.8"/>
  <text x="512" y="74" text-anchor="middle" font-size="10.5" font-weight="700" fill="#166534">RP_FIGHT (1)</text>
  <text x="512" y="90" text-anchor="middle" font-size="9" fill="#334155">สู้ 2 Sub-waves / บอส</text>

  <rect x="606" y="54" width="126" height="46" rx="8" fill="#FEF3C7" stroke="#D97706" stroke-width="1.8"/>
  <text x="669" y="74" text-anchor="middle" font-size="10.5" font-weight="700" fill="#92400E">RP_CLEAR (2)</text>
  <text x="669" y="90" text-anchor="middle" font-size="9" fill="#334155">ลูกศรเด้งกระพริบ &gt;&gt;&gt;</text>

  <rect x="606" y="138" width="126" height="48" rx="8" fill="#FCE7F3" stroke="#DB2777" stroke-width="1.8"/>
  <text x="669" y="158" text-anchor="middle" font-size="10.5" font-weight="700" fill="#9D174D">RP_QUIZ (3)</text>
  <text x="669" y="174" text-anchor="middle" font-size="9" fill="#334155">สุ่มควิซ Logic Gate</text>

  <rect x="434" y="138" width="146" height="48" rx="8" fill="#CCFBF1" stroke="#0D9488" stroke-width="1.8"/>
  <text x="507" y="158" text-anchor="middle" font-size="10.5" font-weight="700" fill="#115E59">RP_DOOR (4)</text>
  <text x="507" y="174" text-anchor="middle" font-size="9" fill="#334155">ประตูสไลด์เปิด → Wave+1</text>

  <rect x="274" y="218" width="458" height="58" rx="8" fill="#FEE2E2" stroke="#DC2626" stroke-width="1.8"/>
  <text x="503" y="239" text-anchor="middle" font-size="11" font-weight="700" fill="#991B1B">RP_BOSS (5) — ด่านสุดท้าย (Wave 6)</text>
  <text x="503" y="257" text-anchor="middle" font-size="9.5" fill="#334155">บอสตาย → เอฟเฟคระเบิด + คำพูดเบียว → เปิด Portal งอกร่าง 2 &amp; 3 → ครบ 3 ร่างไป ST_WIN!</text>

  <line x1="410" y1="77" x2="442" y2="77" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <line x1="580" y1="77" x2="604" y2="77" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <line x1="669" y1="100" x2="669" y2="136" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <line x1="606" y1="162" x2="582" y2="162" stroke="#334155" stroke-width="1.8" marker-end="url(#arr2)"/>
  <path d="M 434 162 L 342 162 L 342 102" fill="none" stroke="#0284C7" stroke-width="1.8" marker-end="url(#arr2)"/>
  <line x1="512" y1="100" x2="512" y2="216" stroke="#DC2626" stroke-width="1.8" stroke-dasharray="4 3" marker-end="url(#arr2)"/>
</svg>
'''

BRIDGE_DIAGRAM_SVG = '''
<svg viewBox="0 0 760 220" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arr3" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#0F766E"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="756" height="216" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>

  <rect x="16" y="34" width="150" height="110" rx="8" fill="#E0F2FE" stroke="#0284C7" stroke-width="1.8"/>
  <text x="91" y="60" text-anchor="middle" font-size="12" font-weight="800" fill="#0369A1">1. Twin USB Joysticks</text>
  <text x="91" y="82" text-anchor="middle" font-size="10" fill="#334155">จอย 1 &amp; จอย 2 (สาย USB)</text>
  <text x="91" y="100" text-anchor="middle" font-size="10" fill="#334155">รองรับทั้ง Analog 2 Speed</text>
  <text x="91" y="118" text-anchor="middle" font-size="10" fill="#334155">และ Digital D-Pad + Start</text>

  <rect x="196" y="34" width="175" height="110" rx="8" fill="#FEF3C7" stroke="#D97706" stroke-width="1.8"/>
  <text x="283" y="60" text-anchor="middle" font-size="12" font-weight="800" fill="#92400E">2. PC Python Bridge</text>
  <text x="283" y="80" text-anchor="middle" font-size="10" fill="#334155">scripts/joy_bridge.py</text>
  <text x="283" y="98" text-anchor="middle" font-size="10" fill="#334155">อ่านผ่าน Windows winmm.dll</text>
  <text x="283" y="116" text-anchor="middle" font-size="10" fill="#334155">แพ็ค 3 ไบต์ทุก 1/60 วินาที</text>
  <text x="283" y="132" text-anchor="middle" font-size="9.5" fill="#B45309">(ไม่ต้องลง Library เสริม!)</text>

  <rect x="401" y="34" width="165" height="110" rx="8" fill="#CCFBF1" stroke="#0D9488" stroke-width="1.8"/>
  <text x="483" y="60" text-anchor="middle" font-size="12" font-weight="800" fill="#115E59">3. USB-UART Cable</text>
  <text x="483" y="82" text-anchor="middle" font-size="10" fill="#334155">ส่งผ่านพอร์ต COM (FTDI)</text>
  <text x="483" y="100" text-anchor="middle" font-size="10" fill="#334155">ความเร็ว 115,200 bps</text>
  <text x="483" y="118" text-anchor="middle" font-size="10" fill="#334155">เข้าขา UART_TXD_IN (C4)</text>

  <rect x="596" y="34" width="148" height="110" rx="8" fill="#EDE9FE" stroke="#7C3AED" stroke-width="1.8"/>
  <text x="670" y="60" text-anchor="middle" font-size="12" font-weight="800" fill="#5B21B6">4. FPGA Receiver</text>
  <text x="670" y="82" text-anchor="middle" font-size="10" fill="#334155">uart_joy_rx.v (25 MHz)</text>
  <text x="670" y="100" text-anchor="middle" font-size="10" fill="#334155">ตรวจบิต 0x80 Sync</text>
  <text x="670" y="118" text-anchor="middle" font-size="10" fill="#334155">ถอดรหัส J1, J2 &amp; Pause</text>

  <line x1="166" y1="89" x2="194" y2="89" stroke="#0F766E" stroke-width="2.2" marker-end="url(#arr3)"/>
  <line x1="371" y1="89" x2="399" y2="89" stroke="#0F766E" stroke-width="2.2" marker-end="url(#arr3)"/>
  <line x1="566" y1="89" x2="594" y2="89" stroke="#0F766E" stroke-width="2.2" marker-end="url(#arr3)"/>

  <!-- 4-Byte Packet Breakdown -->
  <rect x="16" y="160" width="728" height="44" rx="6" fill="#0F172A"/>
  <text x="380" y="178" text-anchor="middle" font-size="10" font-weight="700" fill="#38BDF8">แพ็กเก็ต 4 ไบต์: B0=[1|P1_Y|P1_dy|P1_dx] | B1=[0|P2_Y|P2_dy|P2_dx] | B2=[0|Start|P2_btn|P1_btn] | B3=[0..Select]</text>
  <text x="380" y="195" text-anchor="middle" font-size="9.5" fill="#CBD5E1">บิตแรกสุด (MSB = 1) ของ Byte 0 ล็อกหัวแถว + ปุ่ม Y ยิงปืน, Start=Pause, Select=กลับหน้า Menu</text>
</svg>
'''

SLIDES = [
    ("Slide 1 — หน้าปก (Title Slide)", "0:00 – 0:20", "คนที่ 1",
     wireframe_svg("SLIDE 1: TITLE", [(16,34,150,128,"ชื่อเกม + โลโก้\n+ ชื่อสมาชิก 5 คน","#0284C7"), (178,34,126,128,"รูป shot_title.png\n+ รูปบอร์ด Nexys A7","#DB2777")]),
     [
         "<b>หัวข้อใหญ่:</b> VeePire Survivors",
         "<b>หัวข้อรอง:</b> 2D Co-op Action RPG on Digilent Nexys A7-100T FPGA",
         "<b>รายละเอียด:</b> วิชา CPE222 Digital Logic Design | กลุ่มที่ ... | รายชื่อสมาชิก 5 คน + รหัสนักศึกษา",
         "<b>ภาพประกอบ:</b> ใช้รูป <code>shot_title.png</code> คู่กับรูปบอร์ด Nexys A7"
     ],
     "กล่าวทักทายอาจารย์และเพื่อนๆ แนะนำชื่อเกมและสมาชิกทั้ง 5 คนอย่างกระชับ"),

    ("Slide 2 — แนวคิดเกม & วัตถุประสงค์ (Objectives)", "0:20 – 0:50", "คนที่ 1",
     wireframe_svg("SLIDE 2: OBJECTIVES & CONCEPT", [(16,34,138,128,"Project Objectives\n(4 ข้อตาม Brief)","#0284C7"), (166,34,138,128,"Game Concept\nห้องเดี่ยว + ควิซ + บอส","#16A34A")]),
     [
         "<b>ฝั่งซ้าย (ตาม Brief หน้า 2):</b> 1) ออกแบบวงจรเกม Real-time ด้วย Pure Verilog  2) วาดภาพ VGA + รับปุ่มจอย  3) คุมเกมด้วย FSM  4) แบ่งงาน 5 คนและทำวิดีโอ Demo",
         "<b>ฝั่งขวา (Concept):</b> ตะลุยด่านห้องสี่เหลี่ยมเดี่ยว 6 Waves ควบคุมด้วยจอย (1P / 2P) สู้ศัตรูหน้าคนล้วน 2 ระลอกย่อยต่อด่าน → ตอบควิซ Logic Gate เปิดประตูสไลด์ → ปิดท้ายด้วยบอส Ajarn_V 3 ร่างงอกจาก Portal"
     ],
     "อธิบายสั้นๆ ว่าเกมเราสร้างเป็นวงจรฮาร์ดแวร์ล้วนๆ บนบอร์ด ไม่ได้เขียนโปรแกรมรันบน Windows"),

    ("Slide 3 — ฮาร์ดแวร์และข้อกำหนด (Hardware & Requirements)", "0:50 – 1:15", "คนที่ 1",
     wireframe_svg("SLIDE 3: HARDWARE & SPECS", [(16,34,138,60,"VGA 640x480@60Hz\n12-bit (4,096 สี)","#0284C7"), (166,34,138,60,"Board I/O: SW15-12 / 3-0\nLEDs + 7-Seg + Debounce","#D97706"), (16,104,138,60,"Pure Verilog\nVBlank Update","#7C3AED"), (166,104,138,60,"Extras: Joy Bridge\nAudio + Credit FPGADude","#16A34A")]),
     [
         "<b>Display:</b> จอ VGA <code>640×480 @ 60 Hz</code> 12-bit RGB (<code>4,096</code> สี)",
         "<b>Board I/O:</b> <code>SW[15:12]</code> เลือกสกินฝั่งซ้าย (P1), <code>SW[3:0]</code> เลือกสกินฝั่งขวา (P2), <code>16 LEDs</code> + <code>8-Digit 7-Segment</code> แสดงคะแนน/HP/Wave, ปุ่มกดผ่าน <code>5 ms Debouncer</code>",
         "<b>Design Rules:</b> Pure Verilog บน Vivado (ไม่ใช้ MicroBlaze) + อัปเดตภาพเฉพาะช่วง <b>VBlank</b> (ภาพไม่ฉีก)",
         "<b>Credit:</b> ระบุเครดิตโค้ด SPI Accelerometer จาก <code>FPGADude</code> ตามกฎ Brief หน้า 3"
     ],
     "ย้ำว่าทำครบตามสเปกบังคับของวิชาทุกข้อ และให้เครดิตโค้ดภายนอกเรียบร้อย"),

    ("Slide 4 — Feature 1: Movable Player & Arena Combat (25%)", "1:15 – 1:55", "คนที่ 2",
     wireframe_svg("SLIDE 4: FEATURE 1 (25%)", [(16,34,148,128,"4 จุดเด่นบังคับเคลื่อนที่\n• จอย 1P / 2P\n• ห้องเดี่ยว + ชนกำแพง\n• คอมโบ 360° + ซูม\n• Start = Pause","#0284C7"), (174,34,130,128,"รูปจริง:\nshot_combat_lunge.png","#DB2777")]),
     [
         "<b>Joystick-Only 8-Direction:</b> เดิน 8 ทิศทาง (Analog 2 ความเร็ว / D-Pad) ทั้งโหมด <b>1P</b> และ <b>2P Co-op</b>",
         "<b>Single-Room Boundary:</b> เห็นเฉพาะห้องสี่เหลี่ยมของด่านนั้น รอบนอกดำสนิท ชนกำแพง/ศัตรู/ประตูแม่นยำ",
         "<b>Extra Complexity:</b> พุ่งดูดระยะใกล้ (<code>≤72 px</code>) + คอมโบฟันดาบเสี้ยวจันทรา 3 จังหวะ (ท่า 3 ปล่อย <b>360° Nova</b>) + <b>ปุ่ม Y ยิงกระสุนฟ้าเรียวยาว</b>, <b>Smooth Auto-Zoom</b>, <b>Shadow Dash</b>, <b>Chrono-Shift (L2/R2)</b>",
         "<b>Start = Pause / Select = Menu:</b> กด Start ขึ้นหน้า <code>PAUSED</code> พร้อมรูปจอยชี้ปุ่มกด, กด Select กลับหน้า Menu"
     ],
     "ชี้รูป shot_combat_lunge.png ให้ดูวงคลื่นสีเหลือง 360° และกรอบห้องเดี่ยว"),

    ("Slide 5 — Feature 2: Sprite Evolutions, HP Regen & Skins (15%)", "1:55 – 2:35", "คนที่ 2",
     wireframe_svg("SLIDE 5: FEATURE 2 (15%)", [(16,34,288,54,"4 ขั้น Evolution (ไร้ Cutscene) + หลอดเลือด Regen","#7C3AED"), (16,96,288,68,"รูปจริง: sprite_preview.png (ฮีโร่หน้าคน 4 + ศัตรูหน้าคน 8 + บอส 3 + หัวใจ)","#D97706")]),
     [
         "<b>Event-Driven Evolution (≥3 Forms, ไร้ Cutscene):</b> เก็บ Blue Evo Gem (แม่เหล็กดูด) อัปเกรดต่อเนื่องโดยไม่ขัดจังหวะเล่น: <code>UP1 (GEM≥10)</code> ได้ Pet ช่วยยิง → <code>UP2 (GEM≥25)</code> ได้ดาบคู่หมุนรอบตัว → <code>UP3 (GEM≥45)</code> Apex Aura + ฟื้นเต็มหลอด 24 HP",
         "<b>สกินฮีโร่หน้าคนแยกฝั่ง (SW15–12 ซ้าย / SW3–0 ขวา):</b> ฝั่งซ้าย (P1) ใช้ <code>SW15–SW12</code> และฝั่งขวา (P2) ใช้ <code>SW3–SW0</code> ยึดสวิตช์ตัวบนสุดในกลุ่มที่เปิด",
         "<b>หลอดเลือด HP Bar + Out-of-Combat Regen + หัวใจ (<code>♥</code>):</b> เปลี่ยนเป็นหลอดเลือด (<code>0–24 HP</code>) มีหัวใจให้เก็บ และหากพักจากการต่อสู้ ~3 วินาที เลือดจะค่อยๆ ฟื้นฟูอัตโนมัติ"
     ],
     "ชี้รูป sprite_preview.png ว่ารอบนี้ใช้หน้าคนจริงทั้งหมดทั้งฮีโร่ ศัตรู และบอส"),

    ("Slide 6 — Feature 3: Our Own Creative Features (10%)", "2:35 – 3:20", "คนที่ 3",
     wireframe_svg("SLIDE 6: FEATURE 3 (10%)", [(16,34,138,60,"2P Co-op แยกหัวใจ\n+ ชุบเพื่อน 3 วิธี","#0284C7"), (166,34,138,60,"2 Sub-waves/ด่าน\n+ 3-Ch BRAM Audio","#16A34A"), (16,102,138,62,"รูป shot_coop_zoom.png\n(ควิซ Logic Gate)","#DB2777"), (166,102,138,62,"รูป shot_boss_locked.png\n(Portal + คำพูดเบียว)","#7C3AED")]),
     [
         "<b>1) 2P Co-op & 3-Way Revive:</b> แยกหลอดเลือด P1/P2 และชุบเพื่อนได้ 3 วิธี",
         "<b>2) 2 Sub-waves ต่อด่าน + ประตูสไลด์ควิซ Logic Gate:</b> เคลียร์ 2 ระลอกย่อย → ลูกศรเด้งกระพริบ → ชนประตูตอบควิซ Logic Gate (<code>AND/OR/NOT/NAND/NOR/XOR</code>) → เข้าห้องใหม่เกิดเอฟเฟคล็อคประตูปั้ง! + แบนเนอร์ <code>WAVE X</code> สไลด์ออก",
         "<b>3) บอส Ajarn_V 3 ร่างงอกจาก Portal:</b> ตายแล้วระเบิด + คำพูดเบียว + งอกร่างใหม่จาก Portal ครบ 3 ร่างจึง <code>VICTORY!</code>",
         "<b>4) เพลง BGM 3 ช่องเสียงจาก BRAM</b>"
     ],
     "จุดขายของกลุ่มเราคือเอา Logic Gate ที่เรียนในวิชามาทำเป็นประตูควิซก่อนผ่านด่าน"),

    ("Slide 7 — System Architecture & Block Diagram", "3:20 – 4:00", "คนที่ 3",
     wireframe_svg("SLIDE 7: BLOCK DIAGRAM", [(16,38,76,120,"Inputs\nJoy Bridge\nSW0-3 / Btn","#0284C7"), (114,38,92,120,"Core Logic\ngame_engine_v2\n(60 Hz FSM)","#7C3AED"), (228,38,76,120,"Outputs\nVGA 5-Stage\nAudio / LED","#DB2777")]),
     [
         "<b>นำ Block Diagram ด้านล่างไปวางกลางสไลด์ได้เลย</b> (อธิบายง่ายๆ เป็น 3 ฝั่ง: รับคำสั่ง → สมองกลางคำนวณ → แสดงผลขึ้นจอ/ลำโพง)",
         "<b>จุดเด่นทางวิศวกรรม:</b> <code>vga_renderer_v2</code> ออกแบบเป็นท่อส่งข้อมูล 5 จังหวะ (5-Stage Pipeline) ทำให้ภาพคมชัด 60 fps โดยไม่เกิดคอขวดความเร็ว"
     ],
     "เวลาพูดให้ชี้จากซ้าย (รับปุ่มจอย) → กลาง (สมองเกมคำนวณ) → ขวา (ออกจอ VGA และลำโพง)"),

    ("Slide 8 — Finite State Machine (FSM) Design", "4:00 – 4:50", "คนที่ 4",
     wireframe_svg("SLIDE 8: FSM DIAGRAM", [(16,34,100,128,"1. Main Game FSM\nTITLE → PLAY ↔ PAUSE\n→ WIN / LOSE","#2563EB"), (126,34,178,128,"2. Room & Boss Sub-FSM\nBANNER → FIGHT (2 Sub)\n→ CLEAR → QUIZ → DOOR\n& BOSS Portal 3 ร่าง","#9333EA")]),
     [
         "<b>ใช้ภาพ FSM Diagram ด้านล่างวางเต็มหน้าสไลด์นี้ได้เลย</b>",
         "<b>อธิบายให้คนทั่วไปเข้าใจ:</b> FSM ก็เหมือน 'แผนผังบอกจังหวะของเกม' แบ่งเป็น 2 ชั้น: ชั้นนอกคุมหน้าจอหลัก (Title / Play / Pause / Win / Lose) และชั้นในคุมจังหวะในแต่ละด่าน (ล็อคประตู → สู้ 2 ระลอกย่อย → ลูกศร → ควิซ → ประตูเปิด → บอส 3 ร่างงอกจาก Portal)"
     ],
     "เล่าเรียงตามลูกศรเลยครับ อาจารย์จะเห็นภาพ Flow ของเกมทั้งหมดชัดเจนมาก"),

    ("Slide 9 — PC-to-FPGA Joystick Bridge (คอมเป็นสะพานเชื่อมจอย)", "4:50 – 5:40", "คนที่ 4",
     wireframe_svg("SLIDE 9: JOYSTICK BRIDGE", [(16,36,64,76,"1. Twin USB\nJoysticks","#0284C7"), (90,36,70,76,"2. PC Python\nwinmm.dll","#D97706"), (170,36,64,76,"3. USB-UART\n115200 bps","#0D9488"), (244,36,60,76,"4. FPGA\nuart_joy_rx","#7C3AED"), (16,122,288,40,"Packet 4 Bytes: B0[0x80+P1_Y] | B1[P2_Y] | B2[Start+Btns] | B3[Select]","#0F172A")]),
     [
         "<b>ปัญหาที่เจอ:</b> บอร์ด Nexys A7 อ่านจอย USB Gamepad คู่โดยตรงไม่ได้ (บอร์ดรองรับแค่คีย์บอร์ด/เมาส์มาตรฐาน)",
         "<b>วิธีแก้:</b> ใช้โปรแกรม <code>joy_bridge.py</code> บนคอมเป็น 'สะพานเชื่อม' อ่านจอย 1 &amp; 2 ผ่าน Windows API (<code>winmm.dll</code>) 60 ครั้ง/วิ แล้วส่งข้อมูล <b>4 ไบต์</b> ผ่านสาย Micro-USB (<code>UART 115,200 bps</code>) เข้าชิป FPGA",
         "<b>ความฉลาดของโปรโตคอล:</b> ใส่บิตหัวแถว <code>0x80</code> ใน Byte 0 กันข้อมูลสลับตำแหน่ง, ปุ่ม <code>Y</code> ยิงกระสุนฟ้า, ปุ่ม <code>Start</code> สั่ง <b>Pause</b> และปุ่ม <code>Select</code> กลับหน้า <b>Menu</b>"
     ],
     "หน้านี้โชว์ความสามารถแก้ปัญหา Hardware Limitation ด้วยการทำ Software-to-Hardware Bridge"),

    ("Slide 10 — Work Plan & การแบ่งงานสมาชิก 5 คน", "5:40 – 6:20", "คนที่ 5",
     wireframe_svg("SLIDE 10: WORK PLAN (5 MEMBERS)", [(16,34,288,42,"Schedule: 13/11 Proposal  →  20/11 Progress Demo  →  27/11 Final Submit","#16A34A"), (16,84,288,80,"ตารางแบ่งงาน 5 คน (คนที่ 1: VGA/IO | คนที่ 2: Engine | คนที่ 3: Graphics\nคนที่ 4: Joy Bridge/Audio | คนที่ 5: Test/Slide/Video/Report)","#0284C7")]),
     [
         "<b>Timeline ตาม Brief:</b> 13/11 เสนอ Proposal → 20/11 โชว์ความคืบหน้าบนบอร์ด → 27/11 ส่งวิดีโอ + Final Report + Code",
         "<b>การแบ่งงาน 5 คน:</b> 1) VGA/Debounce/7-Seg  2) Game Engine/Quiz/Zoom  3) Renderer/Sprites/Pause UI  4) Joystick Bridge/Audio  5) Simulation/Hardware Test/Slide &amp; Report"
     ],
     "ชี้ให้เห็นว่าทุกคนมีหน้าที่ชัดเจนทั้งฝั่งฮาร์ดแวร์ ซอฟต์แวร์ และเอกสาร"),

    ("Slide 11 — ความคืบหน้า & แผน Demo (Progress & Closing)", "6:20 – 7:00", "คนที่ 5",
     wireframe_svg("SLIDE 11: PROGRESS & DEMO", [(16,34,138,128,"เสร็จแล้ว 100%:\n• Sim PASS (0 Err)\n• Vivado Bitstream OK\n• แฟลชลงบอร์ดจริงแล้ว","#16A34A"), (166,34,138,128,"แผนขั้นถัดไป:\n• อัดวิดีโอ Demo ≤7 นาที\n• ทำ Final Report PDF\n• ส่ง 27/11/2026","#D97706")]),
     [
         "<b>สถานะปัจจุบัน (ทำจริงแล้ว!):</b> Simulation ผ่าน <code>RESULT : PASS</code>, คอมไพล์บน Vivado 2024.2 ผ่าน (<code>0 Errors</code>), และแฟลชลงบอร์ด Nexys A7-100T จริงเรียบร้อย",
         "<b>ขั้นถัดไป:</b> ทดสอบเล่นจริงกับจอยคู่หน้าบอร์ด + อัดวิดีโอ Demo ไม่เกิน 7 นาที + จัดทำ Final Report ส่งวันที่ 27/11/2026"
     ],
     "ปิดท้ายอย่างมั่นใจว่าตัวเกมรันบนบอร์ดจริงได้แล้ว พร้อมรับคำแนะนำจากอาจารย์ครับ!")
]

slide_sections = []
for idx, (stitle, stime, speaker, wf, bullets, tip) in enumerate(SLIDES, 1):
    extra_diagram = ""
    if idx == 7:
        extra_diagram = f'<div class="diag-box"><div class="diag-title">ภาพ Block Diagram สำหรับใส่ใน Slide 7</div>{BLOCK_DIAGRAM_SVG}</div>'
    elif idx == 8:
        extra_diagram = f'<div class="diag-box"><div class="diag-title">ภาพ FSM Diagram สำหรับใส่ใน Slide 8</div>{FSM_DIAGRAM_SVG}</div>'
    elif idx == 9:
        extra_diagram = f'<div class="diag-box"><div class="diag-title">ภาพ PC-to-FPGA Joystick Bridge สำหรับใส่ใน Slide 9</div>{BRIDGE_DIAGRAM_SVG}</div>'

    blist = "".join(f"<li>{b}</li>" for b in bullets)
    slide_sections.append(f'''
    <div class="slide-card">
      <div class="slide-hdr">
        <span class="slide-title">{stitle}</span>
        <span class="badge">{speaker} · {stime}</span>
      </div>
      <div class="slide-grid">
        <div class="wf-col">
          <div class="sub-lbl">ตัวอย่างโครงสร้างหน้าสไลด์ (Layout)</div>
          {wf}
        </div>
        <div class="txt-col">
          <div class="sub-lbl">ข้อความสำหรับใส่ใน Canva</div>
          <ul>{blist}</ul>
          <div class="tip"><b>ทริคตอนพูด:</b> {tip}</div>
        </div>
      </div>
      {extra_diagram}
    </div>
    ''')

html = f'''<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8"/>
<title>VeePire Survivors - Canva Slide Guide</title>
<style>
  @page {{ size: A4; margin: 14mm; }}
  body {{ font-family: "Leelawadee UI", "Tahoma", "Segoe UI", sans-serif; color: #0F172A; margin: 0; line-height: 1.48; font-size: 11.5pt; }}
  .hero {{ background: linear-gradient(135deg, #0F172A, #1E293B); color: #F8FAFC; padding: 18px 22px; border-radius: 12px; margin-bottom: 14px; }}
  .hero h1 {{ margin: 0 0 4px 0; font-size: 20pt; color: #38BDF8; }}
  .hero p {{ margin: 2px 0; font-size: 10.5pt; color: #CBD5E1; }}
  h2 {{ font-size: 14pt; color: #0369A1; border-left: 5px solid #0284C7; padding-left: 10px; margin: 16px 0 8px 0; }}
  table {{ width: 100%; border-collapse: collapse; margin-bottom: 12px; font-size: 10pt; }}
  th, td {{ border: 1px solid #CBD5E1; padding: 6px 8px; text-align: left; vertical-align: top; }}
  th {{ background: #E0F2FE; color: #0C4A6E; }}
  code {{ background: #F1F5F9; padding: 1px 4px; border-radius: 4px; font-family: Consolas, monospace; font-size: 9.5pt; color: #BE185D; }}
  .asset-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-bottom: 12px; }}
  .asset-box {{ border: 1px solid #CBD5E1; border-radius: 8px; padding: 8px; background: #F8FAFC; text-align: center; page-break-inside: avoid; }}
  .asset-box img {{ max-width: 100%; max-height: 165px; border-radius: 4px; border: 1px solid #94A3B8; }}
  .asset-cap {{ font-size: 9.5pt; font-weight: 700; color: #334155; margin-top: 4px; }}
  .slide-card {{ border: 1.5px solid #CBD5E1; border-radius: 10px; padding: 11px 13px; margin-bottom: 12px; page-break-inside: avoid; background: #FFFFFF; }}
  .slide-hdr {{ display: flex; justify-content: space-between; align-items: center; border-bottom: 1px solid #E2E8F0; padding-bottom: 6px; margin-bottom: 8px; }}
  .slide-title {{ font-size: 12.5pt; font-weight: 800; color: #0F172A; }}
  .badge {{ background: #0284C7; color: #FFFFFF; padding: 2px 9px; border-radius: 12px; font-size: 9.5pt; font-weight: 700; }}
  .slide-grid {{ display: grid; grid-template-columns: 230px 1fr; gap: 12px; align-items: start; }}
  .sub-lbl {{ font-size: 9.5pt; font-weight: 700; color: #475569; margin-bottom: 4px; }}
  .wf-svg {{ width: 100%; height: auto; display: block; }}
  .txt-col ul {{ margin: 0 0 6px 0; padding-left: 18px; font-size: 10pt; }}
  .txt-col li {{ margin-bottom: 3px; }}
  .tip {{ background: #FEF9C3; border-left: 4px solid #EAB308; padding: 5px 8px; font-size: 9.5pt; border-radius: 4px; color: #713F12; }}
  .diag-box {{ margin-top: 10px; border-top: 1px dashed #CBD5E1; padding-top: 8px; }}
  .diag-title {{ font-size: 10pt; font-weight: 700; color: #5B21B6; margin-bottom: 4px; }}
  .diag-svg {{ width: 100%; height: auto; display: block; }}
  .page-break {{ page-break-before: always; }}
</style>
</head>
<body>
  <div class="hero">
    <h1>คู่มือทำสไลด์ Canva — VeePire Survivors</h1>
    <p>สำหรับสมาชิกทำสไลด์ที่ไม่ต้องมีพื้นฐาน Digital / Verilog / Vivado | ตรงตาม <b>CPE222 Final Brief</b></p>
    <p><b>เวลาพูดรวม:</b> 7 นาที 00 วินาที | <b>สมาชิก:</b> 5 คน | <b>จำนวนสไลด์:</b> 11 หน้า</p>
  </div>

  <h2>1. พจนานุกรมศัพท์เทคนิคฉบับคนทั่วไป (อ่าน 1 นาทีเข้าใจเลย!)</h2>
  <table>
    <tr><th style="width:26%">คำศัพท์ในสไลด์</th><th>ความหมายภาษาคนทั่วไป (เอาไว้เข้าใจและอธิบายอาจารย์ได้)</th></tr>
    <tr><td><b>FPGA (Nexys A7-100T)</b></td><td>ชิปที่แปลงตัวเองเป็น "วงจรอิเล็กทรอนิกส์" ตามโค้ดที่เราเขียน ทุกส่วนทำงานพร้อมกันแบบฮาร์ดแวร์ล้วนๆ</td></tr>
    <tr><td><b>Pure Verilog (No MicroBlaze)</b></td><td>เขียนโค้ดสร้างวงจรเกมเอง 100% ไม่ได้แอบเอา CPU สำเร็จรูปมาใส่แล้วเขียนภาษา C</td></tr>
    <tr><td><b>VGA 640×480 @ 60 Hz (12-bit)</b></td><td>สายต่อจอภาพสีน้ำเงิน แสดงผลขนาด 640×480 จุด วาดใหม่ 60 ภาพ/วินาที ใช้ได้ 4,096 สี</td></tr>
    <tr><td><b>VBlank Update</b></td><td>จังหวะพักเสี้ยววินาทีหลังวาดจอเสร็จ 1 ภาพ เราขยับตัวละครเฉพาะช่วงนี้ ภาพจะได้ไม่ขาดครึ่งจอ</td></tr>
    <tr><td><b>Debouncer (5 ms)</b></td><td>ตัวกรองสัญญาณปุ่มกดบนบอร์ด (เวลาคนกด 1 ครั้ง หน้าสัมผัสโลหะมันสั่น จึงต้องกรอง 5 มิลลิวินาที)</td></tr>
    <tr><td><b>BRAM</b></td><td>หน่วยความจำขนาดเล็กบนชิป FPGA ใช้เก็บรูปหน้าตัวละคร แผนที่ห้อง และโน้ตเพลง 8-bit</td></tr>
    <tr><td><b>FSM (Finite State Machine)</b></td><td>แผนผัง "สถานะของเกม" เช่น หน้าเริ่ม → เล่น → Pause → ตอบควิซ → บอส → ชนะ/แพ้</td></tr>
    <tr><td><b>Joystick Bridge (UART)</b></td><td>โปรแกรมบนคอมพิวเตอร์ที่ทำหน้าที่เป็น "ล่าม/สะพาน" อ่านจอย USB คู่แล้วส่งผ่านสายเข้าบอร์ด FPGA</td></tr>
  </table>

  <h2>2. ตารางแบ่งเวลาพูด 7 นาที (สมาชิก 5 คน)</h2>
  <table>
    <tr><th>สมาชิก</th><th>สไลด์ที่รับผิดชอบ</th><th>เวลาพูด</th><th>ช่วงเวลา</th></tr>
    <tr><td><b>คนที่ 1</b></td><td>Slide 1 – 3 (หน้าปก, Objectives &amp; Concept, Hardware Specs)</td><td>1 นาที 15 วิ</td><td>0:00 – 1:15</td></tr>
    <tr><td><b>คนที่ 2</b></td><td>Slide 4 – 5 (Feature 1 บังคับตัวละคร/ห้องเดี่ยว, Feature 2 อัปเกรด &amp; สกิน SW0–SW3)</td><td>1 นาที 20 วิ</td><td>1:15 – 2:35</td></tr>
    <tr><td><b>คนที่ 3</b></td><td>Slide 6 – 7 (Feature 3 ควิซประตู/บอส 3 ร่าง, System Block Diagram)</td><td>1 นาที 25 วิ</td><td>2:35 – 4:00</td></tr>
    <tr><td><b>คนที่ 4</b></td><td>Slide 8 – 9 (<b>FSM Diagram</b> และ <b>PC-to-FPGA Joystick Bridge</b>)</td><td>1 นาที 40 วิ</td><td>4:00 – 5:40</td></tr>
    <tr><td><b>คนที่ 5</b></td><td>Slide 10 – 11 (การแบ่งงาน 5 คน + Timeline, ความคืบหน้า &amp; ปิดท้าย Demo)</td><td>1 นาที 20 วิ</td><td>5:40 – 7:00</td></tr>
  </table>

  <div class="page-break"></div>
  <h2>3. คลังภาพประกอบจริงจากตัวเกม (Asset Gallery — ดึงไฟล์จากโฟลเดอร์โปรเจกต์ลง Canva ได้เลย)</h2>
  <div class="asset-box" style="margin-bottom:10px;">
    <img src="{IMG_SPRITES}" style="max-height:190px;"/>
    <div class="asset-cap">sprite_preview.png — ใส่ Slide 5 (ฮีโร่หน้าคน 4 ตัว + ศัตรูหน้าคน 8 ตัว + บอส Ajarn_V 3 ร่าง + หัวใจ)</div>
  </div>
  <div class="asset-grid">
    <div class="asset-box"><img src="{IMG_TITLE}"/><div class="asset-cap">docs/screenshots/shot_title.png — ใส่ Slide 1</div></div>
    <div class="asset-box"><img src="{IMG_COMBAT}"/><div class="asset-cap">docs/screenshots/shot_combat_lunge.png — ใส่ Slide 4</div></div>
    <div class="asset-box"><img src="{IMG_QUIZ}"/><div class="asset-cap">docs/screenshots/shot_coop_zoom.png — ใส่ Slide 6 (ควิซ Logic Gate)</div></div>
    <div class="asset-box"><img src="{IMG_BOSS}"/><div class="asset-cap">docs/screenshots/shot_boss_locked.png — ใส่ Slide 6 (Portal + คำพูดเบียว)</div></div>
  </div>

  <div class="page-break"></div>
  <h2>4. แผนผังและตัวอย่างโครงสร้างสไลด์ทั้ง 11 หน้า (Layout + ข้อความ + Diagrams)</h2>
  {''.join(slide_sections)}
</body>
</html>
'''

html_path = os.path.join(DOC_DIR, "Canva_Slide_Guide.html")
pdf_path = os.path.join(DOC_DIR, "Canva_Slide_Guide.pdf")
with open(html_path, "w", encoding="utf-8") as f:
    f.write(html)

edge = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
subprocess.run([edge, "--headless", "--disable-gpu", f"--print-to-pdf={pdf_path}", "--no-pdf-header-footer", html_path], check=True)
print("Generated:", pdf_path)
