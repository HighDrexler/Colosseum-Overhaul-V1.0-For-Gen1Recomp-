# CBE 1.9.27 — Relic Chamber + Outskirts fidelity lock

## Scope

This pass intentionally changes only the two arenas still failing the source-presentation bar: **Relic Chamber** and **Outskirts**. Pyrite, Deep, Water, Orre, Realgam, Relic Cave, Wildlands and Mt. Battle retain their current contracts.

## Relic Chamber

- Keeps `M3_shrine_1F_bf` as the canonical retail source.
- Expands retained source limits to `7200 / 18000 / 6800` for scene radius, maximum group span and vertex radius.
- Honors HSD render-pass visibility and skips shadow-only materials during canonical extraction.
- Adds an extraction-time protected battle cylinder (`battleClearRadiusRaw=300`) that rejects only broad, thin, elevated geometry whose source bounds physically cross the battle core. This targets the giant canopy/branch/cliff carrier sheets without deleting perimeter trees, roots or architecture.
- Tightens the arena-specific camera to a lower inner clearing: shot radius scale `0.60`, height scale `0.42`, max radius `36`, max eye Y `13.5`, max pitch `11.5°`, and a narrow focus-height band.
- Applies the same safe-volume correction to ordinary choreography, source-Waza targets and final interpolated poses.
- Strengthens the projected-frustum foreground guard: camera-side cutout foliage/branch cards are rejected based on their visible footprint rather than object-center rays. Rear foliage and vertical architecture remain.
- Adds a continuous forest-floor extension beneath the authentic source scene so legal angles cannot expose a square island edge.
- Replaces black/flat fallback gaps with a daylight blue sky, thin high clouds, two distant treeline layers and low forest haze. This closure is camera-azimuth independent and sits behind the source HSD scene.

## Outskirts

- Keeps `S1_out_bf` as the canonical opening-battle source.
- Expands source and packed-runtime limits to `16000 / 42000 / 15000`, retaining substantially more distant source dressing.
- Enables retail render-pass and shadow-only filtering for Outskirts canonical extraction.
- Preserves the low/horizontal opening-battle camera contract introduced in 1.9.25.
- Reconciles the source battle pad and far desert in the arena shaders themselves. Low upward-facing fragments on both desktop and mobile are graded toward a common sand target while retaining source texture luminance/detail, eliminating the pasted-white-tile vs yellow-background split.
- Extends the desert through five depth rings out to radius `12800`, with flatter near terrain and restrained distant dune relief.
- Keeps the cobalt Orre sky, broad soft cloud banks, warm horizon, restrained sun and low continuous mesa line.
- Increases the deterministic sand drift enough to read in motion while keeping opacity extremely low; no heavy particle emitter is introduced.

## Migration / compatibility

- Canonical arena identity remains `cbe-arena=9`; changing its marker payload invalidates the old Relic/Outskirts presentation contract without touching the global extractor.
- Complete modern installs run `relic-outskirts-only` canonical refresh and re-extract only those two arenas from the user's GC6E01 source.
- Arena packed runtime sidecars advance to **format 6** / `cache/runtime_mesh_v6/arenas/`.
- Global extractor revision remains **15**.
- Existing trainer, Pokémon, MoveFX, capture, hard-cache and canonical audio identities remain reusable.
- 1.9.21 Pyrite lower-bowl camera safety remains intact.

## Validation boundary

Static/runtime-contract regression verifies the extraction policies, camera bounds, projected Relic foreground guard, 360 environment closure, Outskirts floor reconciliation, sand drift, migration isolation, packed sidecar format and unrelated cache identities. A live GC6E01 render is still the final visual authority for exact source-scene appearance.
