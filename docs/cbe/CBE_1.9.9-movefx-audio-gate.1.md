# Colosseum Battle Environments 1.9.9-movefx-audio-gate.1

## Why the previous build sounded unchanged

`BuildPipeline.lua` asserted `fullVisualReady == 251` immediately after the
source MoveFX scan. The current extractor reports 185 executable visual chains,
so the build exited at `movefx_failed` before `WazaSfxBuilder` ran. That left
the old empty SFX cache in place and allowed the game’s default move sounds to
remain audible.

The pipeline now retains the complete source move index and coverage report,
continues into the retail GameSound renderer, and withholds only the full
MoveFX ownership marker until all 251 chains are executable. This makes audio
progress observable without misrepresenting the remaining visual work.

