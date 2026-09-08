# CBE 1.10.0-movefx-turnflow-test.1

## Baseline and installation

This combined CBE-only test is based directly on `ColosseumBattleEnvironments-1.10.0-movefx-transit-test.1.zip` (SHA-256 `c1177d7bfb7f9b84abcfa25be0d872f8d9901b1b32790ea84468a59d0356f347`). It includes the mandatory requirements recovered from `CBE_DOUBLES_TURN_FLOW_ADDENDUM(1).md`; those changes are not postponed to another build.

Keep **Colosseum-Inspired-UI-Overhaul 2.4.0-doubles-test.4**. Replace only CBE, with one CBE version enabled. Both generations remain supported. Use a backed-up save outside battle; do not restore an in-battle checkpoint across test versions.

Keep the existing Colosseum source import and caches. Run **Hard Cache Save once after installing**, even if the old completion marker still reads READY. Its existing queue revalidates assets and prepares the new Waza packed-effect sidecars ahead of use. This patch does not invalidate the source extraction, arenas, Pokemon, trainers or audio as a group. Missing or independently stale assets can still need their normal build. Do not erase the whole cache.

The packed Waza namespace is now schema 2 plus the MoveFX extractor revision (`_runtime_v2_r33` for this source revision). Canonical source effects remain revision 33. Old unstamped binaries cannot masquerade as this revision's ready meshes. A cold sidecar can rebuild when requested; warming first is preferable to doing that during its first presentation. No new handset frame-time guarantee is made.

The original mod ID, eligibility toggle (eligible trainers with **three or more** Pokemon), singles path, Bag/items, previous source extraction repairs, eleven arenas including Cipher Lab Underground, and paired UI bridge are retained. UI files and assets are not changed by this package.

## 1. Live arena transit, not only isolated effect rendering

The live name-based move path and the isolated numeric-ID path differed. Linked particle placement now uses the resolved source record's numeric move ID. In particular, Surf foam and the animated wave select the same battlefield-space transform instead of placing one relative to the Pokemon.

Four identified source particle cores were authored over shorter travel spans than the generic 100-unit lane: Flamethrower, Water Gun, BubbleBeam and Octazooka. Their measured source spans now map to the actual source-to-target distance. This mapping applies only to the identified attacking core selectors, including their `sp1` copies; it does not stretch unrelated muzzle particles, receiving effects or effect-model attachments. Velocities and lifetimes remain the source programs' values. These measured lane mappings are a presentation adaptation, not evidence that every retail placement selector has been reconstructed.

Packed effect reuse checks schema, extractor revision, canonical path, available source size, complete triangle counts, expected binary path and exact static/morph byte stride. Morph stride comes from the actual `morphFrames` field. The wrong/stale-binary path is no longer accepted simply because an old sidecar exists.

There is no blanket removal of depth testing, arena occlusion or effect clipping. No generic replacement flame/wave artwork is introduced.

## 2. Dig and Fly: absence survives the effect chapter

Doubles now snapshots the native structural absence flag before and after an action, with the original battler token. A queued automatic visibility transition survives the end of the temporary MoveFX chapter, the partner's actions and the interval between turns. The return/release path reveals the correct actor; a native cancellation that clears absence also produces a restore even without a move event.

The four-model presenter and its Models-OFF sprite fallback use the same gate. A replacement does not inherit the outgoing token's hidden state. Faint/recall cleanup releases the structural hide rather than leaving a permanently missing occupant. The native singles model path now reads the same kind of structural absence while continuing to update the hidden actor so release is not frozen.

This is not the generic transient hit-blink/picture-hide flag. Native Gen I invulnerability and Gen II `volatile.vanished` remain authoritative; this presentation fix does not rewrite their hit rules or remove a native mechanics glitch by silently changing battle state. Exact source ascent/burrow choreography and Fly's remaining unsupported source variant are not certified by this change.

## 3. Required doubles turn-flow contract — both generations

### After each complete action

The controller finishes all targets, recoil and faint presentation, captures the KO participants, then suspends its existing action continuation for native progression. Each defeated opponent has an exactly-once reward state; a spread double KO is drained serially, not through overlapping menus. Native EXP calculations, Gen I deferred level/stat commits, stat windows, learning/replacing/declining decisions and sharing extension points remain the award machinery.

The generation-specific EXP.ALL / EXP.SHARE paths are retained, including their legitimate separate sharing passes. An earlier earned award is committed before later combat can change HP or participants. It therefore does not disappear after a later faint or loss. Zero eligible Gen I participants cannot trigger the native singles fallback that would award an unrelated current actor.

The arena retains its four actor handles during progression. The doubles command snapshot yields to the normal native progression UI. On return, active Gen I battle views refresh their committed stats and moves without rebuilding or reordering the saved party. Level/evolution eligibility is retained for the native post-battle phase, not consumed by intermediate KO screens.

### Continue the already committed turn

Action order, original party indices and battler tokens survive progression. A fainted/replaced token cannot act again. If learning replaced the selected move's slot, the old command does not silently become the new move or spend its PP; that stale command is explicitly skipped. The new move can be selected at the next real command phase. Existing deliberate switch action timing and Encore handling are retained.

Fainted positions do not receive forced reserves midturn. A remaining action can use the valid surviving-target behavior; when no target exists, the adapter applies its native pre-action/status gate and explicit failure/PP path rather than inventing a reserve target or returning before all action handling. A charging release does not spend a second PP.

### End of turn and finalization

Only after committed actions resolve or skip does residual processing run once. Any resulting KO progression finishes before forced replacement selection/send-outs. Both sides obey this timing. Distinct eligible reserves are selected; an entry-hazard KO can cause another replacement without reopening the previous action queue or repeating residual damage. A deliberate switch is not a forced faint replacement.

