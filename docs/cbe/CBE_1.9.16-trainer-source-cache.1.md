# CBE 1.9.16-trainer-source-cache.1

## Scope

This build rebases the trainer-model fidelity and cache/performance work on top of
`1.9.15-gpt1-runtime-rebuild.1`. It does not revert the live-validated Waza/GPT1,
PKX action handoff, canonical v9 audio, capture, arena fidelity, or cross-generation
battle runtime work from that baseline.

## Trainer source-motion audit

The main trainer discrepancy was architectural. `TrainerExtractor` was sampling B1
motion banks and compressing them to one generic gesture family plus one generic
reaction family. Those two families were then reused across opening, throw, sendout,
command, victory, brace, concern, frustration and defeat presentation. Because the
old reaction classifier positively rewarded lower-body displacement, a source
locomotion clip could score as a strong battle reaction.

Recovered Colosseum motion work gives one exact anchor for the player actor:
`field_common.fsys :: ken_b1` has 11 motions; 0 is the bind/T-pose and recovered
straight-motion roles are 1=idle, 5=walk and 8=run. CBE now hard-excludes 5 and 8
from battle gesture/reaction selection. This is an exact source-role correction,
not a visual heuristic.

For B1 banks whose complete retail semantic table is not yet recovered, the
extractor now computes a conservative locomotion signature over five chronological
samples. A clip is rejected only when lower-body displacement overwhelmingly
dominates upper-body/head/asymmetric motion. The action-bank fail-open can restore
a suspect clip only when fewer than two action families remain; explicit recovered
role exclusions such as Wes 5/8 can never be restored.

Reaction selection is now torso/upper-body led and penalizes lower-body travel.
Gesture selection remains lead-arm/asymmetry driven. Selected gesture and reaction
families retain five chronological samples from the same source clip so runtime
interpolation follows a coherent authored arc instead of crossing unrelated clips.
Trainer diagnostics now record explicit exclusions, inferred locomotion clips and
any fail-open restorations for follow-up source recovery.

### Fidelity boundary

This build does **not** claim that opening/throw/sendout/command/victory/defeat are
mapped to the exact original motion ID for every trainer. The exact per-event motion
state table is still unresolved for most B1 actors. Where the source role is proven,
CBE enforces it; where it is not, CBE stays on source animation data and records the
classification decision instead of presenting a guessed semantic map as retail
truth.

## Trainer/cache fast path

Trainer extraction now writes packed 44-float-stride `.f32` runtime meshes and a
compact runtime metadata file at extraction time. `PlayerTrainer` and enemy
`Trainer` prefer those sidecars immediately. Canonical `model_cache.lua` remains
an authoritative fail-open recovery path, but first PC/Stats/battle presentation is
no longer intended to parse thousands of large Lua vertex rows before it can draw.

The trainer identity advances from v12 to v13. This invalidates only trainer data
that needs the corrected source-role and extraction-time-sidecar contract. The
canonical v9 soundtrack and the 1.9.15 Waza/MoveFX/PKX caches are not globally
invalidated.

## Arena first-entry performance

All five arenas now receive v2 packed runtime sidecars during build/migration,
before their first battle view. Existing installs that already have current
canonical arena caches enter a one-time `arena_runtime_sidecars` migration: the
canonical cache is parsed once, packed, marked complete, and reused thereafter.
This path does not re-open/re-extract the HSD arena scene from the disc merely to
obtain the fast format.

The arena runtime keeps the canonical Lua cache for recovery and preserves the
existing culling/material/crowd preprocessing contract. The runtime marker is now
part of visual-ready inspection, so CBE cannot report the visual cache fully ready
while this fast-cache migration is still missing.

## Metadata-less cache backends

Gen1Recomp cache providers may expose a valid file entry without a byte-size field.
Before this build, several binary-mesh validators treated missing `info.size` as a
missing/corrupt sidecar. On those hosts, valid trainer, Pokemon and arena `.f32`
files could be rejected and the runtime would silently return to expensive Lua
parsing.

Trainer, Pokemon, arena runtime and arena migration validation now distinguish
"file missing" from "size metadata omitted." If a size is available it is checked;
if it is omitted, file existence is accepted and the actual binary payload/stride is
validated by `RuntimeMeshCache.meshFromBytes` when loaded.

## GPU work flattening

`game.ready` is now a bookkeeping seam only for heavyweight presentation data. A
new `ResidentPrewarm` coordinator owns the resident warm queue and is pumped only
after an engine step that did not change the active state. It executes at most one
heavy job per interval (0.90 s Android, 0.24 s desktop) after an initial breathing
window. The queue covers:

- AUTO/fixed/primed-RANDOM arena runtime scene upload;
- the bounded Android battle framebuffer allocation;
- the player trainer actor;
- TrainerRoster enemy actor warms;
- cached party base bodies with no disc extraction;
- portable battle/MoveFX shader compilation;
- cached MoveFX metadata promotion, one move at a time.

This removes the old `game.ready` wall where Android AUTO could synchronously pay
for two arenas, the framebuffer, Red/Wes, up to two enemy trainers and party model
work before normal play had settled. RANDOM still chooses the next venue at the
authoritative exit boundary, but its scene is only queued there and materialized
later on a stable overworld frame.

Battle entry prepares only active Pokemon base bodies. Exact source action banks are
queued and promoted one bank at a time during stable battle frames on both desktop
and mobile, while bench species stay deferred to the authoritative switch seam.

Android MoveFX cache promotion also no longer calls `collectgarbage("collect")`
after every prefetched move. It uses a small incremental GC step instead, avoiding a
stop-the-world pause inside an operation intended to make later presentation faster.

This changes *when* cached source data is materialized, not which source animation
is used.

## GPU/resource lifetime

Player and enemy trainer paths now explicitly release replaced mesh/texture objects.
Runtime reset also releases trainer shaders, shadow resources and fallback capture
ball objects. This reduces heap/GPU accumulation across repeated scene/model changes
and avoids depending on a later full garbage collection for heavyweight LÖVE
objects.

## Files with behavioral changes

- `extract/TrainerExtractor.lua`
- `extract/ArenaBuilder.lua`
- `extract/BuildPipeline.lua`
- `lib/RuntimeMeshCache.lua`
- `lib/PlayerTrainer.lua`
- `lib/Trainer.lua`
- `lib/TrainerPerformance.lua`
- `lib/Arena.lua`
- `lib/PokemonActors.lua`
- `lib/BattleRuntime.lua`
- `lib/ResidentPrewarm.lua`
- `lib/CacheManager.lua`
- `main.lua`
- `extract/MoveFXExtractor.lua`
- `tests/TrainerSourceCacheTests.lua`

See `VALIDATION_1.9.16-trainer-source-cache.1.md` for the completed gates and the
remaining real-device validation boundary.
