import base64
import glob
import os
import subprocess

from PIL import Image

BASE = r"D:\vivado_pj\DRAGO_NEXUS_V2"
DOC_DIR = os.path.join(BASE, "doc")
DIAG_DIR = os.path.join(DOC_DIR, "diagrams")
EDGE_TMP = os.path.join(BASE, "vivado_tmp", "edge_prof")
os.makedirs(DOC_DIR, exist_ok=True)
os.makedirs(DIAG_DIR, exist_ok=True)
os.makedirs(EDGE_TMP, exist_ok=True)

EDGE_EXE = r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"


def convert_all_v5_ppms():
    for pat in ("rtl_v5_*.ppm", "rtl_v6_*.ppm"):
        for ppm in glob.glob(os.path.join(BASE, "sim_work", pat)):
            png = ppm[:-4] + ".png"
            if not os.path.exists(png) or os.path.getmtime(ppm) > os.path.getmtime(png):
                try:
                    Image.open(ppm).save(png)
                except Exception:
                    pass


def img_b64(path_or_rel, fallback=None):
    p = path_or_rel if os.path.isabs(path_or_rel) else os.path.join(BASE, path_or_rel)
    if not os.path.exists(p) and fallback:
        p = fallback if os.path.isabs(fallback) else os.path.join(BASE, fallback)
    with open(p, "rb") as f:
        return "data:image/png;base64," + base64.b64encode(f.read()).decode("ascii")


def edge_env():
    env = os.environ.copy()
    tmp_d = os.path.join(BASE, "vivado_tmp")
    os.makedirs(tmp_d, exist_ok=True)
    env["TEMP"] = tmp_d
    env["TMP"] = tmp_d
    return env


def html_to_pdf(html_path, pdf_path):
    url = "file:///" + html_path.replace("\\", "/")
    cmd = [
        EDGE_EXE,
        "--headless",
        "--disable-gpu",
        f"--user-data-dir={EDGE_TMP}",
        "--no-pdf-header-footer",
        "--run-all-compositor-stages-before-draw",
        f"--print-to-pdf={pdf_path}",
        url,
    ]
    subprocess.run(cmd, env=edge_env(), check=True)
    print(f"[OK] Built PDF: {pdf_path} ({os.path.getsize(pdf_path)} bytes)")


def html_to_png(html_path, png_path, width=1600, height=900):
    url = "file:///" + html_path.replace("\\", "/")
    cmd = [
        EDGE_EXE,
        "--headless",
        "--disable-gpu",
        f"--user-data-dir={EDGE_TMP}",
        "--hide-scrollbars",
        "--run-all-compositor-stages-before-draw",
        f"--window-size={width},{height}",
        f"--screenshot={png_path}",
        url,
    ]
    subprocess.run(cmd, env=edge_env(), check=True)
    print(f"[OK] Built PNG: {png_path} ({os.path.getsize(png_path)} bytes)")


# ==============================================================================
# SHARED SVG ARCHITECTURAL DIAGRAMS (used inside PDFs + exported for Canva)
# ==============================================================================

SVG_MASTER_FSM = """
<svg viewBox="0 0 820 290" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="arr-b" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#2563EB"/>
    </marker>
    <marker id="arr-r" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#DC2626"/>
    </marker>
    <marker id="arr-g" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#16A34A"/>
    </marker>
    <marker id="arr-o" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#D97706"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="816" height="286" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <text x="410" y="24" text-anchor="middle" font-size="12" font-weight="800" fill="#1E293B" font-family="sans-serif">DIAGRAM 1.1: MASTER GAME STATE MACHINE (game_state [2:0] &amp; paused)</text>

  <!-- rst_n arrow -->
  <line x1="16" y1="90" x2="48" y2="90" stroke="#2563EB" stroke-width="2" marker-end="url(#arr-b)"/>
  <text x="31" y="82" text-anchor="middle" font-size="9.5" font-weight="700" fill="#1D4ED8">rst</text>

  <!-- ST_TITLE -->
  <rect x="52" y="48" width="165" height="86" rx="10" fill="#EFF6FF" stroke="#2563EB" stroke-width="2.2"/>
  <text x="134" y="69" text-anchor="middle" font-size="12" font-weight="800" fill="#1D4ED8">ST_TITLE (3'd0)</text>
  <text x="134" y="86" text-anchor="middle" font-size="9.5" fill="#334155">Dead Cells Auto-Detect:</text>
  <text x="134" y="99" text-anchor="middle" font-size="9" fill="#475569">KB=1P Only | Joy=1P/2P</text>
  <text x="134" y="112" text-anchor="middle" font-size="9" fill="#475569">BTNs: Head + 6 Weapons</text>
  <text x="134" y="125" text-anchor="middle" font-size="9" fill="#0369A1">help_page 1..3 (SEL/ESC)</text>

  <!-- Arrow TITLE -> PLAY -->
  <line x1="217" y1="90" x2="318" y2="90" stroke="#2563EB" stroke-width="2" marker-end="url(#arr-b)"/>
  <text x="267" y="79" text-anchor="middle" font-size="9" font-weight="700" fill="#1D4ED8">Fire / Space / J</text>
  <text x="267" y="104" text-anchor="middle" font-size="8.5" fill="#64748B">(via ST_CUTSCENE=1)</text>

  <!-- ST_PLAY -->
  <rect x="322" y="45" width="215" height="92" rx="10" fill="#F0FDF4" stroke="#16A34A" stroke-width="2.5"/>
  <text x="429" y="67" text-anchor="middle" font-size="12.5" font-weight="800" fill="#15803D">ST_PLAY (3'd2)</text>
  <text x="429" y="84" text-anchor="middle" font-size="9.5" fill="#334155">Active Gameplay Loop (46-Cycle Engine)</text>
  <text x="429" y="98" text-anchor="middle" font-size="9" fill="#475569">J1 + KB control P1 | J2 controls P2</text>
  <text x="429" y="112" text-anchor="middle" font-size="9" fill="#475569">Runs Room Sub-FSM (room_phase [2:0])</text>
  <text x="429" y="126" text-anchor="middle" font-size="9" fill="#166534">ADT7420 Fever + PDM 2P Sonic Wave</text>

  <!-- PAUSED Overlay State -->
  <rect x="342" y="182" width="175" height="82" rx="10" fill="#FFFBEB" stroke="#D97706" stroke-width="2.2"/>
  <text x="429" y="203" text-anchor="middle" font-size="11.5" font-weight="800" fill="#B45309">PAUSED Overlay</text>
  <text x="429" y="218" text-anchor="middle" font-size="9" fill="#475569">(paused=1, step_state=0)</text>
  <text x="429" y="233" text-anchor="middle" font-size="9" fill="#334155">Unified 3-Page Controls Guide</text>
  <text x="429" y="247" text-anchor="middle" font-size="9" fill="#B45309">SEL = Exit to ST_TITLE</text>

  <!-- PLAY <-> PAUSED -->
  <path d="M 405 137 L 405 180" stroke="#D97706" stroke-width="2" marker-end="url(#arr-o)"/>
  <text x="342" y="160" text-anchor="middle" font-size="8.5" font-weight="700" fill="#B45309">START/ENT/ESC</text>
  <text x="342" y="170" text-anchor="middle" font-size="8" fill="#64748B">(!QUIZ &amp;&amp; !Morph)</text>
  <path d="M 455 182 L 455 139" stroke="#16A34A" stroke-width="2" marker-end="url(#arr-g)"/>
  <text x="515" y="163" text-anchor="middle" font-size="8.5" font-weight="700" fill="#15803D">START/ENT/ESC</text>

  <!-- PAUSED -> TITLE via SEL -->
  <path d="M 342 225 L 115 225 L 115 136" fill="none" stroke="#64748B" stroke-width="1.8" stroke-dasharray="4 3" marker-end="url(#arr-b)"/>
  <text x="225" y="218" text-anchor="middle" font-size="8.5" font-weight="700" fill="#475569">joy_select edge (Main Menu)</text>

  <!-- ST_WIN -->
  <rect x="615" y="48" width="180" height="78" rx="10" fill="#ECFDF5" stroke="#10B981" stroke-width="2.2"/>
  <text x="705" y="70" text-anchor="middle" font-size="12" font-weight="800" fill="#047857">ST_WIN (3'd3)</text>
  <text x="705" y="87" text-anchor="middle" font-size="9.5" fill="#334155">Boss Form 2 Defeated!</text>
  <text x="705" y="101" text-anchor="middle" font-size="9" fill="#475569">end_lockout = 90f (1.5s)</text>
  <text x="705" y="114" text-anchor="middle" font-size="8.5" fill="#047857">Start=Retry | L/R=Title</text>

  <!-- Arrow PLAY -> WIN -->
  <line x1="537" y1="86" x2="613" y2="86" stroke="#16A34A" stroke-width="2" marker-end="url(#arr-g)"/>
  <text x="575" y="72" text-anchor="middle" font-size="8.5" font-weight="700" fill="#15803D">boss_kind==2</text>
  <text x="575" y="82" text-anchor="middle" font-size="8" fill="#15803D">&amp;&amp; hp==0</text>

  <!-- ST_LOSE -->
  <rect x="615" y="176" width="180" height="82" rx="10" fill="#FEF2F2" stroke="#DC2626" stroke-width="2.2"/>
  <text x="705" y="198" text-anchor="middle" font-size="12" font-weight="800" fill="#B91C1C">ST_LOSE (3'd4)</text>
  <text x="705" y="215" text-anchor="middle" font-size="9.5" fill="#334155">All Active Players HP == 0</text>
  <text x="705" y="229" text-anchor="middle" font-size="9" fill="#475569">end_lockout = 90f (1.5s)</text>
  <text x="705" y="243" text-anchor="middle" font-size="8.5" fill="#B91C1C">Start=Retry | L/R=Title</text>

  <!-- Arrow PLAY -> LOSE -->
  <path d="M 537 115 L 575 115 L 575 210 L 613 210" fill="none" stroke="#DC2626" stroke-width="2" marker-end="url(#arr-r)"/>
  <text x="580" y="150" text-anchor="start" font-size="8.5" font-weight="700" fill="#DC2626">!p1_alive</text>
  <text x="580" y="162" text-anchor="start" font-size="8.5" font-weight="700" fill="#DC2626">&amp;&amp; !p2_alive</text>

  <!-- Return arcs from WIN/LOSE -->
  <path d="M 705 176 L 705 152 L 545 152 L 495 137" fill="none" stroke="#64748B" stroke-width="1.3" stroke-dasharray="3 3" marker-end="url(#arr-b)"/>
  <path d="M 705 258 L 705 275 L 90 275 L 90 136" fill="none" stroke="#64748B" stroke-width="1.5" stroke-dasharray="4 3" marker-end="url(#arr-b)"/>
  <text x="415" y="270" text-anchor="middle" font-size="8.5" fill="#475569">L / R / SEL -&gt; Reset &amp; Return to ST_TITLE | Start -&gt; Instant Retry ST_PLAY</text>
</svg>
"""

