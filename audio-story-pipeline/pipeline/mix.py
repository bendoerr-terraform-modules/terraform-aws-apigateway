"""Stage 5 — Mix / assemble: render the cue sheet into a single audio file."""

from __future__ import annotations

import io
import math
import os
import struct
from pathlib import Path
from typing import Optional

import av  # type: ignore
import numpy as np
from pydub import AudioSegment  # type: ignore
from pydub.effects import normalize  # type: ignore
import pydub.utils  # type: ignore


def _configure_pydub_ffmpeg() -> None:
    """Point pydub at a working ffmpeg binary (static build via imageio-ffmpeg)."""
    try:
        import imageio_ffmpeg  # type: ignore
        ffmpeg_path = imageio_ffmpeg.get_ffmpeg_exe()
        pydub.utils.get_encoder_name = lambda: ffmpeg_path
        pydub.utils.get_player_name = lambda: ffmpeg_path
        AudioSegment.converter = ffmpeg_path
        AudioSegment.ffmpeg = ffmpeg_path
        AudioSegment.ffprobe = ffmpeg_path
    except ImportError:
        pass


_configure_pydub_ffmpeg()

from .models import ClipInfo, ClipSegment, CueSheet, MusicSegment, NarrationSegment

TARGET_SAMPLE_RATE = 44100
TARGET_CHANNELS = 2
TARGET_SAMPLE_WIDTH = 2  # 16-bit


def _load_via_av(path: Path) -> AudioSegment:
    """Decode any audio file via PyAV (bypasses ffprobe) and return a pydub AudioSegment."""
    frames: list[np.ndarray] = []
    sample_rate = TARGET_SAMPLE_RATE
    channels = TARGET_CHANNELS

    with av.open(str(path)) as container:
        audio_streams = [s for s in container.streams if s.type == "audio"]
        if not audio_streams:
            raise ValueError(f"No audio stream in {path}")
        stream = audio_streams[0]
        sample_rate = stream.codec_context.sample_rate or TARGET_SAMPLE_RATE
        channels = stream.codec_context.channels or TARGET_CHANNELS

        for frame in container.decode(audio=0):
            arr = frame.to_ndarray()
            frames.append(arr)

    if not frames:
        raise ValueError(f"No audio frames decoded from {path}")

    # frames shape: (channels, samples) or (samples,) depending on format
    audio_np = np.concatenate(frames, axis=-1)

    # Ensure 2D: (channels, samples)
    if audio_np.ndim == 1:
        audio_np = audio_np[np.newaxis, :]

    # Resample to target rate if needed
    if sample_rate != TARGET_SAMPLE_RATE:
        ratio = TARGET_SAMPLE_RATE / sample_rate
        new_len = int(audio_np.shape[-1] * ratio)
        from scipy.signal import resample  # type: ignore
        audio_np = resample(audio_np, new_len, axis=-1)
        sample_rate = TARGET_SAMPLE_RATE

    # Mix to target channels
    if audio_np.shape[0] != TARGET_CHANNELS:
        if audio_np.shape[0] == 1:
            audio_np = np.repeat(audio_np, TARGET_CHANNELS, axis=0)
        else:
            audio_np = audio_np[:TARGET_CHANNELS]

    # Convert to int16
    if audio_np.dtype in (np.float32, np.float64):
        audio_np = np.clip(audio_np, -1.0, 1.0)
        audio_np = (audio_np * 32767).astype(np.int16)
    elif audio_np.dtype != np.int16:
        audio_np = audio_np.astype(np.int16)

    # Interleave channels: (channels, samples) -> (samples * channels,)
    audio_interleaved = audio_np.T.flatten()
    raw_bytes = audio_interleaved.tobytes()

    return AudioSegment(
        data=raw_bytes,
        sample_width=TARGET_SAMPLE_WIDTH,
        frame_rate=TARGET_SAMPLE_RATE,
        channels=TARGET_CHANNELS,
    )


def _load_clip(path: Path, volume: float = 1.0) -> AudioSegment:
    try:
        seg = _load_via_av(path)
    except Exception:
        # Fallback to pydub (may work if ffprobe is functional)
        ext = path.suffix.lower().lstrip(".")
        seg = AudioSegment.from_file(str(path), format=ext)
        seg = seg.set_frame_rate(TARGET_SAMPLE_RATE).set_channels(TARGET_CHANNELS).set_sample_width(TARGET_SAMPLE_WIDTH)

    if volume != 1.0:
        change_db = 20 * math.log10(max(volume, 1e-6))
        seg = seg + change_db
    return seg


def _trim(seg: AudioSegment, trim_in: float, trim_out: Optional[float]) -> AudioSegment:
    start_ms = int(trim_in * 1000)
    end_ms = int(trim_out * 1000) if trim_out is not None else len(seg)
    return seg[start_ms:end_ms]


