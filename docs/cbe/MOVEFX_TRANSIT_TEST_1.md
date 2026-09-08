# CBE 1.10.0-movefx-transit-test.1

## Install and baseline

This is a CBE-only update built directly on `ColosseumBattleEnvironments-1.10.0-doubles-stability-test.2.zip`. Keep the existing `Colosseum-Inspired-UI-Overhaul-2.4.0-doubles-test.4` installed. No new UI package is required.

Replace the existing CBE mod with this ZIP through the launcher. Keep only one CBE version enabled. Start from a backed-up save outside battle; do not resume an in-battle checkpoint from another test version.

Keep the user-provided Colosseum import available. MoveFX extractor revision advances from 30 to 33, so allow the MoveFX-specific cache refresh to finish. Do not wipe all caches. Global, arena, Pokémon, trainer and audio extractor revisions are not deliberately advanced by this patch. Source-generated effect-model pages and linked-part sidecars are rebuilt locally; they are not bundled in this download.

The baseline's doubles eligibility, independent commands, Bag/item flow, target identities, arena selector, eleven arenas including Cipher Lab Underground, boss intro, model cache work and UI bridge are retained. Doubles still applies only to eligible trainers with three or more party members when its option is enabled. This remains an experimental build.

## Main target: the missing middle of an attack

The user's observation distinguished the attacker animation and receiving effect from the absent stream, projectile or wave between them. This patch addresses concrete failures in that shared travel layer, rather than adding a generic line between the two Pokémon.

### Animated effect bodies were sent the wrong shader

The previous shader lookup used `morph and shaderMorph or shaderStatic`. When the static shader was warm but the first animated shader was cold, Lua selected the static shader. The subsequent animated-weight upload failed because that shader has no `w0` uniform. That could leave particles visible while the actual animated beam/wave model failed to draw.

Static and animated shader selection is now explicit. The regression test exercises both cold and warm paths, and the actual LÖVE renderer successfully draws animated source effect models. A retained pre-fix render log records the uniform failure.

### Particle motion was incorrectly erased

The particle VM now honors the source flags enabling gravity and friction. A stored friction value of zero must not stop a particle when friction is disabled. This affected source programs including secondary Flamethrower generators. The A2/A3 commands now update the corresponding flags as well as their values.

Emission stopping and particle death are separate. Living particles and child generators drain after the emitting chapter ends instead of being deleted at a fixed short boundary. A 30-second particle watchdog and 32-second doubles chapter watchdog remain explicit diagnostic fault recovery, not normal animation durations.

Frame partitioning and entry-local timing are tested. Timed particles are not advanced twice by both a global update and their doubles entry scheduler. These are timing-consistency repairs, not proof that every retail animation-rate variant has been reconstructed.

### Source model decoding and attachments

HSD relocated pointers with data offset zero are now distinguished from unrelocated NULL pointers. Duplicate GX vertex descriptors no longer consume the same attribute twice and corrupt the display-list stride. Incomplete triangles are not exported as stray rows. A semantic Waza effect model can contain as few as three vertices without relaxing the ordinary Pokémon/arena mesh threshold.

The corrected Surf wave decodes to 3,276 vertices, instead of the malformed four-row result observed before the repair. Its authored animation starts at source frame zero rather than the bind pose. One clip-wide bound prevents collapsed first poses or changing animation pages from continually rescaling an effect.

Particles explicitly linked to an effect model now use that model's authored animated joint matrices. Surf's foam follows the wave, not the Pokémon's body-slot map. The binding requires the exact sequence instance, chapter, model identity and part index. Missing links are reported instead of borrowing an unrelated actor.

Each particle freezes its birth transform, so previously emitted foam does not slide with the moving emitter. Child particles and generators inherit that transform. Only referenced model parts are cached. Mist and Haze use explicit skeleton-only source carriers; these are accepted only through semantic roots with joints and no polygon objects, not by treating failed geometry as an invisible success.

Surf's primary wave and sea share a battlefield-space transform instead of being reduced to the attacker's body height. In doubles, the attack-side field mapping uses the target-group centroid. Receiving chapters remain separate; the target does not receive a second duplicated field wave.

### Additional sweep repairs

Scalar effect-intensity keys are no longer misread as RGBA tables. That error could abort drawing on moves such as Mega Punch. True color curves still interpolate normally. Two source projection paths now preserve both return coordinates instead of losing Y through a Lua conditional expression.

Root selection uses the exact source phase, bank and script selector. Child-program discovery parses instruction boundaries instead of treating bytes inside floating-point operands as child opcodes.

Audio readiness uses the selected source chapters rather than requiring unused variant sound banks. Actual selected sounds and legacy unphased records are preserved. No new audio synthesis or cross-platform audio parity claim is made.

Doubles now queues receiving presentation for successful non-damaging status/stat effects without inventing HP damage. Misses, charging, self-targeting and replaced battler identities are covered by added native-kernel fixtures. Damage, PP and turn mechanics remain under the native adapters/controller.

