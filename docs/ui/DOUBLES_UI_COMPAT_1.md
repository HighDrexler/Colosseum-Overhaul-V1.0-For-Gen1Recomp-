# Colosseum UI — Doubles Test 3, UI-only compatibility fix 1

## Install only the UI ZIP

Version: `2.4.0-doubles-test.3-ui-compat.1`.
Replace the existing Colosseum UI mod with this ZIP. Keep your current Codex CBE build installed. This package contains no CBE implementation and requires no new CBE package, cache wipe, extraction, or source import. Do not change mod versions while resuming an unsupported in-battle checkpoint.

These instructions supersede the paired-install instructions in the historical `DOUBLES_TEST_3.md` for this UI build.

## What depended on the paired CBE before this fix

The original UI Test 3 used CBE Test 3's optional display fields for allied experience and full Party details. Earlier version-1 producers did not carry experience in their portrait records or complete species/moves/stats/item/identity information for reserves. Target-ring commands and the two-active/four-reserve layout already used the existing version-1 command contract.

This UI now fills missing display information from the native Gen I/II party table and species definitions, using the original party indices. It does not run native switch callbacks, reorder the party, or write to the saved Pokémon. Current bridge display data wins when present. Controller legality flags and request identities are unchanged.

HP/status still follow the CBE snapshot rather than being replaced with values from the native kernel that may be ahead of the visible event. Incoming occupants cannot supply outgoing actors' experience merely because they occupy the same position or are the same species. Duplicate species keep separate party identities. Native field copies are bounded and omit nested engine/model/animation objects.

## The unavoidable shared interface

Doubles still requires the CBE export `exports.doubles` with `version=1`, callable `snapshot(battle)` and `submit(request)`, and the existing snapshot/request meanings. This patch does not require `displayVersion=3`, an exact CBE release number, or the CBE Test 3 display helpers. The UI is not a replacement doubles controller.

The producer remains authoritative for battleId, revision, ticket, turn, commandSlot, battlerId, phase, slot identities, partyIndex, legal moves, targets, enabled/active/reserved party flags, presentation events, and command validation. Switching and targeting use the same original request fields and indices. Unknown/incompatible bridges are not guessed into a new protocol.

If a custom engine stores a different detached party not exposed through its native battle party fields, it must either retain the existing native party view or provide the optional display fields itself. This patch cannot recover missing data without an identifiable source. Fallback typing uses known native/species types; a transient battle-only type change requires that information from CBE. An older producer's absent events or incorrect HP/status timing cannot be repaired by a display adapter.

No CBE changes are bundled: camera/model/Articuno/Blastoise repairs, boss intros, audio, MoveFX, items, experience-award timing and battle mechanics are whatever your installed CBE build supplies. The normal non-doubles Party renderer and all existing UI art assets are unchanged.

## Validation performed for this patch

- 511 compatibility assertions pass in both LuaTeX's Lua runtime and the LÖVE 11.5-distributed LuaJIT library, using the actual released CBE Test 1, Test 2 and Test 3 snapshot producers with Gen I/II-shaped party fixtures and the real DoublesUI factory. Tests cover EXP, party portraits/details, duplicate species, non-leading active indices, request preservation, display priority, detached data, event identities, malformed/absent bridges and bounded cyclic native objects. Graphics are stubs.
- Existing Test 3 UI/detail (245) and presentation (376) assertions pass.
- Native move/completion regression suites pass with CBE Test 2 (106 assertions) and Test 3 (138 assertions). These are headless native-engine tests, not live graphics or device tests.
- All four UI Lua files, including the new test file, compile with the LÖVE 11.5-distributed LuaJIT library.
- The full UI entry loads through the supplied native Gen I and Gen II mod loaders, with the compatibility export present. These are headless loader checks; the Gen II run retains the existing StatBox-facade warning.
- All 536 baseline art/audio/font asset files are byte-identical. No baseline UI file is removed. No CBE ZIP is modified or repackaged.

Your exact current Codex CBE ZIP was not supplied in this turn, so it has not been executed or certified. This is compatibility with the existing version-1 contract, not a guarantee for arbitrary changes to that contract. No new live ROM-backed battle, visual render comparison, Windows/Android run or performance benchmark was performed for this patch.
