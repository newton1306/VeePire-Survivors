# คู่มือวางแผนทำสไลด์ (ฉบับเพื่อน — Progress V6 Final) | VeePire Survivors

> **อ้างอิงเกณฑ์:** วิชา CPE222 Digital Logic Design — บอร์ด Digilent Nexys A7-100T (`XC7A100T-1CSG324C`)
> **เวลาพูดรวม:** **7 นาที 00 วินาที** | **สมาชิก:** **5 คน** | **จำนวนสไลด์:** **12 สไลด์ (เพิ่มหน้าสรุป 8 Inputs + 18 Sub-Features สำหรับเกณฑ์ Ranking)**
> **โฟลเดอร์รวมไฟล์ส่งเพื่อน:** `D:\vivado_pj\DRAGO_NEXUS_V2\doc\for_friend_2_progress\`
>   - `VeePire_FSM_Specification.pdf` (สเปก FSM ทั้งหมดของระบบ)
>   - `VeePire_Game_Manual.pdf` (กติกาเกม, อาวุธ, เซนเซอร์, ผังขาบอร์ด)
>   - `VeePire_Slide_Plan_For_Friend.pdf` (คู่มือสไลด์พร้อมภาพตัวอย่าง Layout + Diagram ฉบับ PDF)
>   - ภาพประกอบ `01_*.png` .. `15_*.png` (อยู่ในโฟลเดอร์เดียวกันทั้งหมด ลากใส่สไลด์ตามตารางได้เลย)

---

## 0. ปูพื้นฐาน 1 นาทีสำหรับเพื่อน (ไม่ต้องรู้ Digital / Verilog ก็อธิบายอาจารย์ได้!)

| คำศัพท์ในสไลด์ | แปลเป็นภาษาคนทั่วไป (สำหรับพูดอธิบายในห้อง) |
| :--- | :--- |
| **FPGA (Nexys A7-100T)** | ชิปที่แปลงตัวเองเป็น "วงจรอิเล็กทรอนิกส์" ตามโค้ดที่เราออกแบบ ทุกส่วนทำงานขนานพร้อมกันแบบฮาร์ดแวร์ล้วนๆ |
| **Pure Verilog (ไม่ใช้ MicroBlaze)** | เราเขียนวงจรเกมด้วยภาษา Verilog เอง 100% ไม่ได้แอบใส่ CPU สำเร็จรูป (`MicroBlaze`) แล้วเขียนภาษา C |
| **VGA `640×480 @ 60 Hz` (12-bit)** | พอร์ตต่อจอภาพขนาด `640×480` จุด วาดใหม่วินาทีละ `60` ภาพ แสดงสีได้ `4,096` สี (`RGB444`) |
| **46-Cycle VBlank Update** | ช่วงพักเสี้ยววินาทีหลังวาดจอครบ 1 ภาพ ระบบคำนวณฟิสิกส์/AI เสร็จภายใน `46` รอบนาฬิกา (`<0.015%` ของเวลาเฟรม) ทำให้ภาพไม่ขาดครึ่งจอ |
| **Dead Cells Auto-Detect** | แตะคีย์บอร์ด -> เกมเปลี่ยนไอคอนเป็นปุ่มคีย์บอร์ดสีขาว & บังคับโหมด 1 คนอัตโนมัติ / แตะจอย -> เปิดเลือก 1P หรือ 2P Co-op |
| **PDM Mic & I2C Temp** | ไมโครโฟนบนบอร์ด (`ADMP421`) ตรวจเสียงตะโกนปล่อยคลื่นกระแทก 2P, เซนเซอร์ความร้อน (`ADT7420`) ตรวจอุณหภูมิเพิ่มโบนัสพลังโจมตี `+2 DMG` |
| **UART + PS/2 Bridge** | โปรแกรม `joy_bridge.py` ส่งสัญญาณจอย USB คู่และคีย์บอร์ดแบบ `5 ไบต์` ผ่านสาย USB (`115,200 bps`) และยังต่อคีย์บอร์ดเข้าพอร์ต `J5` ของบอร์ดโดยตรงได้ด้วย |

---

## 1. ตารางจับคู่รูปภาพ (ใช้รูปไหน -> ประกอบสไลด์หน้าไหน)

| ชื่อไฟล์ภาพ (อยู่ในโฟลเดอร์นี้) | เอาไปวางสไลด์ไหน | จุดที่ควรชี้ให้อาจารย์ดู |
| :--- | :--- | :--- |
| `01_title_2p_joy.png` | **Slide 1 (หน้าปก)** & **Slide 4** | หน้าแรกโหมด 2 คน (`< 2 PLAYERS >`), เคอร์เซอร์สามเหลี่ยม, อาวุธข้างตัว (`SWORD` / `SABER`), ปุ่มจอยเด้งดึ๋ง |
| `02_title_1p_kb.png` | **Slide 2** & **Slide 4 (Auto-Detect)** | พอแตะคีย์บอร์ด แถบ `1P/2P` หายไป (บังคับเล่นคนเดียว), ปุ่มด้านล่างเปลี่ยนเป็นคีย์แคปขาว `[SPACE]` และ `[ESC] GUIDE` |
| `03_guide_board_btns.png` | **Slide 3 (Hardware & I/O)** | หน้าสอนปุ่มกดบนบอร์ด `BTNL/BTNR/BTNC/BTNU/BTND` + ผังสวิตช์ `SW[15:11]` Audio / `SW[0..1]` Temp |
| `04_guide_joystick.png` | **Slide 4 (Controls)** | ภาพจอยจริงพร้อมเส้นชี้ปุ่ม (`Move` ชี้ D-Pad, `Nova/Bullet/Dash/Attack` ชี้ 1-4) |
| `05_guide_keyboard.png` | **Slide 4 (Controls)** | ปุ่มคีย์บอร์ดสีขาว (`W/A/S/D`, `SPACE/J`, `K/E/Z`, `3/L`, `4/U`) |
| `14_pause_unified_guide.png` | **Slide 4 (Pause Menu)** | หน้า Pause ระหว่างเล่น ใช้หน้าจอเดียวกับหน้าสอน + เพิ่มปุ่มกลาง `[STR] RESUME` / `[ENT] RESUME` |
| `06_combat_sword_lunge.png` | **Slide 5 (Combat & 6 Weapons)** | ฉากต่อสู้จริง ฟันดาบ 360° Nova, กรอบห้องสี่เหลี่ยม, ล็อคเป้าศัตรู |
| `07_sprite_preview.png` | **Slide 6 (KMUTT Evolution)** | คลังสไปรท์ฉบับสมบูรณ์: 4 ฮีโร่ x 4 ชุด (ถึงเกราะทอง) + 6 อาวุธ + ศัตรูสูทดำ + บอส Ajarn_V 3 ร่าง + ไอเทม |
| `08_upgrade_cutscene.png` | **Slide 6 (Upgrade Cutscene)** | คัตซีนสปอตไลท์เปลี่ยนชุด `"EQUIPPED"` (และหยุดฉายซ้ำเมื่อถึงชุดเกราะทอง Stage 3) |
| `09_quiz_logic_gate.png` | **Slide 7 (Creative Features)** | หน้าต่างควิซ Logic Gate ก่อนเปิดประตูสไลด์ (ตอบผิดขึ้น `"F" + CAUTION: GO RETAKE !!`) |
| `10_boss_ajarn_v.png` | **Slide 7 (Boss 3 Forms)** | บอส Ajarn_V ร่าง Portal + ปืน Auto-Aim ล็อคเป้า 240 px + Anti-Melee Knockback 220 px |
| `15_sonic_wave_2p.png` | **Slide 7 & Slide 12 (2P Sound)** | ตะโกนใส่ไมค์แล้วปล่อยคลื่นเสียง **ทั้ง P1 (ฟ้า Cyan) และ P2 (ชมพู Pink) พร้อมกัน!** |
| `11_diag_block.png` | **Slide 8 (System Architecture)** | ผังสถาปัตยกรรมทั้งระบบ (`uart_joy_rx / ps2 / sensors -> game_engine_v2 -> vga_renderer_v2 + audio`) |
| `12_diag_fsm.png` | **Slide 9 (FSM Diagrams)** | ผัง Master Game FSM และ Room & Logic Gate Quiz Sub-FSM |
| `13_diag_bridge.png` | **Slide 10 (5-Byte UART Bridge)** | ผังโปรโตคอล `5-Byte UART @ 115,200 bps` + `b4[6]` Quiz Mux + PS/2 Standalone Fallback |

---

## 2. การแบ่งเวลาพูด 7 นาที สำหรับสมาชิก 5 คน

| สมาชิก | ช่วงเนื้อหา | สไลด์ | เวลาพูด |
| :--- | :--- | :--- | :--- |
| **คนที่ 1** | เปิดตัว, แนวคิดเกม & Objectives, สเปกฮาร์ดแวร์ + I/O บอร์ด Nexys A7 (`SW[15:11]` / `SW[1:0]`) | Slide 1 – 3 | **1:15 นาที** (`0:00 – 1:15`) |
| **คนที่ 2** | Dead Cells Auto-Input + Unified Pause, การต่อสู้ 6 อาวุธ + ปืน Auto-Aim + Dynamic Zoom | Slide 4 – 5 | **1:20 นาที** (`1:15 – 2:35`) |
| **คนที่ 3** | วิวัฒนาการชุด มจธ. 4 ขั้น, ควิซ Logic Gate + เซนเซอร์อุณหภูมิ/เสียง 2P + บอส 3 ร่าง | Slide 6 – 7 | **1:25 นาที** (`2:35 – 4:00`) |
| **คนที่ 4** | System Block Diagram, Master/Room FSM และ 5-Byte UART + PS/2 Bridge | Slide 8 – 10 | **1:40 นาที** (`4:00 – 5:40`) |
| **คนที่ 5** | สรุป Ranking Inventory (8 Inputs + 18 Sub-Features), ผลทดสอบ & แผน Demo สด | Slide 11 – 12 | **1:20 นาที** (`5:40 – 7:00`) |

---

## 3. รายละเอียดข้อความ & วิธีจัดวางทั้ง 12 สไลด์ (ก๊อปวางได้เลย)

- **ธีมสีแนะนำ (Arcade Dark Theme):** พื้นหลัง `#0D1117` | กล่องการ์ด `#161B22` ขอบ `#30363D` | สีเน้นหลัก `#00E5FF` (ฟ้าไซเบอร์) | สีเน้นตัวเลข/ทอง `#FFD54F` | สีเน้นบอส/ควิซ `#FF4081` (ชมพู)
- **ฟอนต์:** หัวข้อ `Montserrat ExtraBold` / เนื้อหาภาษาไทย `Noto Sans Thai` หรือ `IBM Plex Sans Thai`

