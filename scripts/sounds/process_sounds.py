"""Cuts the chosen part out of each original recording and makes the review MP3.

Usage (from the project root):
    python scripts/sounds/process_sounds.py

Reads animal-sound-research/selections.json. For every entry with an
original file it writes <folder>/<key>.mp3 inside the research folder, where
folder is "processed" or "needs-review" as the entry says. The original is
only read. Per entry: "segment" = [start second, length in seconds] (left
out = the whole recording), "highpass" = cut-off in Hz for removing tape
rumble below the animal's sound (left out = none).

What is done to the sound, and nothing else: mixed to one channel, the
segment cut out, a 30 ms fade-in and a 150 ms fade-out, one fixed volume
change so the loudness matches the app's existing sounds (about -16.5 LUFS)
without the peak passing -1 dB, saved as 44.1 kHz 128 kbit/s MP3. No speed
or pitch change, no noise removal, no compression. The measured length,
loudness and peak and the list of edits are written back into the entry.
"""
import json
import pathlib
import re
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[2]
BASE = ROOT / "animal-sound-research"
TARGET_LUFS = -16.5
PEAK_LIMIT = -1.0


def measure(args: list) -> tuple:
    """Integrated loudness (LUFS) and true peak (dB) of what the ffmpeg arguments decode."""
    run = subprocess.run(["ffmpeg", "-hide_banner", "-nostats", *args, "-f", "null", "-"],
                         capture_output=True, text=True, encoding="utf-8", errors="replace")
    tail = run.stderr[run.stderr.rfind("Summary:"):]
    loud = re.search(r"I:\s+(-?[\d.]+) LUFS", tail)
    peak = re.search(r"Peak:\s+(-?[\d.]+) dBFS", tail)
    if not loud or not peak:
        raise SystemExit("could not measure loudness:\n" + run.stderr[-600:])
    return float(loud.group(1)), float(peak.group(1))


def main() -> int:
    path = BASE / "selections.json"
    entries = json.loads(path.read_text(encoding="utf-8"))
    for entry in entries:
        if not entry.get("original"):
            continue
        source = BASE / entry["original"]
        start, length = entry.get("segment") or [0, None]
        cut = ["-ss", str(start)] + (["-t", str(length)] if length else [])
        filters = ["aformat=channel_layouts=mono", "aresample=44100"]
        edits = ["tek kanala indirildi"]
        if entry.get("preview_only"):
            edits.insert(0, "Freesound yüksek kaliteli önizleme dosyasından (OGG) işlendi")
        if entry.get("highpass"):
            filters.append(f"highpass=f={entry['highpass']}")
            edits.append(f"{entry['highpass']} Hz altındaki bant uğultusu süzüldü")
        edits.append(f"{start}. saniyeden {length} saniyelik bölüm alındı" if length else "kaydın tamamı kullanıldı")
        probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                str(source)], capture_output=True, text=True)
        seconds = float(length or float(probe.stdout.strip()) - start)
        fade_out = min(0.15, seconds / 6)
        filters += ["afade=t=in:d=0.03", f"afade=t=out:st={seconds - fade_out:.3f}:d={fade_out:.3f}"]
        edits.append("başa 30 ms, sona 150 ms yumuşak geçiş")
        base = [*cut, "-i", str(source)]
        loud, peak = measure([*base, "-af", ",".join(filters + ["ebur128=peak=true"])])
        gain = min(TARGET_LUFS - loud, PEAK_LIMIT - peak)
        edits.append(f"ses düzeyi {gain:+.1f} dB değiştirildi")
        edits.append("MP3 128 kbit/s, 44,1 kHz")
        folder = BASE / entry["folder"]
        folder.mkdir(parents=True, exist_ok=True)
        target = folder / f"{entry['key']}.mp3"
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *base,
                        "-af", ",".join(filters + [f"volume={gain:.2f}dB"]),
                        "-ac", "1", "-ar", "44100", "-c:a", "libmp3lame", "-b:a", "128k",
                        "-map_metadata", "-1", str(target)], check=True)
        out_loud, out_peak = measure(["-i", str(target), "-af", "ebur128=peak=true"])
        probe = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "format=duration", "-of", "csv=p=0",
                                str(target)], capture_output=True, text=True)
        entry.update({"file": target.relative_to(BASE).as_posix(), "seconds": round(float(probe.stdout.strip()), 2),
                      "lufs": out_loud, "peak_db": out_peak, "bytes": target.stat().st_size, "edits": edits})
        print(f"{entry['key']:14} {entry['seconds']:5.2f} s  {out_loud:6.1f} LUFS  peak {out_peak:5.1f} dB  "
              f"gain {gain:+.1f} dB  -> {entry['file']}")
    path.write_text(json.dumps(entries, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
