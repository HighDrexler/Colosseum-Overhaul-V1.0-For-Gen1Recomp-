# Paired CBE / Colosseum UI test — integration notes

## Builds and baseline

CBE: **1.10.0-doubles-stability-test.2**. UI: **2.4.0-doubles-test.4**.

The CBE code was modified directly from the supplied **ColosseumBattleEnvironments-1.10.0-doubles-stability-test.1.zip**, not replaced with an older doubles or arena build. The UI starts from **2.4.0-doubles-test.3-ui-compat.1**, the latest recovered UI compatibility build. The handoff report records SHA-256 identities and changed/unchanged members for both baselines.

These are experimental integration builds. They add functional fixes and source-presentation improvements; they do **not** certify complete doubles mechanics, every original Colosseum effect, or an exhaustive visual approval of every arena. The sections below distinguish implementation and executed tests from remaining work. Historical release notes retained in the packages describe their own older releases; these instructions govern this pair.

## Install and first test

Replace the existing CBE and Colosseum UI mods with the two corresponding ZIPs through the launcher. Both archives have their own `main.lua` and `manifest.json` at the root. Do not extract one mod over the other or keep duplicate versions enabled. Both retain the original mod IDs and experimental flag; allow experimental mods in a launcher that filters them.

Use a save outside battle, preferably with a backup. Do not resume an in-battle checkpoint created under a different test version. Keep the existing user-provided Colosseum source import available.

Enable **Colosseum Arenas**, the paired **Colosseum Battle UI**, and the **Double Battles** option. Doubles remains OFF by default. Eligible ordinary trainer encounters need **three or more opposing party members**; two-member trainers do not trigger it. Wild, link and the existing special-encounter exclusions remain outside this doubles path. Turning doubles off retains native singles combat.

The arena source/packed-cache schema changes once. An otherwise complete installation refreshes the source arenas, adds Cipher Lab Underground and prepares the new arena sidecars. This is **not a request to clear all caches**. The global extractor revision, Pokémon/trainer revisions and source-audio completion contract are not bumped by this integration. An unrelated incomplete component can still require its own existing repair. Allow the arena refresh to finish before evaluating first-entry performance.

Cipher Lab Underground is in the arena selector and random pool. Its selection now survives settings normalization.

## Doubles and Bag changes

The recovered UI had Bag disabled despite the supplied CBE already exporting its item API. The new UI consumes the existing version-1 bridge plus its additive `itemApiVersion=1` capability. It shows a six-row scrolling Bag with quantities/reservations, selects the actual party recipient, and opens a move selector for Ether-style PP restoration. Healing, status/revival and supported battle-stat items remain governed by the generation's item handlers. Both active slots and reserve recipients use original party indices.

Commands retain the battle ID, ticket, turn, command slot and battler token. The controller, not the UI, validates and consumes items. There is no native singles Bag callback, save-party reorder or independent UI turn resolution. Back navigation, reservation rejection, unavailable items and stale command tickets have explicit tests. Older version-1 bridges remain compatible; Bag stays unavailable when that producer does not advertise item support.

A reproducible Gen I X Attack preview crash is fixed: native item validation was given an empty opposing battler. Preview now receives a detached real opponent record; live item use binds the actual opponent. Validation does not modify the real opponent, stages or inventory.

Target-specific adapters now cover Disable, Encore, Mean Look, Spider Web, Lock-On, Mind Reader, Spikes and Psych Up. A faster Disable can invalidate a queued action without spending its PP. Encore is re-resolved when the action executes. Traps and accuracy locks track the originating battler token, not just one of four reusable positions. Spikes belongs to a side and invokes the native entry-damage calculation, with visible damage/faint/replacement events. Random rampage target choices expose foes rather than allies.

The supplied Gen II engine lists Psych Up without a handler. The compatibility implementation is installed on the private doubles kernel only, not the native registry. It copies the seven selected-target stage values without sharing the target's table, fails for an all-neutral target, and keeps native PP, move-history and event handling. An existing installed primary handler is retained. This follows the Gen II command semantics rather than claiming that CBE changes every battle rule to Gen III.

## MoveFX and actor timing

Doubles now uses the same source-sequence-to-body-animation selection as singles. Waza phase selection occurs before the actor's bank starts; native charge/release state and attacker species feed chapter selection, including damage-bank variants. The chosen actor supplies its animation timing points and duration. A cold MoveFX lookup is queued for prefetch rather than synchronously extracting a move during its visible boundary.

