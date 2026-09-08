# CBE 1.9.31-relic-visual-fidelity.1

## Scope

1.9.31 is a focused Relic Chamber visual-fidelity pass built on 1.9.30. It preserves the 1.9.29 Pokémon battle-animation rollback and the 1.9.30 Deep Colosseum fidelity changes.

## Relic Chamber visual fidelity

- The source scene remains `M3_shrine_1F_bf`; the existing clean inner battle-camera and projected foreground-occlusion protections remain active.
- The retained canonical scene envelope is widened to `7800 / 20000 / 7400` so more legitimate perimeter source geometry can survive extraction.
- The old narrow repeated forest cadence is replaced by one coherent 180-degree source half chosen from the densest valid perimeter region. That half keeps trunks, roots, rocks, ground and foliage in their source-relative arrangement and is used only to close the genuinely missing opposite side.
- Low authentic perimeter ground/root/rock/understory groups are reused separately as sparse depth detail, instead of assembling fake trees from isolated components.
- The continuity land under the source scene is denser and extends through seven low-relief rings. It uses restrained deterministic mottling/relief to prevent the surrounding land from reading as a flat empty plate without replacing source textures in the near field.
- Relic receives restrained world-space dapple variation and clearer bark/ground separation. This does not add texture fetches and is intentionally much lighter than the generic grading previously used on some arenas.
- Relic distance fog begins later and is weaker (`300 -> 760`, strength about `0.070`) so the expanded trees and ground detail remain legible instead of collapsing into a muddy green wall.
- The daylight sky and very soft horizon haze remain the only backdrop filler. No flat screen-space treeline is restored.

## Colosseum UI 2.3.4 bridge

`informationModels.version` advances to 6 and adds an explicit `setAnimation()` showroom-only gate. Colosseum UI 2.3.4 can therefore freeze/promote information-menu idle animation without directly mutating a CBE actor table. This does not change live battle animation clocks, action selection, or gameplay.

## Cache / migration behavior

- Global extractor revision remains 15.
- Pokémon extractor remains revision 36; the 1.9.29 battle-animation fix is preserved.
- Hard Cache remains v3.
- On a complete installation, the arena repair path refreshes **Relic Chamber only** and regenerates runtime arena sidecars from the existing canonical arena caches.
- Audio, trainers, Pokémon, MoveFX and capture caches are not deliberately invalidated by this build.

## Pairing

For improved Colosseum-model quality in PC / Pokédex / Summary while retaining the static-first performance architecture, pair with **Colosseum Inspired UI Overhaul 2.3.4**.