SVG_ROOM_FSM = """
<svg viewBox="0 0 820 275" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="r-b" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#2563EB"/></marker>
    <marker id="r-g" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#16A34A"/></marker>
    <marker id="r-r" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#DC2626"/></marker>
    <marker id="r-p" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#9333EA"/></marker>
  </defs>
  <rect x="2" y="2" width="816" height="271" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <text x="410" y="23" text-anchor="middle" font-size="12" font-weight="800" fill="#1E293B" font-family="sans-serif">DIAGRAM 2.1: ROOM PROGRESSION &amp; LOGIC GATE QUIZ SUB-FSM (room_phase [2:0])</text>

  <!-- RP_BANNER -->
  <rect x="20" y="55" width="132" height="78" rx="8" fill="#EFF6FF" stroke="#2563EB" stroke-width="2"/>
  <text x="86" y="75" text-anchor="middle" font-size="11" font-weight="800" fill="#1D4ED8">RP_BANNER (0)</text>
  <text x="86" y="91" text-anchor="middle" font-size="8.8" fill="#334155">wave_banner_t = 90f</text>
  <text x="86" y="104" text-anchor="middle" font-size="8.8" fill="#334155">door_slam_t = 45f</text>
  <text x="86" y="118" text-anchor="middle" font-size="8.5" fill="#1D4ED8">Revives 2P if dead</text>

  <line x1="152" y1="94" x2="188" y2="94" stroke="#2563EB" stroke-width="2" marker-end="url(#r-b)"/>
  <text x="170" y="84" text-anchor="middle" font-size="8" font-weight="700" fill="#1D4ED8">t==0</text>

  <!-- RP_FIGHT -->
  <rect x="190" y="55" width="145" height="78" rx="8" fill="#FFF7ED" stroke="#EA580C" stroke-width="2"/>
  <text x="262" y="75" text-anchor="middle" font-size="11" font-weight="800" fill="#C2410C">RP_FIGHT (1)</text>
  <text x="262" y="91" text-anchor="middle" font-size="8.8" fill="#334155">Wave 1..5 Sub-waves</text>
  <text x="262" y="104" text-anchor="middle" font-size="8.8" fill="#334155">(30..80 Minions total)</text>
  <text x="262" y="118" text-anchor="middle" font-size="8.5" fill="#9A3412">Or Wave 6: Boss Ajarn_V</text>

  <line x1="335" y1="94" x2="372" y2="94" stroke="#16A34A" stroke-width="2" marker-end="url(#r-g)"/>
  <text x="353" y="79" text-anchor="middle" font-size="8" font-weight="700" fill="#15803D">Subwaves</text>
  <text x="353" y="88" text-anchor="middle" font-size="8" font-weight="700" fill="#15803D">Cleared</text>

  <!-- RP_CLEAR -->
  <rect x="374" y="55" width="128" height="78" rx="8" fill="#F0FDF4" stroke="#16A34A" stroke-width="2"/>
  <text x="438" y="75" text-anchor="middle" font-size="11" font-weight="800" fill="#15803D">RP_CLEAR (2)</text>
  <text x="438" y="91" text-anchor="middle" font-size="8.8" fill="#334155">Guide Arrows Flash</text>
  <text x="438" y="104" text-anchor="middle" font-size="8.5" fill="#166534">Walk to East Door</text>
  <text x="438" y="118" text-anchor="middle" font-size="8.5" fill="#166534">x &gt;= 516, y=176..272</text>

  <line x1="502" y1="94" x2="538" y2="94" stroke="#9333EA" stroke-width="2" marker-end="url(#r-p)"/>
  <text x="520" y="84" text-anchor="middle" font-size="8" font-weight="700" fill="#7E22CE">Door</text>

  <!-- RP_QUIZ -->
  <rect x="540" y="48" width="140" height="90" rx="8" fill="#FAF5FF" stroke="#9333EA" stroke-width="2"/>
  <text x="610" y="68" text-anchor="middle" font-size="11" font-weight="800" fill="#7E22CE">RP_QUIZ (3)</text>
  <text x="610" y="84" text-anchor="middle" font-size="8.5" fill="#334155">6 Logic Gates (AND..XOR)</text>
  <text x="610" y="97" text-anchor="middle" font-size="8.5" fill="#334155">30f anti-mash lockout</text>
  <text x="610" y="110" text-anchor="middle" font-size="8.5" fill="#15803D">PASS: stage&lt;3 =&gt; Morph</text>
  <text x="610" y="123" text-anchor="middle" font-size="8.5" fill="#DC2626">FAIL: GO RETAKE (105f)</text>

  <line x1="680" y1="94" x2="704" y2="94" stroke="#16A34A" stroke-width="2" marker-end="url(#r-g)"/>

  <!-- RP_DOOR -->
  <rect x="706" y="55" width="98" height="78" rx="8" fill="#ECFEFF" stroke="#0891B2" stroke-width="2"/>
  <text x="755" y="75" text-anchor="middle" font-size="10.5" font-weight="800" fill="#0E7490">RP_DOOR (4)</text>
  <text x="755" y="92" text-anchor="middle" font-size="8.5" fill="#334155">Door Slides 0..31</text>
  <text x="755" y="106" text-anchor="middle" font-size="8.5" fill="#334155">Enter x &gt;= 534</text>
  <text x="755" y="120" text-anchor="middle" font-size="8.5" fill="#0E7490">wave &lt;= wave + 1</text>

  <!-- FAIL arc RP_QUIZ -> RP_BANNER -->
  <path d="M 610 138 L 610 170 L 86 170 L 86 135" fill="none" stroke="#DC2626" stroke-width="1.9" stroke-dasharray="5 3" marker-end="url(#r-r)"/>
  <text x="345" y="164" text-anchor="middle" font-size="9" font-weight="700" fill="#DC2626">WRONG ANSWER ("F" + CAUTION: GO RETAKE !!) -&gt; Replay Same Wave</text>

  <!-- RP_DOOR loop -> RP_BANNER -->
  <path d="M 755 133 L 755 190 L 58 190 L 58 135" fill="none" stroke="#0891B2" stroke-width="1.8" marker-end="url(#r-b)"/>
  <text x="410" y="185" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0E7490">Next Wave (wave + 1) &amp; Revive Fallen 2P Partner (12 HP)</text>

  <!-- RP_BOSS box at bottom -->
  <rect x="190" y="205" width="445" height="54" rx="8" fill="#FEF2F2" stroke="#DC2626" stroke-width="2"/>
  <text x="412" y="224" text-anchor="middle" font-size="10.5" font-weight="800" fill="#B91C1C">RP_BOSS (3'd5) - Wave 6 (FINAL_WAVE): 3-Form Portal Transformation</text>
  <text x="412" y="240" text-anchor="middle" font-size="9" fill="#334155">Form 0 (105 HP) -&gt; 160f Portal -&gt; Form 1 (145 HP) -&gt; 160f Portal -&gt; Form 2 (190 HP, Enraged &lt;=95 HP)</text>
  <text x="412" y="252" text-anchor="middle" font-size="8.5" fill="#991B1B">Anti-Spam: 3 consecutive melee hits =&gt; 220 px Knockback + 60f Stun | Form 2 Defeat =&gt; ST_WIN</text>
  <path d="M 262 133 L 262 203" fill="none" stroke="#DC2626" stroke-width="1.8" marker-end="url(#r-r)"/>
</svg>
"""

SVG_BLOCK_DIAG = """
<svg viewBox="0 0 820 340" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="bd-arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#0284C7"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="816" height="336" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <text x="410" y="23" text-anchor="middle" font-size="12" font-weight="800" fill="#0F172A">HARDWARE SYSTEM BLOCK DIAGRAM - DRAGO-NEXUS V2 (Pure Verilog on Nexys A7-100T @ 25 MHz)</text>

  <!-- Left Inputs Column -->
  <rect x="18" y="38" width="215" height="60" rx="7" fill="#E0F2FE" stroke="#0284C7" stroke-width="1.8"/>
  <text x="125" y="57" text-anchor="middle" font-size="11" font-weight="800" fill="#0369A1">uart_joy_rx.v (C4, 115200)</text>
  <text x="125" y="73" text-anchor="middle" font-size="9" fill="#334155">5-Byte PC Bridge: J1, J2, USB KB</text>
  <text x="125" y="86" text-anchor="middle" font-size="8.5" fill="#0284C7">1-sec Watchdog + b4[6] Quiz Mux</text>

  <rect x="18" y="108" width="215" height="52" rx="7" fill="#EDE9FE" stroke="#7C3AED" stroke-width="1.8"/>
  <text x="125" y="127" text-anchor="middle" font-size="11" font-weight="800" fill="#5B21B6">ps2_keyboard.v (F4, B2)</text>
  <text x="125" y="142" text-anchor="middle" font-size="9" fill="#334155">USB HID / PS2 Scan Code Decoder</text>
  <text x="125" y="154" text-anchor="middle" font-size="8.5" fill="#6D28D9">OR-Merged with UART PC Keyboard</text>

  <rect x="18" y="170" width="215" height="54" rx="7" fill="#DCFCE7" stroke="#16A34A" stroke-width="1.8"/>
  <text x="125" y="189" text-anchor="middle" font-size="11" font-weight="800" fill="#166534">board_io_v2.v + acl_tilt.v</text>
  <text x="125" y="204" text-anchor="middle" font-size="9" fill="#334155">5ms Debounce (BTNs), SW[1:0] Temp</text>
  <text x="125" y="216" text-anchor="middle" font-size="8.5" fill="#15803D">16 LEDs, 2x RGB, 8-Dig 7-Seg, SW[15:11]</text>

  <rect x="18" y="234" width="215" height="44" rx="7" fill="#FEE2E2" stroke="#DC2626" stroke-width="1.8"/>
  <text x="125" y="252" text-anchor="middle" font-size="10.5" font-weight="800" fill="#B91C1C">i2c_temp_adt7420.v (C14/C15)</text>
  <text x="125" y="266" text-anchor="middle" font-size="8.8" fill="#334155">0x4B 100kHz -&gt; temp_fever (+2 DMG)</text>

  <rect x="18" y="286" width="215" height="42" rx="7" fill="#CFFAFE" stroke="#0891B2" stroke-width="1.8"/>
  <text x="125" y="303" text-anchor="middle" font-size="10.5" font-weight="800" fill="#0E7490">pdm_mic_decoder.v (J5/H5)</text>
  <text x="125" y="317" text-anchor="middle" font-size="8.8" fill="#334155">2.5 MHz PDM -&gt; 2P Sonic Shockwave</text>

  <!-- Center Game Engine -->
  <rect x="285" y="55" width="245" height="255" rx="10" fill="#F5F3FF" stroke="#6D28D9" stroke-width="2.5"/>
  <text x="407" y="80" text-anchor="middle" font-size="13.5" font-weight="800" fill="#4C1D95">game_engine_v2.v</text>
  <text x="407" y="98" text-anchor="middle" font-size="10" font-weight="700" fill="#6D28D9">46-Cycle Time-Multiplexed FSM</text>
  <line x1="305" y1="108" x2="510" y2="108" stroke="#DDD6FE" stroke-width="1.5"/>
  <text x="407" y="126" text-anchor="middle" font-size="9.5" fill="#1E293B">- Master Game &amp; Unified Pause FSM</text>
  <text x="407" y="143" text-anchor="middle" font-size="9.5" fill="#1E293B">- Dead Cells KB(1P) / Joy(1P|2P) Detect</text>
  <text x="407" y="160" text-anchor="middle" font-size="9.5" fill="#1E293B">- 6 Weapons + 3-Hit Combo &amp; Nova</text>
  <text x="407" y="177" text-anchor="middle" font-size="9.5" fill="#1E293B">- 16-Enemy AI + Dual Sonic Repel</text>
  <text x="407" y="194" text-anchor="middle" font-size="9.5" fill="#1E293B">- Auto-Aim Gun Vector (<=240 px)</text>
  <text x="407" y="211" text-anchor="middle" font-size="9.5" fill="#1E293B">- Logic Gate Quiz + Sliding Door</text>
  <text x="407" y="228" text-anchor="middle" font-size="9.5" fill="#1E293B">- Stage Evolution (0..3, Cap Stage 3)</text>
  <text x="407" y="245" text-anchor="middle" font-size="9.5" fill="#1E293B">- 3-Form Boss Portal &amp; Knockback</text>
  <text x="407" y="262" text-anchor="middle" font-size="9.5" fill="#1E293B">- Brawlhalla Dynamic Camera &amp; Zoom</text>
  <text x="407" y="280" text-anchor="middle" font-size="9.5" fill="#1E293B">- Out-of-Combat HP Regen (360f/90f)</text>
  <rect x="310" y="288" width="195" height="16" rx="4" fill="#EDE9FE"/>
  <text x="407" y="299" text-anchor="middle" font-size="8.5" font-weight="700" fill="#5B21B6">60 Hz VBlank Update (&lt;0.015% budget)</text>

  <!-- Right Outputs Column -->
  <rect x="578" y="45" width="224" height="106" rx="8" fill="#FCE7F3" stroke="#DB2777" stroke-width="2"/>
  <text x="690" y="66" text-anchor="middle" font-size="11.5" font-weight="800" fill="#9D174D">vga_renderer_v2.v + BRAM</text>
  <text x="690" y="83" text-anchor="middle" font-size="9" fill="#334155">4-Stage Pipeline + Layer Priority</text>
  <text x="690" y="98" text-anchor="middle" font-size="9" fill="#334155">Walk BRAM, 4 Hero Heads, Boss 1&amp;2</text>
  <text x="690" y="113" text-anchor="middle" font-size="9" fill="#334155">Joy/KB Icon LUTs + Dual Sonic Rings</text>
  <text x="690" y="128" text-anchor="middle" font-size="9" font-weight="700" fill="#BE185D">VGA 640x480 @ 60 Hz (12-bit RGB)</text>

  <rect x="578" y="166" width="224" height="66" rx="8" fill="#FFEDD5" stroke="#EA580C" stroke-width="1.8"/>
  <text x="690" y="187" text-anchor="middle" font-size="11.5" font-weight="800" fill="#9A3412">audio_synth_v2.v (A11/D12)</text>
  <text x="690" y="203" text-anchor="middle" font-size="9" fill="#334155">3-Ch+Noise PWM | SW[15:11] Mute/Vol</text>
  <text x="690" y="218" text-anchor="middle" font-size="8.8" fill="#9A3412">4 BRAM Songs (Title/Play/Boss/Win)</text>

  <rect x="578" y="246" width="224" height="64" rx="8" fill="#E2E8F0" stroke="#475569" stroke-width="1.8"/>
  <text x="690" y="267" text-anchor="middle" font-size="11" font-weight="800" fill="#1E293B">Console Feedback</text>
  <text x="690" y="283" text-anchor="middle" font-size="9" fill="#334155">16 LEDs (EXP / Fever / Mic Strobe)</text>
  <text x="690" y="298" text-anchor="middle" font-size="9" fill="#334155">8-Dig 7-Seg: Wave+Score or Temp C</text>

  <!-- Routing arrows -->
  <line x1="233" y1="68" x2="283" y2="110" stroke="#0284C7" stroke-width="1.8" marker-end="url(#bd-arr)"/>
  <line x1="233" y1="134" x2="283" y2="134" stroke="#0284C7" stroke-width="1.8" marker-end="url(#bd-arr)"/>
  <line x1="233" y1="196" x2="283" y2="180" stroke="#0284C7" stroke-width="1.8" marker-end="url(#bd-arr)"/>
  <line x1="233" y1="256" x2="283" y2="230" stroke="#0284C7" stroke-width="1.8" marker-end="url(#bd-arr)"/>
  <line x1="233" y1="306" x2="283" y2="265" stroke="#0284C7" stroke-width="1.8" marker-end="url(#bd-arr)"/>

  <line x1="530" y1="120" x2="576" y2="98" stroke="#0284C7" stroke-width="2" marker-end="url(#bd-arr)"/>
  <line x1="530" y1="195" x2="576" y2="195" stroke="#0284C7" stroke-width="2" marker-end="url(#bd-arr)"/>
  <line x1="530" y1="255" x2="576" y2="275" stroke="#0284C7" stroke-width="2" marker-end="url(#bd-arr)"/>
</svg>
"""

