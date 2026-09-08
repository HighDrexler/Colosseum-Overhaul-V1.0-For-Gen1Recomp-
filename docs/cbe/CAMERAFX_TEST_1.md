CameraFX Test 1 — 1.10.0-camerafx-test.1

Install
Replace the previous CBE ZIP with this ZIP; do not load both versions. Keep your existing imported source/cache. This runtime update does not require rebuilding that cache. Continue using ColosseumUIOverhaul-2.4.0-doubles-items-test.1 (or newer compatible UI). No UI replacement or save migration is required. Automatic battle flow, doubles item actions, trainer work, grouped throws and source sound/visibility fixes remain included.

Camera
Doubles moves open on the actual attacking slot, then smoothly widen to the attacker/target lane. Spread moves frame the full target set immediately. Impact closeups frame the receiving slot while retaining the arena safety bounds. The existing arena viewing side is preserved. This is a presentation refinement toward the reference, not a claim that retail camera curves have been decoded.

FREE LOOK CAMERA defaults ON in CBE settings. During command/move/target selection, start a right-mouse drag in the central arena area to orbit. Middle-mouse drag pans; Shift + right-mouse vertical drag zooms. On touchscreens, drag with one finger to orbit or pinch with two to zoom. Gestures must start within the middle 44% of screen width and between 16% and 60% of screen height, avoiding the surrounding UI. HOME resets. The pose remains while choosing commands, then resets automatically when battle action begins; boss intros always own their camera. Bag/party overlays block free-look. This is bounded orbit/pan/zoom, not unrestricted collision-aware flight. The old unrestricted F8/manual-camera path is replaced.

Move alignment
Directed source banks now use the live launch attachment and actual receiving slot, including their height difference. Particle trajectories keep a stable direction and distance scale after emission. Model-bound Hydro Pump particle roots inherit the preceding model's mouth/cannon attachment. Psychic's attack field is placed on its recipient.

Directed mappings cover Flamethrower, Water Gun, Hydro Pump, Ice Beam, Psybeam, Bubblebeam, Aurora Beam, Hyper Beam, Dragon Rage, Thunderbolt, Octazooka and Dragonbreath. Beam morph pages retain authored extension instead of being resized to each changing frame's bounds. Ice Beam and Aurora Beam model reach uses measured final source-page extents. Other directed banks use a 100-source-unit lane adaptation. These mappings are not a complete decoding of retail attachment/controller semantics, and are not a guarantee of exact parity for every species or move. Damage chapters remain bound to their individual recipients; this build does not add independent simultaneous attack emitters for every target of a spread move.

Cries
Each new doubles release plays the species' standard engine cry once, at the start of Pokemon materialization, including all four opening releases and later replacements. Missing source ball-effect cache does not suppress the cry. Already-presented native releases retain their native cry path. Source Colosseum cry archives were found, but their species lookup has not been verified; this build does not substitute unverified high-quality cry samples.

Validation
All Lua files parse. 31 focused suites pass, including free-look mouse/touch handoff, UI/settings boundaries, one-shot cry timing and 80 directed pairs across ten arenas with unequal attachment heights. Existing presentation/UI tests pass 382 assertions; native Gen I/II integration passes 194 assertions.
A real LOVE GPU test ran 5,464 frames using ten moves extracted from the local source ISO, cold cache lookup, both attacking sides and attack/damage chapters. All ten produced visible framebuffer output; 23 source sound files decoded, 56 playback starts occurred, no native move-audio fallback was required and no Waza errors occurred. Moves: Tackle, Flamethrower, Water Gun, Hydro Pump, Surf, Ice Beam, Aurora Beam, Thunderbolt, Psychic, Swords Dance. GPU fixtures use a fixed camera and simple actor attachments; camera geometry is checked separately. This is not a live playthrough of the complete installed mod stack. Source rendering/colour fidelity and wider move coverage still need further work.

Useful test cases
Opening doubles: four cries, one per appearance. Command menu: orbit/pinch, then select a move and confirm automatic camera takeover. Cross-lane Ice Beam/Hydro Pump/Aurora Beam: effect leaves the user and aims at the selected opponent. Surf: wide composition includes both opponents and each impact frames the correct recipient. Test both sides and a small-versus-tall Pokemon pairing.
