#!/usr/bin/env python3
"""Generates the busboy "new delivery" chime (`new_order.wav`).

The alert sound is checked in as a WAV rather than downloaded, so there is no
licence to track — but a committed binary nobody can regenerate is its own
problem. Run this to reproduce or retune it:

    python3 tool/generate_chime.py

Writes both copies the app needs:
  * assets/sounds/new_order.wav          — played in-app by `audioplayers`
  * android/app/src/main/res/raw/…       — the notification channel's sound;
                                           Android can only take one from
                                           res/raw, not a Flutter asset

Retuning it means bumping `PluginNewOrderAlerts.busboy`'s `channelId`: an
Android notification channel's sound is fixed when the channel is created,
so existing installs keep playing the old one until the id changes.

Tenant's chime (`tenant_order.wav`, `PluginNewOrderAlerts.tenant`) is a
separately-sourced asset — this script does not generate or manage it.
"""

import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
DURATION = 1.15
# Fade the tail to zero. The decay is still at ~7% amplitude when the clip
# ends, and cutting there puts an audible tick on every chime.
FADE = 0.12
PEAK_DBFS = -3.0

# Partials of a struck bell are not integer multiples of the fundamental;
# 2.4 and 3.7 are what make this read as a chime rather than an organ tone.
# (multiplier, amplitude, decay seconds)
PARTIALS = (
    (1.00, 1.00, 0.42),
    (2.00, 0.52, 0.30),
    (2.40, 0.30, 0.22),
    (3.70, 0.16, 0.15),
)

# A5 then D6 — a rising two-note figure, the "someone needs you" shape rather
# than the "something broke" one. (onset seconds, frequency, gain)
STRIKES = ((0.00, 880.00, 0.62), (0.17, 1174.66, 0.72))


def strike(t: float, t0: float, f0: float, gain: float) -> float:
    if t < t0:
        return 0.0
    dt = t - t0
    # 3ms attack: crisp onset without a click.
    attack = min(1.0, dt / 0.003)
    v = sum(
        amp * math.exp(-dt / tau) * math.sin(2 * math.pi * f0 * mult * dt)
        for mult, amp, tau in PARTIALS
    )
    return v * attack * gain


def main() -> None:
    total = int(SAMPLE_RATE * DURATION)
    fade_from = total - int(SAMPLE_RATE * FADE)
    samples = []
    for n in range(total):
        t = n / SAMPLE_RATE
        v = sum(strike(t, *s) for s in STRIKES)
        if n >= fade_from:
            v *= (total - n) / (total - fade_from)
        samples.append(v)

    norm = (10 ** (PEAK_DBFS / 20)) / max(abs(v) for v in samples)
    frames = b"".join(
        struct.pack("<h", int(max(-1.0, min(1.0, v * norm)) * 32767))
        for v in samples
    )

    root = Path(__file__).resolve().parent.parent
    for out in (
        root / "assets/sounds/new_order.wav",
        root / "android/app/src/main/res/raw/new_order.wav",
    ):
        out.parent.mkdir(parents=True, exist_ok=True)
        with wave.open(str(out), "wb") as w:
            w.setnchannels(1)
            w.setsampwidth(2)
            w.setframerate(SAMPLE_RATE)
            w.writeframes(frames)
        print(f"wrote {out.relative_to(root)}")


if __name__ == "__main__":
    main()
