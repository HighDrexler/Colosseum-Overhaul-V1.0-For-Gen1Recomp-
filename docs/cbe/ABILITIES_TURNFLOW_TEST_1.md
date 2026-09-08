# CBE / Colosseum UI — abilities forward-port, test 1

## Install this pair

**CBE: 1.11.0-abilities-turnflow-test.1**  
**UI: 2.5.0-abilities-compat-test.1**

Replace both existing mod ZIPs in the launcher; do not leave duplicate copies enabled. Each archive has its original mod ID, `main.lua` and `manifest.json` at the ZIP root. Both remain experimental builds. Start from a backed-up save outside battle, not an in-battle checkpoint from another version.

Open **COLOSSEUM BATTLE settings → ABILITIES (TEST)** to enable abilities. The default is **OFF**. An existing saved ON/OFF preference is retained. With OFF, the new battle wrappers delegate to the existing native methods and the UI uses its prior fallback for Pokémon without external ability data. Explicit ability labels supplied by other mods remain visible as before.

Keep the user-provided Colosseum import and existing caches. This merge does not increment the arena, Pokémon, trainer, audio, MoveFX or packed-mesh cache schemas. If the latest MoveFX + Turn Flow build's cache preparation is already complete, no extra reset or Hard Cache Save is introduced for abilities. Coming directly from the older ability donor can still require the existing Turn Flow build's cache preparation. **Do not wipe the whole cache.**

## Correct baseline and preserved work

This is a forward-port, not a replacement with the older ability ZIP. CBE starts from **1.10.0-movefx-turnflow-test.1**; the UI starts from **2.4.0-doubles-test.4**. The supplied ability CBE branches from **doubles-stability-test.2**. Only its ability-related changes were transplanted, followed by native-engine integration repairs. The validation JSON pins all four input ZIP hashes and the resulting changed/unchanged members.

The latest doubles `Runtime.lua` is unchanged. Native per-KO EXP/stat commits/learning, frozen committed-action continuation, native sharing hooks, post-battle evolution eligibility, after-residual forced replacements on both sides, and the protection against Gen II locked-move combat re-entry remain. Explicit switch actions retain their normal timing. No unsupported special switching move was enabled by the ability merge.

The latest MoveFX, model/particle renderer, source extractors, arena code, four-actor presenter, Dig/Fly visibility and source-cache code are unchanged. All eleven arenas, current transit fixes, import/audio gating, sprite/model provider selection and StadiumFX-independent hosting remain in the baseline code. This is a byte-preservation statement, not a claim of a new visual, device or every-provider runtime sweep.

The UI retains its current Bag/item/PP-recipient flow, reservations, original party indices, target rings, EXP/type/status HUD and all existing art/audio assets. It remains a presentation client; it does not calculate ability damage or take over doubles turn resolution. The existing bridge is still version 1, with additive ability information.

## Ability changes carried forward

The donor catalogue is retained byte-for-byte: entries for 251 species, including 94 dual-option and 157 single-option species, with 62 distinct ability IDs. Catalogue coverage does **not** mean 62 fully implemented mechanics. The coverage report separates hooked experimental effects, catalogue-only gaps and out-of-battle exclusions.

For a Pokémon without an explicit ability supplied by another mod, selection uses the donor's deterministic DVs/OT-ID/species resolver. Summary uses the individual result; the Pokédex dossier lists the species options. Resolution is read-only: it does not stamp new permanent ability fields into saved Pokémon. Existing explicit ability fields are respected; an unknown external ID is not replaced with a guessed CBE ability. Existing explicit assignments from the older donor are likewise not silently removed or migrated, because they have no provenance marker distinguishing them from another mod's assignment.

Trace and Flash Fire activation now live in battle-local state. Trace does not overwrite the saved assignment and clears when that Pokémon leaves. Copied entry abilities activate from the copied runtime state. Snapshots preserve the original individual OT/DV identity and detached labels. The UI tolerates absent, incompatible, disabled or throwing optional ability exports; cached Pokédex labels invalidate when the CBE ability setting changes.

## Native integration repairs beyond a textual merge

- **Generation isolation:** production installs only the active game's engine hooks. Gen I must not require Gen II battle structures; Gold's Gen I `BattleState` facade is a presentation proxy, not the Gen I combat kernel. The generation-specific installer was executed through the actual supplied mod sandbox.
- **Native singles lifecycle:** opening, switch-out, switch-in and end-of-turn hooks are connected to native events/methods. Gen II entry abilities wait until entry-hazard processing, and a hazard-fainted entrant does not activate Intimidate. The singles listeners decline doubles-owned combat, progression and final-handoff hosts.
- **Four-position doubles entry:** all four slots exist before opening abilities run. Entry order follows effective speed; Intimidate and Cloud Nine see the relevant full active field rather than the last temporary native pair. Replacement entry effects run at the latest scheduler's after-residual boundary, not midway through a committed turn.
- **Actual method/record contracts:** Gen I status vetoes return message arrays, not booleans; Gen I cached effect records are wrapped rather than an unused legacy table. Gen II consumes `opts.move`, its native status vocabulary and its cached OHKO record. Per-hit damage metadata is retained so immunity cannot be treated as a successful damaging hit by later native logic.
- **Secondary, drain and recoil boundaries:** Gen II changes the call-local `useMove` definition where those effects actually run, not a fictitious `hitOnce` layout. Shield Dust prevents supported secondary effects before application; Rock Head suppresses native recoil rather than healing it back; Liquid Ooze redirects eligible drain healing. Shared move definitions are not mutated.
- **Pressure:** extra PP is attached to a real native PP debit and each distinct targeted holder. A two-holder spread attack uses three PP total; native paired dispatches, sleep interruptions and already-paid charge releases do not independently add charges. Native singles and doubles use separate accounting boundaries.
- **Isolation/error cleanup:** saved stats and ability assignments are not overwritten. Temporary crit, RNG, move-definition, weather and source-identity hooks are restored after success or failure. Existing native/custom accuracy vetoes remain authoritative; there is no second roll that can turn another mod's veto into a hit. Nil-bearing multi-return values are preserved at scoped wrappers.