SVG_BRIDGE_DIAG = """
<svg viewBox="0 0 820 265" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="br-arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#0284C7"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="816" height="261" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <text x="410" y="23" text-anchor="middle" font-size="12" font-weight="800" fill="#0F172A">5-BYTE PC-TO-FPGA BRIDGE &amp; PS/2 HYBRID INPUT PIPELINE (joy_bridge.py -&gt; uart_joy_rx.v)</text>

  <rect x="18" y="42" width="165" height="90" rx="8" fill="#EFF6FF" stroke="#2563EB" stroke-width="1.8"/>
  <text x="100" y="63" text-anchor="middle" font-size="11" font-weight="800" fill="#1D4ED8">PC Inputs (WinMM)</text>
  <text x="100" y="81" text-anchor="middle" font-size="9" fill="#334155">- Joy 1 + Joy 2 (USB)</text>
  <text x="100" y="95" text-anchor="middle" font-size="9" fill="#334155">- PC Keyboard (WASD,</text>
  <text x="100" y="108" text-anchor="middle" font-size="9" fill="#334155">  Space, J/K/L/U, 1-4,</text>
  <text x="100" y="121" text-anchor="middle" font-size="9" fill="#334155">  Enter, Esc) @ 100Hz</text>

  <line x1="183" y1="87" x2="210" y2="87" stroke="#0284C7" stroke-width="2" marker-end="url(#br-arr)"/>

  <!-- 5 Byte Packet Layout -->
  <rect x="212" y="38" width="388" height="150" rx="8" fill="#FFFFFF" stroke="#475569" stroke-width="1.6"/>
  <text x="406" y="56" text-anchor="middle" font-size="10.5" font-weight="800" fill="#0F172A">5-Byte Serial Frame @ 115,200 bps (8N1, CLKS_PER_BIT=217)</text>
  <rect x="224" y="65" width="364" height="20" rx="4" fill="#DBEAFE"/>
  <text x="232" y="79" font-size="9" font-weight="700" fill="#1E3A8A" font-family="monospace">B0: [7]=1 | [6]=J1_Shoot | [5:3]=J1_dy | [2:0]=J1_dx</text>
  <rect x="224" y="89" width="364" height="20" rx="4" fill="#E0E7FF"/>
  <text x="232" y="103" font-size="9" font-weight="700" fill="#312E81" font-family="monospace">B1: [7]=0 | [6]=J2_Shoot | [5:3]=J2_dy | [2:0]=J2_dx</text>
  <rect x="224" y="113" width="364" height="20" rx="4" fill="#FEF3C7"/>
  <text x="232" y="127" font-size="9" font-weight="700" fill="#78350F" font-family="monospace">B2: [7]=0 | [6]=Joy_Start | [5:3]=J2_Btn | [2:0]=J1_Btn</text>
  <rect x="224" y="137" width="364" height="20" rx="4" fill="#DCFCE7"/>
  <text x="232" y="151" font-size="9" font-weight="700" fill="#14532D" font-family="monospace">B3: [7]=0 | [6]=KB_Shoot | [5:3]=KB_dy | [2:0]=KB_dx</text>
  <rect x="224" y="161" width="364" height="20" rx="4" fill="#FCE7F3"/>
  <text x="232" y="175" font-size="9" font-weight="700" fill="#831843" font-family="monospace">B4: [7]=0 | [6]=QHit | [5:4]=QSel/(Esc,Ent) | [3]=JSel | KB</text>

  <line x1="600" y1="113" x2="626" y2="113" stroke="#0284C7" stroke-width="2" marker-end="url(#br-arr)"/>

  <rect x="628" y="42" width="174" height="146" rx="8" fill="#F0FDFA" stroke="#0D9488" stroke-width="1.8"/>
  <text x="715" y="63" text-anchor="middle" font-size="11" font-weight="800" fill="#115E59">FPGA UART + PS/2</text>
  <text x="715" y="80" text-anchor="middle" font-size="8.8" fill="#334155">1. Sync on B0[7]==1</text>
  <text x="715" y="94" text-anchor="middle" font-size="8.8" fill="#334155">2. pkt_state 0..4</text>
  <text x="715" y="108" text-anchor="middle" font-size="8.8" fill="#334155">3. 1s Watchdog clears</text>
  <text x="715" y="122" text-anchor="middle" font-size="8.8" fill="#334155">4. OR with PS/2 (F4/B2)</text>
  <text x="715" y="140" text-anchor="middle" font-size="8.8" font-weight="700" fill="#0F766E">Dead Cells Auto-Switch:</text>
  <text x="715" y="154" text-anchor="middle" font-size="8.5" fill="#115E59">KB =&gt; 1P Solo | Joy =&gt; 1P/2P</text>
  <text x="715" y="168" text-anchor="middle" font-size="8.5" fill="#115E59">In-Game: Both drive P1</text>

  <!-- Bottom Hardware Note -->
  <rect x="18" y="202" width="784" height="46" rx="6" fill="#EFF6FF" stroke="#93C5FD" stroke-width="1.2"/>
  <text x="410" y="221" text-anchor="middle" font-size="9.5" font-weight="700" fill="#1E40AF">b4[6] Multiplexing Fix: When KB Quiz keys (1-4) are NOT held, b4[5:4] carries discrete Esc &amp; Enter flags</text>
  <text x="410" y="237" text-anchor="middle" font-size="9" fill="#334155">Direct USB-HID PS/2 keyboards also work standalone on Nexys A7 J5 (PS2_CLK=F4, PS2_DATA=B2) without running the Python bridge.</text>
</svg>
"""

SVG_SUB_FSMS = """
<svg viewBox="0 0 820 220" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <marker id="sf-arr" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#0891B2"/>
    </marker>
    <marker id="sf-r" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#DC2626"/>
    </marker>
  </defs>
  <rect x="2" y="2" width="816" height="216" rx="10" fill="#F8FAFC" stroke="#CBD5E1" stroke-width="1.5"/>
  <text x="410" y="22" text-anchor="middle" font-size="11.5" font-weight="800" fill="#0F172A">DIAGRAM 3.1: SENSOR CONTROLLERS (PDM MICROPHONE SONIC WAVE &amp; ADT7420 THERMAL FEVER)</text>

  <!-- Left: PDM Sonic Wave FSM -->
  <rect x="16" y="34" width="388" height="172" rx="8" fill="#ECFEFF" stroke="#0891B2" stroke-width="1.6"/>
  <text x="210" y="53" text-anchor="middle" font-size="10.5" font-weight="800" fill="#0E7490">pdm_mic_decoder.v -&gt; 2P Sonic Shockwave FSM</text>
  <rect x="28" y="68" width="102" height="58" rx="6" fill="#FFFFFF" stroke="#0891B2" stroke-width="1.5"/>
  <text x="79" y="88" text-anchor="middle" font-size="9.5" font-weight="800" fill="#0E7490">MIC_IDLE</text>
  <text x="79" y="102" text-anchor="middle" font-size="8" fill="#334155">128-sample PDM</text>
  <text x="79" y="114" text-anchor="middle" font-size="8" fill="#334155">M_CLK = 2.5 MHz</text>

  <line x1="130" y1="97" x2="152" y2="97" stroke="#0891B2" stroke-width="1.8" marker-end="url(#sf-arr)"/>

  <rect x="154" y="68" width="110" height="58" rx="6" fill="#CFFAFE" stroke="#0284C7" stroke-width="1.5"/>
  <text x="209" y="86" text-anchor="middle" font-size="9.5" font-weight="800" fill="#0369A1">ROAR_LATCH</text>
  <text x="209" y="100" text-anchor="middle" font-size="8" fill="#334155">raw_dev &gt;= 28</text>
  <text x="209" y="113" text-anchor="middle" font-size="8" fill="#334155">Hold ~320 ms</text>

  <line x1="264" y1="97" x2="286" y2="97" stroke="#0891B2" stroke-width="1.8" marker-end="url(#sf-arr)"/>

  <rect x="288" y="68" width="104" height="58" rx="6" fill="#FCE7F3" stroke="#DB2777" stroke-width="1.5"/>
  <text x="340" y="86" text-anchor="middle" font-size="9.5" font-weight="800" fill="#9D174D">SONIC_2P</text>
  <text x="340" y="100" text-anchor="middle" font-size="8" fill="#334155">sonic_wave_t = 24f</text>
  <text x="340" y="113" text-anchor="middle" font-size="8" fill="#9D174D">R: 100/140/180 px</text>

  <path d="M 340 126 L 340 148 L 79 148 L 79 128" fill="none" stroke="#0891B2" stroke-width="1.5" stroke-dasharray="3 3" marker-end="url(#sf-arr)"/>
  <text x="210" y="164" text-anchor="middle" font-size="8.5" font-weight="700" fill="#0E7490">V5 Fix: Emits Cyan Ring (P1) &amp; Pink Ring (P2)</text>
  <text x="210" y="178" text-anchor="middle" font-size="8.3" fill="#334155">+ Repels Enemies (+/-8 px/f) from nearest active player!</text>
  <text x="210" y="193" text-anchor="middle" font-size="8" fill="#475569">LEDs[15:0] strobe 16'hFFFF/0000 + RGB LED17 pulses</text>

  <!-- Right: ADT7420 I2C 10-State FSM -->
  <rect x="416" y="34" width="388" height="172" rx="8" fill="#FEF2F2" stroke="#DC2626" stroke-width="1.6"/>
  <text x="610" y="53" text-anchor="middle" font-size="10.5" font-weight="800" fill="#B91C1C">i2c_temp_adt7420.v -&gt; 10-State I2C Master &amp; Fever</text>
  <rect x="428" y="68" width="110" height="58" rx="6" fill="#FFFFFF" stroke="#DC2626" stroke-width="1.5"/>
  <text x="483" y="86" text-anchor="middle" font-size="9.5" font-weight="800" fill="#B91C1C">S_IDLE (0)</text>
  <text x="483" y="100" text-anchor="middle" font-size="8" fill="#334155">Poll every 100 ms</text>
  <text x="483" y="113" text-anchor="middle" font-size="8" fill="#334155">(2,500,000 clks)</text>

  <line x1="538" y1="97" x2="558" y2="97" stroke="#DC2626" stroke-width="1.8" marker-end="url(#sf-r)"/>

  <rect x="560" y="68" width="118" height="58" rx="6" fill="#FFEDD5" stroke="#EA580C" stroke-width="1.5"/>
  <text x="619" y="86" text-anchor="middle" font-size="9.2" font-weight="800" fill="#9A3412">I2C READ (1..8)</text>
  <text x="619" y="100" text-anchor="middle" font-size="8" fill="#334155">START -&gt; WR 0x4B</text>
  <text x="619" y="113" text-anchor="middle" font-size="8" fill="#334155">RD MSB + RD LSB</text>

  <line x1="678" y1="97" x2="696" y2="97" stroke="#DC2626" stroke-width="1.8" marker-end="url(#sf-r)"/>

  <rect x="698" y="68" width="94" height="58" rx="6" fill="#FEE2E2" stroke="#B91C1C" stroke-width="1.5"/>
  <text x="745" y="86" text-anchor="middle" font-size="9.2" font-weight="800" fill="#991B1B">S_UPDATE (9)</text>
  <text x="745" y="100" text-anchor="middle" font-size="8" fill="#334155">Latch baseline_c</text>
  <text x="745" y="113" text-anchor="middle" font-size="8" fill="#B91C1C">Compute temp_c</text>

  <path d="M 745 126 L 745 148 L 483 148 L 483 128" fill="none" stroke="#DC2626" stroke-width="1.5" stroke-dasharray="3 3" marker-end="url(#sf-r)"/>
  <text x="610" y="164" text-anchor="middle" font-size="8.5" font-weight="700" fill="#B91C1C">eff_temp_fever = (temp_c &gt;= baseline + 1C) || (temp_c &gt;= 35C) || SW[0]</text>
  <text x="610" y="178" text-anchor="middle" font-size="8.3" fill="#334155">Grants +2 Bonus Melee DMG + Knight-Rider Flame LEDs</text>
  <text x="610" y="193" text-anchor="middle" font-size="8" fill="#475569">SW[1]=ON shows live XX.X C on 7-Seg | SW[15:11]=Audio Mute/BGM/SFX/Vol</text>
</svg>
"""


def build_diagram_pngs():
    for fname, svg_code, h in [
        ("diag_block.png", SVG_BLOCK_DIAG, 740),
        ("diag_fsm.png", SVG_MASTER_FSM + "<div style='height:14px'></div>" + SVG_ROOM_FSM, 1140),
        ("diag_bridge.png", SVG_BRIDGE_DIAG, 600),
    ]:
        tmp_html = os.path.join(DIAG_DIR, fname.replace(".png", ".html"))
        out_png = os.path.join(DIAG_DIR, fname)
        html = f"""<!DOCTYPE html>
<html><head><meta charset="utf-8"><style>
body {{ margin:0; padding:16px; background:#0D1117; display:flex; flex-direction:column; align-items:center; justify-content:flex-start; font-family:'Segoe UI',sans-serif; }}
.card {{ background:#FFFFFF; border-radius:14px; padding:14px; width:1480px; box-sizing:border-box; }}
svg {{ width:100%; height:auto; display:block; }}
</style></head><body><div class="card">{svg_code}</div></body></html>"""
        with open(tmp_html, "w", encoding="utf-8") as f:
            f.write(html)
        html_to_png(tmp_html, out_png, width=1540, height=h)