Whole-roster exhaustion is a separate terminal path. Pending KO progression settles, then native prize/Pay Day, result, evolution and completion callbacks run once. Settled KO rewards and public faint notifications are not replayed at finalization.

A progression-only queue boundary prevents Gen II's native `locked-in` state from submitting a singles turn when EXP text drains. The real charge/rampage state is preserved through an intermediate pause rather than indiscriminately erased. Native combat submission is blocked while progression owns the screen. Normal end-of-battle volatile cleanup remains with the native completion path.

After progression has committed, experimental abort-to-initial-singles is deliberately rejected; it would roll back party state while potentially retaining rewards/hooks. An error at that point asks for the pre-battle save instead of risking duplicate awards.

## 4. Related lifecycle repairs from the diagnosis

Custom opponent reveals now mark seen species through the appropriate generation's bookkeeping, including the native Gen II Unown helper. Actual faints publish a coherent public `battle.fainted` notification with the real host, side, original party index and battler identity. The private two-slot damage kernel remains isolated from public lifecycle dispatch.

Gen II faint happiness uses the causative opposing battler instead of binding the player as its own opponent. The Yellow companion faint-happiness hook is forwarded once. Native helpers remain responsible for their actual calculations. Recoil/residual cases without an opposing cause use the adapter's explicit fallback rather than pretending every KO has the last attack's source.

## 5. Executed validation and its limits

The accompanying machine-readable validation report records the final archive identity, source member hashes, actual exit codes and tests. The new source was compiled with the LuaJIT library distributed in the supplied LÖVE 11.5.

- **1,432 native regression assertions**, plus the retained **345-case effect sweep**, pass against the supplied Gen1Recomp source. New coverage includes Dig/Fly charge/release, both sides, per-KO rewards, native deferred commits, native sharing plus synthetic hook callbacks, no-target PP/status gates, turn continuation, later loss, residual KOs, real Spikes replacement chains and Gen II's final charge-lock case.
- Native screen fixtures exercise empty-slot learning, full-moveset accept/decline, non-leading original party indices, native stat presentation, and old-command/new-move identity. Post-battle evolution fixtures exercise two eligible Pokemon, accepting/canceling the first while continuing the second, one result callback and no reward replay. The Gen II evolved species in that routing fixture is explicitly synthetic, not a retail data certification.
- **49 root regression suites** pass. The new arena integration suite has **54 assertions**, and structural visibility has **58**; the retained transit suite has **100**. These are included in the 49 suites, not additional live battle counts.
- Retained presentation tests pass **374 assertions / 382 including their item checks**. The unchanged UI's Bag/item suite passes **116**. Graphics in these suites are stubs.
- Actual LÖVE arena runs use four source Pokemon with the real Arena, DoublesPresenter, MovePresentation and effects renderer. Flamethrower and Surf run in both directions in Water Colosseum; Ice Beam runs in Cipher Lab Underground. A separate lab render gate checks all four identities hidden/restored, with real draw-call counts and images. The source events/party are controlled fixtures; audio is silent and the full UI/native combat controller is not running inside those image tests.

The final counted render set contains five 420-frame attack cases and nine hidden/returned-state views. Two exploratory fixtures used invalid shorthand arena IDs and fell back to Water; they are excluded from named-arena validation. The harness now asserts the selected and resolved arena IDs. No Orre/Realgam render coverage is claimed from those exploratory labels.

These results do NOT constitute a complete live ROM-backed battle, physical Windows/Android/GLES run, performance benchmark, exhaustive installed-mod compatibility pass, every evolution condition, all HM-forget permutations, or a retail audiovisual comparison of all moves. Native hooks were retained and synthetic hook use tested; arbitrary installed EXP mods were not certified. The normal UI handoff has fixture coverage, but the complete styled UI inside a live arena needs the user's device run.

## 6. Remaining visual and gameplay work

The current integrated captures still show over-bright flame cores, visible particle-card edges and incomplete wave material/opacity fidelity. The fixed cases establish battlefield travel/visibility, not final art approval. Other source attachment/size selectors, material/TEV reconstruction, exact cameras, audio timing and all species/move variants still need comparison. The earlier all-251 source availability report is not being relabeled as a new all-move visual pass.

The existing source-entry gaps for Fly, Tail Whip, Surf's alternate variant, Growth, Agility, Double Team, Minimize, Splash, Sandstorm, Encore and Hidden Power are not all removed. Structural Fly invisibility is fixed independently of full source-variant support.

Existing complex doubles exclusions remain: Bide, Counter, Mirror Coat, Mirror Move, Metronome, Mimic, Sleep Talk, Future Sight, Baton Pass, Roar, Whirlwind, Teleport, Transform, Attract, Pursuit, Beat Up, Destiny Bond, Nightmare and Sketch, plus Gen I Bind/Wrap/Fire Spin/Clamp. This build does not silently enable them or claim complete Gen III mechanics. Original audience audio and the remaining arena fidelity work are not part of these fixes.

## First in-game check

Start an eligible trainer encounter after the warm cache completes. Check Flamethrower/Surf between the two actors, then Dig/Fly across the partner's action and next turn. Defeat one opponent while other actions remain: native EXP/stat/learning should complete, the same turn should continue without a forced reserve, residuals should finish once, and only then should replacements appear. Repeat with a spread double KO and the other generation. Finally finish a battle while another ally is charging and confirm one normal prize/evolution/overworld return with no extra singles attack.

## Distribution

The installable package and code-only handoff contain no Colosseum image, generated model/texture/audio cache, engine ROM or font files. Runtime screenshots are diagnostic captures, not replacement assets. Historical notes retained in the mod describe older versions; this document governs the combined test.
