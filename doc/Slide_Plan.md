# คู่มือวางแผนทำสไลด์ Canva — VeePire Survivors (ฉบับเพื่อนที่ไม่รู้ Digital / Verilog ก็ทำตามได้!)

> **อ้างอิงเกณฑ์:** `UTF-8CPE222+Final+brief.pdf` (วิชา CPE222 Digital Logic Design — บอร์ด Digilent Nexys A7-100T)
> **เวลาพูด:** **7 นาที 00 วินาที** | **สมาชิก:** **5 คน** | **จำนวนสไลด์:** **11 สไลด์**
> **ไฟล์ PDF ที่มีภาพประกอบ + Diagram + Layout ตัวอย่างครบ:** `D:\vivado_pj\DRAGO_NEXUS_V2\doc\Canva_Slide_Guide.pdf`

---

## 0. ปูพื้นฐาน 1 นาทีสำหรับเพื่อน (ไม่ต้องรู้ Digital / Verilog ก็เข้าใจ!)

| คำศัพท์ในสไลด์ | แปลเป็นภาษาคนทั่วไป (เอาไว้เข้าใจและอธิบายอาจารย์ได้) |
| :--- | :--- |
| **FPGA (บอร์ด Nexys A7)** | ชิปที่จำลองตัวเองเป็น "วงจรอิเล็กทรอนิกส์" ตามโค้ดที่เราเขียน ต่างจากคอมพิวเตอร์ตรงที่ทุกอย่างทำงานพร้อมกันเป็นฮาร์ดแวร์ล้วนๆ |
| **Pure Verilog (ไม่ใช้ MicroBlaze)** | เราเขียนโค้ดสร้างวงจรเกมเอง 100% ไม่ได้แอบเอา CPU สำเร็จรูป (`MicroBlaze`) มาลงแล้วเขียนภาษา C |
| **VGA `640×480 @ 60 Hz` (12-bit)** | สายต่อจอคอมแบบสีน้ำเงิน แสดงภาพขนาด `640×480` พิกเซล วาดใหม่วินาทีละ `60` ภาพ มีสีให้ใช้ `4,096` สี (`12-bit RGB`) |
| **VBlank Update** | ช่วงพักสั้นๆ ระหว่างวาดจอเสร็จ 1 ภาพ เราอัปเดตตำแหน่งตัวละครในช่วงนี้เท่านั้น ภาพจะได้ไม่ขาดครึ่งจอ |
| **Debouncer (5 ms)** | วงจรกันปุ่มบนบอร์ดเด้ง (เวลากดปุ่ม 1 ครั้ง สัญญาณจริงมันสั่นรัวๆ เลยต้องกรองให้นิ่ง 5 มิลลิวินาที) |
| **BRAM** | หน่วยความจำขนาดเล็กบนชิป FPGA เอาไว้เก็บรูปตัวละคร, แผนที่, และโน้ตเพลง |
| **FSM (Finite State Machine)** | แผนผัง "สถานะของเกม" ว่าตอนนี้เกมอยู่หน้าไหน (หน้าเริ่ม → กำลังเล่น → หยุดพัก → ตอบควิซ → บอส → ชนะ/แพ้) |
| **Joystick Bridge (UART)** | โปรแกรม Python บนคอม ทำหน้าที่เป็น "ล่าม/สะพาน" อ่านปุ่มจอย USB แล้วส่งผ่านสาย Micro-USB เข้าบอร์ด FPGA |

---

## 1. การตกแต่ง Canva & ไฟล์รูปที่ต้องดึงไปใส่

- **โทนสีแนะนำ (Arcade Dark Theme):**
  - พื้นหลัง: `#0D1117` (ดำน้ำเงินเข้ม) | การ์ด/กล่องข้อความ: `#161B22` ขอบบางสี `#30363D`
  - สีเน้นหัวข้อ: `#00E5FF` (ฟ้าไซเบอร์) | สีเน้นตัวเลข/คะแนน: `#FFD54F` (เหลืองทอง) | สีเน้นบอส/ควิซ: `#FF4081` (ชมพูนีออน)
