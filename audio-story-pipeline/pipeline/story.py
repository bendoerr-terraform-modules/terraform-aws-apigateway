"""Stage 3 — Story generation: send clip inventory to Claude and get back
a readable script (story.md) and a machine-readable cue sheet (cue_sheet.json)."""

from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Optional

import anthropic

from .models import (
    ClipInfo,
    ClipSegment,
    CueSheet,
    MusicSegment,
    NarrationSegment,
    NarrativeMode,
)

MODEL = "claude-sonnet-4-6"

CUE_SHEET_SCHEMA = """
{
  "title": "string",
  "mode": "found-audio | memory | reconstructor | soundscape",
  "target_length": "string",
  "segments": [
    // each segment is one of:
    {
      "type": "narration",
      "text": "string — the words to speak aloud",
      "voice_direction": "string — one line, e.g. 'low, exhausted, trailing off'",
      "duration_estimate": number  // seconds
    },
    {
      "type": "clip",
      "file": "string — exact filename from the inventory",
      "trim_in": number,   // seconds from start; 0 = from beginning
      "trim_out": number | null,  // seconds from start; null = to end
      "volume": number,    // 0.0–1.0; 1.0 = full
      "crossfade_ms": number  // ms crossfade with previous segment
    },
    {
      "type": "music",
      "mood": "string",
      "volume": number,    // 0.0–1.0; recommend 0.2–0.35
      "duck_under_speech": true
    }
  ]
}
"""

SYSTEM_PROMPT = """You are a sound-drama writer specialising in audio fiction.
You craft intimate, atmospheric pieces that treat source recordings as sacred artifacts.
When you output JSON, output ONLY valid JSON with no trailing commas."""

USER_PROMPT_TEMPLATE = """\
You are a sound-drama writer. You are given an inventory of real audio clips \
(transcripts for speech, descriptions for ambient sound), each with a duration in seconds. \
Write a short original fictional audio story in the **{mode}** style, target length **{length}**.

Rules:
- Every clip in the inventory MUST appear in the final piece. Treat each as load-bearing \
— the story should not work without it.
- Do not contradict what a speech clip actually says. You may reframe its *meaning* \
through surrounding context.
- Narration bridges and contextualises the clips; it must never merely restate them.
- Account for each clip's duration when pacing toward the target runtime.
- Output exactly two things:
  1. A readable script inside a ```markdown code block labelled "SCRIPT".
  2. A JSON cue sheet inside a ```json code block labelled "CUE_SHEET", conforming \
to the schema below.
- For each narration segment, include a one-line voice direction \
(e.g. "flat, exhausted, trailing off at the end").
- Music segments are optional; include at most one music bed.

Cue sheet schema:
```
{schema}
```

Clip inventory:
{clips_json}
"""

AUTO_MODE_PROMPT = """\
Given the following audio clip inventory, choose the single best narrative mode \
from [found-audio, memory, reconstructor, soundscape] and explain your reasoning \
in 2-3 sentences.

Respond in this exact format:
MODE: <chosen-mode>
REASON: <your reasoning>

Clip inventory:
{clips_json}
"""


def _build_inventory_text(clips: list[ClipInfo]) -> str:
    return "\n".join(c.inventory_text() for c in clips)


def _pick_auto_mode(clips: list[ClipInfo], client: anthropic.Anthropic) -> NarrativeMode:
    inventory = _build_inventory_text(clips)
    response = client.messages.create(
        model=MODEL,
        max_tokens=256,
        messages=[{"role": "user", "content": AUTO_MODE_PROMPT.format(clips_json=inventory)}],
    )
    text = response.content[0].text.strip()
    print(f"[story] Auto-mode selection:\n{text}\n")

    match = re.search(r"MODE:\s*(\S+)", text, re.IGNORECASE)
    if match:
        raw = match.group(1).strip().lower()
        try:
            return NarrativeMode(raw)
        except ValueError:
            pass
    return NarrativeMode.FOUND_AUDIO