### Slide 1 — หน้าปก (Title Slide) | 0:00 – 0:20 (คนที่ 1)
- **รูปประกอบ:** `01_title_2p_joy.png` (วางฝั่งขวาใหญ่ๆ)
- **ข้อความในสไลด์:**
  - `VeePire Survivors: DRAGO-NEXUS V2`
  - `2D Co-op Action RPG on Digilent Nexys A7-100T FPGA (Pure Verilog • Zero CPU)`
  - `CPE222 Digital Logic Design — Progress Report`
  - `กลุ่ม <เลขกลุ่ม> | รายชื่อสมาชิก 5 คน + รหัสนักศึกษา`

### Slide 2 — แนวคิดเกม & วัตถุประสงค์ (Motivation & Objectives) | 0:20 – 0:50 (คนที่ 1)
- **รูปประกอบ:** `02_title_1p_kb.png` (วางมุมขวาล่าง/ขวาข้างกล่อง)
- **ข้อความในสไลด์:**
  - **Objectives:** ออกแบบวงจรเกม Real-time ด้วย Pure Verilog 100% (ไม่ใช้ MicroBlaze CPU), สร้างวงจร VGA + Audio + อ่านอินพุตหลายช่องทาง, คุมระบบด้วย FSM ชัดเจน
  - **Core Innovation:** เกมเอาชีวิตรอดในห้องสี่เหลี่ยม 6 Waves พร้อมระบบ **Dead Cells Auto-Detect** สลับไอคอนจอย/คีย์บอร์ดทันทีที่แตะอุปกรณ์, ด่านควิซ Logic Gate, เซนเซอร์ความร้อน/เสียงจริง และบอส Ajarn_V 3 ร่าง