- **ฟอนต์:** หัวข้อ `Montserrat ExtraBold` / `Space Grotesk` — เนื้อหา `Noto Sans Thai` หรือ `IBM Plex Sans Thai`
- **คลังภาพจริงของโปรเจกต์ (เปิดดู/ลากลง Canva ได้เลย):**
  - `D:\vivado_pj\DRAGO_NEXUS_V2\sprite_preview.png` (รวมฮีโร่ชุดนักศึกษา/ช็อปวิศวะ/ครุย + ศัตรูกีกี้สูทดำ + บอส Ajarn_V 3 ร่าง + ดาบ + หัวใจ)
  - `D:\vivado_pj\DRAGO_NEXUS_V2\docs\screenshots\shot_title.png` (หน้าจอ Title)
  - `D:\vivado_pj\DRAGO_NEXUS_V2\docs\screenshots\shot_combat_lunge.png` (ฉากสู้ฟันดาบ 4 จังหวะในห้องเดี่ยว)
  - `D:\vivado_pj\DRAGO_NEXUS_V2\docs\screenshots\shot_upgrade_cutscene.png` (คัตซีนสปอตไลท์เปลี่ยนชุด "NEW GEAR -> EQUIPPED")
  - `D:\vivado_pj\DRAGO_NEXUS_V2\docs\screenshots\shot_coop_zoom.png` (หน้าต่างควิซ Logic Gate และ 2P Co-op)
  - `D:\vivado_pj\DRAGO_NEXUS_V2\docs\screenshots\shot_boss_locked.png` (บอส Ajarn_V + ระบบ Auto-Aim ปืนล็อคเป้า 100%)

---

## 2. การแบ่งเวลาพูด 7 นาที สำหรับสมาชิก 5 คน

| สมาชิก | ช่วงเนื้อหา | สไลด์ | เวลาพูด |
| :--- | :--- | :--- | :--- |
| **คนที่ 1** | เปิดตัว, แนวคิดเกม & Objectives, สเปกฮาร์ดแวร์ตาม Brief | Slide 1 – 3 | **1:15 นาที** (`0:00 – 1:15`) |
| **คนที่ 2** | Feature 1 (บังคับตัวละคร/ห้องเดี่ยว/ปืน Auto-Aim 100%/ฟันดาบ 4 จังหวะ) & Feature 2 (ชุดนักศึกษา-ช็อป-ครุย/หลอดเลือด Regen/สกิน `SW15–12` & `SW3–0`) | Slide 4 – 5 | **1:20 นาที** (`1:15 – 2:35`) |
| **คนที่ 3** | Feature 3 (2P Co-op อัปเกรดร่วม, ควิซประตูสไลด์ + คัตซีนเปลี่ยนชุด + ลงโทษ GO RETAKE, บอส 3 ร่าง Super Knockback) & System Block Diagram | Slide 6 – 7 | **1:25 นาที** (`2:35 – 4:00`) |
| **คนที่ 4** | **หน้า FSM Diagram** และ **หน้า PC-to-FPGA Joystick Bridge** | Slide 8 – 9 | **1:40 นาที** (`4:00 – 5:40`) |
| **คนที่ 5** | การแบ่งงาน 5 คน + Timeline, ความคืบหน้าปัจจุบัน & ปิดท้าย/Demo | Slide 10 – 11 | **1:20 นาที** (`5:40 – 7:00`) |

---

## 3. รายละเอียดสไลด์ทั้ง 11 หน้า (ข้อความก๊อปวาง + วิธีจัดวางใน Canva)

### Slide 1 — หน้าปก (Title Slide) | 0:00 – 0:20 (คนที่ 1)
- **Layout:** ซ้ายวางชื่อโปรเจกต์ใหญ่ๆ + ชื่อสมาชิก 5 คน / ขวาวางรูป `shot_title.png` คู่กับรูปบอร์ด Nexys A7
- **ข้อความในสไลด์:**
  - `VeePire Survivors`
  - `2D Co-op Action RPG on Digilent Nexys A7-100T FPGA`
  - `CPE222 Digital Logic Design — Final Project Proposal`
  - `Group <เลขกลุ่ม> | สมาชิก 5 คน (ใส่ชื่อ-รหัส)`

