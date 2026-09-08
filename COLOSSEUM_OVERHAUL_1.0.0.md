# Colosseum Overhaul 1.0.0

## What this is

A single merged mod replacing the two previously separate, paired mods:
**Colosseum Battle Environments 1.11.1-integrated-test.1** (3D battle
presentation: camera, doubles engine, GameCube asset-extraction pipeline,
150 Lua files) and **Colosseum Inspired UI Overhaul 2.5.1-integrated-test.1**
(presentation-only battle/menu UI, ~26,800 lines in one `main.lua`). Both
source mods are treated as complete, launcher-ready baselines; this build is
a structural merge and targeted cleanup of them, not a rewrite of their
gameplay-facing behavior. Every feature, arena, doubles mechanic, ability,
and UI screen from both originals is retained.

## Why merge

The two mods previously found each other at runtime by manifest id string
(`optional_dependencies`), version-negotiating a small exported API surface
(doubles battle service, item sub-protocol, boss-intro gate, ability labels,
3D information-model bridge, battle world/trainer ownership). That bridge
existed only because they shipped as two independently-versioned mods. As one
mod, that indirection is unnecessary: it added per-frame lookup overhead in
hot paths (battle-ownership sampling runs every battle frame) and a real,
concrete bug surface (a renamed mod id would have silently orphaned players'
saved UI preferences -- fixed here, see below).

## What changed

**Merged skeleton.** One manifest (`id=COLOSSEUM_OVERHAUL`, `category=GRAPHICS`,
`priority=115`, matching CBE's former priority so world/arena ownership
negotiation with Stadium/Battle Art/other mods resolves the same way).
`optional_dependencies` is the union of both originals' lists, minus each
other's own id. `conflicts=["gen3_battle_ui"]` and the Colosseum-USA ISO
`required_imports` block are both carried over unchanged. One `main.lua`:
CBE's original file, byte-identical, with a small bootstrap appended at the
end that loads and runs the paired UI's original `main.lua` (shipped here as
`UIMain.lua`) the same way the two mods' own conventions already worked
individually. `lib/`, `extract/`, `recipes/`, `assets/`, `tests/`,
`third_party/` are CBE's trees with the paired UI's two lib files
(`DoublesUI.lua`, `DoublesDisplayCompat.lua`), assets, and test files merged
in -- verified zero filename/path collisions across both entire trees before
merging flat rather than nesting under a `ui/` subfolder, which avoided
rewriting any of the paired UI's ~15 internal `mod:read(...)` asset/lib path
literals.

**Collapsed the CBE<->UI bridge.** Every runtime mod-id lookup between the
two halves (`ModLookup.find(mod,'colosseum_ui_overhaul')` in
`lib/doubles/Runtime.lua`; `findLoadedMod("COLOSSEUM_BATTLE_ENVIRONMENTS")`
and `modRef.find(...)` call sites across `UIMain.lua` and
`lib/DoublesUI.lua`, including the once-per-frame battle-ownership sample)
now reads the already-shared `mod`/`exports` table directly. One exception,
deliberately kept as a `GoldCompat.findLoadedMod(...)` call rather than a
direct reference: `cbeAbilitiesBridge`, because `tests/AbilityBridgeTests.lua`
unit-tests it by extracting its source text and re-evaluating it standalone
against a mocked `GoldCompat` table, which cannot see a file-local upvalue.
`GoldCompat.findLoadedMod` itself now short-circuits CBE's former id to the
live mod, so the real behavior is still direct, the test stays valid, and
every other mod id (Stadium, Battle Art, Dramatic Shape, ...) still goes
through the real lookup unchanged. The `informationModels` -> Stadium fallback
and every bridge to a genuinely different mod (`BattleArtBridge.lua`,
`StadiumBridge.lua`, `NativeLauncherCompat.lua`) are untouched.

**Settings continuity.** The paired UI persisted its own settings under the
hardcoded literal mod id `"colosseum_ui_overhaul"` in three places
(`DexUI.setOption`'s in-memory and on-disk writes, and a `mod.options_changed`
event payload). Left alone, the id rename would have silently orphaned every
existing player's saved UI preferences -- including `colosseumBattleUI`,
which gates whether doubles battles are even allowed to start. Those three
sites now use the live `mod.id`, and a one-time, pcall-guarded migration
(`GoldCompat.migrateLegacyModOptions`, run on the first `screen.pushed` event
and defensively again from `DexUI.setOption`) copies an existing
`colosseum_ui_overhaul` options bucket forward to the new id, in both the
loader's in-memory cache and its on-disk options file, the first time either
runs after upgrading. Not live-game verified (see validation doc).