### Slide 3 — ฮาร์ดแวร์และผังพอร์ต Nexys A7-100T (Hardware Specs & I/O) | 0:50 – 1:15 (คนที่ 1)
- **รูปประกอบ:** `03_guide_board_btns.png` (วางซ้าย) คู่ตารางสเปก (วางขวา)
- **ข้อความในสไลด์:**
  - **Display & Timing:** `VGA 640×480 @ 60 Hz` 12-bit RGB (`4,096 สี`), pixel clock `25 MHz` (`clk25`), อัปเดตช่วง VBlank (ไม่เกิดภาพฉีก)
  - **On-Board Controls (`5 ms Debouncer`):** `BTNL/BTNR` เลื่อนเคอร์เซอร์ P1/P2, `BTNC` เปลี่ยนหน้าตัวละคร, `BTNU/BTND` เปลี่ยนอาวุธ 6 แบบ
  - **Switches & Audio Mixer (V6):**
    - `SW[15:11]` ระบบเสียงเท่านั้น: `SW15` ปิดเสียงทั้งหมด (`AUD_SD=0`) | `SW14` ปิด BGM | `SW13` ปิด SFX | `SW[12:11]` ลดความดัง `100% / 50% / 25% / 12.5%`
    - `SW[0]` จำลอง Thermal Fever (`+2 DMG`) | `SW[1]` แสดงอุณหภูมิสดบน 7-Segment 4 หลักซ้าย
    - ไฟ `16 LEDs` + `LED16/17` + ลำโพง `AUD_PWM (A11)`
  - **Sensors & Ports:** `ADT7420 I2C (C14/C15 @ 0x4B)`, `ADMP421 PDM Mic (J5/H5 @ 2.5 MHz)`, `UART (C4 @ 115,200 bps)`, `PS/2 (F4/B2)`

