# CBE 1.9.25-arena-fidelity.1

## Scope
Focused presentation/fidelity sweep for Relic Chamber, Outskirts and Deep Colosseum on top of 1.9.24. No battle logic changes.

## Relic Chamber
- Retains the existing `M3_shrine_1F_bf` battle circle, trees, roots and masonry.
- Adds a large low-profile forest-ground continuation beneath the authentic source scene so the extracted square no longer reads as a floating island.
- Replaces the black fallback with layered distant forest depth and green atmospheric continuity.
- Extends the projected-view guard to the large opaque overhead/cliff carrier visible in the supplied capture. It is suppressed only when its projected slab occupies the battle view; ordinary walls and floor geometry remain.
- Keeps the low inner-bowl camera introduced in 1.9.23.

## Outskirts
- Packed runtime source envelope grows from 5200/14000/5000 to 12000/32000/11500 raw scene/span/vertex radius so substantially more `S1_out_bf` outer geometry survives repacking.
- Automatic camera is lower and more horizontal (`height=13.5`, `shotHeightScale=.62`) to better match the first-battle footage.
- Far-field desert expands to five rings out to raw radius 10800, with pale yellow source-like sand and only low distant relief.
- Backdrop is rebalanced toward the supplied source clip: strong blue upper sky, broad pale cloud banks, warm late-afternoon sun, a low distant Orre mesa, and layered dust/haze.
- Full and Android shader paths compress the very pale source highlights so Outskirts no longer blooms toward featureless white.

## Deep Colosseum
- Packed runtime source envelope grows from 4200/9800/4100 to 8500/22000/8200, allowing much more of `M4_bottom_colo`'s ceiling rotor, pipe forest, masonry and audience shell to survive.
- Figure scale drops to .315 and the camera moves lower/wider so battlers read small against the huge chamber, consistent with the source presentation.
- Dedicated Deep shader profile preserves dark industrial recesses, cool-green source tonality and floor highlights without borrowing Realgam/Wildlands grading.
- Deep distance fog starts much farther out and uses a dark chamber color, preventing the recovered source machinery from being greyed away.

## Cache migration
- Canonical arena identity remains `cbe-arena=9` / HSD v33.
- Global extractor remains revision 15.
- Packed arena runtime sidecars advance from v4 to v5 only.
- Existing trainer/Pokemon/MoveFX/capture/audio/hard-cache data remains reusable.
