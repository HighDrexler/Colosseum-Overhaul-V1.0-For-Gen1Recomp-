# CBE 1.9.24-relic-presentation.1

## Relic Chamber presentation cleanup

The 1.9.23 camera-only fix reduced the problem but did not fully solve it. The supplied 12.73-second runtime capture shows more than one foreground artifact: very broad leaf-canopy cards and pale/root-bark carrier surfaces can span the upper third to half of the frame while their object centre remains outside the simple camera-to-focus ray. That is why the prior centre/radius based solutions could report a safe camera while the rendered image was still visibly obstructed.

### Camera composition

`relic_chamber` now uses a lower inner-bowl base camera (`side=33`, `height=10.2`) with authored shot compression retained. The final venue safety volume is radius `24..34`, eye Y `6.8..11.5`, pitch `-5..10.5°`, FOV `34..48°`, and focus Y `4.6..6.35`. The existing Camera module applies that volume after semantic/source-Waza target selection and again after interpolation.

### Projected foreground guard

`lib/RelicPresentation.lua` adds a pure projected-view classifier used only by Relic Chamber. It projects the eight corners of an oversized source group's AABB into the current camera frame and measures overlap with a protected battle viewport. Only elevated source-cutout, broad horizontal, or thin root/bark carrier candidates on the camera side of the battlers can be suppressed. Rear groups, ordinary architecture and small source details are explicitly retained.

This is view-adaptive presentation culling, not source-scene deletion: the same foliage/root group renders normally again as soon as it no longer blocks the active battle view.

### Compatibility/cache boundary

No arena extraction revision, packed-sidecar identity, trainer/Pokemon/MoveFX/capture cache, HARD CACHE SAVE identity, or canonical audio identity is changed. 1.9.22 Outskirts presentation work and 1.9.21 Pyrite camera work remain intact.
