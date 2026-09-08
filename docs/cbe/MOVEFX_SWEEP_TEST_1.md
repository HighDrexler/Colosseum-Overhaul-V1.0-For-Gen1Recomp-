CBE 1.10.0-movefx-sweep-test.1
Built on the user's 1.10.0-doubles-test.2 baseline, retaining Presentation Test 1's trainer overhaul.

Install
Replace the previous CBE ZIP with this ZIP. Keep the Colosseum import and existing generated caches. Do not install both CBE versions together. This update does not require deleting all assets or re-extracting every move. Installing directly over doubles-test.2 still performs the previously required trainer migration.

Implemented
- One selected attack chapter and one selected damage chapter instead of layering all discovered alternatives. This changes default attack scheduling for 119 of 251 move IDs. Species-named source overrides are selected when present; standard primary banks remain the fallback. Cached alternative banks remain available.
- Flamethrower schedules 9 primary attack entries rather than attack + sp1's combined 18. Surf selects 16 rather than 49 entries across attack/sp1/Lugia; Lugia can select its own bank. SolarBeam's release selects 8 rather than mixing 24 entries from release/alternate/charging banks. These are source timeline entry counts, not particle counts or measured FPS gains.
- Explicit charge-stage selection is supported, but end-to-end two-turn host event routing still needs verification. Numbered damage variants are separated from attacks; they are NOT guessed to mean successive hits. An explicit damage variant remains available to future verified routing.
- Queued damage effects and their camera chapter now start when the corresponding native Pokemon reaction initializes. Duplicate hit notifications do not start an extra reaction/effect. A lethal queued hit still completes before faint.
- Particle F1 now consumes a 16-bit lookup ID without swallowing the next opcode. Source Seismic Toss/Vital Throw streams were previously misread into enormous position values. Regression tests preserve the following color command and delay framing.
- Held launch, contact, wide wave, self/status and impact compositions cut to damage chapters. Generic orbit/pan/shake waveforms were removed from these shared source shots. Live actor attachments still move the framing, and existing manual controls, wall-clock camera limits and venue visibility guards remain.
- Source sequence kind and attachment inform camera-family selection for moves outside the small curated camera list. Exact retail camera curves, lenses and every species-specific shot are NOT decoded by this change.
- Sentinel-only WZX phases now parse as valid empty chapters rather than a missing-entry error. Existing cached parser diagnostics are not forcibly rebuilt just for this compatible parser correction.

Performance
- Fixed cache validation expecting extractor 29/Waza 11 while the actual cache format is 30/12.
- A completed 251-move source cache plus ready source audio can now be reused even when some executable visual chains remain incomplete. This avoids repeatedly rescanning the full bank on startup. Missing move metadata or stale index versions still invalidate reuse. Partial visual coverage is not relabeled as complete.
- Each particle entry loads textures only from its referenced bank, avoiding unrelated-bank image setup. Selected phase views are memoized without retaining discarded source caches through a strong reference cycle.
- Prior trainer track/GPU upload and cache reuse improvements remain. No live loading-time or FPS measurements are claimed.

Validation
- 23 focused Lua suites pass; all Lua files parse. New checks cover phase isolation, species/charge/explicit-damage selection, shared-cache immutability, queued damage handoff, duplicate/lethal reactions, empty WZX parsing, both-side camera cuts across seven shot families, cache reuse/invalidation and F1 command boundaries.
- All 251 move IDs resolve to source archive candidates in the user's GC6E01 ISO. Of 634 unique candidates, 632 WZX files extract and parse completely; two unused-looking attck archives have invalid FSYS entry counts. Every move has a default attack selection; this does not prove every effect is executable or visually accurate.
- Particle audit: 17,401 program records checked for supported command framing; 941 source particle entries launched. Up to 300 simulated frames per entry, 180-frame emission window. Zero unsupported program framings, reported opcode faults or invalid/out-of-range position samples after the fix. The previous VM produced 1,280 out-of-range coordinate samples in four Seismic Toss/Vital Throw damage banks.
- This is a CPU particle audit without source joint transforms, GPU compositing, live Pokemon bodies or host battle events. Some chains reach the existing 768-particle cap. These results do not prove no clipping, all particle semantics, effect appearance, or 1:1 retail parity.
- movefx-sweep-coverage.csv lists all 251 IDs, source stems, available/selected phases, entry counts, camera families and remaining source errors. Every visual-parity field remains 'no' because a per-move retail comparison has not been completed.

Test in game
Start with Charizard Flamethrower, Surf (including Lugia), SolarBeam, Seismic Toss, Vital Throw, a multi-hit move and a lethal final hit. Check the launch stream, camera cut, target reaction ordering and return to the normal battle view. Try both attacking sides and a higher battle speed. Retest with your other mods enabled to expose presentation-hook conflicts.

Limits and remaining parity work
Experimental doubles remains byte-for-byte unchanged from doubles-test.2 and bypasses the shared MoveFX presenter. These effects/camera changes currently apply to singles. Exact retail cameras, special/numbered/alternate-PKX variant conditions, two-turn charging, full particle/controller semantics and all 251 move/species appearances still require verification. No live host gameplay validation was completed for this test build. Previous trainer presentation improvements are retained, not newly revalidated against retail in this sweep.

The ZIP contains code and tests, not the ISO or extracted source assets. See the included PRESENTATION_TEST_1.md for the retained trainer changes; this document supersedes its MoveFX update status.
