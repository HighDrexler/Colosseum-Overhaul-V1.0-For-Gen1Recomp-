> Historical Test 1 notes. See **DOUBLES_TEST_2.md** for this installed build, model cache migration, and current validation.

# CBE + Colosseum UI — Doubles Test 1

**Experimental gameplay build. Back up your save and keep the stable mod ZIPs before installing.**

## Packages and baseline

- CBE: `1.10.0-doubles-test.1`, based on `1.9.31-relic-visual-fidelity.1`.
- UI: `2.4.0-doubles-test.1`, based on `2.3.4`.
- This is an isolated doubles experiment, not a merge of the separate MoveFX actor-clock/import-fix branch or a fix for the outstanding Articuno/Blastoise idle reports.
- The original mod IDs, required Colosseum import specification, cache paths and extractor revisions are unchanged. No manual cache reset is required by these changes. Previously uncached models can still trigger normal extraction.

## Installation and activation

Install both mod ZIPs through the launcher, replacing their existing versions rather than running duplicate copies. Enable both experimental mods. Keep your existing Colosseum disc import.

In UI Settings, turn **Colosseum Battle UI ON**. In CBE's **Battle** menu, turn **Colosseum Arenas ON**, keep **Colosseum Models ON** for the intended 3D test, and set **DOUBLE BATTLES (TEST) ON**. Doubles defaults to OFF.

Begin an ordinary trainer battle against a party of **three or more** Pokemon. Exactly two, one, and wild encounters remain singles. Link battles, tutorials, and Battle Tower/contest special modes are excluded. The threshold uses the constructed trainer party, and the choice stays locked for that encounter. A player with only one usable Pokemon can still fight with an empty partner position. Eggs and fainted party members are not sent out.

The native introduction currently plays before conversion at the first command boundary. The added partner send-outs are an experimental presentation, not the finished Colosseum dual-send-out sequence.

## Controls

Use the normal directional controls and A/B inputs, including controller or the host's virtual buttons. Choose **Fight** or **Pokemon / Switch** for the first active Pokemon, then the second. A normal single-target move gets a target-selection page identifying ALLY/FOE and LEFT/RIGHT. Spread moves resolve their target set automatically. B backs out; at the second Pokemon's command page it lets you revise the first command. A advances presentation messages.

Four HP/status panels show the active positions. The current command owner and selected target are highlighted. Duplicate species remain distinct battlers. Forced replacement selection excludes the other active Pokemon, Eggs, fainted Pokemon and reserved bench choices.

Mouse/touch pointing directly at these new panels is not implemented. Use the normal directional/A/B controls.

## Implemented

The new controller runs one four-position action queue, with move priority, effective speed and one-time tie ordering. It does not run two singles battles. Native Gen I/II move kernels supply damage and many effect/status calculations; the doubles adapter supplies per-battler state, team/field state, target iteration, one-PP spread execution, switching, replacement and outcome handling. Its simple enemy AI currently chooses randomly among legal supported moves/targets; it is not Colosseum's AI.

CBE and UI communicate through `exports.doubles` / `exports.doublesUI`, version 1. Commands carry battle, turn, selection-ticket and battler identities, preventing stale input and old actions from executing for a replacement. The UI never applies damage or independently advances turns.

The presenter manages four independent actor handles using CBE's existing shared assets, transfers resident opening actors where possible, stages at most one additional acquisition per update, routes attacks/reactions by battler identity and uses wider battle framing. This does not guarantee hitch-free uncached model loading or final arena-specific camera quality.

After the encounter, experience and the final result are handed back to the native battle screens, preserving their reward and completion callbacks. The test deliberately does not replace overworld trainer scripts.

## Important limits

**Fight and Switch only.** Bag/item commands, trainer item AI and run commands are not implemented in doubles Test 1. Singles retains its existing commands.

**Experience is deferred to the end of the encounter.** In-battle level-ups and learning therefore do not follow their usual per-KO timing; this can affect battle balance and the treatment of participants that faint later. Native XP/learning/result screens resume during the final handoff.