### Slide 4 — ระบบควบคุมอัจฉริยะ Dead Cells Auto-Detect & Unified Pause | 1:15 – 1:55 (คนที่ 2)
- **รูปประกอบ:** วางคู่ `04_guide_joystick.png` + `05_guide_keyboard.png` + `14_pause_unified_guide.png` (หรือ `02_title_1p_kb.png`)
- **ข้อความในสไลด์:**
  - **Auto Input Switching:**
    - **แตะ Keyboard (`WASD / Space / ESC`):** ซ่อนแถบ `1P/2P` ที่หน้าแรก **บังคับเล่นคนเดียว (1P Solo)** พร้อมเปลี่ยนปุ่มแนะนำเป็นคีย์แคปสีขาว
    - **แตะ Joystick (`D-Pad / 1-4`):** เปิดแถบ `< 1 PLAYER > / < 2 PLAYERS >` ให้เลือกเล่นเดี่ยวหรือ Co-op 2 คน
  - **In-Game Hybrid Control:** ระหว่างเล่น **ทั้ง Joystick 1 และ Keyboard** บังคับ P1 ได้พร้อมกันไร้รอยต่อ (และ Joy 2 บังคับ P2)
  - **Unified 3-Page Pause Guide:** กด `START / ENTER / ESC` เปิดหน้าคู่มือ 3 หน้าเดียวกับหน้าแรก พร้อมปุ่ม **`[STR] RESUME` / `[ENT] RESUME`** ที่เปลี่ยนไอคอนตามอุปกรณ์ที่แตะทันที!

### Slide 5 — การต่อสู้ 6 อาวุธ, Auto-Aim & Dynamic Zoom | 1:55 – 2:35 (คนที่ 2)
- **รูปประกอบ:** `06_combat_sword_lunge.png` (วางใหญ่ฝั่งขวา)
- **ข้อความในสไลด์:**
  - **6 Selectable Melee Weapons:** `0: SWORD` | `1: SABER` | `2: FISTS` | `3: B-AXE` | `4: SPEAR` | `5: SCYTH` (เลือกที่หน้าแรกด้วย `BTNU/BTND`)
  - **3-Hit Combo & Nova:** ฟันจังหวะที่ 3 ปล่อยคลื่น `360° Nova` + `Shadow Dash` อมตะชั่วขณะ
  - **Auto-Aim Plasma Gun (ระยะ `<= 240 px`):** กดปุ่มยิง (`1` / `4` / `U`) กระสุนคำนวณเวกเตอร์นำวิถีล็อคศัตรูอัตโนมัติ
  - **Brawlhalla Dynamic Camera + Regen:** กล้องซูมอัตโนมัติ `320..520 px`, ออกจากต่อสู้ `6 วิ` (360f) เลือดฟื้นอัตโนมัติ `+1 HP / 1.5 วิ`

