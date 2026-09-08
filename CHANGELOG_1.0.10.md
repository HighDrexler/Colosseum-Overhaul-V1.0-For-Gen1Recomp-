# Colosseum Overhaul 1.0.10

Complete combined CBE + UI update, built directly from the delivered v1.0.9.
The mod ID remains `COLOSSEUM_OVERHAUL`. No source import reassignment or cache purge is required.

## Quick Start: 30 new models at a time

Choose **BATTLE CACHE > QUICK START / 30 NEW** from the main menu. Each selection checks the existing disk cache and selects up to **30 incomplete/new model assets**, rather than selecting the same party repeatedly. Select it again to prepare the next batch; the final batch can be smaller. A completed catalog produces a completion screen without starting another build.

Selection is deterministic and reads the selected save's current team, PC ownership, caught/seen records, current and connected areas, encounter levels, and near-term evolutions. Team level is the median of the valid party levels, so a single overlevelled member does not entirely determine the selection. Exact owned shiny variants receive priority. Other species remain in the remaining-catalog queue and are eventually covered. No battle RNG, progression, party data or Pokédex records are changed.

The quota counts **unique source-model assets**, not duplicate colour requests: **270 model assets cover 502 normal/shiny appearances**. For 232 species, the normal model and source-authored shiny colour recipe are prepared together. Nineteen species have a separate shiny asset. A shared normal/shiny pair uses one slot, not two. The screen reports both persistent model and appearance totals.

## Completed work persists across restarts

The disk cache, not a per-session counter or GPU-residency flag, determines whether a model is complete. Before selecting each batch, the mod checks compact geometry manifests, native/shiny metadata, animation sidecars and texture sizes. Valid completed v1.0.8/v1.0.9 caches are recognized as well.

A fresh startup loads valid runtime binaries instead of re-running source extraction or rebuilding the same animation sidecars. Closing the game, cancelling a batch, changing save slots, or unloading a model from graphics memory does not erase completed disk work under this installation. Each model is retained as it completes; the entire 30-model batch does not need to finish first. An unfinished model can still require work on its incomplete components. Missing, incompatible or detectably damaged files remain eligible for repair.

**CONTINUE does not automatically start another 30-model batch.** It only prepares/loads the current team's exact required appearances, using completed disk files. NEW GAME retains the required starter warm-up. The batch operation is an explicit Quick Start selection. FULL CATALOG remains a separate optional operation. A batch completion screen waits for acknowledgement rather than launching another batch.

GPU objects must still be uploaded each application session and can be evicted on mobile. That is not source extraction or disk-cache regeneration. Selecting just a batch also does not make the rest of the catalog resident: a first uncached encounter can still require preparation, with the existing strict model-readiness guard.

## Colosseum portraits restored

The established Colosseum headshot atlas again takes precedence in the Pokémon menu's compact cards/rows and PC cells/badges when the Colosseum Icons setting is enabled. These are the same portrait assets used by the battle presentation, including their shiny variants—not small full-body 3D showroom actors. Larger model viewers in summary/inspection/Pokédex contexts retain their 3D route.

The existing icon preference is respected. Disabling it still permits the selected 3D provider where appropriate. Battle-model selection remains exclusive: these portrait changes do not restore Battle Arts/native-sprite substitution in battles.

## Gen I/II cache screen

The cache screen is now drawn in the full-colour HUD stage **after** the native cartridge palette/compositing pass. It no longer draws ordinary RGB text into Gen I's 160 × 144 palette-indexed canvas. The replacement uses readable screen-resolution text, separate phase/progress/model lines, cumulative saved totals, elapsed time and clear keyboard/controller/pointer controls. Portrait layouts leave room below the panel for touch controls.

## Installation and limits

Close the game and replace the existing combined package with this ZIP. Keep only one combined `COLOSSEUM_OVERHAUL` enabled; leave standalone CBE/UI duplicates disabled. Keep the existing source import and generated cache. No audio rerender is required.

All 548 packaged assets are unchanged. Existing v1.0.7–1.0.9 audio, Poké Ball-facing, arena, model/shiny, camera, UI and battle-rule changes are retained. Source decoding, model detail and animation sampling have not been reduced.

This release bounds each manual batch and fixes cross-session reuse; **it does not claim to eliminate the high cost of generating a previously uncached model**. Thirty cold models can still take substantial time on a phone. There is no measured mobile/Windows completion-time promise. See `VALIDATION_1.0.10.md` for the executed checks and their scope.
