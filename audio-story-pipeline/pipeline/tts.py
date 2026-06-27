"""Stage 4 — Narration synthesis: text → audio with ElevenLabs / OpenAI / pyttsx3."""

from __future__ import annotations

import hashlib
import os
import tempfile
import wave
from pathlib import Path
from typing import Optional

from .models import CueSheet, NarrationSegment


def _cache_key(text: str, voice: str, provider: str) -> str:
    blob = f"{provider}|{voice}|{text}"
    return hashlib.sha256(blob.encode()).hexdigest()[:16]


def _synthesize_elevenlabs(text: str, voice_id: str, out_path: Path) -> bool:
    api_key = os.environ.get("ELEVENLABS_API_KEY", "")
    if not api_key:
        return False
    try:
        from elevenlabs import ElevenLabs  # type: ignore

        client = ElevenLabs(api_key=api_key)
        audio_bytes = client.text_to_speech.convert(
            voice_id=voice_id,
            text=text,
            model_id="eleven_multilingual_v2",
            output_format="mp3_44100_128",
        )
        out_path.write_bytes(b"".join(audio_bytes))
        return True
    except Exception as e:
        print(f"  [tts] ElevenLabs error: {e}")
        return False


def _synthesize_openai(text: str, out_path: Path) -> bool:
    api_key = os.environ.get("OPENAI_API_KEY", "")
    if not api_key:
        return False
    try:
        import openai  # type: ignore

        client = openai.OpenAI(api_key=api_key)
        response = client.audio.speech.create(
            model="tts-1",
            voice="onyx",
            input=text,
        )
        response.stream_to_file(str(out_path))
        return True
    except Exception as e:
        print(f"  [tts] OpenAI TTS error: {e}")
        return False


def _synthesize_pyttsx3(text: str, out_path: Path) -> bool:
    try:
        import pyttsx3  # type: ignore

        engine = pyttsx3.init()
        engine.setProperty("rate", 150)
        # pyttsx3 saves to wav
        wav_path = out_path.with_suffix(".wav")
        engine.save_to_file(text, str(wav_path))
        engine.runAndWait()
        engine.stop()
        if wav_path.exists() and wav_path.stat().st_size > 0:
            out_path.rename(out_path.with_suffix(".wav"))  # keep as wav
            return True
    except Exception as e:
        print(f"  [tts] pyttsx3 error: {e}")
    return False


def _synthesize_silent_wav(text: str, out_path: Path) -> bool:
    """Last-resort fallback: generate a silent WAV proportional to word count."""
    try:
        words = len(text.split())
        duration_s = max(1.0, words / 2.5)
        sample_rate = 22050
        num_samples = int(duration_s * sample_rate)
        wav_path = out_path.with_suffix(".wav")
        with wave.open(str(wav_path), "w") as wf:
            wf.setnchannels(1)
            wf.setsampwidth(2)
            wf.setframerate(sample_rate)
            wf.writeframes(b"\x00\x00" * num_samples)
        preview = text[:60] + ("..." if len(text) > 60 else "")
        print(f'  [tts] Generated silent placeholder ({duration_s:.1f}s) for: "{preview}"')
        out_path.rename(wav_path)  # keep wav extension
        return True
    except Exception as e:
        print(f"  [tts] Silent fallback error: {e}")
    return False


def synthesize_segment(
    segment: NarrationSegment,
    cache_dir: Path,
    voice_id: str = "21m00Tcm4TlvDq8ikWAM",  # ElevenLabs "Rachel"
) -> Optional[Path]:
    """Synthesize one narration segment. Returns path to audio file, or None."""
    provider_order = []

    el_key = os.environ.get("ELEVENLABS_API_KEY", "")
    oai_key = os.environ.get("OPENAI_API_KEY", "")

    if el_key:
        provider_order.append(("elevenlabs", voice_id))
    else:
        print("  [tts] ELEVENLABS_API_KEY not set, skipping ElevenLabs")

    if oai_key:
        provider_order.append(("openai", "onyx"))
    else:
        print("  [tts] OPENAI_API_KEY not set, skipping OpenAI TTS")

    provider_order.append(("pyttsx3", "default"))
    provider_order.append(("silent", "silent"))

    tts_cache = cache_dir / "narration"
    tts_cache.mkdir(parents=True, exist_ok=True)

    for provider, pvoice in provider_order:
        key = _cache_key(segment.text, pvoice, provider)
        # try mp3 and wav
        for ext in (".mp3", ".wav"):
            candidate = tts_cache / f"{key}{ext}"
            if candidate.exists() and candidate.stat().st_size > 0:
                print(f"  [tts] Cache hit ({provider}): {candidate.name}")
                return candidate

        out_mp3 = tts_cache / f"{key}.mp3"
        out_wav = tts_cache / f"{key}.wav"

        preview = segment.text[:60] + ("..." if len(segment.text) > 60 else "")
        print(f'  [tts] Synthesizing via {provider}: "{preview}"')

        success = False
        if provider == "elevenlabs":
            success = _synthesize_elevenlabs(segment.text, voice_id, out_mp3)
            out = out_mp3
        elif provider == "openai":
            success = _synthesize_openai(segment.text, out_mp3)
            out = out_mp3
        elif provider == "pyttsx3":
            out = out_wav
            success = _synthesize_pyttsx3(segment.text, out_wav)
        elif provider == "silent":
            out = out_wav
            success = _synthesize_silent_wav(segment.text, out_wav)

        if success:
            # find the file that was actually written
            for candidate in [out_mp3, out_wav]:
                if candidate.exists() and candidate.stat().st_size > 0:
                    return candidate

    return None


def run(
    cue_sheet: CueSheet,
    cache_dir: Path,
    voice_id: str = "21m00Tcm4TlvDq8ikWAM",
    force: bool = False,
) -> CueSheet:
    """Synthesize all narration segments. Mutates cue_sheet in place (audio_file field)."""
    print(f"[tts] Synthesizing narration segments…")
    narration_segs = [s for s in cue_sheet.segments if isinstance(s, NarrationSegment)]

    if not narration_segs:
        print("[tts] No narration segments found.")
        return cue_sheet

    for i, seg in enumerate(narration_segs, 1):
        if seg.audio_file and Path(seg.audio_file).exists() and not force:
            print(f"  [{i}/{len(narration_segs)}] Already synthesized: {seg.audio_file}")
            continue

        audio_path = synthesize_segment(seg, cache_dir, voice_id)
        if audio_path:
            seg.audio_file = str(audio_path)
        else:
            print(f'  [warn] Failed to synthesize segment {i}: "{seg.text[:40]}..."')

    return cue_sheet