### Slide 2 — แนวคิดเกม & วัตถุประสงค์ (Objectives) | 0:20 – 0:50 (คนที่ 1)
- **Layout:** แบ่ง 2 คอลัมน์ — ซ้าย "Project Objectives (ตาม Brief)" / ขวา "Game Concept"
- **ข้อความในสไลด์:**
  - **Objectives:** ออกแบบวงจรเกม Real-time ด้วย Pure Verilog, สร้างวงจรแสดงผล VGA + อ่านจอย, ควบคุมเกมด้วย FSM, ทำงานร่วมกัน 5 คน
  - **Game Concept:** เกมตะลุยด่านห้องสี่เหลี่ยมเดี่ยว 6 Waves ควบคุมด้วย **จอยสติ๊ก (1P / 2P Co-op)** สู้ศัตรูหน้าคนชุดสูทดำ → ตอบควิซ Logic Gate เปิดประตูสไลด์พร้อมคัตซีนแปลงร่างเปลี่ยนชุด → ปิดท้ายด้วยบอส **Ajarn_V 3 ร่างงอกจาก Portal พร้อมระบบป้องกันสแปม Super Knockback**

### Slide 3 — ฮาร์ดแวร์และข้อกำหนด (Hardware & Requirements) | 0:50 – 1:15 (คนที่ 1)
- **Layout:** การ์ด 4 ใบเรียง 2×2 (Display / Board I/O / Timing & Design / Extras & Credit)
- **ข้อความในสไลด์:**
  - **VGA Output:** `640×480 @ 60 Hz`, 12-bit RGB (`4,096` สี)
  - **On-Board I/O:** `SW[15:12]` เลือกสกินฝั่งซ้าย (P1) และ `SW[3:0]` เลือกสกินฝั่งขวา (P2), `16 LEDs` + `8-Digit 7-Segment` แสดงคะแนน/HP/Wave, ปุ่มบนบอร์ดผ่าน `5 ms Debouncer`
  - **Design Rule:** เขียนด้วย Pure Verilog บน Vivado (ไม่ใช้ MicroBlaze) และอัปเดตเฟรมเฉพาะช่วง **VBlank**
  - **Optional Extras & Credit:** USB Joystick Bridge (UART), PWM 3-Ch Audio, ADXL362 *(ให้เครดิต SPI Driver จาก FPGADude)*

### Slide 4 — Feature 1: Movable Player & Arena Combat (25%) | 1:15 – 1:55 (คนที่ 2)
- **Layout:** ซ้ายหัวข้อ + 4 Bullet / ขวารูป `shot_combat_lunge.png`
- **ข้อความในสไลด์:**
  - **Joystick-Only 8-Direction:** เดิน 8 ทิศทาง 2 ระดับความเร็ว (Analog / D-Pad) ทั้ง **1P** และ **2P Co-op**
  - **Single-Room Arena:** เห็นเฉพาะห้องสี่เหลี่ยมของด่านนั้น รอบนอกสีดำสนิท ชนกำแพง/ศัตรู/ประตูแม่นยำ
  - **Extended 4-Hit Sword Slash:** อนิเมชันฟันดาบ 4 จังหวะ (Stance -> Anticipation -> Shear -> Follow-through) ปราศจากเอฟเฟคบดบังสายตา
  - **Auto-Aim 100% Gun:** กดปุ่ม `Y` กระสุนปืนฟ้าจะคำนวณเวกเตอร์ล็อคเป้าศัตรูเดี่ยวอัตโนมัติ ไม่ต้องเล็งมือ
  - **Shadow Dash & Chrono-Shift:** พุ่งเร็วอมตะ + ชะลอเวลา `L2/R2` พร้อมปุ่ม `Start` Pause และ `Select` Menu

