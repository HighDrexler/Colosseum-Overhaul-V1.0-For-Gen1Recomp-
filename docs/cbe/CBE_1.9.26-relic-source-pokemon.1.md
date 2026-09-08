# CBE 1.9.26 — Relic source rebuild / Pokémon presentation integrity

## Relic Chamber: source-first rebuild

Relic Chamber had become the only arena whose presentation was being held together by CBE-authored world-shell patches. The underlying source mapping was already correct (`M3_shrine_1F_bf.fsys` / `M3_shrine_1F_bf.dat`), but arena extraction was not honoring the complete HSD render-pass contract. That allowed helper/proxy/zero-pass and shadow-only geometry which the retail GameCube renderer does not submit to survive into CBE's ordinary stage mesh. Those carrier surfaces are the most plausible source of the giant foliage sheets, floating cliff/ceiling slabs, and other random foreground artifacts seen in the captures.

1.9.26 changes the canonical Relic extraction itself:

- enables native HSD JOBJ OPA/XLU/TEXEDGE render-pass filtering for Relic;
- filters DOBJ pass mismatches at the source-material level;
- quarantines dedicated shadow-pass material geometry;
- raises Relic extraction/traversal budgets so the full source scene is not cut short while removing helpers;
- expands the retained Relic packed scene envelope to `6000 / 16000 / 5800` source units;
- disables the synthetic `worldShell="forest"` route and its procedural ground/tree completion;
- keeps only a quiet atmospheric fallback behind holes in the real source shell;
- retains the projected foreground guard as a final readability backstop, not as the primary arena construction technique.

The camera is relaxed slightly from the aggressively constrained 1.9.23/1.9.24 setup because it now operates against a cleaner retail-style source scene instead of compensating for invalid helper geometry.

### Migration behavior

The canonical arena marker changes so an existing bad Relic cache cannot remain valid. On an otherwise complete modern ten-arena installation, `ArenaBuilder.repair()` rebuilds **Relic Chamber only** from the user's GC6E01 source, then regenerates arena runtime sidecars. Older/incomplete installs still take the full arena-source path. The global extractor revision remains 15, so this arena repair does not invalidate canonical audio, trainers, MoveFX, capture data, or unrelated arena source caches.

## Outskirts: final desert integration

The 1.9.25 low camera, widened `S1_out_bf` shell, distant mesas and broad sky are retained. 1.9.26 specifically addresses the remaining visible seam between the bright source battlefield and CBE's generated far desert:

- the Outskirts far-field/fog palette is pulled toward a much paler sand value;
- distance rings use a gradual pale-to-warm desert ramp rather than the darker mustard band seen in the previous build;
- the source stage remains authoritative; no replacement battlefield is painted over it;
- an extremely light deterministic blowing-sand pass adds slow horizontal streaks and a few tiny grains at roughly 1–2% opacity;
- the sand drift is screen-space and allocation-free, avoiding a heavy particle emitter on mobile/low-end systems.

## Articuno / split-part idle integrity

The reported Articuno failure is highly diagnostic: the head is present during attacks but disappears in idle. That points to an idle pose/part transform fault rather than missing source geometry.

Pokémon extraction advances from revision 34 to **35** and adds an idle-only isolated-part integrity check. A sampled idle pose is compared against a proven complete reference with identical topology. Only a small render group showing a severe rigid-part jump, collapse/explosion, high-part drop into the torso, or other implausible isolated transform is restored to its reference pose. Large body/wing groups are never eligible, and ordinary small appendage motion is left authored.

The repair is applied to:

- the selected base idle pose;
- idle frame zero;
- attached idle morph frames;
- dense idle page samples when present.

The logic is species-agnostic, so other split-part Pokémon receive the same integrity protection instead of Articuno being hard-coded by Pokédex number.

## Diglett / Dugtrio ground presentation

CBE's generic actor floor invariant previously translated an entire model upward until its lowest sampled vertex cleared the arena plane. That is correct for ordinary Pokémon, but wrong for source-authored burrowing bodies: it exposes geometry that is intended to remain underground.

Diglett (#50) and Dugtrio (#51) now receive a burrow-aware floor allowance. Their lower source geometry can remain below the battle plane while normal actors and reaction poses continue using the strict solid-floor clamp. This changes world placement only; it does not alter the extracted model or attack animations.

## Compatibility retained

- Gen 1 and Gen 2 CBE battle ownership remains unchanged.
- Pyrite's lower-bowl camera correction remains intact.
- Deep Colosseum and the 1.9.25 expanded source-shell treatment remain intact.
- Existing audio, trainer, MoveFX, capture and hard-cache identities are preserved.
- Pokémon caches refresh under extractor revision 35 as each species is needed / prewarmed / hard-cached so the idle integrity update can take effect.
