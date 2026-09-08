# CBE 1.9.23-relic-camera.1

## Relic Chamber camera correction

The repeated Relic Chamber obstruction was not reliably solvable from renderer-side mesh bounds: the large shrine foliage cards can cover the camera frustum even when the carrier centre does not intersect the camera-to-focus ray. This build therefore stops treating foliage deletion as the primary fix.

`lib/ArenaCatalog.lua` now gives `relic_chamber` a dedicated low inner-bowl camera contract: `shotRadiusScale=0.66`, `shotHeightScale=0.58`, maximum camera radius `38`, maximum eye height `15.5`, maximum pitch `13.5°`, and a focus-height band of `4.7..7.2`. The complete source shrine shell remains present.

`lib/Camera.lua` now accepts optional per-venue `minFocusY` / `maxFocusY` limits. Because the venue clamp already runs after semantic/source-Waza target selection and again after interpolation, the Relic limits apply to intro/passive/send-out/attack/damage/reaction/switch/faint shots, source-Waza targets, and unsafe host/previous-camera blend frames.

No canonical arena/extractor/audio/cache revision is changed. This is a camera-only runtime correction on top of 1.9.22, preserving the Outskirts expansion and the 1.9.21 Pyrite lower-bowl fix.
