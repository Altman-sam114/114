#!/usr/bin/env python3
import math
import struct
import zlib
from pathlib import Path

SIZE = 1024
OUT = Path("ChronoFocus/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png")


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(lerp(c1[i], c2[i], t)) for i in range(3))


def clamp(value, low=0, high=255):
    return max(low, min(high, int(value)))


def blend(dst, src, alpha):
    return tuple(clamp(dst[i] * (1 - alpha) + src[i] * alpha) for i in range(3))


def distance_to_segment(px, py, ax, ay, bx, by):
    dx = bx - ax
    dy = by - ay
    if dx == 0 and dy == 0:
        return math.hypot(px - ax, py - ay)
    t = max(0.0, min(1.0, ((px - ax) * dx + (py - ay) * dy) / (dx * dx + dy * dy)))
    qx = ax + t * dx
    qy = ay + t * dy
    return math.hypot(px - qx, py - qy)


pixels = bytearray()
center = SIZE / 2

for y in range(SIZE):
    row = bytearray([0])
    for x in range(SIZE):
        nx = x / (SIZE - 1)
        ny = y / (SIZE - 1)
        base = mix((7, 10, 16), (5, 33, 40), min(1, (nx + ny) * 0.58))
        if nx > 0.44:
            base = mix(base, (35, 20, 54), (nx - 0.44) * 0.92)

        dx = x - center
        dy = y - center
        radius = math.hypot(dx, dy)
        angle = math.atan2(dy, dx)

        # Subtle radial scan lines and halo.
        for ring in range(150, 460, 52):
            ring_alpha = max(0.0, 1.0 - abs(radius - ring) / 3.0) * 0.08
            base = blend(base, (61, 232, 197), ring_alpha)

        halo = max(0.0, 1.0 - abs(radius - 310) / 62.0) * 0.18
        base = blend(base, (61, 232, 197), halo)

        # Main dial track.
        track = max(0.0, 1.0 - abs(radius - 326) / 22.0)
        base = blend(base, (255, 255, 255), track * 0.15)

        # Progress arc from upper-left across the top and right side.
        in_arc = -2.45 <= angle <= 1.32
        if in_arc:
            arc = max(0.0, 1.0 - abs(radius - 326) / 25.0)
            base = blend(base, (61, 232, 197), arc * 0.96)

        # Clock hands.
        minute = max(0.0, 1.0 - distance_to_segment(x, y, center, center, center, 296) / 15.0)
        hour = max(0.0, 1.0 - distance_to_segment(x, y, center, center, 675, 610) / 15.0)
        base = blend(base, (245, 252, 255), max(minute, hour) * 0.92)

        # Center pin.
        pin = max(0.0, 1.0 - radius / 31.0)
        base = blend(base, (61, 232, 197), pin)

        # Minimal CF monogram, drawn as block strokes for reliable asset generation.
        if 260 <= y <= 765:
            # C outline.
            c_top = 660 <= y <= 710 and 314 <= x <= 500
            c_bottom = 315 <= y <= 365 and 314 <= x <= 500
            c_left = 315 <= y <= 710 and 292 <= x <= 342
            if c_top or c_bottom or c_left:
                base = blend(base, (245, 252, 255), 0.88)
            # F outline.
            f_left = 315 <= y <= 710 and 550 <= x <= 602
            f_top = 660 <= y <= 710 and 550 <= x <= 738
            f_mid = 488 <= y <= 538 and 550 <= x <= 710
            if f_left or f_top or f_mid:
                base = blend(base, (245, 252, 255), 0.88)

        vignette = max(0.0, (radius - 445) / 290)
        base = mix(base, (3, 5, 8), min(0.5, vignette))

        row.extend(bytes(base))
    pixels.extend(row)


def chunk(name, data):
    return (
        struct.pack(">I", len(data))
        + name
        + data
        + struct.pack(">I", zlib.crc32(name + data) & 0xFFFFFFFF)
    )


raw = bytes(pixels)
png = b"\x89PNG\r\n\x1a\n"
png += chunk(b"IHDR", struct.pack(">IIBBBBB", SIZE, SIZE, 8, 2, 0, 0, 0))
png += chunk(b"IDAT", zlib.compress(raw, level=9))
png += chunk(b"IEND", b"")

OUT.write_bytes(png)
print(f"Generated {OUT}")
