#!/usr/bin/env python3
"""Audio Story Pipeline — turn a folder of audio clips into a fictional audio story."""

from __future__ import annotations

import sys
from enum import Enum
from pathlib import Path
from typing import Optional

import typer

from pipeline import analyze, ingest, mix, story, tts
from pipeline.models import NarrativeMode

app = typer.Typer(
    name="make_story",
    help="Turn a folder of audio clips into a short fictional audio story.",
    pretty_exceptions_enable=False,
)


class Stage(str, Enum):
    INGEST = "ingest"
    ANALYZE = "analyze"
    STORY = "story"
    TTS = "tts"
    MIX = "mix"
    ALL = "all"


@app.command()
def main(
    input: Path = typer.Option(
        ..., "--input", "-i", help="Directory containing source audio clips.", exists=True, file_okay=False
    ),
    output: Path = typer.Option(
        Path("./out/story.mp3"), "--output", "-o", help="Output audio file path."
    ),
    mode: NarrativeMode = typer.Option(
        NarrativeMode.AUTO, "--mode", "-m", help="Narrative mode."
    ),
    length: str = typer.Option("3min", "--length", "-l", help="Target story length (e.g. 2min, 90s)."),
    voice: str = typer.Option(
        "21m00Tcm4TlvDq8ikWAM",
        "--voice",
        help="ElevenLabs voice ID (default: Rachel).",
    ),
    music: Optional[Path] = typer.Option(None, "--music", help="Optional music bed file path."),
    stage: Stage = typer.Option(Stage.ALL, "--stage", "-s", help="Run only this pipeline stage."),
    whisper_model: str = typer.Option("base", "--whisper-model", help="Whisper model size: tiny|base|small|medium|large-v2"),
    force: bool = typer.Option(False, "--force", "-f", help="Re-run stage even if cached output exists."),
    non_interactive: bool = typer.Option(False, "--non-interactive", help="Skip interactive prompts (ambient clips get generic description)."),
    draft: bool = typer.Option(False, "--draft", help="Draft mode: write story inline without a runtime API call (for offline demos)."),
) -> None:
    output = output.resolve()
    cache_dir = output.parent / ".cache"
    input_dir = input.resolve()

    typer.echo(f"Audio Story Pipeline")
    typer.echo(f"  Input : {input_dir}")
    typer.echo(f"  Output: {output}")
    typer.echo(f"  Mode  : {mode.value}")
    typer.echo(f"  Length: {length}")
    typer.echo(f"  Stage : {stage.value}")
    typer.echo("")

    if draft:
        _run_draft(input_dir, output, cache_dir, mode, length, force)
        return

    # --- Stage 1: Ingest ---
    if stage in (Stage.ALL, Stage.INGEST):
        clips = ingest.run(input_dir, cache_dir, force=force)
    else:
        clips_path = cache_dir / "clips_raw.json"
        if not clips_path.exists():
            typer.echo(f"[error] clips_raw.json not found in {cache_dir}. Run --stage ingest first.", err=True)
            raise typer.Exit(1)
        import json
        from pipeline.models import ClipInfo
        clips = [ClipInfo(**d) for d in json.loads(clips_path.read_text())]

    if stage == Stage.INGEST:
        return

    # --- Stage 2: Analyze ---
    if stage in (Stage.ALL, Stage.ANALYZE):
        clips = analyze.run(
            clips, input_dir, cache_dir,
            whisper_model=whisper_model, force=force, non_interactive=non_interactive
        )
    else:
        clips_path = cache_dir / "clips.json"
        if not clips_path.exists():
            # Fall back to clips_raw.json (e.g. after --draft run)
            clips_path = cache_dir / "clips_raw.json"
        if not clips_path.exists():
            typer.echo(f"[error] clips.json not found. Run --stage ingest/analyze first.", err=True)
            raise typer.Exit(1)
        import json
        from pipeline.models import ClipInfo
        clips = [ClipInfo(**d) for d in json.loads(clips_path.read_text())]

    if stage == Stage.ANALYZE:
        return

    # --- Stage 3: Story generation ---
    if stage in (Stage.ALL, Stage.STORY):
        cue_sheet, script_md = story.run(clips, cache_dir, mode=mode, target_length=length, force=force)
    else:
        cue_path = cache_dir / "cue_sheet.json"
        if not cue_path.exists():
            typer.echo(f"[error] cue_sheet.json not found. Run --stage story first.", err=True)
            raise typer.Exit(1)
        from pipeline.models import CueSheet
        cue_sheet = CueSheet.load(cue_path)
        script_md = (cache_dir / "story.md").read_text() if (cache_dir / "story.md").exists() else ""

    typer.echo(f"\n--- STORY SCRIPT ---\n{script_md[:1200]}{'…' if len(script_md) > 1200 else ''}\n")

    if stage == Stage.STORY:
        return

    # --- Stage 4: TTS ---
    if stage in (Stage.ALL, Stage.TTS):
        cue_sheet = tts.run(cue_sheet, cache_dir, voice_id=voice, force=force)
        # Persist updated cue sheet with audio_file paths
        cue_sheet.save(cache_dir / "cue_sheet.json")
    elif stage == Stage.MIX:
        # Reload with audio_file paths already set
        from pipeline.models import CueSheet
        cue_sheet = CueSheet.load(cache_dir / "cue_sheet.json")

    if stage == Stage.TTS:
        return

    # --- Stage 5: Mix ---
    if stage in (Stage.ALL, Stage.MIX):
        mix.run(cue_sheet, clips, input_dir, output, cache_dir, music_file=music, force=force)

    typer.echo(f"\nDone! Story saved to {output}")


