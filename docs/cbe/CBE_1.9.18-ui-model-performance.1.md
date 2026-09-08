# CBE 1.9.18-ui-model-performance.1

## Information-menu performance contract

1.9.18 is paired with Colosseum UI 2.3.2 and addresses the CBE side of long 3D information-menu stalls.

### Scheduler isolation

- A visible information viewer can hold a short **viewer lease**.
- While that lease is active, ordinary arena, trainer, MoveFX, party and other resident-prewarm jobs are held.
- Cached information-model promotion is the only viewer-safe scheduler job.
- Source extraction for an uncached species never runs while the information viewer is active.
- Authored `idle` sidecar baking is also deferred until the viewer lease has ended.
- PC/Pokédex requests are tagged by surface; a newer selection prunes an older queued species before it can consume a model upload.

### Correct background boundary

The normal resident scheduler now runs only while the actual top state is the live overworld. The old `not in battle + stack unchanged` condition also matched PC, Pokédex, Summary and dialogue screens, allowing unrelated model/arena work to freeze those menus. Two deliberate exceptions remain: the scheduler-filtered information viewer path and an explicit Hard Cache Save operation.

### Bounded information residency

Information browsing no longer grows the CBE `scenes` table without a desktop bound. Successful information warms keep the six party species plus a small recent working set and evict older GPU scenes while preserving generated disk caches. This prevents long PC/Pokédex sessions from turning into progressively larger VRAM/driver/GC stalls.

### Hard Cache Save v2

Hard Cache Save now builds a stronger persistent information-model cache:

- current party: base body + authored idle sidecar + required damage/faint/physical/special action sidecars;
- unique boxed species: base body + authored idle sidecar;
- existing MoveFX/Waza and generated-file metadata registry work remains intact;
- box-only temporary GPU scenes are trimmed during the build, so preparing a large collection does not make the whole collection resident in VRAM.

The completion marker is now `build/hard_cache_v2.complete`. A v1 marker from 1.9.17 is intentionally not treated as READY, so users upgrading to 1.9.18 should run **HARD CACHE SAVE once more**. After v2 reaches READY it remains persistent across normal relaunches, just like the previous hard cache.

Battle rendering, source PKX/Waza behavior, arena/camera behavior, canonical audio and gameplay logic are unchanged.

## Persistent cache lookup path

Information-menu cache-validity checks now route model-path existence through `GeneratedAssets`, so the persisted positive metadata registry from Hard Cache Save is actually consumed after a relaunch. A species that has been validated for the current extractor stamp is memoized for the process, avoiding repeated host-cache metadata probes while moving between PC, Pokédex and Summary.