### Slide 5 — Feature 2: Outfits Progression, HP Regen & Skins | 1:55 – 2:35 (คนที่ 2)
- **Layout:** บน: ลำดับชุด Progression (Student -> CPE Shop -> Graduation) / ล่าง: รูป `sprite_preview.png`
- **ข้อความในสไลด์:**
  - **ชุดเปลี่ยนตามชั้นปี (Progression Outfits):**
    - `Wave 1`: ชุดนักศึกษา (Student) เสื้อขาวแขนยาว กางเกงดำ
    - `Wave 2`: เสื้อช็อปวิศวะคอมพิวเตอร์ มจธ. (CPE Shop `#405F73`)
    - `Wave 3+ & Boss`: ชุดครุยวิทยฐานะ มจธ. (Graduation Gown)
    - `Enemies`: ศัตรูกีกี้สวมสูทดำสุดเนี้ยบ
  - **สกินฮีโร่หน้าคนแยกฝั่ง (`SW15–12` ซ้าย / `SW3–0` ขวา):** เลือกฮีโร่หน้าคน 4 คนอิสระทั้ง P1 และ P2
  - **หลอดเลือด HP Bar + Out-of-Combat Regen + หัวใจ (`♥`):** หลอดเลือด 24 HP อัตราดรอปหัวใจลดลง ออกจากคอมแบตเพื่อฟื้นฟูอัตโนมัติ

### Slide 6 — Feature 3: Our Own Creative Features (10%) | 2:35 – 3:20 (คนที่ 3)
- **Layout:** แบ่ง 2 ฝั่ง — ซ้ายรูป `shot_upgrade_cutscene.png` / ขวารูป `shot_boss_locked.png`
- **ข้อความในสไลด์:**
  1. **2P Co-op & Shared Upgrades:** ดาบหมุน Orbit Swords และไอเทมอัปเกรดแชร์เท่ากันทั้ง 2 คน / เพื่อนล้มจะนอนกองกับพื้นจนกว่าจะเคลียร์ Wave เพื่อนจึงฟื้น
  2. **Logic Gate Quiz & Cutscene:** ประตูสไลด์สุ่มโจทย์ Gate ตอบถูกจะเกิด **Cutscene สปอตไลท์เปลี่ยนชุด ("NEW GEAR -> EQUIPPED")** / ตอบผิดโผล่ **"CAUTION: GO RETAKE !!"** แจกเกรด F รีเซ็ต Wave ทันที
  3. **Final Boss 3 ร่าง & Anti-Melee Knockback:** บอส Ajarn_V 3 ร่าง ปรับสมดุลดาเมจ 1 HP/ครั้ง และหากผู้เล่นเข้าไปสแปมฟันดาบ บอสจะผลักกระเด็นไกล **220 px** ติดสตั๊น 1 วินาที!
  4. **3-Channel BRAM BGM + SFX:** เพลง 8-bit 3 ช่องเสียงเปลี่ยนตามบรรยากาศการต่อสู้

### Slide 7 — System Architecture & Block Diagram | 3:20 – 4:00 (คนที่ 3)
- **Layout:** วาง Block Diagram ขนาดใหญ่เต็มกลางหน้า (ดูภาพตัวอย่างใน `Canva_Slide_Guide.pdf`)
- **คำอธิบายภาษาคนทั่วไป:**
  - **ฝั่งรับคำสั่ง (Input):** จอยคู่ → PC Bridge → `uart_joy_rx` + สวิตช์/ปุ่มบนบอร์ด (`board_io_v2`)
  - **สมองกลาง (Core):** `game_engine_v2` คำนวณตำแหน่ง, คอมโบ, ควิซ, สถานะบอส (อัปเดต 60 ครั้ง/วิ)
  - **ฝั่งแสดงผล (Output):** `vga_renderer_v2` ดึงรูปจาก BRAM วาดขึ้นจอ VGA + `audio_synth_v2` ส่งเสียงออกลำโพง + ไฟ LED/7-Segment