## Executed validation

All checks use the supplied engine source pinned in the validation JSON and LÖVE 11.5's LuaJIT runtime. Native test graphics are stubs, not live gameplay.

- **55/55 CBE root suites pass:** 49 retained suites, five donor ability suites (with inaccurate stub contracts repaired), and a new generation-boundary suite. Root suites include source/cache, arena, actor, visibility, MoveFX and provider contracts, many of which are static or fixture-based.
- **1,953 native assertions pass**, plus the retained **345-case native effect sweep**. This includes 1,432 retained assertions with both ability wrapper modules installed but ordinary baseline fixtures OFF, 86 targeted native ability assertions, 38 active-ability/turn-flow assertions, 25 singles lifecycle assertions, and 372 fault-safety assertions in the catalogue sweep.
- **124 catalogue fault-safety cases:** each of the 62 ability IDs traverses actual entry, outgoing/incoming physical and special moves, a status move, a residual tick and withdrawal in each generation. This proves those exercised paths did not fault or corrupt the tested identity/HP fields. It does not certify the semantic completeness of those abilities.
- **Ability-enabled progression tests:** per-KO native progression pauses committed actions; Pressure is not repeated on returning from the EXP screen; reserve Intimidate waits until after residuals; Speed Boost runs once; final native SolarBeam charge-lock handoff settles all rewards without entering native singles combat.
- **UI compatibility:** 511 retained older-producer assertions using the original CBE doubles Tests 1, 2 and 3; 116 Bag/item UI assertions; 36 new ability bridge/cache-key/identity assertions. The retained presentation suite reports 374 assertions, 382 including its item checks.
- **Actual loader/sandbox checks, both generations:** the complete UI entry loads. A clearly identified synthetic installer mod loads the unchanged ability-module bytes and the production generation-dispatch block through the actual sandbox, then triggers native Intimidate. The separate CBE package entry remains correctly blocked by its missing required Colosseum import in this harness; no complete source-backed CBE boot is inferred from these checks.
- **150 Lua files compile** across the two final working trees. Final ZIP CRC/root-entry checks, member preservation, and a second native/UI run against the extracted finished packages are recorded in the validation report.

The donor's Gen I/II effect tests incorrectly modeled native status returns, legacy record dispatch and Gen II recoil/secondary ownership. Those fixtures were replaced with accurate wrapper-contract tests, and actual native-kernel tests were added. The donor's original tests/notes are retained only in the code-only handoff as explicitly historical evidence, not represented as current passing or correct behavior.

## Limits — not a full ability or compatibility certificate

**Catalogue/display only, not complete runtime effects:** Cute Charm, Damp, Early Bird, Lightning Rod redirection, Oblivious, Run Away, Soundproof, Sticky Hold and Suction Cups. Some were described more optimistically in the donor notes than its code supported. This forward-port does not turn those descriptions into an implementation claim. Illuminate, Stench and Pickup retain the donor's out-of-in-battle scope; Pickup's post-battle item finding is not implemented here.

Several hooked categories remain partial. Post-formula damage multipliers are not exact Gen III stat/base-power arithmetic, including integer rounding and additive constants. Guts/burn interaction, Rest bypassing ordinary sleep-infliction entry points, called/fixed-damage paths, per-hit contact/secondary ordering and every weather/move interaction need further work. Gen I Serene Grace still uses a scoped secondary RNG approximation; Gen II call-local effect chances improve the donor's behavior but do not certify every native effect branch. The donor's contact classification table was preserved, not independently signed off against every source move.

The existing doubles complex-move exclusions remain. Rendering and source fidelity gaps documented for MoveFX + Turn Flow Test 1 are not newly solved by this ability merge. No complete live four-model ROM-backed battle with the full UI, Windows/Android device session, performance benchmark, every installed third-party mod combination, external EXP-mod suite, or frame-by-frame retail comparison was run in this pass. An unchanged provider/renderer file is not proof of every interaction under ability-induced weather or status.

## Focused next test

On a copied save, enable abilities and verify an individual Summary label, both Pokédex species options, a native single-battle Intimidate opener and a doubles opener affecting both opponents. Check an absorption ability, a Pressure target, then an early KO followed by EXP/learning, the remaining committed action, residuals and only then the replacement's entry ability. Finish the battle, reopen the same party record and confirm temporary Trace did not become permanent. Finally turn abilities OFF and repeat the established normal singles/doubles flows. Keep the latest Dig/Fly and traveling MoveFX checks in the normal regression route; this build preserves their code rather than claiming a new visual sign-off.
