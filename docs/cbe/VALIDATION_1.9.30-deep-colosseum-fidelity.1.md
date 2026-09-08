# Validation — CBE 1.9.30-deep-colosseum-fidelity.1

## Automated result

- Lua syntax: **84/84** packaged Lua files parse under LuaTeX/texlua.
- Regression suite: **25/25** test files pass.
- New `DeepColosseumFidelity1930Tests.lua` verifies the Deep-only source repair, retail render-pass policy, widened source/runtime shell, source-neutral shader path, long-depth fog, lower camera composition, cache marker agreement, and preservation of Pokemon extractor revision 36 / global extractor revision 15.

## Regression preservation

Existing tests continue to cover arena expansion, 1.9.25 arena fidelity, audio parity, 1.9.29 Pokemon animation rollback, battle exit boundaries, HSD scale, Hard Cache, UI/model performance isolation, MoveFX handoff/runtime/source chain, Pokemon presentation/reaction, Pyrite camera safety, Relic camera/source/360/presentation contracts, trainer source cache and Waza SFX mapping.

## Migration contract

- Existing complete installs refresh canonical **Deep Colosseum only**.
- Runtime arena sidecar format remains **v6**; Deep's changed canonical source cache invalidates/rebuilds its sidecar while unchanged arena sidecars can be reused.
- Global extractor remains revision **15**.
- Pokemon extractor remains revision **36** from 1.9.29.
- No forced audio/trainer/MoveFX/capture cache rebuild is introduced by this pass.

## Visual-certification boundary

The code-level causes of the muddy Deep perimeter have been addressed against the supplied Colosseum source reference: non-retail render-pass geometry, clipped outer source shell, stacked green/dark grading, and fog beginning inside the readable architecture. This environment does **not** contain the user's generated GC6E01 Deep arena cache, so final 1:1 visual certification still requires the live in-game Deep Colosseum test. This report deliberately does not claim that static regression tests prove final visual parity.
