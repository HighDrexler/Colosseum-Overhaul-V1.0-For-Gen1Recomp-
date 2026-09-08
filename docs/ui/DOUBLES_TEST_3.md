> Historical paired-build notes. This UI-only compatibility build does not require the paired CBE Test 3 ZIP. See `DOUBLES_UI_COMPAT_1.md` for current installation and compatibility instructions.

# CBE + Colosseum UI — Doubles Test 3

**Experimental paired build. Back up your save and keep the Test 2 ZIPs. Do not change mod versions while resuming an in-battle checkpoint.**

## Packages and installation

- CBE: `1.10.0-doubles-test.3`
- Colosseum Inspired UI Overhaul: `2.4.0-doubles-test.3`

Install both ZIPs through the launcher over their respective existing mods, without enabling duplicate copies. Keep Colosseum Battle UI, Colosseum Arenas, Colosseum Models and Double Battles (Test) enabled for the intended doubles test. The ordinary-trainer threshold remains three or more opposing Pokémon; wild encounters and trainers with exactly two Pokémon remain singles. Boss Intro keeps its separate setting and Test 2 classification.

**No cache reset or additional cache rebuild is required when upgrading from Test 2.** Pokémon extractor revision 37 and Hard Cache Save v4 are unchanged, as are all audio, arena, trainer, capture and MoveFX extraction identities. An installation coming from Test 1 or an older model cache must still complete the Test 2 model-cache migration. Previously uncached species still use their normal loading path.

Both packages are supplied because CBE now provides the detached EXP, typing, status and detailed party display data used by the UI. This extends the existing version-1 command bridge with `displayVersion=3`; it does not replace the doubles rules, native move kernels, reward handoff or command validation.

## Allied EXP and compact type/status indicators

Each allied HP plate has a thin blue EXP strip underneath it. It reads that Pokémon's real saved experience and the existing UI's native growth-curve helper, rather than estimating progress from its level. Both generation-specific experience fields and the level cap are supported. Opponents do not acquire an EXP bar.

Up to two type badges fit inside each plate, with a separate compact status badge when a condition is present. HP numbers remain visible for the player's Pokémon. Narrow-screen layouts use an additional interior line for those numbers instead of allowing them to overlap the type/status badges. A confirmed faint is labeled FNT.

A small display fix also prevents the native kernel's newly applied status from appearing early when the corresponding status event has not yet reached the presentation queue. An explicit cleared status is no longer replaced by that future value.

The Test 2 visibility rules remain: command/move/target selection provides the four-position overview, while relevant send-out, damage, healing, status and faint events show the corresponding Pokémon. The Party overlay replaces the battle HUD while open so it does not duplicate all four plates.

**EXP award timing has not changed.** The existing experimental controller still hands experience back at encounter completion, rather than after each knockout. These bars display real current progress; they do not pretend to award or animate uncommitted experience.

## Target selection on the HP plates

The generic target list is removed. Selecting a single-target move enters HP-panel targeting, with a colored outline/halo around the actual selected Pokémon's plate:

- Orange: opposing Pokémon.
- Cyan: allied Pokémon, with an explicit friendly-fire caption.

Use Up/Down to move between legal targets in the same on-screen column and Left/Right to move toward the other column. Navigation considers only the controller's legal target positions. It does not invent a target or silently remove a legal ally target. The initial choice prefers an available opponent.

A confirms the highlighted position. B returns to move selection without submitting the move. A shallow bottom caption retains the move/target name and control hint, but there is no replacement target list. Spread and self/field actions retain the existing controller's targeting behavior.

The ring represents the exact position sent to the controller, with battle, turn, selection-ticket and battler identities attached. Navigation alone does not spend PP or advance the battle.

## Switching through the shared Colosseum Party UI

Pokémon/Switch now calls the same Colosseum Party drawing function used by the regular Pokémon menu, not the prototype bottom list. It retains the existing portrait art, panel borders, HP styling, selected-Pokémon EXP/detail section, held item, status, four moves/PP, stats, prompt and Exit treatment.