def _duck(music: AudioSegment, speech: AudioSegment, duck_db: float = -18.0) -> AudioSegment:
    """Simple sidechain duck: drop music by duck_db dB for the duration of speech."""
    if len(music) < len(speech):
        music = music * (len(speech) // len(music) + 1)
    music = music[: len(speech)]
    # Build duck envelope: full volume → ducked at speech start → full volume at speech end
    duck_ms = len(speech)
    fade_ms = min(300, duck_ms // 4)
    ducked = music + duck_db
    result = (
        music[:fade_ms].fade(to_gain=duck_db, start=0, duration=fade_ms)
        + ducked[fade_ms : duck_ms - fade_ms]
        + music[duck_ms - fade_ms : duck_ms].fade(from_gain=duck_db, start=0, duration=fade_ms)
    )
    return result


def run(
    cue_sheet: CueSheet,
    clips: list[ClipInfo],
    input_dir: Path,
    output_path: Path,
    cache_dir: Path,
    music_file: Optional[Path] = None,
    force: bool = False,
) -> Path:
    """Render *cue_sheet* to *output_path* (mp3) and keep a wav copy."""

    wav_path = output_path.with_suffix(".wav")
    if output_path.exists() and wav_path.exists() and not force:
        print(f"[mix] Using cached {output_path}")
        return output_path

    output_path.parent.mkdir(parents=True, exist_ok=True)

    clip_map: dict[str, ClipInfo] = {c.file: c for c in clips}

    print("[mix] Assembling timeline…")
    timeline = AudioSegment.silent(duration=0, frame_rate=TARGET_SAMPLE_RATE)
    music_track: Optional[AudioSegment] = None
    music_meta: Optional[MusicSegment] = None

    for i, seg in enumerate(cue_sheet.segments):
        print(f"  segment {i + 1}/{len(cue_sheet.segments)}: {seg.type}", end="")

        if isinstance(seg, MusicSegment):
            music_meta = seg
            if music_file and music_file.exists():
                print(f" [{music_file.name}]")
                music_track = _load_clip(music_file, seg.volume)
            else:
                print(" [no music file — skipping]")
            continue

        if isinstance(seg, NarrationSegment):
            if not seg.audio_file:
                print(" [no audio — skipping]")
                continue
            audio_path = Path(seg.audio_file)
            if not audio_path.exists():
                print(f" [missing {audio_path} — skipping]")
                continue
            chunk = _load_clip(audio_path)
            print(f" {len(chunk) / 1000:.1f}s")

        elif isinstance(seg, ClipSegment):
            src = input_dir / seg.file
            if not src.exists():
                print(f" [missing {src} — skipping]")
                continue
            chunk = _load_clip(src, seg.volume)
            chunk = _trim(chunk, seg.trim_in, seg.trim_out)
            print(f" {seg.file} {len(chunk) / 1000:.1f}s")

        else:
            print(" [unknown type — skipping]")
            continue

        crossfade_ms = 0
        if isinstance(seg, ClipSegment):
            crossfade_ms = seg.crossfade_ms

        if crossfade_ms > 0 and len(timeline) > 0:
            crossfade_ms = min(crossfade_ms, len(timeline), len(chunk))
            timeline = timeline.append(chunk, crossfade=crossfade_ms)
        else:
            timeline = timeline + chunk

    # Overlay music bed under the full timeline
    if music_track is not None and music_meta is not None:
        if music_meta.loop and len(music_track) < len(timeline):
            repeats = len(timeline) // len(music_track) + 1
            music_track = music_track * repeats
        music_track = music_track[: len(timeline)]

        if music_meta.duck_under_speech:
            # build a simplified duck: music full except during narration segments
            ducked_music = music_track
            offset_ms = 0
            for seg in cue_sheet.segments:
                if isinstance(seg, MusicSegment):
                    continue
                if isinstance(seg, NarrationSegment) and seg.audio_file:
                    dur_ms = int(seg.duration_estimate * 1000) or 5000
                elif isinstance(seg, ClipSegment):
                    dur_ms = 5000  # rough estimate
                else:
                    dur_ms = 0

                if dur_ms and offset_ms < len(ducked_music):
                    end_ms = min(offset_ms + dur_ms, len(ducked_music))
                    fade_ms = min(200, dur_ms // 4)
                    ducked_section = ducked_music[offset_ms:end_ms] - 14
                    ducked_music = (
                        ducked_music[:offset_ms]
                        + ducked_section
                        + ducked_music[end_ms:]
                    )
                offset_ms += dur_ms

            music_track = ducked_music

        timeline = timeline.overlay(music_track)

    timeline = normalize(timeline)

    print(f"[mix] Total duration: {len(timeline) / 1000:.1f}s")
    print(f"[mix] Exporting {wav_path}…")
    timeline.export(str(wav_path), format="wav")

    print(f"[mix] Exporting {output_path}…")
    timeline.export(str(output_path), format="mp3", bitrate="192k")

    print(f"[mix] Done → {output_path}")
    return output_path