def _run_draft(
    input_dir: Path,
    output: Path,
    cache_dir: Path,
    mode: NarrativeMode,
    length: str,
    force: bool,
) -> None:
    """Offline draft mode: ingest, guess transcripts from filenames, write a simple story stub."""
    from pipeline.models import ClipInfo, ClipSegment, CueSheet, NarrationSegment
    import json

    typer.echo("[draft] Running offline draft mode (no API calls)")

    clips = ingest.run(input_dir, cache_dir, force=force)
    for c in clips:
        if c.transcript is None and c.description is None:
            c.transcript = f"[audio content of {c.file}]"
    # Write clips.json so --stage mix/story/tts can reload it
    import json as _json
    (cache_dir / "clips.json").write_text(_json.dumps([c.model_dump() for c in clips], indent=2))

    effective_mode = mode if mode != NarrativeMode.AUTO else NarrativeMode.FOUND_AUDIO

    # Build a minimal stub cue sheet
    segments = []
    segments.append(NarrationSegment(
        type="narration",
        text="What you are about to hear is a reconstruction. The recordings are real. The story is not.",
        voice_direction="flat, clinical, as if reading from a case file",
        duration_estimate=6.0,
    ))
    for i, clip in enumerate(clips):
        if i > 0:
            segments.append(NarrationSegment(
                type="narration",
                text=f"Next, a fragment. Context unknown.",
                voice_direction="quieter, trailing off",
                duration_estimate=2.5,
            ))
        segments.append(ClipSegment(type="clip", file=clip.file, crossfade_ms=300))
    segments.append(NarrationSegment(
        type="narration",
        text="That is all. The archive closes.",
        voice_direction="slow, definitive",
        duration_estimate=3.0,
    ))

    cue_sheet = CueSheet(
        title="Draft Story",
        mode=effective_mode,
        target_length=length,
        segments=segments,
    )
    cache_dir.mkdir(parents=True, exist_ok=True)
    cue_sheet.save(cache_dir / "cue_sheet.json")

    script = "# Draft Story\n\n*(Generated offline — replace with real story generation)*\n\n"
    for seg in segments:
        if isinstance(seg, NarrationSegment):
            script += f"> NARRATION: {seg.text}\n\n"
        elif isinstance(seg, ClipSegment):
            script += f"[CLIP: {seg.file}]\n\n"
    (cache_dir / "story.md").write_text(script)
    typer.echo(script)

    cue_sheet = tts.run(cue_sheet, cache_dir, force=force)
    cue_sheet.save(cache_dir / "cue_sheet.json")
    mix.run(cue_sheet, clips, input_dir, output, cache_dir, force=force)
    typer.echo(f"\n[draft] Done! → {output}")


if __name__ == "__main__":
    app()
