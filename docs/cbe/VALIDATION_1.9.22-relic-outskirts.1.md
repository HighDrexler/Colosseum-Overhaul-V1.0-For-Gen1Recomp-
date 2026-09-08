# CBE 1.9.22-relic-outskirts.1 validation

- Baseline: packaged `1.9.21-pyrite-camera.1`.
- Relic Chamber: broad alpha-tested/elevated canopy carriers now participate in camera-side occlusion trimming; rear scene geometry is preserved outside the active sight corridor.
- Outskirts packed source envelope: `sceneRadiusRaw=5200`, `maxGroupSpanRaw=14000`, `vertexRadiusRaw=5000`.
- Outskirts presentation: source battlefield + multi-ring desert continuation + warm late-afternoon/sunset sky/horizon/plateau backdrop.
- Arena packed runtime schema: v4 / `cache/runtime_mesh_v4/arenas/`.
- Canonical arena identity remains v9 and extractor revision remains 15, enabling the sidecar-only migration instead of disc/audio/trainer/MoveFX regeneration.
- Pyrite 1.9.21 lower-bowl camera contract remains present.

Static/package checks are executed after packaging. Live GC6E01 visual confirmation remains a device/runtime test because this environment does not contain the user's generated canonical arena cache or full Colosseum disc.

## Final packaged verification

- 74 / 74 packaged Lua files parse under `texluac -p`.
- 16 / 16 packaged regression suites execute successfully under the local headless Lua runner.
- ZIP integrity passes.
- `main.lua` and `manifest.json` are at ZIP root.
- `main.lua` and `manifest.json` both report `1.9.22-relic-outskirts.1`.