Native event metadata is carried into presentation: source and target battler tokens, charge/release, Gen II animation parameters/miss information, and Gen I cancellation information. Native-audio fallback receives the actual phase parameter. This is metadata and handoff support, not a claim that every source-specific miss branch is fully reconstructed.

Only actual target HP damage receives that move's target-side Waza event. Recoil, confusion and self-costs do not masquerade as another target hit. Deferred effects retain the original actor token instead of attaching to a replacement in the same slot. Scoped source/target coordinates continue to use the original four-position geometry rather than repeatedly offsetting an already-rebound context.

Faint/recall retirement now waits for the actor's terminal animation, including a pending hurt-to-faint transition, rather than a fixed short delay. Diagnostic watchdogs remain as fail-open protection against a broken asset/handler; they are not normal animation timings. Codex's existing grouped send-outs, boss intro, source-audio gating and actor extraction work are preserved.

## Arena integration

The arena extractor now preserves packed GX source vertex RGBA alongside authored normals. Both direct rendering and the packed sidecar converter accept the extended source rows; legacy row formats remain supported. This restores source shading information that was previously discarded instead of applying a blanket contrast/sharpening effect. The packed GPU row remains 48 bytes. Canonical arena files grow to carry the recovered information and therefore need the one-time local refresh.

The audience classifier now recognizes source atlases in all six audience-bearing venues: Water, Orre, Pyrite, Deep, Realgam and Mt. Battle Summit. Dedicated crowd handling keeps source color/alpha and encodes restrained per-card motion separately. Summit is no longer classified as audience-free. Water's existing upper-tier/outlier protection is deliberately retained rather than restoring unverified floating spectators: the render check keeps 22 of 57 source audience groups. The other checked counts are Orre 4, Pyrite 30, Deep 10, Realgam 4 and Summit 8.

The lightweight/mobile shader shares the crowd, water, lava and foliage vertex motion instead of omitting those branches. Its fragment shader remains the lighter path. Desktop and mobile shader variants were both compiled and rendered in LÖVE; this does not substitute for Android/GLES device testing.

**Cipher Lab Underground** uses the actual `D1_labo_B1_bf.fsys / D1_labo_B1_bf.dat` battle room from the user's GC6E01 source, not a substitute arena recipe. It is wired through extraction, runtime meshes, camera/palette, selector persistence and cache readiness. The source room contributes 14 mesh groups and 34,902 triangle-list vertices. The environment count is eleven, including the existing intentionally authored Orre Wildlands.

A render check found the generic fallback camera ignoring the selected arena profile. It now derives the pose from that profile and applies the camera guard; the checked Pyrite fallback no longer points through the obstructing foreground rail. This is not a wholesale rewrite of source cinematics.

Arena migration uses schema 16, packed mesh version 7 and arena completion version 10. Build-time sidecar reuse checks canonical content identity, including same-size content changes; production LÖVE uses SHA-256. The runtime fast path does not hash a large canonical file at every battle entry. Other asset families are not deliberately invalidated.

## Dialogue and preserved UI

Both the CBE doubles producer and the UI's battle-text boundaries remove case-insensitive `{PROMPT}` / `{DONE}` control tokens. The direct message, page, string and character-array fallback paths are covered. Ordinary prose containing the word “prompt” is not deleted, and native waiting/input control is not changed. This addresses the control-token leak; a new live occurrence should still be inspected rather than assuming every possible dialogue source has been proven.

The previous compact HUD, EXP/type/status display, target rings, original-index party display and UI-only native-data fallback remain. Existing UI art/audio assets are byte-identical to the recovered UI baseline. This patch does not introduce new 2D placeholders or replace the established model provider.

## Executed validation

