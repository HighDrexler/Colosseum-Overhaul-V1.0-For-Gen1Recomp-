# Colosseum Battle Environments 1.9.0-movefx-source-chain.1

MoveFX correctness and coverage pass based on 1.8.9-audio-source-recovery.1.

The cache builder now reads all 251 GC6E01 move rows directly from
`common.fsys/common_rel.fdat` (row-zero base `0x11E010`, `0x38`-byte rows) and
records both source animation selectors at `+0x32` and `+0x1E`. Those selectors
lead WZX archive discovery before compatibility aliases, and the selected stem
is persisted per move so shared/reused source banks remain stable after restart.
If this table is absent, truncated, or contains an invalid primary selector, the
MoveFX build stops instead of reverting to name/category inference.

The full-cache contract now means every discovered Waza phase parsed completely and every entry in the visual role has its required source-backed runtime resources. Type-4 families declare whether they operate in world, model, or framebuffer space and whether they require a serialized GS texture or embedded HSD model. Missing ranges, failed writes, decode errors, parse warnings, and missing mandatory artifacts are recorded against the exact phase and entry in `build/movefx_coverage.txt`.

Waza timing now resolves the complete entry dependency graph, including forward references. Missing entries, missing timing points, duplicate identifiers, and cycles remain explicit errors; the runtime does not silently move them to frame zero. A role with unresolved timing cannot start or suppress native presentation.

Runtime object identities include the namespaced phase identifier, so attack and auxiliary phases whose local Waza entry numbers overlap no longer replace one another in the active model/effect tables.

Environment-model, sea-model, and Patchiru-model Type-4 entries now retain and animate their embedded source HSD models while applying decoded attachment, position, velocity, scalar, count, and mode data in the live attacker-to-target basis. Environment-model materials use a normal-derived texture-generation path. Existing source GPT1 banks, source-textured electron/lightning/TraceFX/billboards, leaf models, surface/aura, and framebuffer filter/blur/distortion remain part of the same shared Windows/Android renderer.

MoveFX cache identity advances to extractor 23 / Waza parser 7. The complete marker is written only at 251/251 executable visual chains and a complete Waza GameSound cache. No BGM, MusyX, Amuse, arena, trainer, capture, or Pokémon cache revision is changed.

The common move row identifies the Waza animation bank; it does not, by itself,
prove the internal per-species PKX body-motion dispatch used by the retail DOL.
Until that dispatch is established from GC6E01 runtime evidence, source-Waza
moves keep their stable base body pose rather than applying a guessed
Physical-A/Special-C clip. This limitation is explicit and is not represented as
full observed presentation parity.
