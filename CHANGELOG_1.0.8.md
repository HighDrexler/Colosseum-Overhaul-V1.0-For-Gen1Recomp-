# Colosseum Overhaul 1.0.8

Complete combined CBE + UI update applied directly to the supplied
`Colosseum_Overhaul_v1.0.7(1).zip`. The mod ID remains `COLOSSEUM_OVERHAUL`.

## Model preparation before loading a save

The native main menu gains **BATTLE CACHE** in both generations. With Colosseum
models enabled, preparation starts from the title menu before Continue. Continue
and New Game cannot advance past the preparation screen until their required
preparation succeeds. Cancelling returns to the existing menu without loading or
changing a save. Retry reuses completed generated files. Keyboard/controller and
engine-delivered mouse/touch button input are supported.

The plan checks **502 appearances: normal and shiny for each of 251 species**.
These share **270 source assets**: 251 ordinary archives and 19 separate shiny
archives. The other 232 shiny appearances use their source-authored colour
recipes on shared geometry. Their recipes must validate too; a normal model
marker alone is not a complete shiny cache.

Preparation validates source revisions, builds/reuses compact model and native
action sidecars, checks texture payload lengths and loads shared base scenes.
Desktop base scenes remain available across ordinary battle/menu cleanup; unused
large action meshes can be released independently. Android/iOS preparation keeps
persistent data for the full plan but uses a bounded recent-scene working set,
with active actors protected. Active party/PC actors may exceed that soft cap.
GPU resources are rebuilt each application session; generated disk files persist.
This is not a promise that every animation, arena and move effect is simultaneously
resident in GPU memory.

## Exclusive Colosseum model selection

Doubles no longer change an unavailable Colosseum actor to a native/Battle Arts
sprite. Singles and doubles report model acquisition, matrix/build/draw and
renderer failures instead of concealing them with alternate artwork. Before the
native battle update proceeds, a readiness guard checks active species and colour
identities, including replacement Pokémon. It pauses presentation/progression
until the required resource is ready or the failure is reported.

Party cards and rows, PC cells and badges, summary/stat viewers, Pokédex, starter,
evolution and hatch model portraits request the same selected Colosseum provider.
Compact cells are static real 3D actors, not sprite thumbnails, and have separate
screen-cell identities so two visible Pokémon cannot cancel each other's requests.
Larger information viewers retain their existing dwell-to-animate/orbit behaviour.
Pending/failed cells show an explicit model status rather than another art source.
The existing source portrait atlas used by the battle HUD is retained; eggs keep
their native icon. Explicitly turning models OFF restores the configured artwork
route without changing Battle Arts or other provider settings.

## Retained from 1.0.7

The note-layer/keygroup/headroom audio changes, HIGH/FAST rendering options,
EXP gain at 75%, Pokémon-release gain at 85%, source-ball +Z facing corrections,
shiny rendering, arena/camera fixes, native battle rules, abilities, rewards and
single-battle switch fixes are retained. All 548 baseline assets are byte-identical.
No source media, newly extracted models or generated soundtrack files are added
to this ZIP.

## Installation

Close the game and replace the existing combined package with this complete ZIP.
Keep just one enabled `COLOSSEUM_OVERHAUL` installation. Do not enable the separate
CBE or UI Overhaul packages alongside it. Both `main.lua` and `manifest.json` are
at the ZIP root for launcher installation.

**Keep the existing source import and generated cache.** This update does not
invalidate audio or require another audio-quality conversion. Let the new model
preparation finish at the main menu. Its first complete run can take substantially
longer and use more disk space/RAM than loading just one party; no Windows/mobile
startup-time or FPS improvement has been measured here. Subsequent sessions reuse
valid disk files instead of re-extracting the same source units.

At an error, read the displayed message and retry; title preparation can be
cancelled with B or MAIN MENU. A battle error deliberately cannot be bypassed
by cancelling into an incorrect sprite battle. EXIT GAME / START on the error
screen exits the application; unsaved gameplay is lost. Preparation failures are
recorded under the mod cache at `build/model-cache-error.txt`.

See `VALIDATION_1.0.8.md` for executed checks and their limits.
