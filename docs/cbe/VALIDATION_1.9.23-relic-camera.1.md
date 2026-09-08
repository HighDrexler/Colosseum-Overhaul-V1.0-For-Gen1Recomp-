# CBE 1.9.23-relic-camera.1 validation

- Baseline: packaged `1.9.22-relic-outskirts.1`.
- Relic Chamber source geometry is retained; `cameraOccluderTrim=true` is no longer enabled for the venue.
- Relic automatic camera: radius `23..38`, eye Y `7.8..15.5`, pitch `-6..13.5°`, focus Y `4.7..7.2`, FOV `33..50°`.
- Authored shot compression: radius `0.66`, height `0.58`.
- Venue focus bounds are consumed by the shared camera clamp.
- The shared final blended-pose clamp from 1.9.21 remains active, so unsafe host/previous poses cannot leak into the canopy during interpolation.
- Source-Waza camera poses are also constrained by the Relic venue contract before presentation.
- 1.9.22 Outskirts far-desert/sunset presentation remains unchanged.
- 1.9.21 Pyrite lower-bowl camera contract remains unchanged.
- Canonical arena identity, packed arena schema, extractor revision, audio, trainer, Pokemon and MoveFX caches are unchanged.

## Expected package gate

- 75 / 75 Lua files parse under `texluac -p`.
- 17 / 17 regression suites pass under `texlua`, including the new functional `RelicCameraSafetyTests.lua`.
- The new Relic test feeds an intentionally unsafe host camera and an intentionally canopy-high source-Waza pose through intro/passive/attack/damage/switch/faint paths and asserts the final camera never escapes the venue clean volume.
- ZIP root must contain `main.lua` and `manifest.json`, both reporting `1.9.23-relic-camera.1`.
