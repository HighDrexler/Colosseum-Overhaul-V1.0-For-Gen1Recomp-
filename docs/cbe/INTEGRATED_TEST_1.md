# CBE + Colosseum UI — integrated performance / doubles test 1

## Install the complete pair

**CBE 1.11.1-integrated-test.1** and **Colosseum UI 2.5.1-integrated-test.1** are complete launcher-ready mods, not an unfinished checkpoint or patches requiring an older install to be unpacked underneath them. Each ZIP has its own `main.lua` and `manifest.json` at its root. Replace both enabled versions; do not mix their contents or leave duplicate versions enabled.

Start from a backed-up save outside battle. In-battle checkpoints from other builds remain unsupported. Keep the imported Colosseum source and existing caches. **This build does not change source-extraction or packed-cache revisions and does not require another cache wipe or Hard Cache Save when the previous Turn Flow preparation is complete.** An independently absent/stale asset still needs its normal preparation. Coming directly from a much older build retains the earlier migrations, not a waiver of them.

Doubles remains optional and uses the existing eligibility rule: ordinary eligible trainers with at least three party members, not wild encounters or exactly-two-member trainers. Abilities remain optional, OFF by default; saved settings and explicit assignments from other mods are retained.

## Exact starting point and retained functionality

CBE is built directly from `ColosseumBattleEnvironments-1.11.0-abilities-turnflow-test.1.zip`, SHA-256 `1aeb25d0724a3536f2eaf3676fe99cfaf4581e87bbeab6315aa6f92af9d492cb`. UI is built from `Colosseum-Inspired-UI-Overhaul-2.5.0-abilities-compat-test.1.zip`, SHA-256 `08dddda67944261380ab3820fbb426e169ac6cdbb9b8927778beb4bd2659c2f5`. The earlier unfinished checkpoint contained no source patch to merge. The new camera/presentation work was implemented on these complete baselines.

No baseline member is removed. The accompanying validation report lists every changed, added and byte-preserved member. The ability catalogue, both generation-specific ability wrappers, native doubles adapter, source extractors, arena geometry/caches and UI art/audio assets are retained. Modified renderer/director/controller boundaries are tested rather than described as byte-identical.

Preserved native progression: a completed action's KOs enter native EXP, sharing, deferred level/stat commits and learning before the same committed turn resumes. Forced faint replacements wait until all committed actions and residual processing finish, on both sides. Entry-hazard replacements do not repeat residuals. Original party identities, queued move identities, exactly-once rewards, later-loss retention, post-battle evolution and Gen II protection against native singles combat re-entry remain. Deliberate switch actions keep their ordinary timing.

The paired UI remains a presentation client: it does not compute damage, abilities, PP or EXP. Bag/item targeting, PP-recipient moves, reservations, legal targets, original-index Party columns, EXP/type/status/ability labels and the older version-1 bridge remain. All eleven arenas, source imports/audio gating, Dig/Fly structural invisibility, boss intro and provider-selection contracts remain.

## Doubles camera and manual ownership

A dedicated four-battler director uses the actual acting/receiving positions and viewport aspect. It supplies command framing, launch, transit, impact, recall, faint, trainer-throw and send-out-reveal compositions instead of moving mostly along one fixed viewing axis. Spread attacks frame the participating target group. Camera smoothing advances once per presentation update, not once per render call; duplicate draws do not accelerate it. The last completed impact is held through zero-duration bookkeeping instead of jumping back to launch for one frame.

The arena's existing camera guard still applies. Cinematics OFF uses the neutral view; it does not force the new director. This is event-specific CBE cinematography, not a claim that all original retail camera scripts or arena occlusion cases have been reproduced.

Free Look now has priority over the doubles automatic camera and keeps its chosen pose through moves and switches. It resolves the real Gen II screen, not only the compatibility facade. Open **COLOSSEUM BATTLE settings** and enable **FREE LOOK**. Begin the gesture in the central arena region, away from the HUD/menu controls:

- Right-button drag: orbit. Shift + right-button drag: distance. Middle-button drag: pan.
- Touch drag: orbit. Two-finger pinch: distance.
- Home resets manual ownership and returns to the automatic view. Disabling Free Look or leaving battle clears it.

Bag, Party, native progression and other covering screens stop accepting camera gestures without throwing away the stored doubles pose. Normal UI selection is not consumed as a camera command. The existing legacy controls export is retained for compatibility; a new additive `freeLookControls` export describes these actual controls. The old F8/J/L shortcut listing is not presented as a newly working binding. Touch paths have controlled-input tests, not physical-handset verification.

## One connected attack / impact / HP presentation

