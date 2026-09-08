# Colosseum Overhaul 1.0 — cache options hotfix

Based directly on the delivered 1.0 combined release. The display/manifest version
remains 1.0; this archive is named Cache_Options_Hotfix to distinguish it from the
preceding release. The mod ID remains COLOSSEUM_OVERHAUL.

## Explicit selection before cache preparation

The initial title prompt, BATTLE CACHE menu entry, and generic public prepare
entry now open the mode chooser instead of automatically starting cache work.
The chooser itself performs no inventory scan, source extraction or cache write.
Its three choices are QUICK START / 30 NEW, FULL CATALOG, and MAIN MENU.
Opening confirmation input is not reused as mode-selection input. Keyboard,
controller and pointer paths require the opening confirmation to clear first.
Cancelling the chooser does not queue new startup prewarming or invoke a saved
Continue/New Game callback.

CONTINUE/NEW GAME requests that need model preparation also open options. These
include CURRENT TEAM ONLY / STARTER MODELS ONLY, which runs the required warm-up
and resumes the original native action once. Ready current-session models still
pass straight through. Quick/Full remain optional batch operations, not automatic
save-load actions. New Game batch relevance starts from native starters rather
than inheriting the old save's party. Battle readiness safety checks are unchanged.

## Quick Start does not auto-continue through the catalog

The 30-new-model quota, relevance selection and disk-persistent completion checks
are unchanged. A completed Quick batch waits for acknowledgement and stops. It
does not start the next batch in the background. Subsequent manual selections
advance through the remaining catalog, excluding valid completed units.

Separate existing resident-prewarm work can still load cached party bodies,
arenas/trainers/shaders and team move effects. Requested information viewers and
uncached encounters can prepare their specific models. Those paths do not form
an automatic remaining-roster queue. The separate explicit Hard Cache operation
is unchanged.

## Preservation and installation

All 548 existing assets remain byte-identical. Source extraction, animation
sampling, PokemonActors, QuickCachePlanner, ResidentPrewarm, portraits/UI,
battles/abilities/rewards, audio, ball facing, cache formats and compatibility
fields are unchanged. Changes are limited to cache consent/controller behavior,
selector layout/public entry routing, tests and release documentation.

Close the game and manually replace the combined package with the hotfix ZIP.
Keep the same source import and generated cache. Do not enable old combined
copies or the standalone CBE/UI pair alongside it. No cache wipe or audio rerender
is required. This hotfix keeps version 1.0 and needs manual replacement rather
than a higher-version update check.

See VALIDATION_CACHE_OPTIONS_1.0.md for executed checks and limitations. Cold
source extraction is not optimized by this hotfix.
