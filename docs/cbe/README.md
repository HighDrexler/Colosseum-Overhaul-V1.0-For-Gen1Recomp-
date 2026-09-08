# Colosseum Battle Environments 1.9.30-deep-colosseum-fidelity.1

## Deep Colosseum retail-fidelity cleanup

1.9.30 is a targeted Deep Colosseum pass on top of 1.9.29. `M4_bottom_colo` now honors the same retail HSD OPA/XLU/TEXEDGE submission contract used by the newer source-backed arena repairs and skips shadow-only carrier materials. The source traversal/runtime envelope is widened so more of the ceiling rotor, pipe forest, audience banks, masonry and outer industrial shell survive into the fast runtime.

The previous Deep profile was also applying a second dark green grade and a procedural metal breakup over the original Colosseum textures. That treatment is removed. Source color/contrast are preserved, chamber fog begins much farther beyond the battle floor, and the fallback behind true scene gaps is neutral black rather than green haze. Camera height and actor scale are reduced slightly so Deep reads as the enormous low-ceilinged underground venue shown in the source game.

On an existing complete 1.9.29 installation, the arena migration refreshes **Deep Colosseum only**. Trainer, Pokemon, MoveFX, capture and canonical audio caches remain reusable. The Pokemon animation rollback and Relic source-sector work from 1.9.29 are unchanged.

See `VALIDATION_1.9.30-deep-colosseum-fidelity.1.md`.

## Battle-animation regression rollback

1.9.26 introduced a species-agnostic `repairIdleIsolatedGroups()` extraction pass intended to keep isolated head/crest pieces visible. It rewrote small render groups against the bind body on every sampled idle frame and could therefore partially freeze otherwise valid source-authored motion. 1.9.29 removes that rewrite entirely and returns Pokemon extraction to the 1.9.25 source-animation behavior. The Pokemon extractor advances to revision 36 so caches produced under the bad revision are not reused.

The Diglett/Dugtrio ground exception remains because it changes only whole-actor floor placement for dex 50/51 and does not rewrite animation samples.

## Relic Chamber source-sector 360 pass

1.9.28's forest closure was still an approximation: it chose only a handful of trunk and foliage groups and repeated them as artificial rings. 1.9.29 removes those motif rings. At runtime it identifies the densest safe 120-degree perimeter sector in the extracted `M3_shrine_1F_bf` source scene, keeps the complete eligible set of trunks, roots, rocks and matching cutout foliage in that sector, and rotates that whole source sector twice around the shrine. Relative source placement is preserved and copies remain outside the legal Relic battle-camera volume.

The source shrine battle stage, daylight sky, clear-camera occlusion rules, Outskirts, Pyrite, Deep, MoveFX, audio and trainer systems are otherwise unchanged.

See `VALIDATION_1.9.29-battle-animation-relic-source.1.md`.