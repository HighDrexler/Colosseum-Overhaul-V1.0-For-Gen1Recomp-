# CBE 1.9.16-trainer-source-cache.1 validation

## Baseline

Source package: `ColosseumBattleEnvironments-1.9.15-gpt1-runtime-rebuild.1.zip`.
All 1.9.15 Waza/GPT1/PKX/audio changes are retained; this pass changes trainer
motion classification and runtime/cache scheduling only where documented.

## Source audit evidence used

The trainer changes are constrained by recovered Colosseum data rather than a new
procedural animation system.

- `dougchansan/pkmn-colosseum`, `archive/previous_campaign/docs/RE_WORKFLOW.md`:
  recovered `ken_b1` contains 11 motions; motion 0 is the bind/T-pose and 1-10 are
  real animated motions.
- `dougchansan/pkmn-colosseum`,
  `archive/previous_campaign/docs/pcport_batch5_tasklist.md`: recovered straight
  player roles are `ken_b1` 1=idle, 5=walk, 8=run.
- The recovered HSD runtime path attaches distinct motion-bank entries and advances
  stock HSD animation state; this supports preserving coherent source motion clips
  instead of manufacturing new trainer skeleton motion.

Exact semantic battle event -> motion ID mapping is **not** considered recovered for
all B1 trainer actors in this validation.

## Correctness checks

### Trainer source-role contract

- Wes 5/8 are explicit battle-classifier exclusions.
- Excluded recovered roles cannot be restored by the generic locomotion fail-open.
- Unknown B1 gait rejection requires lower-body dominance across a five-sample
  source arc and is intentionally conservative.
- Reaction scoring is upper-body/torso led and lower-body penalized.
- Gesture/reaction playback stays within one selected source clip family across five
  chronological samples.
- Generated trainer cache diagnostics include explicit excluded, inferred-locomotion
  and restored-fallback clip lists.
- Trainer identity marker advanced to v13; global extractor/audio identities did not.

### Packed trainer fast path

- Extraction writes `cache/runtime_mesh_v1/trainers/<id>/base_XX.f32` and compact
  `base.lua` metadata.
- Player and enemy trainer runtimes prefer the sidecar and retain canonical Lua as
  a recovery path.
- Player model replacement and trainer reset explicitly release GPU objects.

### Arena first-view fast path

- `ArenaBuilder.runtimeSidecars` generates all five v2 arena sidecar sets before
  normal runtime view.
- Existing canonical arenas have a sidecar-only migration path without disc/HSD
  arena re-extraction.
- Arena runtime-sidecar completion is required by both BuildPipeline visual readiness
  and CacheManager visual readiness.

### Metadata-less cache provider contract

- Missing `info.size` no longer causes a valid existing `.f32` file to be rejected
  merely because the provider omitted size metadata.
- When size is present, minimum-size and stride divisibility checks still run.
- On actual binary load, `RuntimeMeshCache.meshFromBytes` validates payload size and
  stride before creating/feeding the mesh.

### Work scheduling

- `game.ready` performs no heavyweight arena/trainer/Pokemon resident materialization.
  It creates one `ResidentPrewarm` queue instead.
- AUTO queues Water + Wildlands rather than synchronously uploading both; fixed and
  primed-RANDOM choices queue only the needed venue.
- Player trainer, enemy TrainerRoster actors, Android framebuffer allocation, party
  base bodies, shaders and MoveFX cache promotion all share that same queue.
- The stable-overworld hook executes at most one coordinator job per allowed work
  interval and never pumps on a state-transition frame.
- The coordinator has an explicit startup breathing window so the first interactive
  frame cannot immediately inherit queued GPU work.
- Active battle actors defer source action banks; stable battle frames pump at most
  one bank per work interval.
- Bench roster models/actions are not bulk-uploaded at battle entry.
- Switch prewarm follows the same base-first, action-queued policy.
- Android MoveFX prefetch uses incremental `collectgarbage("step",48)` rather than a
  full `collectgarbage("collect")` after each move.

## Automated gates completed

Full Lua compile gate:

```text
find . -type f -name '*.lua' -print0 | xargs -0 -n1 texluac -p
PASS: zero syntax failures
```

Regression/contract suites:

```text
tests/AudioParityContractTests.lua             PASS
tests/BattleExitBoundaryTests.lua              PASS
tests/HSDScaleTests.lua                        PASS
tests/MoveFXAttackHandoffTests.lua             PASS
tests/MoveFXRetailParticleRuntimeTests.lua     PASS
tests/MoveFXSourceChainTests.lua               PASS
tests/PokemonReactionQueueTests.lua            PASS
tests/WazaSfxMappingTests.lua                  PASS
tests/TrainerSourceCacheTests.lua              PASS
```

Result: **9/9 pass**.

`TrainerSourceCacheTests` includes functional headless fixtures:

- first pass: 5/5 arena runtime sidecars built;
- second pass: 5/5 sidecars reused;
- second pass exposes file metadata without byte sizes, matching the portable cache
  condition being hardened;
- headless `RuntimeMeshCache.packRows` succeeds without requiring graphics APIs;
- coordinated startup warm queues the complete resident set but performs no heavy
  work during its startup breathing window;
- a simulated stable-overworld drain executes 11 heavy jobs and never executes more
  than one in a single pump, including recurring trainer/Pokemon/MoveFX jobs.

## What cannot be truthfully certified in this environment

The user's imported GC6E01 disc/cache is not present in this working container, so
this package does not fabricate any on-device millisecond improvement numbers or
visual A/B captures. The following remain runtime acceptance items for the next test:

1. First arena entry after the one-time migration should use the runtime-v2 sidecar
   and avoid canonical arena Lua parse/rebucketing.
2. First Red/Leaf/Wes/etc. UI or battle view after v13 trainer extraction should hit
   the trainer runtime sidecar.
3. Windows and Android should both retain the fast path even when the cache provider
   does not report `info.size`.
4. Repeated party/PC/battle navigation should show flatter transition latency and no
   multi-subsystem GPU upload burst at `game.ready` or `battle.started`; Android
   should no longer show a full-GC hitch while background MoveFX metadata warms.
5. Wes battle reactions must not visibly enter walk/run locomotion. Other trainers
   should be checked against source footage to continue replacing inferred clip
   roles with recovered exact role IDs.

This is therefore a source-informed hardening/test build, not a declaration that all
trainer battle choreography is already 1:1 with every retail trainer.
