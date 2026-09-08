# Validation — Colosseum Inspired UI Overhaul 2.3.4

Static/package validation completed against the 2.3.3 baseline.

- PASS: `main.lua` parses with LuaTeX/texlua `loadfile()`.
- PASS: `manifest.json` parses and reports version `2.3.4`.
- PASS: rapid browsing retains the 2.3.3 scan target (desktop Gen I/II 0.60/0.68, max 256; Android 0.42/0.48, max 176).
- PASS: deliberate selections promote independently to a sharper detail target (desktop Gen I/II 0.92/1.00, max 384; Android 0.64/0.72, max 256), with stricter caps for material-heavy models.
- PASS: quality-promotion dwell is separate from animation-promotion dwell: PC 0.30 vs 0.90 s, Pokédex 0.26 vs 0.82 s, Summary 0.16 vs 0.62 s.
- PASS: scan/detail canvases are shared by information surface and bounded; no per-species render-target residency is introduced.
- PASS: a static CBE actor still renders once per tier unless invalidated by selection quality promotion or explicit orbit/zoom input.
- PASS: authored idle animation is still not advanced before the longer deliberate-selection dwell.
- PASS: CBE cold acquisition cannot fall through synchronously from a non-resident menu draw.
- PASS: material-heavy models keep bounded redraw cadence on both desktop and Android.
- PASS: CBE 1.9.31+ uses the explicit showroom-only `setAnimation` bridge; older compatible CBE builds retain the actor fallback.
- PASS: runtime `assets/` payload is byte-identical to 2.3.3 (536 files).
- PASS: no CBE package/code is bundled into the UI ZIP.
- PASS: dependency/require surface remains stable (`require(` count 71 in both 2.3.3 and 2.3.4).

Runtime acceptance should stress rapid PC/Pokédex scrolling, stop on both simple and material-heavy Colosseum models, verify the static model sharpens quickly, then verify authored idle begins later without a multi-second input/audio stall. Android should additionally be checked for sustained browsing memory/driver behavior.
