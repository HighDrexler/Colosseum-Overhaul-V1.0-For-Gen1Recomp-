# CBE 1.9.25-arena-fidelity.1 validation

## Baseline
- Built directly from 1.9.24-relic-presentation.1.
- Scope is arena presentation/runtime fidelity only; no battle-logic changes.
- Canonical arena marker remains v9 / HSD scene v33.
- Global extractor remains revision 15.
- Packed arena runtime sidecars advance to v5 so existing canonical arena caches can be repacked without redoing trainer, Pokemon, MoveFX, capture or canonical audio extraction.

## Relic Chamber
- PASS: low inner-bowl camera from 1.9.23 remains.
- PASS: projected foreground-carrier guard remains.
- PASS: oversized opaque overhead/cliff carriers now have a Relic-only projected-view rejection path.
- PASS: ordinary vertical wall geometry is rejected by the overhang classifier.
- PASS: large 3D forest-ground continuation is drawn beneath the authentic source scene.
- PASS: layered forest backdrop replaces exposed black void behind the finite source tree ring.

## Outskirts
- PASS: packed source envelope expanded to 12000 scene radius / 32000 max group span / 11500 vertex radius.
- PASS: runtime sidecar and source-cache fallback use the same expanded envelope.
- PASS: camera is lower/more horizontal and authored shot height/radius are compressed toward the supplied first-battle reference.
- PASS: pale five-ring desert continuation extends to raw radius 10800.
- PASS: backdrop includes blue upper sky, broad pale cloud banks, warm late-afternoon sun, low distant mesa and layered dust/haze.
- PASS: full and Android shader paths apply Outskirts-specific highlight compression rather than allowing pale source materials to bloom toward white.

## Deep Colosseum
- PASS: packed source envelope expanded to 8500 scene radius / 22000 max group span / 8200 vertex radius.
- PASS: actor figure scale reduced to .315 and trainer scale/anchors adjusted for the source arena's enormous architectural scale.
- PASS: lower/wider camera envelope keeps the chamber/ceiling machinery dominant rather than using the generic stadium master.
- PASS: dedicated Deep shader profile uses restrained cool-green industrial lighting and dark recess protection.
- PASS: Deep fog starts much farther out and uses a dark chamber color so recovered outer machinery is not greyed away.

## Regression/static checks
- PASS: all packaged Lua sources parse under `texluac -p`.
- PASS: all 19 packaged regression suites pass under the local Lua harness, including ArenaFidelity1925Tests, RelicPresentationCleanupTests, RelicCameraSafetyTests, PyriteCameraSafetyTests, audio/MoveFX/trainer/cache tests and battle-exit boundaries.
- PASS: GLSL source delimiter balance checked for both full and mobile arena pixel shaders.
- PASS: manifest JSON parses and main/manifest version strings agree.

## Live-runtime boundary
This environment does not contain the user's full GC6E01 disc/cache runtime, so final visual certification of the newly widened Outskirts/Deep source shells still requires the real in-game test. The changes are deliberately structured so that test uses existing canonical arena caches and only regenerates packed arena sidecars. The supplied screenshots/video were used as the presentation targets for camera, horizon, lighting and Relic artifact cleanup.
