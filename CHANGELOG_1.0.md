# Colosseum Overhaul 1.0 — final cleanup release

Based directly on the complete **v1.0.10** combined package. The display, manifest,
exported version and release card now use **1.0**; this is a release rename, not an
older code branch. The mod ID remains `COLOSSEUM_OVERHAUL`.

## Cleanup changes

**Title-menu interoperability.** Continue/New Game cache checks now follow the
actual action values or native/translatable labels, not array positions or an
inferred keepOpen flag. Reordered/custom title menus no longer cause OPTIONS,
EXIT or another mod's row to be intercepted while the real startup action goes
unguarded. Existing callbacks, row data and menu closing behavior are preserved.
A repeated hook pass neither appends another cache row nor wraps guarded actions
a second time.

**Cache worker teardown.** Native StateStack pop/clear now runs the same worker
cleanup as the cache screen's own cancel path. This prevents stale active-screen
ownership and a suspended preparation task after an external reset. Cleanup is
idempotent, does not claim unfinished models are ready, never invokes a cancelled
Continue/New Game callback, and does not delete completed cache files.

**Release documentation.** The old root README still described team-only Quick
Start. The current guide now accurately documents 30-new-model batches, relevance
selection, persistent progress, optional Full Catalog, restored portraits and
post-palette cache UI. A current validation index distinguishes executed checks
from retained historical reports.

## Retained without reduction

- Persistent, save-aware Quick Start batches of **up to 30 new source-model assets**;
  all 270 assets / 502 normal-shiny appearances remain in scope. Completed models
  are skipped across launches; current-team Continue and starter New Game do not
  automatically start another batch. Full Catalog remains optional.
- Colosseum party/PC headshot portraits, larger 3D information viewers, exclusive
  battle model selection, shiny handling and full-color Gen I/II cache screens.
- The complete v1.0.10 arena, camera, trainers, source move-effect/audio, doubles,
  abilities, switching, rewards, settings and provider compatibility implementations.
  No battle logic, animation sampling, model detail, source shader or audio-render
  algorithm changes are made by the cleanup.
- All **548 existing packaged assets** are byte-identical. No original file is
  removed. Import definitions, cache format/revision modules, optional dependencies,
  conflicts and supported engine/game declarations remain unchanged.

## Update

Close the game and manually replace the existing combined package with this ZIP.
Keep previous duplicates and the standalone CBE/UI packages disabled. **Do not
clear the source import or hard cache.** No audio rerender is required for this
release. `1.0` is intentionally a numerically lower release label than `1.0.10`;
manual replacement avoids relying on the automatic newer-version comparison.

Cold model generation still costs time. This cleanup does not claim a phone/PC
startup-time speedup or replace the source extractor. See VALIDATION_1.0.md for
current tests and explicit device/runtime limitations.
