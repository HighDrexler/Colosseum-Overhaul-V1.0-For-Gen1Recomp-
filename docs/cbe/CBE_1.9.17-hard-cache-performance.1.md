# CBE 1.9.17-hard-cache-performance.1

## Performance objective

This release turns CBE's generated cache into a stronger runtime acceleration layer. The canonical GC6E01 extraction remains unchanged and presentation fidelity is not reduced. The new work moves additional conversion, registration, and lookup costs away from battle/menu transition frames and into an explicit paced overworld cache bake.

## Hard Cache Save

The Battle settings now include **HARD CACHE SAVE**. Running it scans the current save and queues a bounded deep-cache pass through `ResidentPrewarm`. It can be safely re-run after the party changes.

The pass performs these jobs incrementally:

- registers paths from the extractor-owned generated-path manifest without reading large asset bodies;
- loads/extracts the current party's CBE base Pokemon bodies when Colosseum Models are enabled;
- builds persistent float32 sidecars for the native damage/faint/physical/special action banks required by that party, then releases only the temporary action meshes;
- promotes the current party's MoveFX source specs;
- discovers the exact Waza Type-2/effect model caches referenced by those moves and backfills missing float32 runtime sidecars;
- persists `build/hard_cache_registry_v1.lua` and `build/hard_cache_v1.complete` when the pass finishes.

All jobs are executed by the existing stable-overworld scheduler. Android remains deliberately slower-paced than desktop so the cache operation does not become a new source of frame hitches.

## Cache hot-path cleanup

- `GeneratedAssets.info()` now keeps validated positive metadata in memory and can restore it from the persisted hard-cache registry on later sessions. Missing probes are not pinned forever, so extractor modules can still create a path later in the same process.
- `RuntimeMeshCache.readLua()` memoizes compact runtime metadata/manifests instead of re-reading and re-parsing the same Lua sidecars repeatedly. Writes and resets invalidate/update that memo correctly.
- Cache diagnostics reuse a short-lived inspection snapshot and no longer read the complete generated transition WAV body just to render status. The existing transactional v9 ledger/marker/existence checks remain the readiness contract.
- Waza runtime-sidecar validation no longer treats a missing host-provided byte-size field as proof that the sidecar is unusable. Exact byte/stride validation remains active whenever size metadata is available, and mesh creation still validates payload length.
- Future Waza extraction can create binary sidecars even on cache providers that support read/write but omit `info.size`.

## Mobile residency

Android's post-battle Pokemon resident set now protects all six player-party species. The old four-party guard could evict slots 5-6 and force a rebuild when the user later opened a model-heavy menu or switched to those slots. The working set remains bounded at ten species (six party priorities plus four recent species).

## Compatibility / fidelity contract

No presentation feature was removed. Gen 1 and Gen 2 behavior, CBE arena/camera ownership, external sprite/model-provider compatibility, trainer source animation, canonical 24/24 audio, Waza/PKX source timing, capture presentation, and all existing fail-open paths are retained from 1.9.16. Hard Cache Save also respects the Colosseum Models toggle: when CBE Pokemon models are disabled it does not unnecessarily extract/bake those Pokemon bodies.