def build_fsm_specification():
    html_path = os.path.join(DOC_DIR, "VeePire_FSM_Specification.html")
    pdf_path = os.path.join(DOC_DIR, "VeePire_FSM_Specification.pdf")

    html = f"""<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<title>VeePire Survivors - Hardware Architecture &amp; FSM Specification</title>
<style>
  @page {{ size: A4; margin: 14mm 14mm 15mm 14mm; }}
  * {{ box-sizing: border-box; }}
  body {{
    font-family: 'Segoe UI', 'Noto Sans Thai', 'Leelawadee UI', sans-serif;
    color: #1E293B; line-height: 1.52; font-size: 10.2pt; margin: 0; padding: 0;
  }}
  .hero {{
    background: linear-gradient(135deg, #0F172A 0%, #1E293B 55%, #1E3A8A 100%);
    color: #FFFFFF; padding: 20px 24px; border-radius: 12px; margin-bottom: 14px;
  }}
  .hero .kicker {{ color: #38BDF8; font-size: 9pt; font-weight: 800; letter-spacing: 1px; text-transform: uppercase; }}
  .hero h1 {{ margin: 4px 0 6px; font-size: 20pt; font-weight: 900; }}
  .hero .meta {{ color: #CBD5E1; font-size: 9pt; }}
  .intro {{ margin: 8px 0 14px; color: #334155; font-size: 10pt; }}
  h2 {{
    display: flex; align-items: center; gap: 8px;
    font-size: 12.5pt; color: #0F172A; border-left: 5px solid #2563EB;
    padding-left: 10px; margin: 16px 0 8px; page-break-after: avoid;
  }}
  .diag-box {{
    border: 1px solid #CBD5E1; border-radius: 10px; padding: 8px; background: #FFFFFF;
    margin: 8px 0 12px; page-break-inside: avoid;
  }}
  .diag-svg {{ width: 100%; height: auto; display: block; }}
  code {{
    background: #F1F5F9; color: #0F172A; padding: 1px 5px; border-radius: 4px;
    font-family: 'Consolas', monospace; font-size: 9pt; font-weight: 700;
  }}
  table {{
    width: 100%; border-collapse: collapse; margin: 8px 0 14px; font-size: 9.2pt;
    page-break-inside: auto;
  }}
  tr {{ page-break-inside: avoid; }}
  th {{
    background: #F1F5F9; color: #0F172A; font-weight: 800; text-align: left;
    padding: 7px 9px; border: 1px solid #CBD5E1;
  }}
  td {{ padding: 6px 9px; border: 1px solid #E2E8F0; vertical-align: top; }}
  .badge {{
    display: inline-block; padding: 2px 6px; border-radius: 5px;
    font-family: 'Consolas', monospace; font-size: 8.5pt; font-weight: 700;
    background: #E2E8F0; color: #0F172A;
  }}
  .callout {{
    background: #EFF6FF; border-left: 4px solid #2563EB; padding: 10px 14px;
    border-radius: 6px; margin: 10px 0; font-size: 9.5pt; page-break-inside: avoid;
  }}
  .page-break {{ page-break-before: always; }}
</style>
</head>
<body>

<div class="hero">
  <div class="kicker">HARDWARE ARCHITECTURE &amp; FINITE STATE MACHINE (FSM) SPECIFICATION</div>
  <h1>VeePire Survivors: DRAGO-NEXUS V2 (FPGA Edition)</h1>
  <div class="meta">Target Platform: Digilent Nexys A7-100T (XC7A100T-1CSG324C) | Clock Domain: 25 MHz VGA Pixel Clock (clk25) | Tick Rate: 60 Hz VBlank</div>
</div>

<p class="intro">
  เอกสารนี้สรุปโครงสร้าง Finite State Machine (FSM) ทั้งหมดของเกม <b>VeePire Survivors</b> ที่พัฒนาด้วย Pure Verilog HDL บนชิป FPGA Artix-7 โดยไม่มี CPU ควบคุม ครอบคลุมตั้งแต่ Master Game Lifecycle FSM, Dead Cells Input Auto-Detection, Room &amp; Logic Gate Quiz Sub-FSM, วิวัฒนาการชุด 4 ขั้น (stage 0..3), Boss Ajarn_V 3 ร่าง, PDM Microphone 2P Sonic Wave FSM, ADT7420 I2C Thermal Fever FSM, ไปป์ไลน์ UART/PS2 และไปป์ไลน์คำนวณ 46-Cycle Time-Multiplexing
</p>

<h2>1. Master Game State Machine (<code>game_state [2:0]</code> &amp; <code>paused</code>)</h2>
<p>ควบคุมวงจรชีวิตหลักของเกมในโมดูล <code>game_engine_v2.v</code> ทำงานร่วมกับรีจิสเตอร์ <code>paused</code>, <code>help_page [1:0]</code> และ <code>control_mode [1:0]</code></p>

<div class="diag-box">{SVG_MASTER_FSM}</div>

<table>
  <thead>
    <tr><th style="width:17%">State Register</th><th style="width:10%">Encoding</th><th style="width:35%">Behavior Inside State</th><th style="width:38%">Next-State Logic &amp; Transitions</th></tr>
  </thead>
  <tbody>
    <tr><td><b>ST_TITLE</b></td><td><span class="badge">3'd0</span></td><td>แสดงหน้าแรกเลือกตัวละคร/อาวุธ 6 แบบ (<code>BTNL/R/C/U/D</code>), ปรับ 1P/2P (เฉพาะจอย) หรือเปิดหน้าสอน <code>help_page 1..3</code></td><td>
      &bull; แตะคีย์บอร์ดใดๆ &rarr; <code>control_mode[0]=1, control_mode[1]=0</code> (บังคับ 1P)<br>
      &bull; แตะจอย &rarr; <code>control_mode[0]=0</code>, D-Pad สลับ 1P/2P<br>
      &bull; กด Select/Esc &rarr; เปิด/ปิด <code>help_page 1..3</code><br>
      &bull; กด Fire / Space / J (เมื่อ <code>help_page==0</code>) &rarr; <b>ST_PLAY</b>
    </td></tr>
    <tr><td><b>ST_CUTSCENE</b></td><td><span class="badge">3'd1</span></td><td>สถานะเชื่อมเข้าเกมหลังเริ่ม (Initial Cutscene Hook)</td><td>อัตโนมัติในรอบถัดไป &rarr; <b>ST_PLAY</b></td></tr>
    <tr><td><b>ST_PLAY</b></td><td><span class="badge">3'd2</span></td><td>เล่นเกมเต็มรูปแบบผ่าน <code>room_phase [2:0]</code> และ 46-Cycle Engine; ทั้ง J1 และ KB บังคับ P1 ได้พร้อมกัน</td><td>
      &bull; <code>!paused &amp;&amp; (joy_pause || kb_start || kb_esc)</code> (นอก Quiz/Morph) &rarr; <code>paused&lt;=1, help_page&lt;=1</code><br>
      &bull; <code>!p1_alive &amp;&amp; !p2_alive</code> &rarr; <b>ST_LOSE</b> (<code>end_lockout=90</code>)<br>
      &bull; <code>boss_kind==2 &amp;&amp; boss_hp==0 &amp;&amp; boss_trans_t==0</code> &rarr; <b>ST_WIN</b> (<code>end_lockout=90</code>)
    </td></tr>
    <tr><td><b>PAUSED (Overlay)</b></td><td><span class="badge">paused=1</span></td><td>หยุด <code>world_tick</code> และแช่แข็ง <code>step_state=0</code>; แสดง Unified 3-Page Pause Guide พร้อมปุ่ม <code>[STR]/[ENT] RESUME</code></td><td>
      &bull; <code>joy_pause / kb_start / kb_esc</code> &rarr; <code>paused&lt;=0, help_page&lt;=0</code> (Resume)<br>
      &bull; Left/Right/Up/Down &rarr; เลื่อน <code>help_page 1 &harr; 2 &harr; 3</code><br>
      &bull; <code>joy_select</code> &rarr; รีเซ็ตเกมกลับ <b>ST_TITLE</b>
    </td></tr>
    <tr><td><b>ST_WIN / ST_LOSE</b></td><td><span class="badge">3'd3 / 3'd4</span></td><td>แสดงหน้า Victory หรือ Game Over พร้อมเพลงจบ; หน่วงกันกดพลาด <code>end_lockout = 90</code> เฟรม (1.5s)</td><td>หลัง <code>end_lockout == 0</code>: Start/Fire &rarr; Retry <b>ST_PLAY</b>; Left/Right &rarr; <b>ST_TITLE</b></td></tr>
  </tbody>
</table>

<div class="page-break"></div>

<h2>2. Room Progression &amp; Logic Gate Quiz Sub-FSM (<code>room_phase [2:0]</code>)</h2>
<p>จัดการการเล่นภายในห้องแต่ละ Wave (<code>wave 1..6</code>, <code>FINAL_WAVE = 6</code>) รวมถึงระบบควิซประตูดิจิทัลลอจิก</p>

<div class="diag-box">{SVG_ROOM_FSM}</div>

<table>
  <thead>
    <tr><th style="width:17%">Sub-State</th><th style="width:10%">Encoding</th><th style="width:35%">Action &amp; Counters</th><th style="width:38%">Transition Rules</th></tr>
  </thead>
  <tbody>
    <tr><td><b>RP_BANNER</b></td><td><span class="badge">3'd0</span></td><td>ขึ้นแบนเนอร์ Wave และล็อกประตู (<code>wave_banner_t=90</code>, <code>door_slam_t=45</code>); หาก 2P และเพื่อนล้มจะชุบเป็น <code>12 HP</code></td><td>เมื่อ <code>wave_banner_t == 0</code> สปอว์นศัตรูกลุ่มแรก &rarr; <b>RP_FIGHT</b> (Wave 1-5) หรือเตรียม <b>RP_BOSS</b> (Wave 6)</td></tr>
    <tr><td><b>RP_FIGHT</b></td><td><span class="badge">3'd1</span></td><td>ต่อสู้ศัตรูชุดย่อย: W1=3&times;10 (30), W2=4&times;12 (48), W3=4&times;14 (56), W4=5&times;15 (75), W5=5&times;16 (80 ตัว)</td><td>เมื่อศัตรูใน Sub-wave หมด: ถ้ามี Sub-wave เหลือเรียกชุดถัดไป / ถ้าหมดแล้ว &rarr; <b>RP_CLEAR</b></td></tr>
    <tr><td><b>RP_CLEAR</b></td><td><span class="badge">3'd2</span></td><td>ลูกศรสีเหลืองกะพริบนำทางไปประตูด้านขวาของห้อง</td><td>ผู้เล่นเข้าเขตประตู (<code>x&ge;516, y=176..272</code>) &rarr; สุ่มประตูตรรกะ 0..5 (<code>quiz_lockout=30</code>) &rarr; <b>RP_QUIZ</b></td></tr>
    <tr><td><b>RP_QUIZ</b></td><td><span class="badge">3'd3</span></td><td>โจทย์ Gate (AND, OR, NOT, NAND, NOR, XOR) ตอบด้วยปุ่ม <code>1-4</code> หรือเลือกช้อยส์; ผิดขึ้น <code>"F" CAUTION: GO RETAKE !!</code> นาน 105f</td><td>
      &bull; ตอบถูก: ถ้า <code>stage &lt; 2'd3</code> เลื่อน <code>stage+1</code> + <code>outfit_cut_t=120</code> (ชุดทอง stage 3 จะไม่ฉายซ้ำ) &rarr; <b>RP_DOOR</b><br>
      &bull; ตอบผิดครบ 105f: รีเซ็ต <code>wave_sub=0</code>, ย้ายผู้เล่นไปซ้าย &rarr; <b>RP_BANNER</b> (เล่นด่านเดิมซ้ำ)
    </td></tr>
    <tr><td><b>RP_DOOR</b></td><td><span class="badge">3'd4</span></td><td>ประตูสไลด์เปิดออก (<code>door_slide 0..31</code>) และแสดง Spotlight เปลี่ยนชุดเมื่อ <code>outfit_cut_t &gt; 0</code></td><td>เมื่อเดินผ่านประตู (<code>x&ge;534, y=184..264</code>) &rarr; <code>wave++</code>, รีเซ็ตตำแหน่ง &rarr; <b>RP_BANNER</b></td></tr>
    <tr><td><b>RP_BOSS</b></td><td><span class="badge">3'd5</span></td><td>เฉพาะ Wave 6: บอส <b>Ajarn_V</b> 3 ร่าง (105 &rarr; 145 &rarr; 190 HP); Anti-Spam Knockback 220 px + 60f stun เมื่อฟันรัว &ge;3 ครั้ง</td><td>
      &bull; ร่าง 0 / 1 ตาย: <code>boss_trans_t=160</code> เปิด Portal งอกร่างถัดไป<br>
      &bull; ร่าง 2 ตาย &amp; <code>boss_trans_t==0</code> &rarr; <b>ST_WIN</b>
    </td></tr>
  </tbody>
</table>

<h2>3. Sensor Controller FSMs (PDM Microphone 2P Sonic Wave &amp; ADT7420 I2C)</h2>
<div class="diag-box">{SVG_SUB_FSMS}</div>

<div class="page-break"></div>

<h2>4. System Architecture &amp; PC-to-FPGA UART + PS/2 Input FSMs</h2>
<div class="diag-box">{SVG_BLOCK_DIAG}</div>
<div class="diag-box">{SVG_BRIDGE_DIAG}</div>

<h2>5. Hardware Time-Multiplexed Execution Pipeline (<code>step_state [5:0]</code>)</h2>
<p>เพื่อหลีกเลี่ยง Critical Path บน Artix-7 ที่ <code>25 MHz</code> โมดูล <code>game_engine_v2.v</code> แบ่งการคำนวณฟิสิกส์ 16 ศัตรูออกเป็น <b>46 รอบสัญญาณนาฬิกาต่อเฟรม 60 Hz</b> (ใช้เวลารวมเพียง <code>46 / 416,666 = 0.011%</code> ของคาบเวลาเฟรม VGA) ก่อนส่งให้ <b>4-Stage Display Pipeline</b> ของ <code>vga_renderer_v2.v</code>:</p>

<table>
  <thead>
    <tr><th style="width:16%"><code>step_state</code></th><th style="width:20%">Pipeline Stage</th><th style="width:64%">Exact Operations Executed per Clock Cycle</th></tr>
  </thead>
  <tbody>
    <tr><td><span class="badge">6'd0</span></td><td><b>Wait VBlank Tick</b></td><td>รับอินพุตจาก <code>j1/j2/uart_kb/ps2</code>, นับเวลา <code>combo_timer, dash_cd, nova_cd, outfit_cut_t, sonic_wave_t</code>, ฟื้นเลือด Out-of-Combat (<code>360f</code> delay, <code>+1 HP/90f</code>), สปอว์น Slash / Bullet / Nova</td></tr>
    <tr><td><span class="badge">6'd1..6'd18</span></td><td><b>P1 Collision</b></td><td>ตรวจสอบการชน Tilemap 5 จุดของ Player 1 ด้วย Dual-Port Map BRAM และอัปเดตตำแหน่ง <code>(px, py)</code> + Dash</td></tr>
    <tr><td><span class="badge">6'd20..6'd37</span></td><td><b>P2 Collision</b></td><td>ตรวจสอบการชน Tilemap 5 จุดของ Player 2 (ทำงานเฉพาะเมื่อ <code>p2_active == 1</code>)</td></tr>
    <tr><td><span class="badge">6'd40</span></td><td><b>Camera &amp; Pet</b></td><td>คำนวณ <code>view_w (320..520)</code> แบบ Brawlhalla Dynamic Zoom, ตามกล้องเรียบ <code>1..8 px/f</code>, อัปเดต Pet Bolt, Spark Particles และ Sky Drops</td></tr>
    <tr><td><span class="badge">6'd41</span></td><td><b>Gems &amp; EXP Drops</b></td><td>ดูด Gem 12 ช่องในระยะ <code>76 px</code>, เก็บ Gem (<code>+5 EXP, +25 pts</code>) / Heart (<code>+8 HP, +50 pts</code>) / Sky Supply (<code>+100 pts</code>), รีฟูลเมื่อ EXP เต็ม 60</td></tr>
    <tr><td><span class="badge">6'd42</span></td><td><b>Lock-On Prep</b></td><td>เตรียมตัวแปรค้นหาเป้าใกล้สุด: Melee Lock-on &le; <code>72 px</code>, Gun Auto-Aim &le; <code>240 px</code></td></tr>
    <tr><td><span class="badge">6'd43</span> (16 clks)</td><td><b>Enemy TDM Loop</b></td><td>ประมวลผลศัตรูทีละตัว <code>e_idx = 0..15</code>: เช็ค Sonic Wave Repel (2P Nearest), เดินไล่, ยิงกระสุน, ตรวจ Hitbox ดาบ/ปืน/Pet/Orbit Blades (1 ตัว/clk)</td></tr>
    <tr><td><span class="badge">6'd44</span></td><td><b>Boss AI &amp; Resolve</b></td><td>คำนวณเวกเตอร์นำวิถีกระสุนปืน, Boss Ajarn_V 3-Form AI &amp; Anti-Spam Knockback, หักเลือดผู้เล่นเมื่อชน, ตรวจชนะ/แพ้/ผ่านด่าน แล้วคืนค่า <code>step_state &lt;= 6'd0</code></td></tr>
  </tbody>
</table>

<div class="callout">
  <b>VGA 4-Stage Renderer Pipeline (<code>vga_renderer_v2.v</code>):</b><br>
  <b>Stage -1</b> คำนวณ Zoom/Camera Offset &rarr; <b>Stage 0</b> คำนวณที่อยู่ BRAM + ฮาร์ดแวร์ตรวจ UI Bounds &rarr; <b>Stage 1</b> อ่านค่าสี Tilemap, Walk Animation BRAM (16 frames/stage), Hero Heads (4 คน), Weapons (6 แบบ) &rarr; <b>Stage 2</b> จัดลำดับความสำคัญเลเยอร์ (UI Banner/Guide Overlay &gt; Popups &gt; Quiz &gt; Hero/Boss &gt; Sonic Rings &gt; Map) &rarr; <b>Stage 3</b> แปลง Palette เป็นสัญญาณ VGA RGB444 12-bit (<code>VGA_R/G/B</code>) ปราศจาก Timing Violation
</div>

<div class="page-break"></div>

<h2>6. V6 Switch Reassignment &amp; Hardware Audio Mixer (<code>SW[15:11]</code> &amp; <code>SW[1:0]</code>)</h2>
<p style="margin:2px 0 6px;">จัดกลุ่มสวิตช์บนบอร์ด Nexys A7-100T ใหม่ทั้งหมด โดยยกชุด MSB <code>SW[15:11]</code> ให้ระบบเสียงฮาร์ดแวร์โดยเฉพาะ และย้ายฟังก์ชัน Thermal / Debug มาไว้ที่ LSB <code>SW[1:0]</code>:</p>
<table style="margin:4px 0 8px; font-size:8.6pt;">
  <thead>
    <tr><th style="width:15%">Switch Pin</th><th style="width:24%">RTL Module / Signal</th><th style="width:61%">Hardware Behavior</th></tr>
  </thead>
  <tbody>
    <tr><td><span class="badge">SW[15]</span></td><td><code>audio_sw[4]</code> (Master Mute)</td><td>ปิดแอมป์เสียงบนบอร์ด (<code>AUD_SD = !rst &amp;&amp; !SW[15]</code>) และเคลียร์ <code>pwm_out = 0</code>; ติด <code>LED17_R</code> เมื่อ Mute</td></tr>
    <tr><td><span class="badge">SW[14]</span></td><td><code>audio_sw[3]</code> (BGM Mute)</td><td>ปิดเฉพาะเสียงเพลงพื้นหลัง 3-Voice + Noise BRAM (SFX ยังดัง); ติด <code>LED17_G</code> เมื่อ BGM ทำงาน</td></tr>
    <tr><td><span class="badge">SW[13]</span></td><td><code>audio_sw[2]</code> (SFX Mute)</td><td>ปิดเฉพาะเสียง SFX Priority Encoder ทั้งหมด (BGM ยังเล่น); ติด <code>LED17_B</code> เมื่อ SFX ทำงาน</td></tr>
    <tr><td><span class="badge">SW[12:11]</span></td><td><code>audio_sw[1:0]</code> (Master Vol)</td><td>ลดทอนแอมพลิจูดฮาร์ดแวร์ด้วย Binary Right-Shift บน <code>mix_raw</code>: <code>00=100%, 01=50%, 10=25%, 11=12.5%</code></td></tr>
    <tr><td><span class="badge">SW[0]</span></td><td><code>eff_temp_fever</code> (Top)</td><td>จำลอง/บังคับเข้าโหมด Thermal Fever (<code>temp_fever | SW[0]</code>) เพิ่มโบนัส +2 Melee DMG และไฟ Flame LEDs</td></tr>
    <tr><td><span class="badge">SW[1]</span></td><td><code>show_temp</code> (Board IO)</td><td>สลับหน้าจอ 7-Segment 4 หลักซ้ายให้แสดงอุณหภูมิสดจาก ADT7420 เป็นหน่วย <code>XX.X C</code></td></tr>
  </tbody>
</table>

<h2>7. Ranking Inventory: Input Channels (8) &amp; Hardware Sub-Features (18)</h2>
<p style="margin:2px 0 6px;">ตารางสรุปจำนวนช่องทางอินพุตและระบบย่อยที่สร้างด้วย Pure Verilog RTL บนชิป Artix-7 เพื่อใช้ประกอบการประเมินผล:</p>
<div style="display:grid; grid-template-columns: 1fr 1.25fr; gap:10px; align-items:start;">
  <table style="margin:2px 0; font-size:8.4pt;">
    <thead><tr><th style="width:12%">#</th><th>Hardware / Hybrid Input Channels (8 ช่องทาง)</th></tr></thead>
    <tbody>
      <tr><td><b>1</b></td><td><b>Twin USB Gamepads</b> (J1 + J2) ผ่าน UART <code>C4</code> @ <code>115,200 bps</code></td></tr>
      <tr><td><b>2</b></td><td><b>PC Keyboard Bridge</b> (<code>joy_bridge.py</code> 5-Byte Serial + <code>b4[6]</code> Mux)</td></tr>
      <tr><td><b>3</b></td><td><b>Direct USB-HID / PS/2 Keyboard</b> (<code>PS2_CLK F4 / PS2_DATA B2</code>)</td></tr>
      <tr><td><b>4</b></td><td><b>5 On-Board Pushbuttons</b> (<code>BTNC/U/D/L/R</code> + 5 ms Debouncer)</td></tr>
      <tr><td><b>5</b></td><td><b>16 Slide Switches</b> (<code>SW[15:11]</code> Audio Mixer, <code>SW[1:0]</code> Temp/Fever)</td></tr>
      <tr><td><b>6</b></td><td><b>ADT7420 I2C Temp Sensor</b> (<code>C14/C15</code>, <code>0x4B</code> @ 100 kHz)</td></tr>
      <tr><td><b>7</b></td><td><b>ADMP421 PDM Microphone</b> (<code>J5/H5/F5</code> @ 2.50 MHz Sampling)</td></tr>
      <tr><td><b>8</b></td><td><b>ADXL362 SPI Accelerometer</b> (<code>acl_tilt.v</code>) + <code>CPU_RESETN (C12)</code></td></tr>
    </tbody>
  </table>
  <table style="margin:2px 0; font-size:8.4pt;">
    <thead><tr><th style="width:10%">#</th><th>Real Hardware Sub-Features (18 ระบบย่อย)</th></tr></thead>
    <tbody>
      <tr><td><b>1–3</b></td><td>Dead Cells Auto-Input (KB=1P, Joy=1P/2P) &bull; In-game Hybrid KB+J1 &bull; Unified 3-Page Guide (Title/Pause w/ live Resume key)</td></tr>
      <tr><td><b>4–6</b></td><td>2P Co-op + Wave Partner Revive (12 HP) &bull; 6 Melee Weapons &bull; 3-Hit Combo + 360&deg; Nova</td></tr>
      <tr><td><b>7–9</b></td><td>Auto-Aim Plasma Gun (&le;240 px) &bull; Shadow Dash i-frames &bull; 4-Stage KMUTT Armor (Skip Stage 3 Repeat Cutscene)</td></tr>
      <tr><td><b>10–12</b></td><td>Companion Pet Bolt &amp; Dual Orbit Blades &bull; Brawlhalla Dynamic Camera Zoom (320..520) &bull; 6-Gate Logic Quiz + Retake Reset</td></tr>
      <tr><td><b>13–15</b></td><td>2P PDM Sonic Shockwave (Cyan/Pink Rings) &bull; ADT7420 Thermal Fever (+2 DMG) &bull; Out-of-Combat Regen (360f/90f) + Magnetic Gems</td></tr>
      <tr><td><b>16–18</b></td><td>3-Form Portal Boss Ajarn_V (220px Anti-Spam) &bull; SW[15:11] Audio Mixer + 4 BRAM Songs &bull; 46-Cycle TDM + VGA 4-Stage Pipeline + LEDs/7-Seg</td></tr>
    </tbody>
  </table>
</div>

<div class="page-break"></div>

<h2>8. Feature-by-Feature FSM Specification (Mandatory 1–2 &amp; Expansion 3.1–3.16)</h2>
<p>นอกเหนือจาก Master FSM และ Room Sub-FSM แล้ว โครงงานยังออกแบบวงจร Finite State Machine แยกเฉพาะสำหรับ <b>ฟีเจอร์บังคับ (Feature 1–2)</b> และ <b>ฟีเจอร์เสริมอันดับ Ranking (Feature 3.1–3.16)</b> รวมทั้งหมด <b>18 Sub-FSMs</b> ที่ทำงานจริงใน Pure Verilog RTL:</p>

<div class="diag-box">
  <svg viewBox="0 0 820 195" class="diag-svg" xmlns="http://www.w3.org/2000/svg">
    <defs>
      <marker id="ff-b" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#0284C7"/></marker>
      <marker id="ff-o" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse"><path d="M 0 1 L 10 5 L 0 9 z" fill="#D97706"/></marker>
    </defs>
    <rect x="2" y="2" width="402" height="191" rx="8" fill="#F0F9FF" stroke="#0284C7" stroke-width="1.6"/>
    <text x="203" y="20" text-anchor="middle" font-size="10.5" font-weight="800" fill="#0369A1">FEATURE 1: Movable Player &amp; Arena Combat FSM</text>
    <rect x="14" y="34" width="84" height="44" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.5"/>
    <text x="56" y="52" text-anchor="middle" font-size="8.8" font-weight="800" fill="#0F172A">COMBO 0</text>
    <text x="56" y="66" text-anchor="middle" font-size="7.8" fill="#475569">Slash 1 (reach)</text>
    <line x1="98" y1="56" x2="118" y2="56" stroke="#0284C7" stroke-width="1.6" marker-end="url(#ff-b)"/>
    <rect x="120" y="34" width="84" height="44" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.5"/>
    <text x="162" y="52" text-anchor="middle" font-size="8.8" font-weight="800" fill="#0F172A">COMBO 1</text>
    <text x="162" y="66" text-anchor="middle" font-size="7.8" fill="#475569">Slash 2 (lunge)</text>
    <line x1="204" y1="56" x2="224" y2="56" stroke="#0284C7" stroke-width="1.6" marker-end="url(#ff-b)"/>
    <rect x="226" y="34" width="166" height="44" rx="6" fill="#FEF3C7" stroke="#D97706" stroke-width="1.6"/>
    <text x="309" y="52" text-anchor="middle" font-size="8.8" font-weight="800" fill="#B45309">COMBO 2: 360&deg; NOVA</text>
    <text x="309" y="66" text-anchor="middle" font-size="7.8" fill="#92400E">+12 px reach, +1 DMG finisher</text>
    <rect x="14" y="96" width="176" height="84" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.3"/>
    <text x="102" y="113" text-anchor="middle" font-size="8.8" font-weight="800" fill="#0369A1">Shadow Dash &amp; 5-Pt Collision</text>
    <text x="102" y="128" text-anchor="middle" font-size="7.8" fill="#334155">IDLE -&gt; DASHING (dash_timer=8f, x4 spd)</text>
    <text x="102" y="142" text-anchor="middle" font-size="7.8" fill="#334155">-&gt; COOLDOWN (dash_cd=36f, i-frames)</text>
    <text x="102" y="156" text-anchor="middle" font-size="7.8" fill="#0369A1">step 1..18 (P1) / 20..37 (P2) BRAM Check</text>
    <text x="102" y="170" text-anchor="middle" font-size="7.6" fill="#475569">6 Weapons: SWORD,SABER,FISTS,AXE,SPEAR,SCYTH</text>
    <rect x="200" y="96" width="192" height="84" rx="6" fill="#FFFFFF" stroke="#0284C7" stroke-width="1.3"/>
    <text x="296" y="113" text-anchor="middle" font-size="8.8" font-weight="800" fill="#0369A1">Auto-Aim Plasma Gun FSM</text>
    <text x="296" y="128" text-anchor="middle" font-size="7.8" fill="#334155">step 42: Scan nearest target &lt;= 240 px</text>
    <text x="296" y="142" text-anchor="middle" font-size="7.8" fill="#334155">step 43: Compute Lock Vector (d1_m)</text>
    <text x="296" y="156" text-anchor="middle" font-size="7.8" fill="#334155">step 44: Spawn pb_active[0..7] bullet</text>
    <text x="296" y="170" text-anchor="middle" font-size="7.6" fill="#475569">Enemy Hit -&gt; Spark Particle + SFX + Score</text>

    <rect x="416" y="2" width="402" height="191" rx="8" fill="#FFFBEB" stroke="#D97706" stroke-width="1.6"/>
    <text x="617" y="20" text-anchor="middle" font-size="10.5" font-weight="800" fill="#B45309">FEATURE 2: Sprite Evolutions &amp; Skins FSM</text>
    <rect x="428" y="34" width="84" height="52" rx="6" fill="#FFFFFF" stroke="#64748B" stroke-width="1.5"/>
    <text x="470" y="51" text-anchor="middle" font-size="8.5" font-weight="800">STAGE 0</text>
    <text x="470" y="64" text-anchor="middle" font-size="7.6" fill="#334155">Student (W1)</text>
    <text x="470" y="76" text-anchor="middle" font-size="7.4" fill="#64748B">30px / 2 DMG</text>
    <line x1="512" y1="60" x2="526" y2="60" stroke="#D97706" stroke-width="1.5" marker-end="url(#ff-o)"/>
    <rect x="528" y="34" width="84" height="52" rx="6" fill="#EFF6FF" stroke="#2563EB" stroke-width="1.5"/>
    <text x="570" y="51" text-anchor="middle" font-size="8.5" font-weight="800" fill="#1D4ED8">STAGE 1</text>
    <text x="570" y="64" text-anchor="middle" font-size="7.6" fill="#334155">CPE Shop</text>
    <text x="570" y="76" text-anchor="middle" font-size="7.4" fill="#1D4ED8">+1 Spd &amp; Pet</text>
    <line x1="612" y1="60" x2="626" y2="60" stroke="#D97706" stroke-width="1.5" marker-end="url(#ff-o)"/>
    <rect x="628" y="34" width="84" height="52" rx="6" fill="#FEF2F2" stroke="#DC2626" stroke-width="1.5"/>
    <text x="670" y="51" text-anchor="middle" font-size="8.5" font-weight="800" fill="#B91C1C">STAGE 2</text>
    <text x="670" y="64" text-anchor="middle" font-size="7.6" fill="#334155">Red Gown</text>
    <text x="670" y="76" text-anchor="middle" font-size="7.4" fill="#B91C1C">Orbit Blades</text>
    <line x1="712" y1="60" x2="726" y2="60" stroke="#D97706" stroke-width="1.5" marker-end="url(#ff-o)"/>
    <rect x="728" y="34" width="78" height="52" rx="6" fill="#FEF3C7" stroke="#B45309" stroke-width="1.8"/>
    <text x="767" y="51" text-anchor="middle" font-size="8.5" font-weight="800" fill="#92400E">STAGE 3</text>
    <text x="767" y="64" text-anchor="middle" font-size="7.6" fill="#334155">Gold Armor</text>
    <text x="767" y="76" text-anchor="middle" font-size="7.4" fill="#92400E">Cap (50px/4D)</text>
    <rect x="428" y="96" width="378" height="84" rx="6" fill="#FFFFFF" stroke="#D97706" stroke-width="1.3"/>
    <text x="617" y="114" text-anchor="middle" font-size="8.8" font-weight="800" fill="#92400E">Spotlight Morph Cutscene &amp; Skin Selector FSM</text>
    <text x="617" y="130" text-anchor="middle" font-size="7.9" fill="#334155">&bull; Quiz Pass &amp; (stage &lt; 2'd3) -&gt; stage &lt;= stage+1, outfit_cut_t &lt;= 120 (Spotlight Morph)</text>
    <text x="617" y="144" text-anchor="middle" font-size="7.9" fill="#B91C1C">&bull; stage == 2'd3 (Gold Armor) -&gt; outfit_cut_t = 0 (Skip repeat animation!)</text>
    <text x="617" y="158" text-anchor="middle" font-size="7.9" fill="#334155">&bull; Title Skin Selector: BTNL/R -&gt; hero_cursor, BTNC -&gt; hero_sel_l/r [0..3] (4 Peers)</text>
    <text x="617" y="172" text-anchor="middle" font-size="7.9" fill="#334155">&bull; Walk BRAM FSM: 4 Walk Cycles x 4 Outfits + Title Idle Bounce</text>
  </svg>
</div>

<table>
  <thead>
    <tr><th style="width:12%">Feature #</th><th style="width:24%">Feature Name &amp; RTL Reg</th><th style="width:28%">States / Encoding</th><th style="width:36%">Exact Transition Logic &amp; Output</th></tr>
  </thead>
  <tbody>
    <tr><td><b>Feat 1</b> (Core)</td><td><b>Movable Player &amp; Arena Combat</b><br><code>p1_combo_step, dash_timer</code></td><td><code>COMBO 0..2(Nova)</code>, <code>DASH IDLE/ACTIVE/CD</code>, <code>PB IDLE/FLY</code></td><td>6 Weapons (BTNU/D); 3-hit combo within window triggers 360&deg; Nova; Dash 4x speed w/ i-frames (<code>dash_cd=36</code>); Auto-Aim scans &le;240 px.</td></tr>
    <tr><td><b>Feat 2</b> (Core)</td><td><b>Sprite Evolutions &amp; Skins</b><br><code>stage[1:0], outfit_cut_t</code></td><td><code>0:Student &rarr; 1:Shop &rarr; 2:RedGown &rarr; 3:Gold</code></td><td>Quiz Pass advances <code>stage</code> (if <code>&lt;3</code>) + plays <code>120f</code> Spotlight; at <code>stage==3</code> stays capped w/o replay. <code>hero_sel[0..3]</code> + 16-frame Walk BRAM.</td></tr>
    <tr><td><b>Feat 3.1</b></td><td><b>Dead Cells Auto-Input Detect</b><br><code>control_mode[1:0]</code></td><td><code>00:Idle</code> | <code>01:KB Solo</code> | <code>10:Joy 1P/2P</code></td><td>Any KB edge in Title forces <code>01</code> (hides 2P bar); Any Joy edge sets <code>10</code> (unlocks 1P/2P). In <code>ST_PLAY</code> KB &amp; J1 merge via OR onto P1.</td></tr>
    <tr><td><b>Feat 3.2</b></td><td><b>Unified 3-Pg Pause &amp; Guide</b><br><code>help_page[1:0], paused</code></td><td><code>0:Off &harr; 1:Board &harr; 2:Joy &harr; 3:KB</code></td><td><code>SEL</code> / <code>ESC</code> toggles overlay in BOTH <code>ST_TITLE</code> &amp; <code>ST_PLAY (paused=1)</code>; Center badge switches dynamically between <code>[STR]</code> &amp; <code>[ENT] RESUME</code>.</td></tr>
    <tr><td><b>Feat 3.3</b></td><td><b>Room Wave Spawner</b><br><code>room_phase[2:0], wave_sub</code></td><td><code>RP_BANNER(0) &rarr; RP_FIGHT(1) &rarr; RP_CLEAR(2)</code></td><td><code>90f</code> Banner &amp; <code>45f</code> Door Slam; spawns W1–W5 sub-waves (30..80 minions); when <code>enemies_left==0</code> opens arrow to East door.</td></tr>
    <tr><td><b>Feat 3.4</b></td><td><b>Logic Gate Quiz Door</b><br><code>RP_QUIZ(3) &rarr; RP_DOOR(4)</code></td><td>Gates <code>0..5 (AND..XOR)</code>, <code>quiz_wrong_t</code></td><td><code>30f</code> lockout prevents mash; Correct slides door <code>0..31</code>; Wrong flashes <code>"F: GO RETAKE !!" (105f)</code> and resets <code>wave_sub=0</code>.</td></tr>
    <tr><td><b>Feat 3.5</b></td><td><b>3-Form Boss Ajarn_V</b><br><code>RP_BOSS(5), boss_kind[1:0]</code></td><td><code>Form 0(105) &rarr; Portal(160f) &rarr; F1(145) &rarr; F2(190)</code></td><td>Form 2 <code>HP&le;95</code> enters Enraged state; &ge;3 consecutive melee hits fire <code>220 px</code> Knockback + <code>60f</code> Stun barrier.</td></tr>
    <tr><td><b>Feat 3.6</b></td><td><b>Brawlhalla Zoom &amp; 2P Revive</b><br><code>zoom_lvl[6:0], p2_active</code></td><td><code>0..80</code> (<code>view_w 320..520</code>), <code>Revive</code></td><td>Computes <code>dx_sep/dy_sep</code> between alive P1/P2 &amp; slews zoom smoothly; entering <code>RP_BANNER</code> revives fallen ally to <code>12 HP</code>.</td></tr>
    <tr><td><b>Feat 3.7</b></td><td><b>PDM Mic 2P Sonic Wave</b><br><code>mic_roar, sonic_wave_t</code></td><td><code>LISTEN &rarr; ROAR_HOLD(320ms) &rarr; EXPAND</code></td><td><code>2.5 MHz</code> 128-sample PDM decimation (<code>raw_dev&ge;28</code>) emits dual Cyan P1 + Pink P2 rings (<code>100/140/180 px</code>) repelling <code>&plusmn;8 px/f</code>.</td></tr>
    <tr><td><b>Feat 3.8</b></td><td><b>ADT7420 I2C Thermal Fever</b><br><code>i2c state[4:0] (0..9)</code></td><td><code>S_IDLE..S_WR_ADDR..S_RD..S_UPDATE</code></td><td>Polls <code>0x4B @ 100kHz</code> every <code>100ms</code>; <code>eff_temp_fever=(temp&ge;base+1C)||(temp&ge;35C)||SW[0]</code> grants <code>+2 DMG</code>; <code>SW[1]</code> shows Celsius.</td></tr>
    <tr><td><b>Feat 3.9</b></td><td><b>5-Byte UART + Quiz Mux</b><br><code>u_state[1:0], pkt_state[2:0]</code></td><td><code>U_IDLE..U_STOP</code> + <code>B0..B4</code></td><td><code>115,200 bps</code> syncs <code>B0[7]=1</code>, unpacks J1/J2/KB &amp; <code>b4[6]</code> Quiz/Esc/Enter Mux; <code>1-sec</code> Watchdog clears stuck inputs.</td></tr>
    <tr><td><b>Feat 3.10</b></td><td><b>Direct PS/2 KB Decoder</b><br><code>ps2_keyboard.v</code> Frame FSM</td><td><code>11-bit RX</code> + <code>F0 Break</code> + <code>E0 Ext</code></td><td>8-sample glitch filter on <code>PS2_CLK (F4)/DATA (B2)</code>; decodes Set-2 make/break scancodes &amp; OR-merges w/ UART KB.</td></tr>
    <tr><td><b>Feat 3.11</b></td><td><b>ADXL362 SPI Tilt Reader</b><br><code>acl_tilt.v state[3:0]</code></td><td><code>S_PWRUP(0)..S_WAIT40(4)..S_RD(7)..S_WAIT10</code></td><td><code>1.04 MHz SPI</code> writes PowerCtl Measure then loops <code>10 ms</code> bursts reading <code>XL/XH/YL/YH</code> tilt offsets.</td></tr>
    <tr><td><b>Feat 3.12</b></td><td><b>OOC Regen, Gems &amp; Sky Drop</b><br><code>regen_wait, col_alive, drop_z</code></td><td><code>COMBAT &rarr; WAIT(360f) &rarr; REGEN(+1/90f)</code></td><td>Peace timer triggers slow HP recovery; Gems magnetize within <code>76 px</code> (<code>EXP=60</code> triggers refill + score); Sky Drops fall via gravity <code>drop_z</code>.</td></tr>
    <tr><td><b>Feat 3.13</b></td><td><b>Pet Auto-Bolt &amp; Orbit Blades</b><br><code>pet_active, blade_ang[3:0]</code></td><td><code>Stage&ge;1 Pet</code> | <code>Stage&ge;2 Blades(0..15)</code></td><td>Companion Pet fires homing bolts automatically; Dual Orbit Blades rotate per player using 16-entry Sine/Cosine LUT.</td></tr>
    <tr><td><b>Feat 3.14</b></td><td><b>SW[15:11] Audio Mixer FSM</b><br><code>audio_synth_v2.v</code></td><td><code>4 BRAM BGM</code> + <code>Priority SFX</code> + <code>SW[15:11]</code></td><td><code>SW15</code> Master Mute (<code>AUD_SD=0</code>), <code>SW14</code> BGM Mute, <code>SW13</code> SFX Mute, <code>SW[12:11]</code> <code>>>0..3</code> Vol over 3-Ch+Noise PWM.</td></tr>
    <tr><td><b>Feat 3.15</b></td><td><b>46-Cycle VBlank TDM &amp; VGA</b><br><code>step_state[5:0]</code></td><td><code>0(VBlank) &rarr; 1..18 &rarr; 20..37 &rarr; 40..44</code></td><td>Executes all collisions &amp; 16-enemy TDM in <code>&lt;0.015%</code> of 60Hz frame, feeding <code>4-Stage</code> glitch-free RGB444 pipeline.</td></tr>
    <tr><td><b>Feat 3.16</b></td><td><b>Board LED / RGB / 7-Seg Mux</b><br><code>board_io_v2.v</code></td><td><code>LED Mode (EXP/Fever/Mic)</code> + <code>AN[7:0]</code></td><td>5 ms button debouncer; drives <code>LED[15:0]</code> bars, <code>LED16</code> Thermal, <code>LED17</code> Audio/Mic, and <code>AN[7:0]</code> Score vs <code>SW[1]</code> Celsius.</td></tr>
  </tbody>
</table>

</body>
</html>"""
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    html_to_pdf(html_path, pdf_path)


