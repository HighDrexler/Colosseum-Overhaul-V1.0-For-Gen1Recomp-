# Single-battle switch prompt hotfix
## Colosseum Overhaul 1.0.3 / Colosseum Inspired UI Overhaul 2.5.3
Validation date: 7 September 2026

## Confirmed causes

The Gen I YES/NO renderer called `mobileBattleUIEnabled()` from outside the
embedded renderer's lexical scope. The function exists only inside that nested
module, so the outer choice renderer raised an undefined-global error. Its caller
caught the error but still reported successful rendering. The real ChoiceBox stayed
on the stack and continued accepting input without visible YES/NO choices.

A second visibility gap existed with Colosseum Battle UI ON and the separate
revamped dialogue option OFF: native battle UI visibility also hides pushed
TextBox/ChoiceBox states, but the replacement discovery/draw path used only the
separate dialogue setting. This combination could leave a battle prompt blank.

The doubles service also accepted any state whose `game` matched the active
session's game. A distinct single battle can use that same game object. A
controlled stale-session regression reproduces the ownership leak; that is a
separate verified code defect, not proof that it happened in the reported live
session.

## Changes

- Use the shared, in-scope mobile UI option reader for YES/NO layout.
- Align battle-dialogue ownership with battle UI ownership without changing any
  saved setting or enabling revamped dialogue in the overworld.
- Recover the live battle prompt from the authoritative stack, including masked
  API-wrapper choice identities; ignore covered/stale choice markers.
- Restore the graphics stack after rendering errors and draw an asset-independent
  fallback containing the live prompt, YES/NO, current cursor and control hints.
- Keep the custom party background under native already-out/fainted selection
  refusal messages.
- Require the actual doubles battle/model/view identity, not just the same game,
  when resolving a session. This CBE-side guard is in the combined package.

Native battle callbacks, the SHIFT/SET option, ChoiceBox answer timing, party
cancel behavior, switch/replacement rules, rewards and combat logic are unchanged.
The native Gen I `forceSwitch` flag also means direct selection during optional
SHIFT; it is deliberately not cleared or treated as proof of a mandatory switch.

## Verification performed

**Focused single-battle regression: 349 assertions passed per package.**
The test loads the entire shipped UIMain implementation into the supplied engine's
ROM-free fixture environment, exposing internals only in memory. It exercises the
actual BattleState queue, ChoiceBox, PartyMenu and the installed UI adapters.

Coverage includes the exact native switch question and both choice labels; five
window sizes (1280x720, 1227x1008, 1920x1080, 720x1280, 390x844); mobile mode ON/OFF;
separate dialogue mode ON/OFF; stale battle markers; renderer exceptions and
explicit false returns; restoration of nested graphics state; NO; B; YES followed
by party B; valid selection; already-out and fainted selection refusals; queued
send-out completion; preservation of the current Pokemon on cancellation; SET
behavior; compulsory native replacement after an actual faint; and field-dialogue
toggle independence. Rendering never submits a choice or changes its callback.

**Doubles encounter-identity regression: 37 assertions passed.**
Real screen/model/view aliases remain valid. A different single-battle/party state
cannot receive a stale doubles command, replacement or presentation snapshot.
Native reward progression and final handoff ownership remain unchanged.

**Regression runs:**
- Combined package: 68 top-level headless suites passed.
- Supplied engine: five existing native engine suites passed.
- Native doubles regression with abilities not installed: 1,432 assertions passed.
- Native doubles regression with abilities installed: 1,953 assertions passed.
  This runner includes the stability, integration, field visibility, turn-flow,
  progression-boundary and enabled ability sub-suites with their required context.
- Doubles presentation runner: 382 assertions passed.
- Standalone package: all six top-level suites passed, including the new focused
  single-battle regression.
- All 179 packaged Lua files parsed successfully under Lua 5.3.
- Both archives have main.lua and manifest.json at their roots. The shared
  UIMain.lua files match byte-for-byte. All pre-existing assets are unchanged.

These are 82 successful suite invocations across the combined package, native
engine/ability configurations and standalone package; shared UI suites are run
again in the standalone tree, not counted as distinct unique implementations.

## Negative controls

The identical new single-battle suite fails against the untouched 1.0.2 package:
`attempt to call a nil value (global 'mobileBattleUIEnabled')`.
The identical encounter-isolation suite also fails against that package because a
single-battle state receives the active doubles session through the same game.
Neither failure was masked with a replacement renderer or altered baseline source.

## Scope and limits

This is headless validation with real native engine logic and instrumented graphics,
not a live LOVE/game session, GPU rendering check, ROM playthrough or Windows/mobile
performance benchmark. LuaJIT/LOVE execution was not available; tests used texlua
(Lua 5.3) with a test-only Lua 5.1 compatibility adapter. The engine source is the
user-supplied `gen1recomp-dev (7).zip`. No engine source or ROM is bundled here.

The historical DoublesDisplayCompatTests suite was not run because its separate
cbe1/cbe2/cbe3 producer fixture directories are absent. Its existing source remains
unchanged. Initially invoking context-dependent doubles sub-suites alone produced
missing-context errors; they were then executed correctly through their native
RegressionTests parent, as described above.

The original cause and the exercised flows are verified in fixtures. A live check
of the reported encounter remains necessary to confirm the complete on-screen
result with the user's installed renderer stack. No claim is made of universal
runtime compatibility or measured performance improvements.

## Installation

Use `Colosseum_Overhaul_v1.0.3.zip` to replace the combined 1.0.2 mod. It includes
both CBE and the UI and contains the encounter-isolation guard.

`Colosseum_UI_Overhaul_v2.5.3.zip` is the standalone UI alternative for a separate
CBE installation. It contains the shared UI hotfix, not a replacement CBE runtime.
Do not enable the standalone UI alongside the combined overhaul. Both archives
are complete root-entry packages rather than loose patch collections. Existing
assets, extraction/cache formats and unrelated runtime modules are retained.
