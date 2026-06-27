# Audio Story Pipeline

Turn a folder of audio clips into a short, original fictional audio story — weaving your actual recordings together with AI-generated narration into a single mixed audio file.

## Concept

The clips are not background texture. They are **artifacts inside the fiction.** Every source clip is load-bearing: the generated story must exist *because* these specific recordings exist. Narration frames, connects, and contextualises the clips; it never drowns them out.

## Setup

### 1. System dependencies

```bash
# macOS
brew install ffmpeg

# Ubuntu / Debian
sudo apt-get install ffmpeg

# Windows
# Download from https://ffmpeg.org/download.html and add to PATH
```

### 2. Python dependencies

```bash
pip install -r requirements.txt
```

### 3. Environment variables

| Variable | Required for | Notes |
|---|---|---|
| `ANTHROPIC_API_KEY` | Story generation | Required |
| `ELEVENLABS_API_KEY` | Narration (best quality) | Optional; falls back to OpenAI TTS → pyttsx3 |
| `OPENAI_API_KEY` | Narration (fallback) | Optional |

If no TTS API keys are set, the pipeline uses `pyttsx3` (local, robotic voice). Missing keys print a clear warning and continue.

## Usage

```bash
python make_story.py \
  --input ./clips \
  --mode found-audio \
  --length 3min \
  --voice <elevenlabs_voice_id> \
  --music ./music/ambient.mp3 \
  --output ./out/story.mp3
```

### All options

```
  --input   -i   Directory containing source audio clips            [required]
  --output  -o   Output audio file (default: ./out/story.mp3)
  --mode    -m   Narrative mode (see below)                         [default: auto]
  --length  -l   Target story length, e.g. 2min, 90s               [default: 3min]
  --voice        ElevenLabs voice ID                                [default: Rachel]
  --music        Optional music bed audio file path
  --stage   -s   Run only one stage: ingest|analyze|story|tts|mix  [default: all]
  --whisper-model  Whisper model: tiny|base|small|medium|large-v2   [default: base]
  --force   -f   Re-run stage even if cached output exists
  --non-interactive  Skip prompts (ambient clips get a generic description)
  --draft        Offline demo mode — no API calls, silent TTS placeholder
```

## Narrative modes

| Mode | Description |
|---|---|
| `found-audio` | Clips are recovered recordings (damaged tape, old voicemails). Narrator = archivist reassembling the pieces. |
| `memory` | Narrator is in the present; clips are fragments of their past surfacing. Tension = memory vs. what the tape says. |
| `reconstructor` | A failing machine tries to assemble the clips and gets it *wrong* — inventing connective tissue. The wrongness is the story. |
| `soundscape` | The clips dictate the plot; the story is written to fit their exact sequence and nature. |
| `auto` | Inspect the clip inventory and pick the best-fitting mode automatically; prints reasoning. |

## Pipeline stages

All intermediate artifacts land in `{output_dir}/.cache/` so stages are debuggable and resumable.

```
1. ingest    → .cache/clips_raw.json   (filenames, durations, speech/ambient guess)
2. analyze   → .cache/clips.json       (transcripts for speech; descriptions for ambient)
3. story     → .cache/cue_sheet.json   (ordered timeline of clip + narration segments)
               .cache/story.md         (human-readable script)
4. tts       → .cache/narration/       (cached synthesized audio per segment)
5. mix       → story.mp3 + story.wav   (final mixed output)
```

Run a single stage against cached outputs:

```bash
python make_story.py --input ./clips --stage story --force
```

## Output files

```
./out/
├── story.mp3          ← final mixed story (192k MP3)
├── story.wav          ← lossless copy
└── .cache/
    ├── clips_raw.json
    ├── clips.json
    ├── story.md
    ├── cue_sheet.json
    └── narration/
        └── <hash>.mp3  ← one file per narration segment
```

## Offline / draft mode

Run without any API keys for a quick demo:

```bash
python make_story.py --input ./clips --draft --output ./out/draft.mp3
```

This generates a minimal story skeleton, uses local TTS, and mixes everything together. No network calls.

## Design decisions

- **`faster-whisper`** over `openai-whisper`: faster inference on CPU, lower memory usage, same accuracy on `base` model.
- **`pydub` + system `ffmpeg`**: handles every audio format (m4a, flac, opus, etc.) without additional codecs.
- **`PyAV`** for duration detection: avoids the `ffprobe` CLI which may not be on PATH in all environments.
- **`pydantic` v2** for the cue sheet schema: strict validation with discriminated unions per segment type.
- **`typer`** for the CLI: automatic `--help`, type coercion, and shell completion.
- **ElevenLabs → OpenAI → pyttsx3** TTS fallback chain: degrades gracefully; always produces audio.
- **Content-hash caching** for narration segments: changing the text or voice ID busts the cache; re-running with the same inputs is free.
