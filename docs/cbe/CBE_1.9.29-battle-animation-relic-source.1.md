# CBE 1.9.29 — battle animation rollback + Relic source-sector rebuild

## Pokemon battle animation regression

The regression was introduced by the 1.9.26 `repairIdleIsolatedGroups()` extractor heuristic. It compared every small idle render group with the bind body and rewrote groups judged to have moved too far. Even though it was added for Articuno's missing idle head/crest, applying it to every species and every sampled idle frame could partially freeze valid authored motion.

1.9.29 removes that heuristic and all of its call sites. Pokemon extraction is restored to the 1.9.25 animation sampling path and bumped to revision 36 so revision-35 caches are not reused. Dense action pages, attack/damage/faint materialization and continuous runtime interpolation remain unchanged.

Diglett and Dugtrio keep their species-specific floor-depth exception. That adjustment is applied only to actor placement at draw time; it does not modify source pose vertices.

## Relic Chamber

1.9.28 repeated a very small set of individual source trunk/leaf groups in two rings. The result could be sparse, repetitive and visibly unlike the real scene even though the meshes themselves came from Colosseum.

1.9.29 instead scores the safe perimeter groups in `M3_shrine_1F_bf` by azimuth, selects the densest contiguous 120-degree source sector, and duplicates that entire sector by +120 and +240 degrees. Original group positions and trunk/root/foliage relationships are preserved. Groups whose bounds could enter the active camera clearing, giant floor carriers and broad overhead sheets are excluded from the copied sector.

This is still a runtime closure around the actual source battle map; no synthetic tree meshes are added.

## Cache migration

Because revision-35 Pokemon caches may already contain rewritten idle samples, 1.9.29 advances Pokemon extraction to revision 36 and Hard Cache Save to v3. Existing arena, audio, trainer, MoveFX and capture caches remain reusable. Run HARD CACHE SAVE once after installing 1.9.29 to refresh the Pokemon base/idle/action sidecars under revision 36.
