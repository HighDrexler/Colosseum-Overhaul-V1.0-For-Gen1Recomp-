# Colosseum Overhaul 1.0.9 — quick-start cache

## Why this changes the default

The v1.0.8 title gate enumerated 502 appearances, called full per-species model
preparation, and baked every indexed native action sidecar before Continue/New
Game could proceed. Even species absent from the user's party/encounters were
included. It also yielded after each completed appearance, even when the work was
just a cheap resident-cache hit. This was an inappropriate mandatory startup scope.

## Changes

- **Quick startup by default:** prepare the selected save's current team (up to
  six distinct exact normal/shiny appearances), not all 251 species. Eggs retain
  their existing icon path. New Game prepares the native starter models instead
  of baking the old saved party or the whole catalog.
- **Explicit full-catalog option:** BATTLE CACHE opens QUICK START / FULL CATALOG /
  MAIN MENU. Only FULL CATALOG requests all 502 appearances. The team comes first
  so cancelling a deliberate full run still leaves useful prepared models.
- **Batched warm entries:** process up to 32 completed entries in one slice under
  one total deadline, rather than one appearance per update. Dedicated loading
  screens get a 12 ms desktop / 8 ms Android/iOS cooperative CPU budget. Repeated
  accelerated game ticks cannot multiply that allowance at the same wall time.
  Avoid the old large per-row GC step for entries that were already resident.
- **Battle preparation remains strict:** native singles/doubles check exact model
  identities before updating. A UI-resident body also has to finish battle-action
  preparation before combat continues. Error/retry and the no-sprite-fallback
  policy remain intact. Quick completion is never reported as full-catalog ready.

## Deliberate tradeoff

This eliminates the required exhaustive bake, not the cost of extracting a model
that has never been prepared. An uncached team, first encounter, or first menu view
can still take time. The unchanged source decoder and authored animation sampling
are not represented as faster. Full Catalog still does substantial work; it is
available for users deliberately choosing the larger up-front preparation.
There is no new automatic whole-roster background extraction and no claim that
all models or animations are resident after Quick Start.

## Preservation and install

Built from the latest delivered v1.0.8 ZIP (SHA-256
`dc1dfaa989cf2f95e2ced7d86d2937a24f417085b2e9d406f65180503f37cc8f`).
No original file is removed; all 548 packaged assets remain byte-identical.
Source extractors, PokemonActors, UIMain, shiny handling, audio, Poké Ball facing,
arenas, camera, abilities, rewards, and native battle logic are unchanged.

Cancel to the main menu and close the game before replacing the combined package.
Keep imports and generated cache files; do not clear them. Completed model units
from the previous long pass can be reused. No audio rebuild or cache-epoch bump.
Do not enable a duplicate combined package or the standalone CBE/UI pair alongside it.
