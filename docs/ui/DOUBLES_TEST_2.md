# CBE + Colosseum UI — Doubles Test 2

**Experimental pair. Back up your save and retain your Test 1 or stable ZIPs. Do not change versions while resuming an in-battle checkpoint.**

## Packages

- CBE: `1.10.0-doubles-test.2`
- Colosseum UI: `2.4.0-doubles-test.2`

Both are built from the paired Test 1 packages. The separate MoveFX actor-clock/import-fix experiment is not merged. This is a presentation/model-repair update to the existing doubles controller, not a new set of battle calculations.

## Install and cache migration

Install both ZIPs in the launcher over their respective existing mods; do not enable duplicate copies. Keep your existing Colosseum import. Keep **Colosseum Battle UI ON**, **Colosseum Arenas ON**, and **Colosseum Models ON** for the intended presentation test. **DOUBLE BATTLES (TEST)** keeps its existing setting and three-or-more-opposing-Pokémon threshold. Trainers with exactly two Pokémon and wild encounters remain singles; the encounter format remains locked after entry.

**No full cache wipe or new ROM import is needed.** Pokémon extraction advances from revision 36 to **37**. Old species caches are no longer accepted as repaired caches: they rebuild through the normal extraction/prewarm paths when requested. First access to a stale species can therefore take longer. **Hard Cache Save** now uses completion marker **v4**, so an old v3 READY marker cannot conceal stale animation caches. Run Hard Cache Save and let it complete before the battle test to prepare the party and stored-model caches. Audio, arena, trainer, capture and MoveFX extractor identities remain unchanged.

## Compact Colosseum HUD

The doubles renderer uses the UI mod's existing Colosseum portrait atlas, portrait frames, beveled status plates, console panels and red selector. Both allies have compact stacked plates at the upper left; both opponents have compact stacked plates at the upper right. The central arena is left open. The command/move/target/replacement console uses a shallow two-column bottom dock; portrait layouts reserve room above virtual controls.

The command screen now visually has **FIGHT / POKéMON / BAG / RUN**. Fight and Pokémon/Switch remain functional. Bag is visibly unavailable and selecting it explains the test limitation. Run explains the trainer-battle restriction; neither button submits an unsupported gameplay action. The move grid shows type and PP. Normal directional/A/B controls remain the input path; direct mouse/touch selection of these new controls is not implemented.

The bars are **not permanent**:

| Moment | Health panels |
|---|---|
| Command, move or target selection | Four-position overview, excluding empty positions |
| Send-out, damage, healing, status or faint presentation | Only that event's Pokémon |
| Forced replacement selection | Player side only |
| Move announcement, recall, quiet queue gap or boss cinematic | No four-panel overlay |

The bridge provides a detached presentation record containing the event, position, battler identity and displayed HP. A queued recall continues to identify the outgoing Pokémon even when the game-side position already contains the replacement. Damage/healing interpolates between the previous and new visible HP. Blank event gaps no longer repeat stale text or a permanent debug console.

## Camera and optional Boss Intro

Doubles send-out and reaction shots frame the actual position. Move shots include the attacker and affected target positions; spread moves do not arbitrarily select one opponent for framing. The normal four-position overview remains the command-selection shot. These are new compatible camera paths, **not a claim that the original game's complete authored camera scripts have been ported**.

In CBE's Battle menu, **BOSS INTRO** is a separate toggle, **OFF by default**. It does not depend on doubles: eligible single battles can use it too. Exact trainer-class checks include Gym Leaders, Elite Four, Champions, rivals, Giovanni and Red. Exact named organization-leader classes are also recognized for compatible custom data. Custom encounters can explicitly supply `cbeBossIntro=true` or a recognized `cbeBossCategory`; `cbeBossIntro=false` excludes them. Ordinary trainers and grunts are not promoted based on party size, level, music or arena. Wild, link, tutorial, contest and Battle Tower encounters are excluded.