### Slide 6 — วิวัฒนาการชุด มจธ. 4 ขั้น & กราฟิก BRAM | 2:35 – 3:15 (คนที่ 3)
- **รูปประกอบ:** `07_sprite_preview.png` (ซ้าย) คู่กับ `08_upgrade_cutscene.png` (ขวา)
- **ข้อความในสไลด์:**
  - **KMUTT 4-Stage Evolution (อัปเกรดผ่านประตูควิซ):**
    1. `Stage 0 (Wave 1)`: ชุดนักศึกษา (Reach `30 px`, DMG `2`)
    2. `Stage 1 (Wave 2)`: เสื้อช็อป CPE `#405F73` (`+1 Speed` + Pet ช่วยยิง)
    3. `Stage 2 (Wave 3)`: ชุดครุยวิทยฐานะสีแดง (`Reach 42 px, DMG 3` + Orbit Blades คู่)
    4. `Stage 3 (Wave 4-6)`: **เกราะทองคำขั้นสุดท้าย (`Reach 50 px, DMG 4`)** + Flame Aura (ไม่เล่นคัตซีนแปลงร่างซ้ำเมื่อเป็นชุดทองแล้ว)
  - **Custom BRAM Art:** 4 ใบหน้าฮีโร่ + Walk Cycle 16 เฟรม + ศัตรูสูทดำ + บอส Ajarn_V 3 ร่าง

### Slide 7 — Creative Features: Logic Gate Quiz, Hardware Sensors & Boss Ajarn_V | 3:15 – 4:00 (คนที่ 3)
- **รูปประกอบ:** `09_quiz_logic_gate.png`, `10_boss_ajarn_v.png`, `15_sonic_wave_2p.png`
- **ข้อความในสไลด์:**
  - **Logic Gate Quiz Doors:** สุ่มโจทย์ `AND, OR, NOT, NAND, NOR, XOR` — ตอบถูกอัปเกรดชุด/เปิดประตู; ตอบผิดขึ้น **`"F" CAUTION: GO RETAKE !!`** บังคับเล่น Wave เดิมซ้ำ!
  - **2P PDM Mic Sonic Shockwave (`ADMP421 @ 2.5 MHz`):** เป่า/ตะโกนใส่ไมค์ ปล่อยวงแหวนคลื่นเสียง (รัศมี `100 / 140 / 180 px`) **ออกจากทั้ง P1 (Cyan) และ P2 (Pink) พร้อมกัน** ผลักศัตรูถอยหนี!
  - **ADT7420 Thermal Fever (`0x4B I2C`):** ความร้อนขึ้น `+1°C` หรือ `>= 35°C` (หรือ `SW[0]=ON`) บวกดาเมจโจมตี **`+2 DMG`** + ไฟ Flame LED
  - **Boss Ajarn_V 3 ร่าง (Wave 6):** `105 -> 145 -> 190 HP` (Enraged `<= 95 HP`) พร้อม **Anti-Melee Spam Barrier** ผลักกระเด็น `220 px` + สตั๊น 1 วินาที

### Slide 8 — สถาปัตยกรรมระบบ & ไปป์ไลน์ 46 รอบนาฬิกา (Block Diagram) | 4:00 – 4:35 (คนที่ 4)
- **รูปประกอบ:** `11_diag_block.png` (วางกลางเต็มสไลด์)
- **ข้อความในสไลด์:**
  - **Input Layer:** `uart_joy_rx`, `ps2_keyboard`, `board_io_v2`, `acl_tilt`, `i2c_temp_adt7420`, `pdm_mic_decoder`
  - **Core `game_engine_v2` (46 Cycles/Frame):** ประมวลผล P1/P2 Collision, ลูป AI ศัตรู 16 ตัว (1 ตัว/clk), Lock-On, Quiz, Boss ครบภายใน `< 0.015%` ของเวลาเฟรม 60 Hz
  - **Output Layer:** `vga_renderer_v2` (4-Stage Pipeline ไร้ Timing Violation) + `audio_synth_v2` (BGM 3-Voice + Noise จาก BRAM) + 16 LEDs / 7-Segment

