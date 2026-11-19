"""
DRAGO-NEXUS V2 - Twin USB Joystick & Wireless Keyboard -> Nexys A7 UART Bridge
Reads:
  1. USB Joystick 1 & 2 via Windows winmm.dll (Digital & Analog modes)
     Matching real_joystick buttons:
       Btn 1 (Top Green)  = Bullet Shoot
       Btn 2 (Right Red)  = Dash
       Btn 3 (Bottom Blue)= Attack / Play
       Btn 4 (Left Pink)  = 360 Nova
       Select (Btn 9)     = Controls Guide / Exit
       Start  (Btn 10)    = Pause / Guide
  2. Wireless / USB / Laptop Keyboard via Windows user32.dll GetAsyncKeyState
     (WASD / Arrows = Move, Space/J = Attack, K/E/Z = Dash, 3/L = Nova, 4/U = Bullet, 1-4 = Quiz, Enter = Pause, Esc = Guide/Back)
Streams 5-byte packets @ 115200 baud to Nexys A7 USB-UART (UART_TXD_IN).
"""
import argparse
import ctypes
from ctypes import wintypes
import sys
import time
import winreg

winmm = ctypes.WinDLL("winmm")
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)
user32 = ctypes.WinDLL("user32", use_last_error=True)

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
OPEN_EXISTING = 3
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value

# Virtual-Key codes
VK_LEFT = 0x25
VK_UP = 0x26
VK_RIGHT = 0x27
VK_DOWN = 0x28
VK_SPACE = 0x20
VK_RETURN = 0x0D
VK_ESCAPE = 0x1B


def is_key_down(vk):
    return bool(user32.GetAsyncKeyState(vk) & 0x8000)


class JOYCAPS(ctypes.Structure):
    _fields_ = [
        ("wMid", wintypes.WORD), ("wPid", wintypes.WORD),
        ("szPname", wintypes.WCHAR * 32),
        ("wXmin", wintypes.UINT), ("wXmax", wintypes.UINT),
        ("wYmin", wintypes.UINT), ("wYmax", wintypes.UINT),
        ("wZmin", wintypes.UINT), ("wZmax", wintypes.UINT),
        ("wNumButtons", wintypes.UINT), ("wPeriodMin", wintypes.UINT), ("wPeriodMax", wintypes.UINT),
        ("wRmin", wintypes.UINT), ("wRmax", wintypes.UINT),
        ("wUmin", wintypes.UINT), ("wUmax", wintypes.UINT),
        ("wVmin", wintypes.UINT), ("wVmax", wintypes.UINT),
        ("wCaps", wintypes.UINT), ("wMaxAxes", wintypes.UINT), ("wNumAxes", wintypes.UINT),
        ("wMaxButtons", wintypes.UINT), ("szRegKey", wintypes.WCHAR * 32),
        ("szOEMVxD", wintypes.WCHAR * 260),
    ]


class JOYINFOEX(ctypes.Structure):
    _fields_ = [
        ("dwSize", wintypes.DWORD), ("dwFlags", wintypes.DWORD),
        ("dwXpos", wintypes.DWORD), ("dwYpos", wintypes.DWORD),
        ("dwZpos", wintypes.DWORD), ("dwRpos", wintypes.DWORD),
        ("dwUpos", wintypes.DWORD), ("dwVpos", wintypes.DWORD),
        ("dwButtons", wintypes.DWORD), ("dwButtonNumber", wintypes.DWORD),
        ("dwPOV", wintypes.DWORD), ("dwReserved1", wintypes.DWORD), ("dwReserved2", wintypes.DWORD),
    ]


class DCB(ctypes.Structure):
    _fields_ = [
        ("DCBlength", wintypes.DWORD),
        ("BaudRate", wintypes.DWORD),
        ("fBits", wintypes.DWORD),
        ("wReserved", wintypes.WORD),
        ("XonLim", wintypes.WORD),
        ("XoffLim", wintypes.WORD),
        ("ByteSize", ctypes.c_ubyte),
        ("Parity", ctypes.c_ubyte),
        ("StopBits", ctypes.c_ubyte),
        ("XonChar", ctypes.c_char),
        ("XoffChar", ctypes.c_char),
        ("ErrorChar", ctypes.c_char),
        ("EofChar", ctypes.c_char),
        ("EvtChar", ctypes.c_char),
        ("wReserved1", wintypes.WORD),
    ]


class COMMTIMEOUTS(ctypes.Structure):
    _fields_ = [
        ("ReadIntervalTimeout", wintypes.DWORD),
        ("ReadTotalTimeoutMultiplier", wintypes.DWORD),
        ("ReadTotalTimeoutConstant", wintypes.DWORD),
        ("WriteTotalTimeoutMultiplier", wintypes.DWORD),
        ("WriteTotalTimeoutConstant", wintypes.DWORD),
    ]


