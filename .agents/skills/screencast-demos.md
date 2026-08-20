---
name: screencast-demos
description: Turn a screen recording into a compact demo GIF for the README (ffmpeg pipeline, 2x speed, storage/embed conventions).
---

# Screencast → demo GIF

## Recording
Record at **600px width**. Save as `.mp4` (e.g. `feature-name.mp4`).

## Convert (2x speed, palette-optimized)

```bash
ffmpeg -y -i feature-name.mp4 \
  -vf "setpts=0.5*PTS,fps=20,scale=480:-1:flags=lanczos,split[s0][s1];[s0]palettegen=stats_mode=diff[p];[s1][p]paletteuse=dither=bayer" \
  -loop 0 data/feature-name.gif
```

- `setpts=0.5*PTS` = 2x speed (adjust the factor for other speeds).
- Two-pass palette (`palettegen`/`paletteuse`) keeps quality decent at small file size — a naive single-pass GIF looks banded.
- To use only the first N seconds of the *source* (before speed-up), add `-t N` right after `-y`.

Verify duration: `ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1 data/feature-name.gif`.

## Store & embed

- GIFs live in `data/` (docs-only assets), not `static/` (app-served assets).
- Embed under the matching `## <Feature>` section in `README.md`: `![<Feature> example](./data/feature-name.gif)`.