**One pre-existing bug fixed, unrelated to the merge.**
`lib/doubles/NativeAdapter.lua`'s `refreshAfterProgression` called
`self.status.bakeOnInflict(self.k,b)` -- a function that has never existed
anywhere in this engine or in CBE's own codebase (confirmed by search across
both). This ran, unconditionally, every time any Pokemon leveled up during a
doubles battle's post-battle progression, and always crashed with "attempt
to call field 'bakeOnInflict' (a nil value)", landing the session in
`Runtime.lua`'s fault state *after* rewards had already committed to the
save. The line above it (`b.badgeExtraBoosts=nil`) already fully replicates
the correct native cache-invalidate-then-lazily-recompute pattern used
elsewhere in this same engine (`src/battle/Damage.lua`,
`src/battle/BattleState.lua`); the bogus call was simply removed. This was
present in the original, unmodified 1.11.1-integrated-test.1 CBE zip and
reproduced against it directly, with zero involvement from any merge-related
code, before being fixed here.

**Known pre-existing issue, not fixed.** `IntegrationTests.lua`'s Psych Up
suite (Gen II) fails two related assertions: when the target has Protect +
Substitute + Lock-On all active, Psych Up's stat-stage copy does not happen,
even though its own effect record has no checkhit gate. Root cause is not
confirmed -- the leading hypothesis is that CBE's Gen II doubles adapter
exempts Psych Up from Lock-On consumption (`NativeAdapter.lua`'s
`consumeLockOn` override) but not from whatever pre-effect Protect/Substitute
gate the native kernel applies before the shim's effect record runs. This is
narrow (one move, one three-flag combination), does not crash or corrupt
state, predates this merge, and was left alone rather than risk a
speculative patch to the most fragile part of this codebase (the shadow-
kernel native-adapter hooks) without being confident in the actual root
cause. See `tests/doubles/IntegrationTests.lua` lines ~101-106.

**Scoped lightening pass.** Removed `GoldCompat.informationModelPointerHook`
(confirmed dead: fully implemented, never registered with any input hook;
the live path is `updateStadiumUiInteraction`, per the code's own comment
explaining why) and its one dangling flag write. Updated two self-identifying
log/version strings (`main.lua`'s own `VERSION` local, one `mod.log:info`
message) that a source-inspecting test caught as now-inconsistent with the
new manifest version. **Deliberately did not** extract the two
already-isolated UI presentation IIFEs (`GoldCompat.ColosseumUI`, the Gen I
battle HUD module; `spritePortraitResolver`) into separate `lib/ui/` files as
originally planned: auditing them showed they rely on lexical closure over
`UIMain.lua`'s own file-top `local` declarations, not just globals -- moving
their text to a separately-loaded file would silently break every one of
those references, which is the same class of risk as the full ~20K-line
de-monolithing this pass was explicitly scoped to defer, not a safe
mechanical cut-and-paste as originally assumed. Left as future work alongside
the rest of `UIMain.lua`'s de-monolithing.

## What did not change

`lib/doubles/Core.lua`, `NativeAdapter.lua` (beyond the one bug fix above),
`MovePresentation.lua`, `Presenter.lua`, `CameraDirector.lua`: untouched
beyond the lookup-collapse call sites. These carry precise, previously
crash-prone invariants (the `actorAnchor`-vs-`anchor`/`figureScale`
coordinate split; `MovePresentation.scope()`'s global-state swap/restore
dance for concurrent attack/receive channels; `Core.lua`'s event-identity
matching for damage/status presentation) that a rewrite would put at
disproportionate risk relative to any benefit. All eleven arenas, the
ability catalogue, both generation-specific ability wrappers, the native
doubles adapter, source extractors, and every UI screen (Bag, Party,
PP-recipient, Pokedex, Pokegear, dialogue theming) are unchanged in
behavior from their originals.

## Install

Same as either original: complete, launcher-ready. Enable Colosseum Overhaul
in place of both Colosseum Battle Environments and Colosseum Inspired UI
Overhaul; do not run this alongside either original (same underlying
functionality, would double-install/conflict). Existing saves and the
imported Colosseum source/caches carry over unchanged -- CBE's own settings
persist via the save file (`game.save.colosseumBattle`), independent of mod
id. See `VALIDATION_COLOSSEUM_OVERHAUL_1.0.0.md` for exact test results and
what remains unverified.
