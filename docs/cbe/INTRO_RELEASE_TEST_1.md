CBE 1.10.0-intro-release-test.1

Install
Replace the previous CBE ZIP with this build. Keep your existing Colosseum import and generated caches; do not delete/rebuild everything. Keep the paired doubles UI installed. This continues the 1.10.0-doubles-test.2 baseline and retains the earlier trainer overhaul and MoveFX Sweep Test 1 changes.

What changed
- Doubles takes over before the native singles sendouts: enemy throws once, enemy Pokemon 1 releases, enemy Pokemon 2 releases, player throws once, then both player Pokemon release separately. Each pair shares its announcement. Later replacement sendouts still have their own throw.
- Trainer throws use the animated source hand attachment and a latched release origin. The first ball targets that Pokemon's actual doubles position. The second opening Pokemon does not replay the trainer performance or take another trainer camera cut.
- Each Pokemon stays hidden until its ball-opening timeline reaches the reveal. Retail ball_open timing resolves the opening at frame 0, energy at frame 30 and owner reveal at frame 50. A white materialization phase fades into the Pokemon's materials, followed by a held reveal.
- Twelve source ball-opening banks are supported: Poke, Great, Ultra, Master, Safari, Net, Dive, Nest, Repeat, Timer, Luxury and Premier. A recognized saved ball field selects the bank; absent/unknown metadata defaults to Poke Ball. Gen I/II do not supply every later-generation ball identity.
- Source ball models, GPT1 particles and GameSounds 139/1163 are used for releases. Effects have independent doubles-slot positions, so they cannot hide or relocate the already-released partner through a shared side controller.
- Reveal cameras focus the correct slot, use a lower full-body composition, and retain the arena's established viewing side. The second throw no longer rotates the camera behind the lava stadium shell. Text advancement cannot skip a pending reveal. Animation presentation uses capped real-time steps.
- Boss Intro ON uses GC6E01 fanfare00_song (setup 12), identified against the retail recording by spectral comparison. It then releases the native music pause so the selected battle theme continues, including its own intro. Boss Intro OFF does not play this cue. No battle theme is forcibly changed to Link1.
- Fixed a shared particle trail rendering error: Lua's logical expression discarded the projected Y coordinate. Source ball trails exposed the fault during GPU verification; the fix also applies to move trails.

Cache/performance
Only missing ball-release banks, the two opening sound effects and the boss cue are added. Existing move, trainer, arena and soundtrack caches remain reusable. Source-release cache checks passed with no ISO reopening or extraction on reuse. Previous performance improvements remain. No live FPS or total loading-time improvement is claimed.

Validation
- All Lua files parse; 26 top-level focused suites pass, including throw origin/destination, once-per-pair behavior, source release timing, hidden-until-reveal, held advancement, camera viewing side, boss music handoff and prior trainer/MoveFX regressions.
- 374 presentation assertions and 119 native Gen I/II integration assertions pass. Early opening takeover, enemy-pair/player-pair order and restoration of the original native intro on test abort are covered. These native integration tests use stubbed graphics.
- Extracted all 12 ball_open banks from the user's GC6E01 ISO. Ran each for 150 frames with the real LOVE renderer and source particle VM (1,800 GPU frames total), with no reported render faults or invalid particle positions. Pokemon shader compiles.
- Actual boss fanfare and both release GameSounds render and pass cache read-back/reuse checks. The cue comparison is spectral evidence, not a claim of an auditory review.

Limits / next visual comparison
This is a test build, not verified 1:1 retail parity. No live host battle with the user's complete mod combination was recorded in this pass. The reveal camera composition and Pokemon grow/materialization transition are presentation approximations; exact retail camera tracks and species-specific entrance performances remain incomplete. One ball_open type-2 resource does not decode as renderable HSD geometry; the available ball model and native particles render, but the complete retail shell/controller animation is not proven. Old trainer caches lacking a usable hand attachment retain a fallback anchor. These grouped source releases apply to experimental doubles; the existing singles sendout path is retained. Full move effects in doubles remain a separate integration task.

Test first
Use the same boss double battle from your recordings, with Boss Intro ON, then OFF. Expect exactly two visible trainer throws total and four separate Pokemon releases, enemy pair first. Check palm attachment at wind-up/release, each Pokemon's full-body framing, sound handoff, and that the second reveal stays outside the stadium walls. Repeat with higher battle speed and button advancement. Test a later replacement and a singles battle for regressions.

This ZIP includes code, tests and existing bundled mod assets. New retail release/audio assets are generated locally from your import. The ISO is not included. This document supersedes the older MoveFX notes' statement that doubles code is unchanged.
