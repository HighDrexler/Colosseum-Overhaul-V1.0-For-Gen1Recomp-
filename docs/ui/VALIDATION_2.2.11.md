# Validation — Colosseum Inspired UI Overhaul 2.2.11

- `main.lua` parses successfully through `texluac -p`.
- `manifest.json` parses and reports 2.2.11.
- Runtime asset inventory remains unchanged from 2.2.10; only `main.lua`, `manifest.json`, and the new 2.2.11 notes/validation files differ.
- PC model viewer calls the shared `drawStadiumUiModel` path used by Summary/Pokédex.
- Actor `update(dt)` now runs before redraw throttling, so a 60 Hz PC menu can continue source animation even when the model canvas is reused.
- Direct mouse/touch polling is enabled for information pods and the `input.pointer` wrapper is deliberately not registered.
- Party-deposit and storage-grid fallback icons receive `selected=false`; the dedicated portrait-side locator is the only orange selection cue.
- 2.2.10 native Gen II `MapNameSign` suppression remains installed.

Live confirmation target: open PC with CBE models ON, leave one model selected for several seconds, rotate/zoom it, cycle through several cached species and revisit them, then repeat with CBE models OFF to confirm normal 2D fallback remains unchanged.