def find_nexys_com_port():
    candidates = []
    try:
        key = winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"HARDWARE\DEVICEMAP\SERIALCOMM")
        idx = 0
        while True:
            try:
                name, val, _ = winreg.EnumValue(key, idx)
                candidates.append((name, val))
                idx += 1
            except OSError:
                break
        winreg.CloseKey(key)
    except OSError:
        pass

    for name, val in candidates:
        if "VCP" in name.upper() or "FTDI" in name.upper():
            return val
    for name, val in candidates:
        if "BTH" not in name.upper():
            return val
    return "COM12"


def open_serial(port_name, baud=115200):
    path = f"\\\\.\\{port_name}"
    h = kernel32.CreateFileW(path, GENERIC_READ | GENERIC_WRITE, 0, None, OPEN_EXISTING, 0, None)
    if h == INVALID_HANDLE_VALUE or not h:
        err = ctypes.get_last_error()
        raise OSError(f"Cannot open {port_name} (WinErr={err}). Close Vivado Serial/other apps if open.")

    dcb = DCB()
    dcb.DCBlength = ctypes.sizeof(DCB)
    if not kernel32.GetCommState(h, ctypes.byref(dcb)):
        kernel32.CloseHandle(h)
        raise OSError("GetCommState failed")

    dcb.BaudRate = baud
    dcb.ByteSize = 8
    dcb.Parity = 0
    dcb.StopBits = 0
    dcb.fBits = 0x00000011
    if not kernel32.SetCommState(h, ctypes.byref(dcb)):
        kernel32.CloseHandle(h)
        raise OSError("SetCommState failed")

    timeouts = COMMTIMEOUTS(50, 0, 50, 0, 100)
    kernel32.SetCommTimeouts(h, ctypes.byref(timeouts))
    return h


def write_serial(h, data: bytes):
    written = wintypes.DWORD(0)
    ok = kernel32.WriteFile(h, data, len(data), ctypes.byref(written), None)
    return bool(ok) and written.value == len(data)


def decode_axis(val, dead=7500, steep=22000):
    diff = int(val) - 32767
    if diff <= -steep:
        return -2
    if diff <= -dead:
        return -1
    if diff >= steep:
        return 2
    if diff >= dead:
        return 1
    return 0


def read_pad(joy_id):
    info = JOYINFOEX()
    info.dwSize = ctypes.sizeof(JOYINFOEX)
    info.dwFlags = 0xFF
    if winmm.joyGetPosEx(joy_id, ctypes.byref(info)) != 0:
        return 0, 0, 0, 0, 0, 0, False

    dx = decode_axis(info.dwXpos)
    dy = decode_axis(info.dwYpos)

    pov = info.dwPOV
    if pov != 0xFFFF and pov < 36000:
        if pov >= 31500 or pov <= 4500:
            dy = -2
        elif 13500 <= pov <= 22500:
            dy = 2
        if 4500 <= pov <= 13500:
            dx = 2
        elif 22500 <= pov <= 31500:
            dx = -2

    b = info.dwButtons
    # Matching real_joystick.webp:
    #   Btn 1 (bit 0, Top Green)   -> Bullet Shoot
    #   Btn 2 (bit 1, Right Red)   -> Dash (+ L1 bit 4)
    #   Btn 3 (bit 2, Bottom Blue) -> Attack / Play (+ R1 bit 5)
    #   Btn 4 (bit 3, Left Pink)   -> 360 Nova (+ L2/R2 bits 6..7)
    shoot_y    = 1 if (b & (1 << 0)) else 0
    dash       = 1 if (b & ((1 << 1) | (1 << 4))) else 0
    fire       = 1 if (b & ((1 << 2) | (1 << 5))) else 0
    nova       = 1 if (b & ((1 << 3) | (1 << 6) | (1 << 7))) else 0
    select_btn = 1 if (b & (1 << 8)) else 0
    start_btn  = 1 if (b & (1 << 9)) else 0
    btn_bits   = (fire << 2) | (dash << 1) | nova
    return dx, dy, btn_bits, shoot_y, start_btn, select_btn, True


