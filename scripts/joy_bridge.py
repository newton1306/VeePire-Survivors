"""
DRAGO-NEXUS V2 - Twin USB Joystick -> Nexys A7-100T UART Bridge (Zero-dependency)
Reads Joystick 1 & Joystick 2 via Windows winmm.dll (works in both Digital & Analog modes)
and streams 3-byte packets @ 115200 baud to Nexys A7 USB-UART (UART_TXD_IN).
"""
import argparse
import ctypes
from ctypes import wintypes
import sys
import time
import winreg

winmm = ctypes.WinDLL("winmm")
kernel32 = ctypes.WinDLL("kernel32", use_last_error=True)

GENERIC_READ = 0x80000000
GENERIC_WRITE = 0x40000000
OPEN_EXISTING = 3
INVALID_HANDLE_VALUE = ctypes.c_void_p(-1).value


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
    """Auto-detect FTDI VCP port for Nexys A7 (prefers \\Device\\VCP* over Bluetooth)."""
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

    # Prefer USB FTDI VCP ports first
    for name, val in candidates:
        if "VCP" in name.upper() or "FTDI" in name.upper():
            return val
    # Fallback to non-BthModem port
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
    dcb.Parity = 0    # NOPARITY
    dcb.StopBits = 0  # ONESTOPBIT
    dcb.fBits = 0x00000011  # fBinary=1, fDtrControl=DTR_CONTROL_ENABLE (no parity/flow control)
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
        return 0, 0, 0, False

    dx = decode_axis(info.dwXpos)
    dy = decode_axis(info.dwYpos)

    # Also read POV hat (active when Twin USB controller is in Analog mode!)
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
    # Fire: Btn2(Circle), Btn3(Cross), Btn6(R1)
    fire = 1 if (b & ((1 << 1) | (1 << 2) | (1 << 5))) else 0
    # Dash: Btn4(Square), Btn5(L1)
    dash = 1 if (b & ((1 << 3) | (1 << 4))) else 0
    # Chrono: Btn1(Triangle), Btn7(L2), Btn8(R2)
    chrono = 1 if (b & ((1 << 0) | (1 << 6) | (1 << 7))) else 0
    # Start (Btn10 = Pause)
    start_btn = 1 if (b & (1 << 9)) else 0
    btn_bits = (fire << 2) | (dash << 1) | chrono
    return dx, dy, btn_bits, start_btn, True


def main():
    parser = argparse.ArgumentParser(description="DRAGO-NEXUS V2 Dual USB Joystick Bridge")
    parser.add_argument("--port", default="", help="COM port (auto-detected if omitted)")
    parser.add_argument("--baud", type=int, default=115200, help="UART baud rate (default 115200)")
    args = parser.parse_args()

    port = args.port or find_nexys_com_port()
    print("==========================================================")
    print("  VeePire Survivors : Twin USB Joystick -> Nexys A7 Bridge")
    print("==========================================================")
    print(f"  UART Port : {port} @ {args.baud} baud")

    for jid in (0, 1):
        caps = JOYCAPS()
        if winmm.joyGetDevCapsW(jid, ctypes.byref(caps), ctypes.sizeof(caps)) == 0:
            dx, dy, bb, sb, ok = read_pad(jid)
            status = "READY" if ok else "NOT CONNECTED"
            print(f"  Joystick P{jid+1} (ID {jid}): {caps.szPname} [{status}]")
        else:
            print(f"  Joystick P{jid+1} (ID {jid}): Not found")

    h = open_serial(port, args.baud)
    print("----------------------------------------------------------")
    print("  Streaming at 60 Hz! Press Ctrl+C to stop.")
    print("  Analog LED ON : Smooth 2-speed Left Stick + D-Pad active")
    print("  Analog LED OFF: Digital D-Pad full-speed active")
    print("==========================================================")

    last_log = 0.0
    try:
        while True:
            dx1, dy1, b1, s1, ok1 = read_pad(0)
            dx2, dy2, b2, s2, ok2 = read_pad(1)
            pause_bit = 1 if (s1 or s2) else 0
            byte0 = 0x80 | (((dy1 + 2) & 0x7) << 3) | ((dx1 + 2) & 0x7)
            byte1 = (((dy2 + 2) & 0x7) << 3) | ((dx2 + 2) & 0x7)
            byte2 = ((pause_bit & 0x1) << 6) | ((b2 & 0x7) << 3) | (b1 & 0x7)
            write_serial(h, bytes([byte0, byte1, byte2]))

            now = time.monotonic()
            if now - last_log > 0.25:
                last_log = now
                sys.stdout.write(
                    f"\r  P1({'OK' if ok1 else '--'}): dx={dx1:+d} dy={dy1:+d} F/D/C={b1:03b} | "
                    f"P2({'OK' if ok2 else '--'}): dx={dx2:+d} dy={dy2:+d} F/D/C={b2:03b}   "
                )
                sys.stdout.flush()
            time.sleep(1.0 / 60.0)
    except KeyboardInterrupt:
        print("\nStopped.")
    finally:
        # Send neutral stop packet before closing
        write_serial(h, bytes([0x80 | (2 << 3) | 2, (2 << 3) | 2, 0]))
        kernel32.CloseHandle(h)


if __name__ == "__main__":
    main()
