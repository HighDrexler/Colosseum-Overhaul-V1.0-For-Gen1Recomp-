CBE 1.10.0-doubles-movefx-test.1

Install
Replace the previous CBE ZIP. Keep the existing Colosseum import and generated caches, plus the paired doubles UI. No full source-cache rebuild is required by this update. This continues the user's 1.10.0-doubles-test.2 baseline and retains the previous trainer, boss-intro music, grouped opening and MoveFX work.

Fixed: balls, Pokemon releases and cameras disagreeing
Arena.player/enemy are actor-space positions, divided by figureScale. The previous doubles presenter mistakenly passed these larger coordinates directly to trainers and cameras, which use arena/stage space. On Mt. Battle Summit (.34 scale), a 21-unit arena position became a roughly 62-unit throw/camera target outside the platform. Pokemon meshes themselves still rendered through the actor scale, so the camera and ball did not meet them.

The presenter now distinguishes actor-space anchors from arena-space anchors. Trainer targets, source ball models and reveal cameras use the arena position; Pokemon meshes and sprite projection use the actor position. The release particles pass through the actor projector exactly once. All four positions are checked against all ten current map definitions, including angled/asymmetric battler placements. The one-throw-per-trainer, enemy-pair-then-player-pair order remains.

Fixed: doubles moves had no MoveFX or source sounds
The doubles native kernel intentionally bypasses the original singles animation queue. Until now, the presenter called only actor attack/hit methods and never started the source Waza model/particle/audio timelines. Doubles now starts these chapters from the actual Pokemon attack/reaction start and binds them to the exact acting and struck slots. Damage events retain their source move and attacking slot, while residual damage does not inherit an unrelated attack effect. Spread moves have one attack chapter followed by each affected slot's impact chapter.

Move and damage events hold their presentation until the body performance and source chapter finish, preventing a fast button press from deleting the effect immediately. Only the doubles presenter advances its source timeline, avoiding double-speed updates through the singles director. Slot bindings are restored even if a renderer fails. Source visibility controls apply to the participating Pokemon and are cleared between chapters.

Source sound playback is used when its WAVs actually load. Otherwise Gen I uses the native move sound definition; Gen II runs the native animation's timed sound/cry commands. This restores an audible fallback instead of leaving moves silent. The fallback does not run native turn logic or spend PP again.

Incomplete source roles in doubles can play their executable entries while retaining unresolved timing/entry diagnostics. A missing companion model no longer suppresses every particle and sound in that doubles move. Singles retains its strict all-or-native ownership policy. Missing cached moves still receive their Pokemon performance and native audio; no ISO extraction is performed on the move frame.

Other shared MoveFX fixes
- Particle projection no longer applies figureScale twice.
- Source effect models now use the actor VP that matches their attachment coordinates.
- Source move-camera coordinates convert to arena space before camera guards.
- Arena postprocessing now calls the source filter/blur/distortion function with the correct argument order.
- Doubles reveal and move cameras continue to focus actual slots from the arena's established viewing side.

Validation
- All Lua files parse. 28 top-level focused suites pass, including source timing/partial playback, exact source/target identities, native audio fallback, queue holds and restoration of shared state after errors.
- Coordinate checks cover all ten current maps and all four doubles positions, including the forward direction from each trainer, mesh/particle projection and reveal focus. These are transform checks, not a live collision/render walkthrough of every map.
- 374 presentation assertions and 121 native Gen I/II integration assertions pass, including the real Gen II sound-script runner preserving two ordered fallback sounds. Native battle integration tests use stubbed graphics.
- Real source extraction, particle VM, model shaders and off-screen GPU rendering were exercised for Tackle, Flamethrower, Water Gun, Surf, Ice Beam, Thunderbolt and Swords Dance, from both attacking sides and through attack/impact chapters: 3,502 frames, 640 active effect-model frames and 40 source sound starts. All seven moves produced nonzero rendered framebuffer pixels. Fifteen source sound WAVs rendered and decoded successfully. Audio lifetime was simulated at 60 Hz for this fast test; this is not an auditory review.
- This GPU check uses attachment fixtures rather than a complete live battle with the user's Pokemon models and other mods. It verifies that real effects reach the renderer and source sounds reach playback scheduling, not exact retail visual parity.

Remaining limits
Retail-perfect cameras, every particle/controller interpretation and every move/species appearance are not complete. Some source entries remain undecoded; partial doubles playback reports those omissions. Spread impacts are sequential rather than simultaneous. Existing unsupported doubles move mechanics remain unchanged. No complete in-game run with the user's full mod combination was recorded in this pass, and no measured FPS/loading-time improvement is claimed. Previous cache reuse and capped trainer clocks remain.

First in-game checks
Repeat the same Mt. Battle opening: both first balls should travel toward the fighting platform and meet the Pokemon release, followed by the second release on that side. Then use Flamethrower, Surf, Thunderbolt, a physical move and a status move from both sides. Check visible launch/impact effects, sound, hit reactions and return to command framing. Repeat at high battle speed and with fast text advancement. The map transform fix is shared across all arenas.

This note supersedes the previous test notes stating that doubles bypasses source MoveFX. The ZIP contains code/tests and existing bundled mod assets; imported retail assets remain generated locally.
