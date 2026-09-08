# Validation — Colosseum Inspired UI Overhaul 2.3.3

Static/package validation completed against 2.3.2 baseline.

- PASS: `main.lua` parses with LuaTeX/texlua `loadfile()`.
- PASS: `manifest.json` parses and reports version `2.3.3`.
- PASS: CBE warming no longer calls the resolved 2D portrait fallback; the 3D-owned pod stays on the 3D path.
- PASS: newly acquired CBE information actors are explicitly armed with information animation disabled.
- PASS: authored idle promotion is gated by per-surface deliberate-selection dwell (PC 0.90 s, Pokédex 0.82 s, Summary 0.62 s).
- PASS: the CBE actor clock is not advanced before animation promotion.
- PASS: a static CBE model is not repainted on the timed preview cadence; it redraws only for first frame / canvas invalidation / user orbit-zoom interaction.
- PASS: the post-dwell idle-preparation request uses a distinct UI dedupe key from the base-body request.
- PASS: CBE cold acquisition still cannot fall through synchronously from a non-resident menu draw.
- PASS: CBE 1.9.18 Hard Cache Save v2 contract is unchanged; no recache/version bump is introduced by the UI build.
- PASS: 2.3.2 scheduler lease, shared depth-canvas, bounded render targets, bounded actor residency and Gen I parity fixes remain present.
- PASS: runtime `assets/` payload is byte-identical to 2.3.2 (536 files).
- PASS: no CBE package/code is bundled into the UI ZIP.
- PASS: coarse registration/code-surface counts remain stable: {'hook_wraps': (18, 18), 'events': (10, 10), 'requires': (71, 71)}.

Runtime device verification should stress rapid PC/Pokédex scrolling after Hard Cache v2 is READY, then stop on a Pokémon and confirm: blank/clean pod only during the brief base-body promotion, correct static 3D model first, authored idle begins only after dwell, and no audio/input multi-second stalls.
