# Validation — 1.9.13-source-move-chain.1

## Supplied Bite capture

The supplied 27.63 s capture was sampled frame-by-frame. At the first Bite
boundary Larvitar enters only a very small generic body motion and the defining
large Bite effect is absent before the target faints. This is consistent with a
Waza presentation-layer loss rather than another attack-state initialization
failure.

## Type-3 embedded HSD handoff

The current source contained an implemented `type3ModelStart` / `drawWorld`
renderer, and the 1.9.1 retained-source notes recorded Bite (`kamituku`) as a
decodable embedded `scene_data` HSD model. However, no production extractor code
assigned `resourceKind="hsd-model"` to a parsed Type-3 row. Only tests manually
constructed that field. A direct embedded non-GPT1 Type-3 row could therefore
fall through GPT1 selector matching and satisfy the old executable-chain gate
while dropping its own HSD model.

Extractor 26 now routes direct Type-3 embedded bytes before selector fallback:

- `GPT1` direct data remains GPT1.
- non-zero-state rows keep the retail shared-resource dependency path.
- direct non-GPT1 data is compiled as its own HSD model.
- successful decode stamps `resourceKind="hsd-model"` and carries the compiled
  model asset into the runtime timeline.
- failed decode stamps `embedded-unknown`; both extraction and runtime ownership
  reject the role instead of substituting an unrelated GPT1 generator.

This is the concrete missing Bite-jaw handoff. The existing HSD Waza renderer,
source timing, attachment, material shells, textures, and animated geometry pages
are then reachable for that row.

## Active-slot PKX body map

The PKX parser already decoded sixteen body-map indices for every animation
entry, but both generated metadata writers serialized only the idle copy.
`Actor:bodyMap()` consequently used idle mouth/chest/limb indices even while an
attack or reaction slot was active. Metadata revision 3 persists each slot's
body map and all of its sub-animation references; runtime attachment selection
now uses `nativeSlot.bodyMap` while that slot owns the actor.

Pokemon extractor revision 33 forces existing species metadata/action caches to
refresh once. MoveFX extractor revision 26 and the full-cache marker invalidate
old false-complete Waza caches. The v9 soundtrack/audio cache identity is not
changed by this visual pass.

## Static/regression checks

- Every Lua source in the package parses under the installed Lua 5.4 runtime.
- MoveFX source-chain assertions pass through the new Dark/Bite Special-A rule,
  active-slot body-map assertion, direct embedded-Type-3 classifier assertion,
  and rejection of `embedded-unknown` ownership.
- PokemonReactionQueueTests, HSDScaleTests, WazaSfxMappingTests,
  AudioParityContractTests, and MoveFXAttackHandoffTests pass under the local
  headless Lua runner.
- BattleExitBoundaryTests also fails in the untouched 1.9.11 baseline under this
  particular Lua 5.4 harness (`completion did not release CBE`), so that harness
  result is not attributed to the 1.9.13 MoveFX changes.

## Remaining fidelity work

This pass restores a missing source resource class and correct attachment map; it
does not certify the whole 251-move renderer. Remaining work still includes the
previously incomplete source chains, exact GPT1 GX/orientation behavior, PKX and
Waza material/texture animation channels, compound PKX sub-animation playback,
and retail move-camera behavior. Live GC6E01 testing should specifically verify
Bite's phantom jaws, jaw target placement, jaw open/close timing, GameSound
synchronization, target Damage timing, and camera choreography before expanding
the same comparison sweep to other moves.