| Check | Result and boundary |
| --- | --- |
| Lua syntax | 128 Lua files compile with the LuaJIT library recovered from LÖVE 11.5. |
| CBE root suites | 46/46 pass. These include source/cache, camera, audio-boundary, actor and MoveFX contracts; many are static or fixture tests. |
| Native doubles regression | 1,003 assertions pass against the supplied Gen I/II native kernels, plus the suite's 345-case effect sweep. Includes coordinated encounters and reward/end-of-battle handoff fixtures. Graphics are stubbed. The sweep is not proof of every move's semantic correctness. |
| Presentation suite | 374 presentation assertions; 382 total including the existing item-UI checks. Headless identities, HUD visibility, layouts, camera and intro contracts. |
| New Bag/UI suite | 116 assertions pass, including second-slot commands, PP target indices, reservations, errors, old-bridge capability gating and control tokens. |
| Older UI bridge compatibility | 511 assertions pass using the actual released CBE doubles Test 1, Test 2 and Test 3 snapshot producers. |
| New arena contracts | 228 assertions, included in the 46 root suites: packed colors, normal preservation, crowd namespace isolation, settings and content identity. |
| New source-timing contracts | 21 assertions, included in the 46 root suites: bank choice, body timing, actor identity and terminal-animation gates. |
| Source build in LÖVE | All eleven arena caches/sidecars rebuild; all eleven sidecars are reused on the warm check. |
| Actual arena renderer | Eleven desktop and eleven mobile-fragment/shared-vertex arena renders from real source-derived packed meshes and textures, with depth rendering. Linux software OpenGL, arena-only views. |

The native mod entry points were also smoke-loaded for Gen I/II. That headless loader harness lacks `love.data.pack`; CBE correctly withheld its custom runtime when that harness attempted a full source import. It is entry-point smoke coverage only. Actual LÖVE arena builds above use the real packing API and succeed. No successful full live battle is inferred from the loader smoke.

Several old tests pinned obsolete release/cache strings; those contracts were updated for the intentional migration. Baseline comparison also exposed pre-existing stale version assertions and LuaJIT-incompatible test helpers (`math.atan` usage and `string.pack`). Those helpers were corrected, not silently skipped. Production camera logic was not changed merely to satisfy the old pitch helper.

## Remaining work — not represented as complete

Doubles is still experimental. The controller explicitly excludes Bide, Counter, Mirror Coat, Mirror Move, Metronome, Mimic, Sleep Talk, Future Sight, Baton Pass, Roar, Whirlwind, Teleport, Transform, Attract, Pursuit, Beat Up, Destiny Bond, Nightmare and Sketch, plus the Gen I binding family Bind/Wrap/Fire Spin/Clamp. These need safe multi-actor adaptations. Native custom effect handlers can add further restrictions. This build is not “all moves work in doubles.”

Original audience ambience/reaction playback is **not** integrated. The prior audit did not establish verified source cue identities and loop behavior, and this build does not replace that with generic cheering. Existing music/audio behavior is preserved.

Complete multi-layer material/TEV reconstruction, every sky/background discrepancy, all Water audience tiers, exhaustive reverse/attack-camera occlusion and retail-frame comparison remain open. Source shading recovery and the lab addition are integrated; the whole arena fidelity project is not visually signed off. Relic/outdoor perimeter detail still needs work beyond restoring source color data.

No Windows/Android gameplay or performance benchmark, complete four-model live battle, comprehensive capture sequence, full UI-stack/device run or every-move A/B comparison against retail Colosseum was completed in this session. Runtime arena images contain no battlers/UI. The source-timing improvements reduce known handoff differences; they are not a 1:1 parity certificate.

## Priority live acceptance sequence

Start a new eligible trainer battle with both mods, confirm independent commands for both allies, then exercise Potion/revival/status items and Ether on both active and reserve party identities, including one remaining item selected by two slots. Verify back navigation and that the arena never drops to overworld during the party/item overlay.

Next check selected-target and spread moves, charge/release, misses, recoil, hurt-to-faint transitions, simultaneous replacement and Spikes entry KOs, followed by reward/move-learning and return-to-overworld. Check normal and accelerated battle speeds. Repeat with Gen I/II and portrait/landscape UI sizes.

Finally check all arenas from both sides and during attack/switch views, especially Pyrite, Deep, Relic and the lab, and confirm the new arena choice survives reload. Listen for music continuity; no claim of new audience audio is made here.

## Source references for the Psych Up compatibility handler

Primary disassembly files consulted on 6 September 2026:

```text
https://github.com/pret/pokecrystal/blob/master/engine/battle/move_effects/psych_up.asm
https://github.com/pret/pokecrystal/blob/master/data/moves/effects.asm
```

Arena extraction uses the user's previously supplied GC6E01 image. No source image, extracted arena/model/audio cache, engine ROM, or font files are included in these test packages or the code-only handoff.
