# CBE 1.9.22-relic-outskirts.1

## Relic Chamber camera occlusion

The prior Relic Chamber trim only recognized long/skinny camera-side carriers. The shrine's most disruptive foliage is instead a very broad, shallow alpha-tested canopy card; its center can sit well off the battler sightline even while the card itself covers most of the camera view.

1.9.22 adds a Relic-only cutout/canopy classifier using packed source material mode, group extents, elevation and camera/focus position. Large elevated cards between the lens and the battlers are suppressed with a footprint-aware sight corridor. Long trunk/root carriers keep the tighter old corridor. Rear roots, walls and chamber detail are not globally deleted; they remain visible whenever they are behind the fight or outside the active sight corridor.

## Outskirts depth and desert presentation

Outskirts now retains a substantially larger portion of the canonical `S1_out_bf` HSD scene in the packed runtime (`5200 / 14000 / 5000` raw-unit radius/span/triangle envelope versus `3600 / 8200 / 3500`). This is a runtime-sidecar change; the canonical source cache already contains the complete scene.

A low multi-ring desert continuation mesh sits underneath the authored battlefield and extends well beyond its finite square. The inner source battle pad, wagon, fences and other GC6E01 props still render on top unchanged. The far rings develop low terrain relief so camera turns read as continuous desert rather than a flat replacement plane.

The dedicated Outskirts backdrop now uses a late-afternoon Orre treatment: cobalt/blue upper sky, a warm gold horizon, a restrained sun glow, desert haze and a low distant plateau silhouette. This follows the original opening battle's broad desert read while honoring the requested sunnier/sunset atmosphere.

## Cache / compatibility

The canonical arena identity remains `cbe-arena=9` and the global extractor remains revision 15. Only the packed arena runtime format advances from v3 to v4. Existing canonical arena caches can therefore be repacked in place through the sidecar-only migration path; trainer, Pokemon, MoveFX, capture and audio caches remain reusable. The Pyrite lower-bowl camera fix from 1.9.21 remains present.
