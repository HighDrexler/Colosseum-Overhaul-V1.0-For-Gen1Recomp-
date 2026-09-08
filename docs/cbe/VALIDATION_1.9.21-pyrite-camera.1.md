# CBE 1.9.21-pyrite-camera.1 validation

Baseline: `ColosseumBattleEnvironments-1.9.20-arena-source-parity.1.zip`

## Pyrite source comparison target

The user-supplied Pyrite Colosseum reference shows retail cameras operating from the lower battle floor/bowl with the spectator galleries retained as background architecture. The reported 1.9.20 failure instead placed some cameras in the gallery itself, producing foreground railings and enormous crowd cards.

## Implemented camera contract

- `PYRITE COLOSSEUM` keeps the real `M2_earth_colo` source scene.
- Pyrite host/fallback base camera is now `side=39`, `back=12`, `height=15.5`, `lookY=5.8`, `frameH=30`.
- automatic authored shots apply `shotRadiusScale=0.72` and `shotHeightScale=0.72`.
- safe volume: radius 24-43, eye Y 6.5-22.5, pitch -9..19 degrees, FOV 31..50 degrees.
- final camera blends are clamped after interpolation, preventing an unsafe base/previous camera from crossing the gallery while blending to a safe target.
- combat readability helper bindings are repaired (`arenaPoint` / `other` forward binding).
- no source Pyrite crowd or architecture is removed as part of this fix.

## Executable checks

- `PyriteCameraSafetyTests.lua`: PASS
  - frame-zero intro pose stays inside Pyrite safe volume even when supplied an intentionally unsafe host base camera
  - early intro blend stays inside the lower bowl
  - completed intro pose stays safe
  - passive/command pose stays safe
  - attack pose stays safe
  - damage pose stays safe
- all packaged regression suites: PASS (15/15)
- all Lua files parse through `loadfile`: PASS (73 files before packaging docs)

## Cache boundary

No extraction/cache identity is advanced in this patch. 1.9.20 arena sidecars and all expensive audio/MoveFX/trainer/Pokemon/hard-cache data remain valid.

## Live-device boundary

Static/runtime harness validation proves the camera cannot enter the old Pyrite gallery volume under the covered intro/passive/attack/damage paths. Final visual composition should still be checked in a live Gen1Recomp battle because the full game renderer is not running in this container.