The outgoing source effect and receiving effects now have independent live channels inside one move presentation. They can overlap without sharing mutable particle/model/controller state. Immutable caches and shaders are shared. Scoped state is restored after errors, and all channels are retired before the move unlocks.

At the impact boundary, the receiver's hurt animation, receiving Waza effect and detached displayed HP change start together. Receiving timing is rebased to the current impact instead of adding the receiver's pre-impact delay a second time. Native PKX body timing and damage calculations are not rewritten. For the identified traveling cores, actual leading-particle arrival is used; other moves retain their source timing, with explicit fail-open handling for absent/broken source assets.

The original queued target notifications remain for order/accounting, but become zero-duration display bookkeeping after that exact source event has already presented them. Matching requires the original event and battler token. Recoil, self-costs, healing, status-only effects and genuine later hits are not erased by a broad same-move or same-Pokémon deduplication rule. Native battle HP is not animated or delayed; only its detached presentation is.

This repairs the reproduced two-stage duplicate-looking hit flow. It is not a certification of every multi-hit, called-move, ability-trigger or retail frame/audio ordering edge case.

## Blizzard, Thunderbolt, particle materials and throws

Blizzard's identified attacking source-bank cores now use measured battlefield travel spans and the actual spread-target group, rather than scaling around only the attacker's body. Thunderbolt's identified main bolt and Pikachu variant now map their authored travel span to the real source-to-target lane. Existing Flamethrower, Water Gun, BubbleBeam and Octazooka mappings remain. Receiving, muzzle/aura and effect-model-linked particles are excluded from this lane stretch. Source programs, particle velocities and lifetimes remain intact. These are explicit placement adaptations, not a generic replacement projectile or evidence that all source size selectors are decoded.

A separate material defect was confirmed: the retained particle RGBA cache stores GX I4/I8 with opaque alpha even though those formats replicate intensity into alpha. The particle shader restores alpha from intensity **only for exact I4/I8 metadata**. IA4/IA8, RGBA8, CMPR and unknown formats retain their own alpha. Source Prim/Env color and alpha interpolation is retained. This is not generic black-keying and does not rewrite unrelated arena/Pokémon textures or require re-extraction. GPU pixel checks exercise both interpolation modes and both restored/untouched formats.

The player's send-out Poké Ball front now derives its yaw from the actual throw origin toward the field destination. The source prop's local +Z front and the fallback orientation use that direction. Capture throw/spin/shake behavior is not globally flipped. The source prop was rendered from both sides to check its front, and the direction math was tested; a complete live trainer-throw choreography/device sweep is not implied by those checks.

## Performance work and measured boundaries

The full legacy `snapshot()` stays available. The paired UI opts into an additive, capability-gated render snapshot which carries the four detached HUD records but builds hidden party/inventory/legal-move details only when the current UI page needs them. Replacement and item/party pages still receive their required identities and data. Old producers continue through the full version-1 path.

The controller still updates every frame. Idle UI input snapshots/dispatch occur on an input edge or command/phase change, not simply because another frame passed. A controlled 120-update workload measured **120 to 1** input snapshots and dispatches while retaining **all 120** simulation updates.

The six-on-six / four-move / twenty-item snapshot microbenchmark ran 2,000 snapshots per repetition, five repetitions, under the supplied LÖVE LuaJIT VM. The full baseline averaged **43,172.976 KiB** transient allocation per repetition; the narrowed command render averaged **9,766.530 KiB**, approximately **77.4% less allocation for that specific workload**. Bag render averaged 16,531.987 KiB. Full legacy snapshots retain their previous complete-data allocation profile. Measured median CPU times are in the validation report; they are not a promised whole-game FPS or handset result. GC was stopped only inside this measurement, not by production code.

Repeated text width/ink scans now use a bounded weak-font cache of up to 512 strings per font. Joint/attachment lookups are memoized only inside one scoped update/draw, including misses; the next frame still samples animation. Waza trace ribbons reuse geometrically sized stream buffers rather than constructing/releasing a GPU mesh every frame. The 1,000-frame ribbon check creates only four capacity-growth buffers and releases all four on completion. Identical repeated trainer-render errors log once until recovery rather than flooding the log each frame. No blanket texture-resolution reduction, forced per-frame collection or removal of arena depth testing is used.

## Executed checks

The final machine-readable report records exit codes, exact finished ZIP hashes, member preservation, Lua compilation and the rerun against freshly extracted finished packages. Do not treat historical test logs retained from earlier releases as new results.

