"""Pydantic schemas for the audio story pipeline."""

from __future__ import annotations

import json
from enum import Enum
from pathlib import Path
from typing import Annotated, Literal, Optional, Union

from pydantic import BaseModel, Field, model_validator


class NarrativeMode(str, Enum):
    FOUND_AUDIO = "found-audio"
    MEMORY = "memory"
    RECONSTRUCTOR = "reconstructor"
    SOUNDSCAPE = "soundscape"
    AUTO = "auto"


class ClipType(str, Enum):
    SPEECH = "speech"
    AMBIENT = "ambient"
    UNKNOWN = "unknown"


class ClipInfo(BaseModel):
    file: str
    duration: float
    type: ClipType = ClipType.UNKNOWN
    transcript: Optional[str] = None
    description: Optional[str] = None

    @model_validator(mode="after")
    def check_content(self) -> "ClipInfo":
        if self.type == ClipType.SPEECH and self.transcript is None and self.description is None:
            pass  # transcript may be populated later
        return self

    def inventory_text(self) -> str:
        label = self.transcript or self.description or "(no content)"
        return f"[{self.file}] ({self.duration:.1f}s, {self.type.value}): {label}"


class NarrationSegment(BaseModel):
    type: Literal["narration"] = "narration"
    text: str
    voice_direction: str = ""
    duration_estimate: float = 0.0
    audio_file: Optional[str] = None  # filled in after TTS


class ClipSegment(BaseModel):
    type: Literal["clip"] = "clip"
    file: str
    trim_in: float = 0.0
    trim_out: Optional[float] = None  # None = use full clip
    volume: float = 1.0
    crossfade_ms: int = 500


class MusicSegment(BaseModel):
    type: Literal["music"] = "music"
    file: Optional[str] = None   # path to local file; None = skip if unavailable
    mood: str = "ambient"
    volume: float = 0.25
    duck_under_speech: bool = True
    loop: bool = True


Segment = Annotated[
    Union[NarrationSegment, ClipSegment, MusicSegment],
    Field(discriminator="type"),
]


class CueSheet(BaseModel):
    title: str
    mode: NarrativeMode
    target_length: str
    segments: list[Segment]

    def save(self, path: Path) -> None:
        path.write_text(self.model_dump_json(indent=2))

    @classmethod
    def load(cls, path: Path) -> "CueSheet":
        return cls.model_validate_json(path.read_text())

    def total_duration_estimate(self) -> float:
        total = 0.0
        for seg in self.segments:
            if isinstance(seg, NarrationSegment):
                total += seg.duration_estimate or len(seg.text.split()) / 2.5
            elif isinstance(seg, ClipSegment):
                total += 0.0  # caller fills from clips.json
        return total
