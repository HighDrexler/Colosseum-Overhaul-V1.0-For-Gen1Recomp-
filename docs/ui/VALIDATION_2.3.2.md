# Validation — Colosseum Inspired UI Overhaul 2.3.2

Static/package validation completed against 2.3.1 baseline.

- PASS: `main.lua` parses with LuaTeX/texlua `loadfile()`.
- PASS: `manifest.json` parses and reports version `2.3.2`.
- PASS: 2.3.1 Gen I Save/dialogue/Pokédex-location parity code remains present.
- PASS: CBE cold model path does not fall through to synchronous `acquire()` when the CBE scene is non-resident.
- PASS: CBE v5 cooperative bridge hooks are present (`touchViewer`, `requestResident`).
- PASS: PC/Pokédex cold-selection debounce is present.
- PASS: information preview canvases are pooled by surface rather than per cached species.
- PASS: preview target resolution and redraw/update cadence are bounded separately from battle rendering.
- PASS: CBE actor handles are not retained in the UI actor LRU after leaving the active surface.
- PASS: PC uses the common information portrait path without a duplicate provider-resolution pass.
- PASS: no CBE files are bundled into the UI package.
- PASS: runtime asset payload is byte-identical to 2.3.1.

Runtime device verification is still required for frame-time proof. Stress test PC row scrolling, Pokédex species scrolling and party Summary cycling on both desktop and Android, especially immediately after relaunch and after a completed CBE Hard Cache Save v2.