def _extract_blocks(text: str) -> tuple[str, str]:
    """Extract SCRIPT and CUE_SHEET from the LLM response."""
    script = ""
    cue_json = ""

    # Try labelled code fences first
    script_match = re.search(r"```(?:markdown)?\s*SCRIPT\s*\n(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if script_match:
        script = script_match.group(1).strip()

    cue_match = re.search(r"```(?:json)?\s*CUE_SHEET\s*\n(.*?)```", text, re.DOTALL | re.IGNORECASE)
    if cue_match:
        cue_json = cue_match.group(1).strip()

    # Fall back to any markdown / json block
    if not script:
        md_match = re.search(r"```markdown\n(.*?)```", text, re.DOTALL)
        if md_match:
            script = md_match.group(1).strip()

    if not cue_json:
        json_match = re.search(r"```json\n(.*?)```", text, re.DOTALL)
        if json_match:
            cue_json = json_match.group(1).strip()

    # Last resort: find a bare JSON object
    if not cue_json:
        obj_match = re.search(r"(\{[\s\S]+\})", text)
        if obj_match:
            cue_json = obj_match.group(1).strip()

    return script, cue_json


def _parse_cue_sheet(raw_json: str, mode: NarrativeMode, target_length: str) -> CueSheet:
    data = json.loads(raw_json)
    data.setdefault("mode", mode.value)
    data.setdefault("target_length", target_length)
    data.setdefault("title", "Untitled")
    return CueSheet.model_validate(data)


def run(
    clips: list[ClipInfo],
    cache_dir: Path,
    mode: NarrativeMode = NarrativeMode.AUTO,
    target_length: str = "3min",
    force: bool = False,
) -> tuple[CueSheet, str]:
    """Generate story + cue sheet. Returns (CueSheet, script_markdown)."""

    cue_path = cache_dir / "cue_sheet.json"
    script_path = cache_dir / "story.md"

    if cue_path.exists() and script_path.exists() and not force:
        print(f"[story] Using cached {cue_path}")
        return CueSheet.load(cue_path), script_path.read_text()

    client = anthropic.Anthropic()

    effective_mode = mode
    if mode == NarrativeMode.AUTO:
        effective_mode = _pick_auto_mode(clips, client)
        print(f"[story] Selected mode: {effective_mode.value}")

    inventory = _build_inventory_text(clips)
    prompt = USER_PROMPT_TEMPLATE.format(
        mode=effective_mode.value,
        length=target_length,
        schema=CUE_SHEET_SCHEMA,
        clips_json=inventory,
    )

    print(f"[story] Calling Claude ({MODEL}) for story generation…")
    response = client.messages.create(
        model=MODEL,
        max_tokens=4096,
        system=SYSTEM_PROMPT,
        messages=[{"role": "user", "content": prompt}],
    )
    raw = response.content[0].text

    script, cue_json = _extract_blocks(raw)

    if not cue_json:
        raise ValueError("Claude did not return a parseable JSON cue sheet. Raw response:\n" + raw[:2000])

    cue_sheet = _parse_cue_sheet(cue_json, effective_mode, target_length)

    # Validate all clip files are present
    inventory_files = {c.file for c in clips}
    referenced = {seg.file for seg in cue_sheet.segments if isinstance(seg, ClipSegment)}
    missing = inventory_files - referenced
    if missing:
        print(f"[story] Warning: these clips were omitted from the cue sheet: {missing}")
        print("[story] Adding them at the end to satisfy the 'every clip is load-bearing' rule.")
        for fname in sorted(missing):
            cue_sheet.segments.append(ClipSegment(type="clip", file=fname))

    cue_sheet.save(cue_path)
    if not script:
        script = raw  # store the whole response as script if extraction failed
    script_path.write_text(script)

    print(f"[story] Wrote {cue_path} and {script_path}")
    return cue_sheet, script
