# CBE 1.9.20-arena-source-parity.1

## Scope
Deep source-fidelity/parity sweep for every CBE arena plus the final arena expansion.

### New source-backed arenas
- **Relic Cave** — `M3_cave_1F_1_bf.fsys` / `M3_cave_1F_1_bf.dat`
- **Outskirts** — `S1_out_bf.fsys` / `S1_out_bf.dat`
- **Pyrite Colosseum** — `M2_earth_colo.fsys` / `M2_earth_colo.dat`
- **Deep Colosseum** — `M4_bottom_colo.fsys` / `M4_bottom_colo.dat`

**Relic Chamber** remains the `M3_shrine_1F_bf` bonus arena from 1.9.19.

### Shared arena fidelity changes
- Source HSD arena cache revision 33 preserves render flags, source diffuse-light enable, vertex-color state, constant-color state, effect state and texture slot through both canonical Lua and packed runtime metadata.
- Original GC6E01 texture atlases are sampled without CBE synthetic sharpening. GX UV/wrap state and source material colors remain authoritative.
- Existing Water, Orre, Realgam and Mt. Battle source traversal/runtime envelopes are widened along with the new arenas so background architecture and venue depth survive the packed fast path.
- Runtime far-plane selection is derived from each arena's preserved source-shell radius instead of the older small-profile assumptions.
- New source venues receive a neutral source-owned material/fog profile rather than inheriting Realgam/Wildlands grading.
- Relic Cave and Deep use enclosed backdrop fallbacks; no outdoor sky is injected through scene-shell gaps.
- Relic Chamber keeps its complete source scene/backside. A camera-side elongated-object guard culls only a foreground obstruction between the camera and battle focus, addressing the giant trunk without deleting authentic room detail.
- Packed arena runtime schema advances from v2 to v3.

### Cache/compatibility contract
Arena marker advances to `cbe-arena=9` / `.cbe-arena-v9.complete`, but global extractor revision remains 15. The migration is arena-only and reuses healthy trainer, Pokemon, MoveFX, capture, HARD CACHE SAVE and canonical audio caches. Gen 1, Gen 2, external Pokemon model providers and CBE's arena independence rules are unchanged.