### Slide 9 — ผังสถานะเกมและด่าน (Master & Sub-FSM Design) | 4:35 – 5:10 (คนที่ 4)
- **รูปประกอบ:** `12_diag_fsm.png` (วางเต็มกลางสไลด์)
- **ข้อความในสไลด์:**
  - **Master FSM (`game_state`):** `ST_TITLE (0)` -> `ST_PLAY (2) [↔ PAUSED 3-Page Guide]` -> `ST_WIN (3)` / `ST_LOSE (4)`
  - **Room Sub-FSM (`room_phase`):** `RP_BANNER (0)` -> `RP_FIGHT (1)` -> `RP_CLEAR (2)` -> `RP_QUIZ (3)` -> `RP_DOOR (4)` (ตอบผิดวนกลับ `RP_BANNER`) และ `RP_BOSS (5)` สำหรับ Wave 6 (โหมด 2P ชุบเพื่อนที่ล้ม `12 HP` เมื่อผ่านประตู)

### Slide 10 — สะพานเชื่อมจอย/คีย์บอร์ด 5 ไบต์ (PC-to-FPGA UART + PS/2 Bridge) | 5:10 – 5:40 (คนที่ 4)
- **รูปประกอบ:** `13_diag_bridge.png` (วางเต็มกลางสไลด์)
- **ข้อความในสไลด์:**
  - **5-Byte Frame (`115,200 bps 8N1`):**
    - `B0`: Sync `0x80` + `J1 Shoot` + `J1 dx/dy` | `B1`: `J2 Shoot` + `J2 dx/dy` | `B2`: `Joy Start` + ปุ่ม J1/J2
    - `B3`: `KB Shoot` + `KB WASD` | `B4`: `b4[6] QHit` มัลติเพล็กซ์ปุ่มควิซ `1-4` แยกจาก `Esc / Enter` และ `Joy Select`
  - **Safety Watchdog & PS/2 Fallback:** ตั้งเวลา Watchdog `1 วินาที` เคลียร์สัญญาณค้างอัตโนมัติ และรองรับการเสียบ USB/PS2 Keyboard ตรงเข้าพอร์ตบอร์ด (`F4/B2`) ได้โดยไม่ต้องรันสคริปต์

### Slide 11 — สรุปความครบครันเพื่อเกณฑ์ Ranking: 8 Inputs & Feature 1, 2, 3.1–3.16 FSMs | 5:40 – 6:20 (คนที่ 5)
- **รูปประกอบ:** วางตัวเลขใหญ่ **`8 INPUT CHANNELS`** | **`18 FEATURES (18 SUB-FSMS)`** คู่กับ `07_sprite_preview.png` หรือตาราง Section 4
- **ข้อความในสไลด์:**
  - **8 Hardware / Hybrid Inputs:** 1) Twin USB Gamepads (UART J1+J2), 2) PC Keyboard Bridge (`5-Byte Serial + b4[6] Mux`), 3) Direct USB-HID/PS2 (`F4/B2`), 4) 5 On-Board Pushbuttons (`5ms Debouncer`), 5) 16 Slide Switches (`SW[15:11]` Audio + `SW[0..1]` Fever/7-Seg), 6) `ADT7420` I2C Temp (`0x4B`), 7) `ADMP421` PDM Mic (`2.5 MHz`), 8) `ADXL362` SPI Accelerometer + `CPU_RESETN`
  - **Mandatory Feature 1 & 2 FSMs:** `Feat 1` Movable Player & Arena Combat FSM (`COMBO 0->1->2 Nova`, Shadow Dash `36f`, Auto-Aim `<=240px`, 6 Weapons) & `Feat 2` Sprite Evolutions & Skins FSM (`Stage 0->1->2->3 Gold Armor Cap` + 4 Heads + 16f Walk BRAM)
  - **Expansion Ranking Feature 3.1–3.16 FSMs:** `3.1` Auto-Detect Input, `3.2` Unified 3-Pg Pause, `3.3` Room Wave, `3.4` Logic Quiz, `3.5` 3-Form Boss, `3.6` Zoom+2P Revive, `3.7` PDM 2P Sonic Wave, `3.8` ADT7420 Fever, `3.9` 5-Byte UART, `3.10` PS/2 Set-2 KB, `3.11` ADXL362 SPI, `3.12` OOC Regen+Gems, `3.13` Pet+Orbit Blades, `3.14` SW[15:11] Audio Mixer, `3.15` 46-Cycle TDM+VGA, `3.16` LED/RGB/7-Seg Mux

