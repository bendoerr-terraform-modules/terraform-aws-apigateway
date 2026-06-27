"""Stage 2 — Analyze: transcribe speech clips; describe ambient clips."""

from __future__ import annotations

import json
from pathlib import Path
from typing import Optional

from .models import ClipInfo, ClipType

WHISPER_MODEL = "base"  # tiny | base | small | medium | large-v2


def _transcribe(path: Path, model_size: str = WHISPER_MODEL) -> str:
    from faster_whisper import WhisperModel  # type: ignore

    print(f"  [whisper] Transcribing {path.name} (model={model_size})…")
    model = WhisperModel(model_size, device="cpu", compute_type="int8")
    segments, _ = model.transcribe(str(path), beam_size=5, language="en")
    return " ".join(seg.text.strip() for seg in segments).strip()


def _describe_ambient_interactive(clip: ClipInfo) -> str:
    """Prompt the user for a one-line description of an ambient clip."""
    print(f"\n  [analyze] Ambient clip detected: {clip.file} ({clip.duration:.1f}s)")
    print("  Please type a one-line description of this sound (e.g. 'distant rain on a window'):")
    description = input("  > ").strip()
    return description or "ambient sound"


def run(
    clips: list[ClipInfo],
    input_dir: Path,
    cache_dir: Path,
    whisper_model: str = WHISPER_MODEL,
    force: bool = False,
    non_interactive: bool = False,
) -> list[ClipInfo]:
    """Populate transcript/description fields on each ClipInfo.
    Result is written to *cache_dir*/clips.json (the canonical clip inventory)."""

    out_path = cache_dir / "clips.json"
    if out_path.exists() and not force:
        print(f"[analyze] Using cached {out_path}")
        data = json.loads(out_path.read_text())
        return [ClipInfo(**d) for d in data]

    print(f"[analyze] Analyzing {len(clips)} clip(s)…")
    enriched: list[ClipInfo] = []

    for clip in clips:
        path = input_dir / clip.file
        updated = clip.model_copy()

        if clip.type == ClipType.SPEECH:
            try:
                transcript = _transcribe(path, whisper_model)
                updated.transcript = transcript
                ellipsis = "…" if len(transcript) > 80 else ""
                print(f'  {clip.file}: “{transcript[:80]}{ellipsis}”')
            except Exception as e:
                print(f"  [warn] Whisper failed for {clip.file}: {e}")
                updated.transcript = ""
        elif clip.type == ClipType.AMBIENT:
            if non_interactive:
                updated.description = "ambient sound"
            else:
                updated.description = _describe_ambient_interactive(clip)
        else:
            # UNKNOWN — try transcription first, fall back to ambient
            try:
                transcript = _transcribe(path, whisper_model)
                if transcript:
                    updated.type = ClipType.SPEECH
                    updated.transcript = transcript
                    print(f'  {clip.file} (reclassified speech): "{transcript[:80]}"')
                else:
                    updated.type = ClipType.AMBIENT
                    if non_interactive:
                        updated.description = "ambient sound"
                    else:
                        updated.description = _describe_ambient_interactive(clip)
            except Exception as e:
                print(f"  [warn] Could not analyze {clip.file}: {e}")
                updated.type = ClipType.AMBIENT
                updated.description = "ambient sound"

        enriched.append(updated)

    out_path.write_text(json.dumps([c.model_dump() for c in enriched], indent=2))
    print(f"[analyze] Wrote {out_path}")
    return enriched