The doubles layout places the two currently active Pokémon in larger cards on the left and the remaining four party members in the right-hand column. The left column is keyed to the live battle positions: it still shows the correct Pokémon after party members 3, 5 or 6 have switched in. It never rearranges the saved party to manufacture that visual layout.

Use directional controls to inspect the cards, A to select a legal reserve, and B or Exit to cancel a voluntary switch. Active Pokémon, reserved replacements, fainted Pokémon and eggs remain inspectable but cannot be submitted as an invalid switch. Their labels explain the restriction. The initial cursor prefers a legal reserve.

During a forced replacement, the empty active position stays visible and B/Exit cannot dismiss the requirement. When fewer than two positions are occupied, there can be five or six entries on the reserve side; the right column scrolls to keep every party member reachable instead of dropping the last entry.

The shared renderer receives a detached display-only party. It does not push a native single-battle Party state or invoke a native single-battle switch callback. The CBE arena remains underneath a transparent dimming overlay. The normal six-card Party screen outside doubles retains its existing layout and behavior.

## Preserved from Test 2

The shared HSD/PKX idle repair for Articuno, Blastoise and the other identified affected species is byte-identical. Pokémon extraction, model actors, the doubles scene presenter, boss-intro implementation, audio, MoveFX, arenas, trainers and cache code are unchanged. The separate MoveFX actor-clock/import-fix experiment is still not merged.

## Validation completed for Test 3

- **138 native regression assertions:** the original 106 plus 32 new Gen I/II assertions driving the new switch selection through the actual doubles controller and native move adapters, including original party identities, partner commands, real PP use, replacement and the native handoff checks.
- **245 new UI/detail assertions:** detached EXP/types/stats/moves/DVs, visible status ordering, legal spatial targeting subsets, exact request identities, ring drawing, 2–4 placement, reserved/fainted/egg rejection, scrolling with empty active positions, required replacements and invocation of the shared Party renderer.
- **376 retained presentation assertions:** sampler repair, boss eligibility/lifecycle, event identity, health-bar visibility, viewport geometry and position-specific cameras.
- All **26** retained subsystem regression suites pass. Two historical build-ID checks were advanced to Test 3 without removing their source-fidelity assertions.
- All **96 Lua files** compile in LÖVE 11.5's LuaJIT. The complete UI entry loads through the actual native Gen I and Gen II mod loaders.
- **38 actual LÖVE render cases** cover both generations, desktop/landscape/portrait sizes, ally/enemy target rings, party layout after non-leading members switch in, required and reserved states, long nicknames and event-only HP presentation. These use fixture battle data and real shared UI code, portraits and fonts—not a live arena.
- The existing Party screen was also rendered with both Test 2 and Test 3. The comparison is pixel-identical for the tested Gen I and Gen II fixture at 1722×896.
- Native growth-helper checks confirm both allied HUD EXP bars in each generation read the expected fixture progress. All **536 existing UI asset files** remain byte-identical, and no baseline files were removed.

## Limits and first test

No complete live ROM-backed battle or Windows/Android device run was performed with this final pair. The graphics checks use the actual LÖVE UI renderer on software graphics with transparent backgrounds, not a simulated claim of in-game arena playback. Device performance, direct mouse/touch pointing at the new cards, every font profile, every third-party mod combination and every special encounter are not certified.

Normal directional/A/B controls remain the supported input path. This update does not add direct mouse/touch card picking, Bag/item commands, modern doubles AI, per-KO experience timing, the excluded complex moves, full multi-target Waza effects or in-battle checkpoints. All previously documented doubles gameplay limitations remain.

Start with the existing Articuno/Blastoise party. Check each allied EXP bar, both type badges and an actual status condition. Select the upper and lower opponent by their HP rings, cancel back to moves, then switch each active position to a non-leading reserve. Reopen Pokémon/Switch and confirm the two active cards moved to the left while the original saved party order stayed intact. Also test a required replacement and set doubles OFF for a normal Party-menu smoke test.