### Slide 12 — ผลทดสอบ RTL, การแบ่งงาน 5 คน & แผนสาธิตสด | 6:20 – 7:00 (คนที่ 5)
- **รูปประกอบ:** วางคู่ `01_title_2p_joy.png` และ `15_sonic_wave_2p.png` (หรือ `10_boss_ajarn_v.png`)
- **ข้อความในสไลด์:**
  - **ตารางแบ่งงาน 5 คน:** 1) VGA/Debounce/7-Seg, 2) Game Engine/Quiz/Zoom, 3) Renderer/Sprites/UI Guide, 4) UART+PS2 Bridge/Audio/Sensors, 5) Simulation Testbench/Vivado Synthesis/Slide & Report
  - **ความคืบหน้า & ผลทดสอบ:** Simulation V6 ผ่านครบทุกโหมด (สวิตช์เสียง `SW[15:11]`, `SW[0..1]`, Stage 3 Cap, 2P Sonic Wave) + แฟลชบอร์ด `xc7a100t` และเอกสาร `FSM_Specification.pdf` + `Game_Manual.pdf` + `Slide_Plan` พร้อมสาธิตสด!

---

## 4. ตาราง Feature-by-Feature FSM Specification (Feature 1, 2 & 3.1–3.16 สำหรับใส่สไลด์)