**Not full Colosseum mechanics.** This uses a doubles scheduler over native Gen I/II damage, status, species and item data. It is not a complete Gen III rules/ability/stat conversion. Multi-target rules, simultaneous outcomes, special held-item behavior and custom move overrides need further parity auditing. Basic Quick Claw priority and the participating Amulet Coin latch are included, but full held-item parity is not claimed.

**Source MoveFX is not doubles-ready.** Battler attack/hit/faint animations are routed independently, but full Waza multi-target effects, source move audio cues, target-aware attack-camera choreography, disappearing/charge-move presentation and the authored dual introduction remain unfinished. The normal arena/music/import pipeline is retained; do not judge final source fidelity from this test.

**Unsupported complex moves are disabled, not silently turned into normal hits.** Test 1 disables Bide, Counter, Mirror Coat, Mirror Move, Metronome, Mimic, Sleep Talk, Future Sight, Baton Pass, Roar, Whirlwind, Teleport, Transform, Attract, Encore, Disable, Lock-On, Mind Reader, Pursuit, Beat Up, Destiny Bond, Mean Look, Spider Web, Nightmare, Psych Up, Sketch and Spikes. Gen I also disables Bind, Wrap, Fire Spin and Clamp, plus native special-flow effects that cannot safely use the current adapter. Struggle is offered when no supported legal move remains, including when all available moves are disabled by this experimental coverage limit.

**In-battle checkpoints are unsupported.** The custom phase intentionally does not masquerade as the native single-battle checkpoint phase. Do not save or restore a battle state through third-party tooling during doubles.

**Fallbacks are limited.** An absent/incompatible/disabled paired HUD declines conversion before play; CBE diagnostics expose `doubles.lastSkip`. With Colosseum Models OFF, the test has a basic native-resolved four-sprite path, not integration with every external 3D or animated-art provider. Full other-mod compatibility is not yet validated.

If an exception is caught during the custom turn/update path, the HUD offers **B: restore the encounter as a single battle**. This restores the captured starting party records; it is an experimental recovery mechanism, not a replacement for a save backup. It is unavailable once native reward handoff starts.

## Validation performed

- **106 assertions passed** against the supplied Gen1Recomp source using native Gen I and Gen II battle code and ROM-free fixtures.
- Three- and six-Pokemon trainer wins, both allies acting, one usable ally, exact eligibility exclusions, stale-command rejection, cancel/revise and unique switches.
- Spread damage reaches multiple targets while PP is charged once; Surf excludes the partner, Earthquake selects all other active positions, and Selfdestruct reaches its targets before removing the user.
- Sleep gates, forced replacements, old battler-token invalidation, zero-PP Struggle, explicit unsupported moves, detached UI snapshots and a native loss handoff.
- Native XP/prize handoff and actual native completion callbacks for both generations; Gen II battle volatiles are cleared before completion.
- UI command submission and draw calls at 1920x1080, 1000x700, 640x360 and 360x640 with stub graphics.
- Four-actor routing, resident handle transfer, one-acquisition-per-update scheduling, separate anchors and release lifecycle with actor mocks.
- Full UI entry loaded through the native Loader with its doubles export present (headless Gen I).
- Retained source-audio cache contract, hard-cache queue, Relic fidelity and Deep Colosseum regression checks passed.

**Not performed:** a live LÖVE/GPU/ROM-backed battle with four source models; visual screenshot inspection; Android/Windows device runs; frame-time or memory benchmarking; exhaustive move/held-item/mod compatibility or trainer-script/evolution scenarios. The native fixtures and renderer mocks cannot prove these. These builds are for that next testing stage, not a release-ready parity claim.

## Suggested first encounter

Use a copied save, a trainer with three Pokemon, and two healthy player Pokemon with simple attacks. Check selecting both actions, choosing either opposing position, switching one side without losing the arena, faint/replacement, and returning to the map with the expected party state and trainer result. Then repeat with a spread move and in the other generation. Finally set doubles OFF and compare an ordinary single battle.

To leave the experiment, finish the current encounter, disable doubles for subsequent battles or reinstall the stable pair. Do not switch mod versions while resuming a custom doubles checkpoint.