- **60 CBE root suites**, including new 134-assertion camera, 79-assertion coherent-presentation, 29-assertion impact/ribbon, 26-assertion snapshot/input, and 22-assertion particle-format tests. Many checks are controlled or static, not live battles.
- **1,953 native Gen I/II assertions**, plus the retained 345-case effect sweep. The ability-enabled regression cases, per-KO progression, learning, replacement, loss and evolution paths remain covered. These use actual native kernels with graphics/sound stubs; catalogue fault-safety is not ability completeness.
- Retained presentation **374 assertions / 382 including item checks**; paired UI item **116**, ability UI **36**, new UI performance **14**, and older CBE Tests 1/2/3 bridge compatibility **511**.
- **157 Lua files** compile under the LÖVE 11.5-distributed LuaJIT VM. Final package root-entry, CRC and source-byte checks are separate gates.
- Actual full UI loads in each generation and renders **48 cases** across commands, moves, targets, Bag, party and PP-recipient screens at 1280×720, 640×360 and 360×640. Its CBE display data is explicitly synthetic. Warm runs add no texture memory or new text-metric misses in the sampled 120 draws per viewport. The existing Gen II Party icon-facade warning is retained in that fixture; it did not cause a draw failure.
- Actual source-derived arenas, four source Pokémon, director and effects renderer execute Blizzard and Thunderbolt travel/receiving cases, including reverse direction and Pikachu, plus Flamethrower in Orre, Surf in Realgam and Ice Beam in Relic. Final material checks use seven 720-update move cases. A separate nine-view lab check hides/restores all four actor identities. These use controlled events, silent audio and no complete native battle/UI controller in the image harness.
- Real GPU source-ball views, a 1,000-frame ribbon workload and **96 particle-shader pixel assertions** pass. All eleven arenas also rebuilt and reused their local packed sidecars; that source-cache check does not mean all eleven received a new every-camera gameplay sweep.

## Limits and remaining work

This is a broad integrated experimental test pair, not complete 1:1 Colosseum, all-move, all-ability or all-mod certification. The source asset inventory and failure-free renderer runs are not a retail audiovisual comparison. Some effect-model/card materials, opacity/brightness, source attachment/size selectors, attack durations and arena camera occlusion still need refinement. Source particle alpha recovery does not reconstruct all GX material/TEV stages.

The prior ability catalogue-only gaps remain: Cute Charm, Damp, Early Bird, Lightning Rod redirection, Oblivious, Run Away, Soundproof, Sticky Hold and Suction Cups. Pickup's post-battle finding is not implemented. Several implemented ability categories retain arithmetic, called/fixed-damage and contact/secondary ordering limitations documented by the abilities baseline.

The prior complex doubles exclusions remain: Bide, Counter, Mirror Coat, Mirror Move, Metronome, Mimic, Sleep Talk, Future Sight, Baton Pass, Roar, Whirlwind, Teleport, Transform, Attract, Pursuit, Beat Up, Destiny Bond, Nightmare and Sketch, plus Gen I Bind/Wrap/Fire Spin/Clamp. No such move is silently enabled by these presentation changes. Original audience-audio integration and remaining arena fidelity work are not claimed here.

No physical Windows/Android/GLES benchmark, full live ROM-backed battle with the complete styled UI, every external EXP/ability/model mod, all Pokémon emitter sizes, all cameras in all eleven arenas or frame-by-frame retail audiovisual pass was completed. The supplied native engine and controlled Linux software-OpenGL fixtures establish the stated boundaries, not a universal compatibility guarantee.

## First live acceptance route

Use both new ZIPs and the prepared source cache. Check manual camera during command selection and throughout attacks; open Bag/Party and confirm those screens do not move it; reset with Home. Check Blizzard in each direction with two targets, regular and Pikachu Thunderbolt, then Flamethrower/Surf. Watch for one connected travel/impact/reaction/HP sequence, with real recoil or later hits still distinct. Check outward send-out ball orientation, Dig/Fly between turns, one early KO with EXP/learning and no forced reserve until after residuals, spread KOs, abilities ON/OFF, and normal single battles. End with one native prize/evolution/map return.

## Source and distribution

The I4/I8 rule was checked against Dolphin's primary GX texture decoder, `Source/Core/VideoCommon/TextureDecoder_Generic.cpp`, specifically its I4 and I8 expansion. Reference: `https://github.com/dolphin-emu/dolphin/blob/master/Source/Core/VideoCommon/TextureDecoder_Generic.cpp`. Other source-asset checks use the user's imported GC6E01 image and existing supplied decoder/runtime; no external game assets were substituted.

The installable pair and code-only handoff contain no ROM/CISO/ISO, generated game model/texture/audio cache, font files, decompilation archive or external runtime libraries. Diagnostic screenshots show actual source-backed renderer fixtures, not mock artwork. The code handoff includes an exact-baseline verifier/patch utility; it is optional and is not the normal install route. Historical notes inside the packages describe their own older releases; this document governs this pair.
