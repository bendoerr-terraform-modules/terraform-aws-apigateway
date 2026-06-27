"""Stage 1 — Ingest: scan audio files and record basic metadata."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from .models import ClipInfo, ClipType

AUDIO_EXTENSIONS = {".wav", ".mp3", ".m4a", ".flac", ".ogg", ".aac", ".wma", ".opus"}

SPEECH_RATIO_THRESHOLD = 0.55  # fraction of non-silent frames that suggest speech


def _duration_via_av(path: Path) -> float:
    """Return clip duration in seconds using PyAV (no ffprobe needed)."""
    try:
        import av
        with av.open(str(path)) as container:
            if container.duration:
                return container.duration / av.time_base
            # fall back to summing packets
            audio = next((s for s in container.streams if s.type == "audio"), None)
            if audio and audio.duration and audio.time_base:
                return float(audio.duration * audio.time_base)
    except Exception:
        pass
    return 0.0


def _guess_speech_or_ambient(path: Path) -> ClipType:
    """Heuristic: try loading a short slice and measuring zero-crossing rate.
    High ZCR with energy → likely speech. Falls back to UNKNOWN."""
    try:
        import av
        import numpy as np

        samples: list[float] = []
        with av.open(str(path)) as container:
            audio_streams = [s for s in container.streams if s.type == "audio"]
            if not audio_streams:
                return ClipType.UNKNOWN
            container.streams.audio[0].codec_context.request_simple = True
            for frame in container.decode(audio=0):
                arr = frame.to_ndarray().flatten()
                samples.extend(arr[:4000])  # sample first ~0.1s at 44kHz
                if len(samples) > 16000:
                    break

        if not samples:
            return ClipType.UNKNOWN

        a = np.array(samples, dtype=np.float32)
        # normalise
        mx = np.abs(a).max()
        if mx < 1e-6:
            return ClipType.AMBIENT  # silence / near-silence → ambient

        a /= mx
        # zero-crossing rate
        zcr = float(np.mean(np.abs(np.diff(np.sign(a)))) / 2)
        # speech ZCR typically 0.05-0.25; music/ambient can be lower or higher
        # energy variance: speech has bursty energy
        energy = np.array([np.mean(a[i : i + 160] ** 2) for i in range(0, len(a) - 160, 160)])
        energy_var = float(np.std(energy))

        if zcr > 0.04 and energy_var > 0.02:
            return ClipType.SPEECH
        return ClipType.AMBIENT
    except Exception:
        return ClipType.UNKNOWN


def run(input_dir: Path, cache_dir: Path, force: bool = False) -> list[ClipInfo]:
    """Scan *input_dir* for audio files and return ClipInfo list.
    Result is written to *cache_dir*/clips_raw.json."""

    out_path = cache_dir / "clips_raw.json"
    if out_path.exists() and not force:
        print(f"[ingest] Using cached {out_path}")
        data = json.loads(out_path.read_text())
        return [ClipInfo(**d) for d in data]

    cache_dir.mkdir(parents=True, exist_ok=True)
    clips: list[ClipInfo] = []

    audio_files = sorted(
        p for p in input_dir.iterdir() if p.suffix.lower() in AUDIO_EXTENSIONS
    )
    if not audio_files:
        raise ValueError(f"No audio files found in {input_dir}")

    print(f"[ingest] Found {len(audio_files)} audio file(s) in {input_dir}")

    for path in audio_files:
        duration = _duration_via_av(path)
        clip_type = _guess_speech_or_ambient(path)
        clip = ClipInfo(file=path.name, duration=round(duration, 2), type=clip_type)
        clips.append(clip)
        print(f"  {path.name:50s}  {duration:5.1f}s  {clip_type.value}")

    out_path.write_text(json.dumps([c.model_dump() for c in clips], indent=2))
    print(f"[ingest] Wrote {out_path}")
    return clips