def read_keyboard():
    dx = 0
    dy = 0
    if is_key_down(0x41) or is_key_down(VK_LEFT):   # A or Left
        dx -= 2
    if is_key_down(0x44) or is_key_down(VK_RIGHT):  # D or Right
        dx += 2
    if is_key_down(0x57) or is_key_down(VK_UP):     # W or Up
        dy -= 2
    if is_key_down(0x53) or is_key_down(VK_DOWN):   # S or Down
        dy += 2

    dx = max(-2, min(2, dx))
    dy = max(-2, min(2, dy))

    fire       = 1 if (is_key_down(VK_SPACE) or is_key_down(0x4A)) else 0  # Space or J
    dash       = 1 if (is_key_down(0x4B) or is_key_down(0x45) or is_key_down(0x5A)) else 0 # K, E, Z
    nova       = 1 if (is_key_down(0x33) or is_key_down(0x4C)) else 0      # 3 or L
    shoot_y    = 1 if (is_key_down(0x34) or is_key_down(0x55)) else 0      # 4 or U
    start_btn  = 1 if is_key_down(VK_RETURN) else 0                        # Enter
    select_btn = 1 if is_key_down(VK_ESCAPE) else 0                        # Esc

    quiz_hit = 0
    quiz_sel = 0
    for idx, vk in enumerate((0x31, 0x32, 0x33, 0x34)):
        if is_key_down(vk):
            quiz_hit = 1
            quiz_sel = idx
            break

    btn_bits = (fire << 2) | (dash << 1) | nova
    has_kb = any([dx, dy, btn_bits, shoot_y, start_btn, select_btn, quiz_hit])
    return dx, dy, btn_bits, shoot_y, start_btn, select_btn, quiz_sel, quiz_hit, has_kb


def enc_axis(v):
    return max(0, min(4, int(v) + 2))


def main():
    parser = argparse.ArgumentParser(description="DRAGO-NEXUS V2 Joystick & Wireless Keyboard Bridge")
    parser.add_argument("--port", default="", help="COM port (auto-detected if omitted)")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate (default 115200)")
    args = parser.parse_args()

    port = args.port or find_nexys_com_port()
    print("==========================================================")
    print("  DRAGO-NEXUS V2 : Dual USB Joystick + Keyboard Bridge")
    print(f"  Target Port : {port} @ {args.baud} baud")
    print("  Controls:")
    print("    - Gamepad : D-pad=Move, Btn1=Bullet, Btn2=Dash, Btn3=Attack, Btn4=Nova, Select/Start")
    print("    - Keyboard: W/A/S/D/Arrows=Move, Space/J=Attack, K/E/Z=Dash, 3/L=Nova, 4/U=Bullet, 1-4=Quiz, Esc=Guide")
    print("==========================================================")

    try:
        h_ser = open_serial(port, args.baud)
    except Exception as e:
        print(f"[ERROR] Failed to open serial port {port}: {e}")
        sys.exit(1)

    print(f"[OK] Connected to {port}. Streaming 5-byte packets to FPGA...")
    frame = 0
    prev_state = None

    try:
        while True:
            j1_dx, j1_dy, j1_btn, j1_shoot, j1_start, j1_sel, has_j1 = read_pad(0)
            j2_dx, j2_dy, j2_btn, j2_shoot, j2_start, j2_sel, has_j2 = read_pad(1)

            kb_dx, kb_dy, kb_btn, kb_shoot, kb_start, kb_sel, kb_qsel, kb_qhit, has_kb = read_keyboard()

            b0 = 0x80 | ((j1_shoot & 1) << 6) | (enc_axis(j1_dy) << 3) | enc_axis(j1_dx)
            b1 = 0x00 | ((j2_shoot & 1) << 6) | (enc_axis(j2_dy) << 3) | enc_axis(j2_dx)
            b2 = (((j1_start | j2_start) & 1) << 6) | ((j2_btn & 7) << 3) | (j1_btn & 7)
            b3 = 0x00 | ((kb_shoot & 1) << 6) | (enc_axis(kb_dy) << 3) | enc_axis(kb_dx)
            kb_meta = (kb_qsel & 3) if kb_qhit else (((kb_sel & 1) << 1) | (kb_start & 1))
            b4 = 0x00 | ((kb_qhit & 1) << 6) | (kb_meta << 4) | (((j1_sel | j2_sel) & 1) << 3) | (kb_btn & 7)

            pkt = bytes([b0, b1, b2, b3, b4])
            write_serial(h_ser, pkt)

            cur_state = (j1_dx, j1_dy, j1_btn, j1_shoot, j2_dx, j2_dy, j2_btn, kb_dx, kb_dy, kb_btn, kb_shoot, kb_start, kb_sel, kb_qhit)
            if cur_state != prev_state and any(cur_state):
                print(f"[Input] J1=({j1_dx:+d},{j1_dy:+d},b={j1_btn:03b}) KB=({kb_dx:+d},{kb_dy:+d},b={kb_btn:03b},sh={kb_shoot},ent={kb_start},esc={kb_sel})")
            prev_state = cur_state

            frame += 1
            if frame % 300 == 0:
                print(f"[Alive #{frame:06d}] Port={port} | J1:({j1_dx:+d},{j1_dy:+d}) | KB:({kb_dx:+d},{kb_dy:+d},b={kb_btn:03b})")

            time.sleep(0.016)

    except KeyboardInterrupt:
        print("\n[STOP] Bridge terminated by user.")
    finally:
        kernel32.CloseHandle(h_ser)


if __name__ == "__main__":
    main()
