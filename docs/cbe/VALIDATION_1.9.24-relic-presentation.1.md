# CBE 1.9.24-relic-presentation.1 validation

## Baseline / scope

- Baseline: `1.9.23-relic-camera.1`.
- User runtime reference inspected: 12.73-second Relic Chamber capture (`ac6a9941-ff19-4199-aa94-4a3542bf5f92.mp4`).
- Scope is Relic Chamber presentation only. Outskirts 1.9.22 and Pyrite 1.9.21 remain intact.
- No canonical arena extraction/cache identity, trainer/Pokemon/MoveFX/capture cache, hard-cache identity, or canonical audio identity is bumped.

## Confirmed presentation corrections

- Relic camera base moved lower/tighter: side 33, height 10.2.
- Venue camera safety volume: radius 24..34, eye Y 6.8..11.5, pitch -5..10.5 degrees, FOV 34..48 degrees, focus Y 4.6..6.35.
- `lib/RelicPresentation.lua` projects all eight corners of candidate source-group AABBs into the current camera frame.
- Only oversized elevated source-cutout / broad-horizontal / thin root-bark carrier candidates on the camera side of the battlers can be omitted.
- Culling is based on actual overlap with a protected battle viewport rather than carrier-centre distance alone.
- Rear shrine foliage/roots and ordinary source architecture are explicitly retained by the classifier.
- `Arena.lua` applies the projected-view guard to the normal opaque/cutout/transparent/additive group paths through the shared `drawGroups()` seam.
- Source-Waza camera targets and final interpolated camera poses remain constrained by the Relic venue safety volume.

## Executable/static validation

- Lua parse: 77 / 77 packaged `.lua` files pass `texluac -p` in the working tree.
- Regression suites: 18 / 18 pass under `texlua`.
- New `RelicPresentationCleanupTests.lua` proves:
  - a broad camera-side source canopy carrier is culled;
  - the same class of carrier behind the battlers remains;
  - small source cutout detail remains;
  - ordinary opaque architecture remains.
- Existing `RelicCameraSafetyTests.lua`, `RelicChamberArenaTests.lua`, `RelicOutskirtsPresentationTests.lua`, `PyriteCameraSafetyTests.lua`, audio, MoveFX, trainer, cache and battle-exit suites all pass.
- `main.lua` and `manifest.json` both report `1.9.24-relic-presentation.1`.

## Runtime boundary

This environment cannot execute the user's live Gen1Recomp + GC6E01 renderer, so the final on-device visual A/B remains the user's test. Unlike the prior centre-ray guard, this pass is specifically constructed around the artifact shape visible in the supplied capture: very broad off-centre foliage/root carrier sheets whose projected geometry covers a large part of the frame.