### Slide 8 — Finite State Machine (FSM) Design | 4:00 – 4:50 (คนที่ 4)
- **Layout:** แบ่งซ้าย (Main Game FSM) และ ขวา (Room & Boss Sub-FSM) พร้อมลูกศรเชื่อมสถานะชัดเจน
- **สถานะหลัก (`game_state`):** `ST_TITLE` → `ST_PLAY` (`PAUSED` เมื่อกด Start) → `ST_WIN` หรือ `ST_LOSE`
- **สถานะย่อยในด่าน (`room_phase`):**
  1. `RP_BANNER`: ขึ้น `DOOR LOCKED! PANG!` + แบนเนอร์ `WAVE X`
  2. `RP_FIGHT`: สู้ศัตรู 2 Sub-waves (สำหรับ Wave 1–5) หรือสู้บอส (Wave 6)
  3. `RP_CLEAR`: ศัตรูหมด → ลูกศรเด้งกระพริบชี้ไปประตูสไลด์
  4. `RP_QUIZ`: ชนประตู → สุ่มควิซ Logic Gate (ตอบถูก → Cutscene สปอตไลท์เปลี่ยนชุด / ตอบผิด → CAUTION RETAKE รีเซ็ต Wave)
  5. `RP_DOOR`: ประตูสไลด์เปิด → เดินเข้าเพื่อไป `Wave + 1`
  6. `RP_BOSS`: บอสร่าง 0/1/2 ตาย → ระเบิด + คำพูดเบียว + Portal งอกร่างถัดไป

### Slide 9 — PC-to-FPGA Joystick Bridge | 4:50 – 5:40 (คนที่ 4)
- **Layout:** แผนภาพไหลจากซ้ายไปขวา 4 กล่องใหญ่ (Twin USB Joy → Python Bridge บน PC → สาย Micro-USB UART → วงจรถอดรหัสบน FPGA)
- **โครงสร้าง 4 ไบต์ Real-time @ 115,200 bps:**
  - `Byte 0`: หัวข้อ `1` (`0x80`) + **บิตที่ 6 (`Auto-Aim Shoot` จอย 1)** + ทิศทาง `dx, dy` ของจอย 1
  - `Byte 1`: **บิตที่ 6 (`Auto-Aim Shoot` จอย 2)** + ทิศทาง `dx, dy` ของจอย 2
  - `Byte 2`: ปุ่ม `Attack / Dash / Chrono` ของทั้ง 2 จอย + **บิตที่ 6 (`Start` สำหรับ Pause)**
  - `Byte 3`: **บิตที่ 0 (`Select` สำหรับกลับหน้า Menu)**
- วงจร `uart_joy_rx.v` ตอบสนอง Real-time ไร้ดีเลย์

### Slide 10 — Work Plan & การแบ่งงานสมาชิก 5 คน | 5:40 – 6:20 (คนที่ 5)
- **Layout:** Timeline 3 หมุด (`13/11 Proposal` → `20/11 Progress Demo` → `27/11 Final Video & Report`) + ตารางหน้าที่ 5 คน
  - **คนที่ 1:** ระบบภาพพื้นฐาน VGA, นาฬิกา, Debouncer ปุ่ม/สวิตช์, ไฟ LED & 7-Segment
  - **คนที่ 2:** ระบบเกมหลัก (`game_engine_v2`), คอมโบ, การซูม, ระบบควิซประตูสไลด์
  - **คนที่ 3:** ระบบวาดกราฟิก (`vga_renderer_v2`), แปลงภาพหน้าคน/ชุดนักศึกษา-ช็อป-ครุย/สูทดำ/บอสลง BRAM
  - **คนที่ 4:** สะพานเชื่อมจอยคู่ (`joy_bridge.py` + `uart_joy_rx.v`) และระบบเสียงเพลง 3 ช่อง (`audio_synth_v2`)
  - **คนที่ 5:** ทดสอบ Simulation & บอร์ดจริง, ทำสไลด์, ตัดต่อวิดีโอ Demo และรวมเล่ม Final Report

### Slide 11 — ความคืบหน้าปัจจุบัน & แผนส่งงาน (Progress & Demo) | 6:20 – 7:00 (คนที่ 5)
- **Layout:** ซ้าย Checklist สีเขียว / ขวา แผนถึงวันส่ง 27/11 + เชิญชม Demo
- **เสร็จและทดสอบแล้ว:**
  - Simulation ผ่าน 100% (`RESULT : PASS`)
  - คอมไพล์บน Vivado 2024.2 ผ่าน (`0 Errors`)
  - แฟลชลงบอร์ด Nexys A7-100T จริงเรียบร้อย
  - ระบบ Co-op 2P, Shared Upgrades, Progression Outfits, Auto-Aim 100%, Cutscene เปลี่ยนชุด และ Boss Anti-Melee Knockback สมบูรณ์แบบ!