A qualifying opening plays the existing canonical GC6E01 `tool_battle1` intro cache, establishes the arena and pans to the opposing and player trainers. The native opening queue is held and then resumes; rewards, trainer scripts and encounter calculations are not replaced. The cinematic uses elapsed wall time rather than 4× game ticks. A/B/Start can skip after the initial brief guard, with a short volume fade and input-release latch. The intro is latched once per encounter, respects music volume, hides the command/HP HUD and resumes the native soundtrack. When the selected battle song uses that same intro, the handoff uses its registered loop body rather than playing the horn twice. A missing/invalid canonical cue declines the optional intro and leaves the normal battle opening available; diagnostics report the reason.

## Pokémon idle repairs

The shared HSD animation sampler previously discarded keys before the requested frame origin. Those keys establish the current pose; deleting them produced zero-scale limbs or missing rotations. The sampler now retains that pre-roll, correctly consumes KEY waits, preserves delayed bind channels and respects legitimate authored zero scales. This repairs source pose data rather than splicing in static body parts.

The PKX metadata's idle slot now selects the resident idle, including **clip zero**, which is a real idle for many Pokémon. The resident animation samples the full authored cycle and carries the source idle duration. The lazy native action bank uses the same corrected sampler.

Measured changes at the source idle start:

- **Blastoise:** 15 incorrectly collapsed scale joints restored.
- **Articuno:** seven joint rotations recover their prior-key context, restoring the head/neck and related pose.
- **Diglett, Sunflora and Entei:** respectively one, six and eight collapsed scale joints restored.
- **Rapidash and Weezing:** one affected rotation joint each restored.

Diglett/Dugtrio's existing burrow-aware ground placement remains. The shared repair serves CBE battle actors and information-menu model caches; it is not restricted to doubles.

## Validation completed

- **106** existing assertions pass against actual Gen I/II engine battle kernels and completion/reward adapters using ROM-free fixtures.
- **376** new assertions pass for FOBJ sampling, boss eligibility, cue/queue lifecycle, skip/time independence, duplicate-horn avoidance, detached event identities, HP visibility, six viewport layouts and position-specific cameras.
- **26** retained regression suites pass. Three historical tests had obsolete build/revision literals; those expectations were advanced to Test 2/revision 37/v4 without removing their arena/action preservation assertions.
- **95** Lua files compile in LÖVE 11.5's LuaJIT VM. The complete UI entry loads through the native Gen I mod Loader with no loader errors.
- All **251** source Pokémon decode and have finite joint values at their PKX-authored idle start. This is a sampled source-integrity audit, not an exhaustive animation certification.
- Blastoise, Articuno and Diglett complete real source cache extraction with **12/12** resident idle frames and native action banks (16, 13 and 13 respectively). Diglett's authored idle clip zero remains animated.
- LÖVE renders were inspected: ten actual shared-HUD-helper scenarios across desktop/landscape/portrait sizes, and fourteen textured source-model before/after captures (seven affected species at frames 0 and 24). HUD renders use fixture battle data; model captures use a standalone source-model harness, not a complete live arena battle.

## Still experimental

No live ROM-backed four-model battle with both packaged mods, Windows/Android device run, camera clipping sweep across all arenas, audio-device playback parity check, or frame-time benchmark was completed for Test 2. The boss cinematic and new action cameras particularly need that in-game verification. This is not a finished port of the complete dual-trainer throw/send-out choreography: the native opening still precedes the custom doubles boundary.

Test 1's gameplay limitations remain: Bag/trainer item commands and sophisticated doubles AI are unfinished; experience is handed back at encounter completion rather than each knockout; the documented complex-move exclusions remain; full multi-target Waza/source MoveFX and in-battle checkpoints are not implemented. This build does not claim complete Colosseum/Gen III rules parity or compatibility with every external model provider.

## First test

Use a copied save with Articuno and Blastoise. Let the revised model cache finish, inspect them in a menu and battle, then test a qualifying boss with Boss Intro ON followed by an ordinary trainer with it still ON. Check that only the boss receives the horn/pans, both allied commands work, relevant bars appear during send-outs/hits, replacements keep the correct portrait/HP, and the battle returns to the map normally. Repeat the ordinary encounter with Boss Intro OFF and verify that the existing doubles/singles selection rules are unchanged.