## Validation performed

- All 251 Gen I/II move IDs resolve to their actual GC6E01 source animation/WZX data; none are missing from the source index.
- The source parser/artifact check reports 240 of 251 moves with all parsed entries supported, up from 232 on the baseline source rebuild. This internal availability classification is NOT a visual or 1:1 parity score.
- All 941 source particle entries, including the enumerated variant chapters, execute in the particle audit without a recorded opcode fault, non-finite coordinate or watchdog truncation.
- The actual LÖVE all-move rendering harness attempts both default attack and damage roles for every move: 502 requests, 447 existing role tracks, 5,922 sampled draw passes, zero recorded renderer/attachment/VM errors and no pending sequence at the end of those runs. The 55 absent roles are expected omissions in the selected chapters, not successful rendered tracks. Partial source sequences are deliberately allowed, matching the doubles presentation path; this test does not erase the unsupported entries listed below.
- Nine focused moves are rendered from both attack directions at six sample times, producing 108 real renderer captures: Flamethrower, Surf, Hydro Pump, Ice Beam, Blizzard, Hyper Beam, BubbleBeam, Water Gun and Thunderbolt. These use source assets and the real CBE effect renderer with diagnostic anchors and a floor grid, not live Pokémon, arena or UI gameplay. Representative frames were inspected; this is not a frame-by-frame retail comparison.
- 47 CBE root regression suites pass, including 100 new transit assertions. These include many headless/static fixtures and must not be interpreted as 47 live gameplay runs.
- Native Gen I/II doubles regression: 1,013 assertions plus the retained 345-case effect sweep. Presentation: 374 assertions, 382 including its retained item-UI checks. UI item compatibility: 116 assertions. Graphics in those suites are stubbed.
- Final archive integrity, launcher-root files and LuaJIT compilation are recorded in the accompanying validation report. The code-only handoff includes the baseline diff and reproducible test sources.

The graphics runs use Linux software OpenGL with LÖVE 11.5. Sound scheduling is silent in the renderer harness. No Windows/Android physical-device run, live four-model battle, performance benchmark, all-species emitter comparison or complete audiovisual A/B against retail Colosseum was performed.

## Remaining source presentation gaps

The following eleven moves still have one or more explicitly unsupported parsed entries or variants: Fly (19), Tail Whip (39), Surf (57), Growth (74), Agility (97), Double Team (104), Minimize (107), Splash (150), Sandstorm (201), Encore (227), Hidden Power (237). The coverage JSON lists the exact chapter, entry and reason. Surf's outstanding entry is an alternate `sp1` model entry; its primary animated wave and foam are now rendered. An available main chapter does not certify every species-specific or alternate chapter.

Complete TEV/material reconstruction, all source controller behaviors, all source attachment/size selectors, exact native animation-clock variants, beam/stream reach and thickness across all Pokémon sizes, and every camera/audio handoff still need retail comparison. The fixture views still show material/brightness differences such as over-bright flame cores and visible card edges; they are evidence that the missing layer renders, not final art approval. No generic replacement is claimed to be original source behavior.

The baseline doubles gameplay exclusions are unchanged: Bide, Counter, Mirror Coat, Mirror Move, Metronome, Mimic, Sleep Talk, Future Sight, Baton Pass, Roar, Whirlwind, Teleport, Transform, Attract, Pursuit, Beat Up, Destiny Bond, Nightmare and Sketch, plus the Gen I binding family Bind/Wrap/Fire Spin/Clamp. Source FX availability for a move does not imply that its multi-actor battle mechanics are implemented.

Original audience ambience remains outside this patch. Arena fidelity, UI features and existing cache preservation are retained rather than represented as newly completed here.

## First live acceptance check

After the MoveFX refresh, use Flamethrower and Surf in both directions. Watch the interval after the attacker starts and before the receiving effect: the stream/wave body should remain visible during that interval, with foam traveling with Surf rather than collecting on the Pokémon. Check selected targets and spread targets in doubles, misses, two-turn moves, recoil, status-only moves and hurt-to-faint transitions. Repeat at normal and accelerated battle speed, then finish the encounter and verify return to the map.

Check Hydro Pump, Ice Beam, Hyper Beam, Blizzard, Water Gun and BubbleBeam next, including a small-to-large Pokémon matchup. Do not judge initial cache-building pauses as warm playback performance. Device footage remains necessary for final presentation tuning.

## Source and redistribution boundary

Extraction and render checks used the user's GC6E01 source image. HSD archive, geometry and particle behavior were checked against the primary SysDolphin decompilation in `doldecomp/melee`; Waza attachment dispatch was compared with `dougchansan/pkmn-colosseum/src/game/wazaSequenceEntry.c` and relevant native executable code. The latter decompilation contains partial routines and was not treated as complete retail proof.

The installable ZIP and code-only handoff contain no source image, extracted effect/model/texture/audio cache, engine ROM, executable disassembly or font files. Optional screenshots are runtime diagnostic captures, not replacement game assets.