| Feature # | ชื่อฟีเจอร์ & รีจิสเตอร์หลัก | State Flow (FSM) | เงื่อนไขการเปลี่ยนสถานะ (RTL Transitions) |
| :--- | :--- | :--- | :--- |
| **Feature 1** *(บังคับ)* | **Movable Player & Arena Combat**<br>`p1_combo_step, dash_timer, pb` | `COMBO 0->1->2(Nova)` + `DASH` + `AutoAim` | 6 อาวุธ (`BTNU/D`); ฟัน 3 จังหวะปล่อย 360° Nova; Dash อมตะ `36f`; ปืนสแกนเป้า `<=240 px` (`step 42..44`) |
| **Feature 2** *(บังคับ)* | **Sprite Evolutions & Skins**<br>`stage[1:0], outfit_cut_t, hero_sel` | `0:Student->1:Shop->2:Gown->3:Gold` | Quiz Pass เลื่อน `stage+1` + `120f` Spotlight (ถึง `stage==3` Gold หยุดฉายซ้ำ!); 4 หน้าฮีโร่ (`BTNC`) + 16f Walk BRAM |
| **Feature 3.1** | **Dead Cells Auto-Input Detect** (`control_mode[1:0]`) | `00:Idle \| 01:KB 1P \| 10:Joy 1P/2P` | แตะ KB บน Title ซ่อน 2P บังคับเล่นเดี่ยว; แตะ Joy เปิด 1P/2P; ในเกม `KB \| J1` คุม P1 พร้อมกัน |
| **Feature 3.2** | **Unified 3-Pg Pause & Guide** (`help_page[1:0], paused`) | `0:Off <-> 1:Board <-> 2:Joy <-> 3:KB` | คู่มือ 3 หน้าชุดเดียวทั้ง Title/Pause + ปุ่มกลาง `[STR]/[ENT] RESUME` สลับตามอุปกรณ์ |
| **Feature 3.3** | **Room Wave Spawner** (`room_phase[2:0]`) | `BANNER(0)->FIGHT(1)->CLEAR(2)` | `90f` แบนเนอร์ + `45f` Door Slam; สปอว์น Sub-waves (30..80 ตัว); หมดห้องเปิดลูกศรประตูขวา |
| **Feature 3.4** | **Logic Gate Quiz Door** (`RP_QUIZ->RP_DOOR`) | `Gates 0..5 (AND..XOR)` | 30f lockout; ถูกสไลด์ประตู `0..31`; ผิดขึ้น `"F: GO RETAKE !!" (105f)` รีเซ็ตด่านเดิม |
| **Feature 3.5** | **3-Form Boss Ajarn_V** (`RP_BOSS(5)`) | `F0(105)->Portal(160f)->F1(145)->F2(190)` | ร่างสุดท้าย `HP<=95` Enraged; ฟันรัว 3 ครั้งผลัก Knockback `220 px` + สตั๊น `60f` |
| **Feature 3.6** | **Brawlhalla Zoom & 2P Revive** (`zoom_lvl[6:0]`) | `view_w 320..520` + `Revive 12HP` | คำนวณ `dx_sep/dy_sep` ซูมลื่น; เข้า `RP_BANNER` ชุบเพื่อนที่ล้มอัตโนมัติ (`12 HP`) |
| **Feature 3.7** | **PDM Mic 2P Sonic Wave** (`mic_roar, sonic_wave_t`) | `LISTEN->ROAR(320ms)->EXPAND` | `2.5 MHz` 128-sample (`raw_dev>=28`) ปล่อยวง P1 Cyan + P2 Pink (`100/140/180 px`) |
| **Feature 3.8** | **ADT7420 I2C Thermal Fever** (`i2c state[4:0]`) | `S_IDLE..WR_ADDR..RD..UPDATE` | อ่าน `0x4B` ทุก `100ms`; `eff_temp_fever=(temp>=base+1C)\|\|(temp>=35C)\|\|SW[0]` (`+2 DMG`), `SW[1]` โชว์ 7-Seg |
| **Feature 3.9** | **5-Byte UART + Quiz Mux** (`u_state, pkt_state`) | `U_IDLE..STOP` + `B0..B4` | `115,200 bps` ซิงค์ `B0[7]=1` + J1/J2/KB + `b4[6]` Quiz Mux + Watchdog `1 วิ` |
| **Feature 3.10** | **Direct PS/2 KB Decoder** (`ps2_keyboard.v`) | `11-bit RX` + `F0 Break / E0 Ext` | เสียบ KB ตรง (`F4/B2`) กรอง 8-sample & OR รวมกับ UART KB |
| **Feature 3.11** | **ADXL362 SPI Accelerometer** (`acl_tilt.v`) | `S_PWRUP(0)..S_RD(7)..WAIT10(8)` | `1.04 MHz SPI` อ่าน `XL/XH/YL/YH` ทุก `10 ms` |
| **Feature 3.12** | **OOC Regen, Gems & Sky Drop** (`regen_wait, drop_z`) | `COMBAT->WAIT(360f)->REGEN` | พักรบ `6 วิ` ฟื้น `+1 HP/90f`; Gem ดูด `76 px` (เต็ม 60 รีฟูล); Sky Drops แรงโน้มถ่วง `drop_z` |
| **Feature 3.13** | **Pet Auto-Bolt & Orbit Blades** (`pet_active, blade_ang`) | `Stage>=1 Pet \| Stage>=2 Blades` | Pet ยิงนำวิถี (`Stage>=1`); Orbit Blades หมุนด้วย Cos/Sin 16 ขั้น (`Stage>=2`) |
| **Feature 3.14** | **SW[15:11] Audio Mixer FSM** (`audio_synth_v2.v`) | `4 Songs + SFX + SW[15:11]` | `SW15` Mute ทั้งระบบ, `SW14` BGM Mute, `SW13` SFX Mute, `SW[12:11]` 100/50/25/12.5% Vol |
| **Feature 3.15** | **46-Cycle VBlank TDM & VGA** (`step_state[5:0]`) | `VBlank->P1->P2->Cam->En[0..15]` | จบใน 46 clks ส่งต่อ `4-Stage VGA Pipeline` ไร้ Timing Violation |
| **Feature 3.16** | **Board LED / RGB / 7-Seg Mux** (`board_io_v2.v`) | `EXP/Fever/Mic LED + AN[7:0]` | Debounce 5ms; ขับ 16 LEDs, `LED16` Temp, `LED17` Mic/Audio, 7-Seg Score หรือ `SW[1]` Celsius |