def build_game_manual():
    html_path = os.path.join(DOC_DIR, "VeePire_Game_Manual.html")
    pdf_path = os.path.join(DOC_DIR, "VeePire_Game_Manual.pdf")

    convert_all_v5_ppms()

    # Select best available screenshots (preferring fresh rtl_v5 PNGs where ready)
    sim_dir = os.path.join(BASE, "sim_work")
    scr_dir = os.path.join(BASE, "docs", "screenshots")

    img_title_joy2p = img_b64(os.path.join(sim_dir, "rtl_v5_title_joy_2p.png"), os.path.join(scr_dir, "shot_title.png"))
    img_title_kb1p = img_b64(os.path.join(sim_dir, "rtl_v5_title_kb_1p.png"), os.path.join(scr_dir, "shot_title.png"))
    img_guide_p1 = img_b64(os.path.join(sim_dir, "rtl_v6_guide_p1.png"), os.path.join(sim_dir, "rtl_guide_p1.png"))
    img_pause = img_b64(os.path.join(sim_dir, "rtl_v5_pause_p2_joy.png"), os.path.join(sim_dir, "rtl_guide_p2.png"))
    img_sonic = img_b64(os.path.join(sim_dir, "rtl_v6_sonic_2p.png"), os.path.join(sim_dir, "rtl_v5_sonic_2p.png"))
    img_cutscene = img_b64(os.path.join(scr_dir, "shot_upgrade_cutscene.png"))
    img_boss = img_b64(os.path.join(scr_dir, "shot_boss_locked.png"))
    img_sprites = img_b64(os.path.join(BASE, "sprite_preview.png"))
    img_block = img_b64(os.path.join(DIAG_DIR, "diag_block.png"))

    html = f"""<!DOCTYPE html>
<html lang="th">
<head>
<meta charset="utf-8">
<title>VeePire Survivors - Game Manual &amp; System Specification</title>
<style>
  @page {{ size: A4; margin: 13mm 14mm 14mm 14mm; }}
  * {{ box-sizing: border-box; }}
  body {{
    font-family: 'Segoe UI', 'Noto Sans Thai', 'Leelawadee UI', sans-serif;
    color: #1E293B; line-height: 1.5; font-size: 10pt; margin: 0; padding: 0; background: #FFFFFF;
  }}
  .hero {{
    background: linear-gradient(125deg, #1E1B4B 0%, #312E81 45%, #0284C7 100%);
    color: #FFFFFF; padding: 20px 24px; border-radius: 14px; margin-bottom: 14px;
    box-shadow: 0 6px 18px rgba(15,23,42,0.16);
  }}
  .hero h1 {{ margin: 0 0 6px; font-size: 22pt; font-weight: 900; letter-spacing: 0.5px; color: #38BDF8; text-shadow: 0 2px 0 rgba(0,0,0,0.3); }}
  .hero .sub {{ font-size: 10.2pt; color: #E2E8F0; margin-bottom: 10px; }}
  .pill-row {{ display: flex; flex-wrap: wrap; gap: 6px; }}
  .pill {{
    background: rgba(15, 23, 42, 0.72); border: 1px solid rgba(56, 189, 248, 0.45);
    color: #F8FAFC; font-size: 8.5pt; font-weight: 700; padding: 4px 9px; border-radius: 999px;
  }}
  .card-sec {{
    border: 1px solid #CBD5E1; border-radius: 12px; padding: 14px 16px; margin-bottom: 13px;
    background: #FFFFFF; page-break-inside: avoid;
  }}
  .sec-title {{
    font-size: 13pt; font-weight: 800; color: #1D4ED8; margin: 0 0 10px;
    border-bottom: 2px solid #E2E8F0; padding-bottom: 5px;
  }}
  .grid-2 {{ display: grid; grid-template-columns: 1fr 1fr; gap: 14px; align-items: start; }}
  .grid-4 {{ display: grid; grid-template-columns: repeat(4, 1fr); gap: 10px; }}
  .evo-box {{
    border-radius: 9px; padding: 10px; font-size: 8.8pt; border: 1.5px solid #CBD5E1;
  }}
  .evo-0 {{ background: #F8FAFC; border-color: #64748B; }}
  .evo-1 {{ background: #EFF6FF; border-color: #2563EB; }}
  .evo-2 {{ background: #FEF2F2; border-color: #DC2626; }}
  .evo-3 {{ background: #FFFBEB; border-color: #D97706; }}
  .evo-box h4 {{ margin: 0 0 4px; font-size: 9.8pt; }}
  .callout-dark {{
    background: #0F172A; color: #E2E8F0; border-radius: 10px; padding: 12px 15px; margin-top: 10px;
    border-left: 5px solid #06B6D4; font-size: 9.3pt;
  }}
  .callout-dark b {{ color: #38BDF8; }}
  .callout-warn {{
    background: #FFFBEB; border: 1.5px solid #F59E0B; border-radius: 8px; padding: 9px 12px;
    font-size: 9pt; color: #78350F; margin-top: 8px;
  }}
  table {{ width: 100%; border-collapse: collapse; margin: 6px 0; font-size: 8.9pt; }}
  th {{ background: #F1F5F9; color: #0F172A; padding: 6px 8px; border: 1px solid #CBD5E1; text-align: left; font-weight: 800; }}
  td {{ padding: 5px 8px; border: 1px solid #E2E8F0; vertical-align: top; }}
  .keypill {{
    display: inline-block; background: #1E293B; color: #38BDF8; font-family: 'Consolas', monospace;
    font-weight: 800; padding: 1px 6px; border-radius: 4px; font-size: 8.3pt;
  }}
  .shot-grid {{ display: grid; grid-template-columns: 1fr 1fr; gap: 10px; margin-top: 8px; }}
  .shot-card {{ border: 1px solid #CBD5E1; border-radius: 8px; padding: 6px; background: #0D1117; text-align: center; page-break-inside: avoid; }}
  .shot-card img {{ width: 100%; border-radius: 5px; display: block; }}
  .shot-cap {{ color: #E2E8F0; font-size: 8.3pt; font-weight: 700; margin-top: 4px; }}
  .page-break {{ page-break-before: always; }}
</style>
</head>
<body>

<div class="hero">
  <h1>VEEPIRE SURVIVORS: FPGA ACTION RPG</h1>
  <div class="sub">เอกสารสรุปกฎเกณฑ์ สถาปัตยกรรมฮาร์ดแวร์ กลไกการต่อสู้ และคู่มือการเล่นฉบับสมบูรณ์ (DRAGO-NEXUS V2)</div>
  <div class="pill-row">
    <span class="pill">Target: Nexys A7-100T (XC7A100T)</span>
    <span class="pill">VGA: 640&times;480 @ 60Hz (12-bit RGB)</span>
    <span class="pill">Audio: 3-Ch BRAM PWM Synth</span>
    <span class="pill">Sensors: ADT7420 I2C + ADMP421 PDM</span>
    <span class="pill">Input: Dead Cells Auto (KB 1P / Joy 1P-2P)</span>
  </div>
</div>

<div class="card-sec">
  <div class="sec-title">1. กฎการเล่นและเงื่อนไขการเอาตัวรอด (Core Rules &amp; Mechanics)</div>
  <div class="grid-2">
    <div>
      <b>กฎพื้นฐาน (Gameplay Rules)</b>
      <ul style="margin:5px 0 0; padding-left:18px;">
        <li><b>พลังชีวิตเริ่มต้น:</b> ผู้เล่นเริ่มต้นด้วย <code>24 HP</code> (มีสถานะอมตะหลังโดนโจมตี <code>60</code> เฟรม / 1 วินาที)</li>
        <li><b>Out-of-Combat Regeneration:</b> หากไม่โดนดาเมจนาน <code>6 วินาที</code> (360 เฟรม) จะฟื้นเลือดอัตโนมัติ +1 HP ทุก 1.5 วินาที</li>
        <li><b>การทำคะแนน (6-Digit BCD Max 999,999):</b> ศัตรูลูกกระจ๊อก <code>+50</code> / Blue Gem <code>+25 (+5 EXP)</code> / Heart <code>+50 (+8 HP)</code> / Sky Supply <code>+100 (+8 HP, EXP+10)</code></li>
        <li><b>กติกาโหมด 2P Co-op:</b> หากเพื่อนล้ม (HP=0) จะนอนรอจนกว่าเพื่อนที่รอดจะเคลียร์ Wave แล้วฟื้นคืนชีพให้ <code>12 HP</code> ทันที</li>
      </ul>
    </div>
    <div>
      <b>ระบบตรวจจับการควบคุมอัตโนมัติ (Dead Cells Auto-Detect)</b>
      <table>
        <thead><tr><th>อุปกรณ์ที่แตะ</th><th>พฤติกรรมที่หน้าแรก (Title)</th><th>พฤติกรรมในเกม (ST_PLAY)</th></tr></thead>
        <tbody>
          <tr><td><b>Keyboard</b><br><span class="keypill">WASD / Space / ESC</span></td><td>ซ่อนแถบ 1P/2P บังคับเล่น <b>1P Solo เท่านั้น</b> พร้อมขึ้นปุ่มคีย์บอร์ดสีขาว</td><td>บังคับ P1 ร่วมกับจอย 1 ได้ทันที (พร้อมคีย์ลัด Quiz <code>1-4</code>)</td></tr>
          <tr><td><b>Joystick 1/2</b><br><span class="keypill">D-Pad / 1-4</span></td><td>แสดงแถบ <b>&lt; 1 PLAYER &gt; / &lt; 2 PLAYERS &gt;</b> ใช้ D-Pad เลือกเล่นคนเดียวหรือสองคน</td><td><b>Joy 1 + KB</b> บังคับ P1, <b>Joy 2</b> บังคับ P2 พร้อมกันแบบ 2P Co-op</td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

<div class="card-sec">
  <div class="sec-title">2. วิวัฒนาการชุดนักศึกษา มจธ. 4 ขั้น &amp; อาวุธระยะประชิด 6 แบบ</div>
  <div class="grid-4">
    <div class="evo-box evo-0">
      <h4>Stage 0: นักศึกษา (Wave 1)</h4>
      <div>ชุดนักศึกษาเสื้อขาว กางเกงดำ</div>
      <div><b>Reach:</b> 30 px | <b>DMG:</b> 2</div>
      <div>ชุดเริ่มต้นถาวร</div>
    </div>
    <div class="evo-box evo-1">
      <h4>Stage 1: เสื้อช็อป CPE (Wave 2)</h4>
      <div>เสื้อช็อปวิศวะ มจธ. (#405F73)</div>
      <div><b>Reach:</b> 36 px | <b>DMG:</b> 2</div>
      <div><b>โบนัส:</b> +1 Speed &amp; Pet ช่วยยิง</div>
    </div>
    <div class="evo-box evo-2">
      <h4>Stage 2: ชุดครุย (Wave 3)</h4>
      <div>ชุดครุยวิทยฐานะสีแดงคาดทอง</div>
      <div><b>Reach:</b> 42 px | <b>DMG:</b> 3</div>
      <div><b>โบนัส:</b> ดาบหมุน Orbit คู่</div>
    </div>
    <div class="evo-box evo-3">
      <h4>Stage 3: เกราะทอง (Wave 4-6)</h4>
      <div>เกราะทองคำ + แกน Cyan (ขั้นสูงสุด)</div>
      <div><b>Reach:</b> 50 px | <b>DMG:</b> 4</div>
      <div><b>โบนัส:</b> Flame Aura ถาวร (ไม่ฉายซ้ำ)</div>
    </div>
  </div>
  <p style="margin:8px 0 0; font-size:9.3pt;">
    <b>อาวุธ 6 รูปแบบ (ปรับที่หน้าแรกด้วย <code>BTNU/BTND</code>):</b>
    <code>0: SWORD</code> | <code>1: SABER</code> | <code>2: FISTS</code> | <code>3: B-AXE</code> | <code>4: SPEAR</code> | <code>5: SCYTH</code>
    — ฟันคอมโบ 3 จังหวะ (จังหวะที่ 3 ปล่อย 360&deg; Nova รอบตัว), ยิงปืน Auto-Aim ล็อคเป้า (ระยะ <code>240 px</code>), และ Shadow Dash อมตะชั่วขณะ
  </p>
</div>

<div class="page-break"></div>

<div class="card-sec">
  <div class="sec-title">3. ระบบเซนเซอร์ฮาร์ดแวร์อัจฉริยะ (On-Board FPGA Sensors)</div>
  <div class="callout-dark">
    <b>ก. คลื่นเสียงไมโครโฟน 2P Sonic Shockwave (ADMP421 PDM @ 2.50 MHz):</b>
    <ul>
      <li>ตะโกนหรือเป่าลมใส่ไมโครโฟนบนบอร์ด (<code>raw_dev &ge; 28</code>) เพื่อล็อกสัญญาณ <code>mic_roar</code> นาน <code>320 ms</code></li>
      <li><b>รองรับโหมด 2 คนสมบูรณ์แบบ:</b> ปล่อยวงแหวนคลื่นเสียง 3 ชั้น (รัศมี <code>100 / 140 / 180 px</code>) ออกจากทั้ง <b>P1 (สีฟ้า Cyan)</b> และ <b>P2 (สีชมพู Pink)</b> พร้อมกัน</li>
      <li>ผลักศัตรูทั้งหมดที่อยู่ในรัศมีกระเด็นถอยออกจากผู้เล่นที่ใกล้ที่สุด <code>&plusmn;8 px/frame</code> โดยไม่เสีย HP</li>
    </ul>
  </div>
  <div class="callout-dark" style="border-left-color:#EF4444;">
    <b>ข. เซนเซอร์อุณหภูมิความร้อน Overclock Fever (ADT7420 I2C @ 0x4B):</b>
    <ul>
      <li>ชิปบนบอร์ดวัดอุณหภูมิจริงทุก <code>100 ms</code> เทียบกับค่าเริ่มต้นตอนเปิดเครื่อง (<code>baseline_c</code>)</li>
      <li>เมื่ออุณหภูมิสูงกว่าค่าตั้งต้น <code>+1&deg;C</code> หรือถึง <code>35&deg;C</code> (หรือเปิดสวิตช์จำลอง <code>SW[0]=ON</code>) จะเข้าโหมด <b>Thermal Fever</b>: ดาบ/อาวุธทุกชนิดได้โบนัส <b>+2 DMG</b> และไฟ <code>LED[15:0]</code> วิ่ง Knight-Rider สีเพลิง</li>
      <li>สับ <code>SW[1]=ON</code> เพื่อเปลี่ยนตัวแสดงผล 7-Segment 4 หลักซ้ายเป็นอุณหภูมิเรียลไทม์ (เช่น <code>31.5 C</code>)</li>
    </ul>
  </div>
</div>

<div class="card-sec">
  <div class="sec-title">4. ระบบควิซประตู Logic Gate, บอส Ajarn_V 3 ร่าง และ Unified Pause Guide</div>
  <div class="grid-2">
    <div>
      <b>ระบบควิซประตูดิจิทัลลอจิก (Logic Gate Quiz)</b>
      <ul style="margin:4px 0 0; padding-left:18px;">
        <li>หลังกำจัดศัตรูหมดห้อง (Wave 1-5) ประตูด้านขวาจะท้าทายด้วยสมการเกตสุ่ม: <code>AND, OR, NOT, NAND, NOR, XOR</code></li>
        <li><b>ตอบถูก:</b> เปิดประตูสไลด์ พร้อมคัตซีนสปอตไลท์เปลี่ยนชุดขึ้นระดับถัดไป (หากเป็นชุดทอง Stage 3 แล้วจะเข้าประตูทันทีโดยไม่เล่นซ้ำ)</li>
        <li><b>ตอบผิด:</b> หน้าจอสั่นขึ้นคำเตือนเกรด <b>"F" + CAUTION: GO RETAKE !!</b> และบังคับเล่น Wave เดิมซ้ำทันที!</li>
      </ul>
    </div>
    <div>
      <b>บอสใหญ่ Ajarn_V 3 ร่าง (Wave 6 FINAL_WAVE)</b>
      <ul style="margin:4px 0 0; padding-left:18px;">
        <li>ต่อสู้ต่อเนื่อง 3 ร่างผ่าน Portal ระเบิด (<code>105 HP &rarr; 145 HP &rarr; 190 HP</code>) ในร่างสุดท้ายหากเลือด <code>&le; 95 HP</code> จะเข้าโหมดตาแดง <b>Enraged</b></li>
        <li><b>Anti-Melee Spam Barrier:</b> หากผู้เล่นฟันบอสติดต่อกัน 3 ครั้ง บอสจะระเบิดพลังผลักผู้เล่นกระเด็น <code>220 px</code> พร้อมติดสตั๊น <code>60</code> เฟรม (ต้องสลับใช้ปืน Auto-Aim!)</li>
        <li><b>Unified Pause Menu:</b> กด <code>START / ENTER / ESC</code> เพื่อเปิดหน้าคู่มือ 3 หน้าได้ทันทีระหว่างเล่น และกดอีกครั้งเพื่อ Resume</li>
      </ul>
    </div>
  </div>
</div>

<div class="card-sec">
  <div class="sec-title">5. การเชื่อมต่อฮาร์ดแวร์และผังพอร์ต Nexys A7-100T (Hardware I/O Reference)</div>
  <div class="grid-2">
    <table>
      <thead><tr><th style="width:28%">ปุ่ม / อุปกรณ์</th><th>หน้าที่การทำงานในระบบ</th></tr></thead>
      <tbody>
        <tr><td><span class="keypill">BTNL / BTNR</span></td><td>สลับเคอร์เซอร์สามเหลี่ยมเลือกระหว่าง P1 (ซ้าย) &harr; P2 (ขวา) ในหน้าแรก (2P)</td></tr>
        <tr><td><span class="keypill">BTNC</span></td><td>เปลี่ยนสไปรท์ใบหน้าฮีโร่ 4 แบบ (วนซ้าย-ขวาตามเคอร์เซอร์)</td></tr>
        <tr><td><span class="keypill">BTNU / BTND</span></td><td>สลับอาวุธระยะประชิด 6 แบบ (SWORD, SABER, FISTS, B-AXE, SPEAR, SCYTH)</td></tr>
        <tr><td><span class="keypill">CPU_RESETN</span></td><td>ปุ่มสีแดง (C12) รีเซ็ตวงจร FPGA ทั้งหมดกลับหน้าแรก</td></tr>
        <tr><td><span class="keypill">SW[15:11]</span></td><td><b>ระบบเสียงฮาร์ดแวร์:</b> <code>SW15</code> ปิดเสียงทั้งหมด | <code>SW14</code> ปิด BGM | <code>SW13</code> ปิด SFX | <code>SW12:11</code> ลดความดัง 100/50/25/12.5%</td></tr>
        <tr><td><span class="keypill">SW[0] / SW[1]</span></td><td><code>SW[0]</code>: จำลองโหมด Thermal Fever (+2 DMG) | <code>SW[1]</code>: แสดงอุณหภูมิบน 7-Seg</td></tr>
      </tbody>
    </table>
    <table>
      <thead><tr><th style="width:32%">พอร์ต / Interface</th><th>หมุดขา FPGA &amp; สเปก (XDC Verified)</th></tr></thead>
      <tbody>
        <tr><td><b>UART Joy/KB Bridge</b></td><td><code>UART_TXD_IN (C4)</code> @ 115,200 bps รับแพ็กเก็ต 5 ไบต์จาก <code>joy_bridge.py</code></td></tr>
        <tr><td><b>USB HID / PS/2 KB</b></td><td><code>PS2_CLK (F4)</code>, <code>PS2_DATA (B2)</code> ต่อคีย์บอร์ดตรงเข้าบอร์ดได้ทันที</td></tr>
        <tr><td><b>PDM Microphone</b></td><td><code>M_CLK (J5)</code> 2.50 MHz, <code>M_DATA (H5)</code>, <code>M_LRSEL (F5)</code></td></tr>
        <tr><td><b>ADT7420 Temp</b></td><td><code>TMP_SCL (C14)</code>, <code>TMP_SDA (C15)</code> บัส I2C 100 kHz แอดเดรส <code>0x4B</code></td></tr>
        <tr><td><b>VGA &amp; Audio PWM</b></td><td>VGA 12-bit (<code>B11/B12/A3..D8</code>), ลำโพง 3.5mm (<code>AUD_PWM A11</code>)</td></tr>
      </tbody>
    </table>
  </div>
</div>

<div class="page-break"></div>

<div class="card-sec">
  <div class="sec-title">6. ภาพตัวอย่างจริงจาก RTL Simulation &amp; สถาปัตยกรรมระบบ</div>
  <div class="shot-grid">
    <div class="shot-card">
      <img src="{img_title_joy2p}" alt="Title Joy 2P">
      <div class="shot-cap">หน้าแรกโหมด 2P (ตรวจจับจอยอัตโนมัติ + P1/P2 Weapon Select)</div>
    </div>
    <div class="shot-card">
      <img src="{img_title_kb1p}" alt="Title KB 1P">
      <div class="shot-cap">หน้าแรกเมื่อแตะคีย์บอร์ด (ซ่อนปุ่ม 2P บังคับเล่นเดี่ยว + ปุ่ม Space)</div>
    </div>
    <div class="shot-card">
      <img src="{img_pause}" alt="Unified Pause Guide">
      <div class="shot-cap">หน้า Pause ระหว่างเล่น (ใช้หน้าคู่มือเดียวกับ Title + RESUME)</div>
    </div>
    <div class="shot-card">
      <img src="{img_guide_p1}" alt="Board Hardware Guide V6">
      <div class="shot-cap">คู่มือฮาร์ดแวร์บอร์ด V6: ปุ่ม BTNC/U/D/L/R + SW0/SW1 + SW15-11 Audio</div>
    </div>
    <div class="shot-card">
      <img src="{img_sonic}" alt="Dual Sonic Wave or Combat">
      <div class="shot-cap">ฉากต่อสู้จริง: 2P Co-op &amp; คลื่นเสียง Sonic Shockwave (Cyan/Pink)</div>
    </div>
    <div class="shot-card">
      <img src="{img_boss}" alt="Boss Battle">
      <div class="shot-cap">Wave 6 บอส Ajarn_V 3 ร่าง + ปืนล็อคเป้า Auto-Aim 240 px</div>
    </div>
  </div>
</div>

<div class="card-sec">
  <div class="sec-title">7. คลังกราฟิก Sprite BRAM ฉบับสมบูรณ์ (รวมชุดเกราะทอง &amp; 6 อาวุธ) &amp; สถาปัตยกรรมระบบ</div>
  <div style="display:grid; grid-template-columns: 1fr 1.15fr; gap:10px; align-items:stretch;">
    <div class="shot-card" style="display:flex; flex-direction:column; justify-content:space-between;">
      <img src="{img_sprites}" alt="BRAM Sprite Sheet">
      <div class="shot-cap">คลังภาพ Pixel Art BRAM ล่าสุด (ฮีโร่ 4 คน x 4 ชุดรวม Gold Armor, 6 อาวุธ, บอส 3 ร่าง)</div>
    </div>
    <div class="shot-card" style="background:#FFFFFF; border-color:#CBD5E1; display:flex; flex-direction:column; justify-content:space-between;">
      <img src="{img_block}" alt="System Block Diagram">
      <div class="shot-cap" style="color:#0F172A;">ผังสถาปัตยกรรมระบบฮาร์ดแวร์ Pure Verilog บน Nexys A7-100T</div>
    </div>
  </div>
</div>

<div class="page-break"></div>

<div class="card-sec">
  <div class="sec-title">8. สรุประบบทั้งหมดสำหรับเกณฑ์ Ranking: ช่องทาง Input (8 แบบ) &amp; Sub-Features (18 ระบบ)</div>
  <p style="margin:0 0 8px; font-size:9.3pt;">
    สรุปรายการระบบอินพุตฮาร์ดแวร์และฟีเจอร์ย่อยทั้งหมดที่สร้างจริงด้วย Pure Verilog RTL บนบอร์ด Digilent Nexys A7-100T เพื่อความชัดเจนในการนับคะแนน Ranking:
  </p>
  <div class="grid-2">
    <div>
      <table>
        <thead><tr><th style="width:12%">ข้อ</th><th style="width:36%">ช่องทาง Input (8 แบบ)</th><th>รายละเอียดการทำงานในวงจร</th></tr></thead>
        <tbody>
          <tr><td><b>1</b></td><td><b>Twin USB Gamepads</b></td><td>จอยคู่ J1 + J2 ผ่าน UART Bridge <code>115,200 bps</code> มี Watchdog 1 วิ</td></tr>
          <tr><td><b>2</b></td><td><b>PC Keyboard Bridge</b></td><td>ส่งคีย์บอร์ดผ่าน Serial พร้อม <code>b4[6]</code> Quiz/Esc/Enter Mux</td></tr>
          <tr><td><b>3</b></td><td><b>PS/2 / USB-HID Port</b></td><td>ต่อคีย์บอร์ดตรงเข้าบอร์ดผ่านขา <code>PS2_CLK (F4) / PS2_DATA (B2)</code></td></tr>
          <tr><td><b>4</b></td><td><b>5 Pushbuttons</b></td><td><code>BTNC/U/D/L/R</code> + 5 ms Debouncer เลือกฮีโร่ 4 คน &amp; อาวุธ 6 แบบ</td></tr>
          <tr><td><b>5</b></td><td><b>16 Slide Switches</b></td><td><code>SW[15:11]</code> คุมระบบเสียง (Mute/BGM/SFX/Vol) | <code>SW[0..1]</code> Fever &amp; 7-Seg</td></tr>
          <tr><td><b>6</b></td><td><b>ADT7420 I2C Temp</b></td><td>ชิปวัดอุณหภูมิ <code>0x4B (C14/C15)</code> ปลุกโหมด Thermal Fever (+2 DMG)</td></tr>
          <tr><td><b>7</b></td><td><b>ADMP421 PDM Mic</b></td><td>ไมโครโฟนบนบอร์ด (<code>J5/H5/F5</code> @ 2.5 MHz) ตะโกนปล่อยคลื่น Sonic</td></tr>
          <tr><td><b>8</b></td><td><b>ADXL362 + CPU_RESETN</b></td><td>ไจโร/ความเร่ง SPI (<code>acl_tilt.v</code>) + ปุ่มรีเซ็ตฮาร์ดแวร์ (<code>C12</code>)</td></tr>
        </tbody>
      </table>
    </div>
    <div>
      <table>
        <thead><tr><th style="width:14%">ข้อ</th><th>Sub-Features ฮาร์ดแวร์จริง (18 ระบบย่อย)</th></tr></thead>
        <tbody>
          <tr><td><b>1–2</b></td><td><b>Auto Input Detect (Dead Cells):</b> แตะคีย์บอร์ดบังคับ 1P / แตะจอยเลือก 1P-2P &bull; <b>In-Game Hybrid:</b> จอย1 + KB บังคับ P1 พร้อมกัน</td></tr>
          <tr><td><b>3–4</b></td><td><b>Unified 3-Page Guide:</b> คู่มือ Title &amp; Pause มีปุ่ม Resume สด &bull; <b>2P Co-op + Wave Revive:</b> ชุบเพื่อนอัตโนมัติ (12 HP)</td></tr>
          <tr><td><b>5–6</b></td><td><b>6 Selectable Melee Weapons:</b> SWORD..SCYTH เปลี่ยนได้ในเกม &bull; <b>3-Hit Combo + 360&deg; Nova Finisher</b></td></tr>
          <tr><td><b>7–8</b></td><td><b>Auto-Aim Plasma Bullets:</b> ยิงล็อคเป้าอัตโนมัติในระยะ 240 px &bull; <b>Shadow Dash:</b> พุ่งหลบพร้อม i-frames (cd=36f)</td></tr>
          <tr><td><b>9–10</b></td><td><b>4-Stage KMUTT Outfit Evolution:</b> นักศึกษา&rarr;ช็อป&rarr;ครุย&rarr;เกราะทอง (ไม่ฉายซ้ำขั้น 3) &bull; <b>Pet Bolt + Dual Orbit Blades</b></td></tr>
          <tr><td><b>11–12</b></td><td><b>Brawlhalla Dynamic Camera:</b> ซูม/แพนตามระยะ 2 คน (<code>view_w 320..520</code>) &bull; <b>6-Gate Logic Quiz + &quot;F&quot; Wave Reset</b></td></tr>
          <tr><td><b>13–14</b></td><td><b>2P PDM Sonic Shockwave:</b> คลื่น Cyan (P1) + Pink (P2) ผลัก <code>&plusmn;8 px/f</code> &bull; <b>ADT7420 Thermal Fever (+2 DMG)</b></td></tr>
          <tr><td><b>15–16</b></td><td><b>OOC HP Regen (360f/90f) + Magnetic Gems (76 px)</b> &bull; <b>3-Form Portal Boss Ajarn_V</b> (Anti-Spam Knockback 220 px)</td></tr>
          <tr><td><b>17–18</b></td><td><b>SW[15:11] Hardware Audio Mixer + 4 BRAM BGM + SFX</b> &bull; <b>46-Cycle VBlank TDM + 4-Stage VGA + 16 LEDs/7-Seg</b></td></tr>
        </tbody>
      </table>
    </div>
  </div>
</div>

</body>
</html>"""
    with open(html_path, "w", encoding="utf-8") as f:
        f.write(html)
    html_to_pdf(html_path, pdf_path)


if __name__ == "__main__":
    build_diagram_pngs()
    build_fsm_specification()
    build_game_manual()
