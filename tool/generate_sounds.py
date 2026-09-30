#!/usr/bin/env python3
"""Generates Riksa's learning feedback sounds into assets/audio/.

Run from the repo root:
    python3 tool/generate_sounds.py

Every cue is synthesised here rather than sourced, so the set is consistent in
timbre, tuning and loudness, and carries no licence obligations. The tones are
bell-like: a sine fundamental plus quiet upper harmonics under an exponential
decay, which reads as "chime" rather than "beep".

Swapping in professionally designed audio later needs no code change — drop
files with the same names into assets/audio/ and delete this script.
"""
import math
import struct
import wave
from pathlib import Path

SAMPLE_RATE = 44100
OUT = Path(__file__).resolve().parent.parent / "assets" / "audio"

# Equal temperament, A4 = 440.
def note(name: str) -> float:
    steps = {"C": -9, "C#": -8, "D": -7, "D#": -6, "E": -5, "F": -4,
             "F#": -3, "G": -2, "G#": -1, "A": 0, "A#": 1, "B": 2}
    pitch, octave = name[:-1], int(name[-1])
    semitones = steps[pitch] + (octave - 4) * 12
    return 440.0 * (2 ** (semitones / 12))


def tone(freq, duration, amplitude=1.0, decay=6.0, harmonics=(1.0, 0.28, 0.12)):
    """One bell-like note as a list of float samples."""
    total = int(SAMPLE_RATE * duration)
    attack = max(1, int(SAMPLE_RATE * 0.006))  # a click without this
    out = []
    for i in range(total):
        t = i / SAMPLE_RATE
        envelope = math.exp(-decay * t)
        if i < attack:
            envelope *= i / attack
        value = sum(
            gain * math.sin(2 * math.pi * freq * (n + 1) * t)
            for n, gain in enumerate(harmonics)
        )
        out.append(amplitude * envelope * value)
    return out


def mix(layers):
    """Overlays (start_seconds, samples) pairs onto one buffer."""
    length = max(int(start * SAMPLE_RATE) + len(s) for start, s in layers)
    buffer = [0.0] * length
    for start, samples in layers:
        offset = int(start * SAMPLE_RATE)
        for i, value in enumerate(samples):
            buffer[offset + i] += value
    return buffer


def write(name, samples, peak=0.72):
    """Normalises to a shared peak so no cue is louder than the others."""
    loudest = max(abs(v) for v in samples) or 1.0
    scale = peak / loudest
    # A short fade-out guarantees the file ends at zero crossing.
    fade = min(len(samples), int(SAMPLE_RATE * 0.02))
    frames = bytearray()
    for i, value in enumerate(samples):
        v = value * scale
        if i >= len(samples) - fade:
            v *= (len(samples) - i) / fade
        frames += struct.pack("<h", int(max(-1.0, min(1.0, v)) * 32767))

    path = OUT / name
    with wave.open(str(path), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(SAMPLE_RATE)
        f.writeframes(bytes(frames))
    print(f"  {name:24} {len(samples) / SAMPLE_RATE:.2f}s  {path.stat().st_size // 1024}KB")


def arpeggio(notes, gap, duration, decay=6.0, amplitude=1.0):
    return [(i * gap, tone(note(n), duration, amplitude, decay)) for i, n in enumerate(notes)]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    print("Writing sounds to", OUT)

    # Correct — a major triad rising quickly. Short, so rapid answering never
    # feels like it is waiting on the audio.
    write("correct.wav", mix(arpeggio(["C5", "E5", "G5"], 0.055, 0.30, decay=8.0)))

    # Wrong — two soft descending notes, a minor third apart. Deliberately gentle
    # and low-harmonic: a learner hears this most often, and a harsh buzzer
    # punishes the exact moment they need encouragement to retry.
    write("wrong.wav", mix([
        (0.0, tone(note("G4"), 0.18, 0.9, decay=9.0, harmonics=(1.0, 0.12))),
        (0.10, tone(note("D#4"), 0.32, 0.9, decay=7.0, harmonics=(1.0, 0.12))),
    ]))

    # Section complete — the correct cue carried one octave higher.
    write("section_complete.wav", mix(arpeggio(["C5", "E5", "G5", "C6"], 0.075, 0.42, decay=5.5)))

    # Lesson complete — the fanfare, with a held triad ringing under it.
    write("lesson_complete.wav", mix(
        arpeggio(["C5", "E5", "G5", "C6", "E6"], 0.085, 0.55, decay=4.5)
        + [(0.34, tone(note(n), 1.1, 0.34, decay=2.6)) for n in ("C5", "E5", "G5")]
    ))

    # Achievement — a high sparkle that sits clearly above the others.
    write("achievement.wav", mix(
        arpeggio(["G5", "C6", "E6", "G6"], 0.06, 0.45, decay=6.0)
        + [(0.24, tone(note("C6"), 0.9, 0.3, decay=3.0))]
    ))


if __name__ == "__main__":
    main()
