# CBE 1.9.28 — Relic Chamber source-forest 360 fidelity pass

## Scope

This pass is intentionally narrow: **Relic Chamber**. The 1.9.27 Outskirts lock, Pyrite camera safety, Deep Colosseum fidelity work, Pokemon presentation fixes, MoveFX/audio/trainer systems and existing cache identities are preserved.

## Relic Chamber — 360 source-asset closure

- Keeps the real retail `M3_shrine_1F_bf` scene as the canonical arena.
- Keeps the 1.9.27 HSD render-pass/shadow filtering, extraction-time central-overhang rejection, projected foreground foliage guard and low inner-clearing camera volume.
- Removes the old screen-space fake/cardboard treeline used to hide reverse-angle gaps.
- Builds the missing 360-degree forest closure from the **already extracted source arena itself**:
  - compact vertically dominant opaque groups are selected as source trunk/root motifs;
  - compact binary-alpha groups are selected as authentic source foliage motifs;
  - small source root/rock/forest-floor groups are reused sparsely as understory detail;
  - giant horizontal/overhead carrier sheets are explicitly ineligible for the closure.
- Reuses those authentic HSD meshes in two staggered deterministic rings outside the battle camera volume:
  - inner source-forest ring: 14 placements around ~86 world units;
  - outer source-forest ring: 18 placements around ~145 world units;
  - position, scale and yaw are varied deterministically to avoid a repeated wallpaper cadence.
- The nearest closure geometry remains more than twice Relic's legal camera radius (`36`), so these trees can only act as **background** scenery and cannot reintroduce the branch/leaf-in-camera regression.
- Original source geometry renders afterward into the same depth buffer, so the authentic shrine/near trees remain authoritative wherever they exist.

## Sky / lighting / depth

- Relic's static backdrop is now **sky-only**, with no painted tree sprites.
- Daylight sky is lifted to a clearer Agate blue with a soft green-gold horizon and thin high clouds.
- Only very low-opacity horizon haze remains behind the 3D forest shell to hide the mathematical far-field seam.
- Relic source lighting is slightly brighter and more directional so bark, roots and foliage retain source texture detail instead of collapsing into a dark green wall.
- Distance fog is pushed farther out and changed from near-black green to a daylight forest haze, preserving depth across the new outer tree rings.

## Cache / migration behavior

- No new GameCube disc extraction is required.
- Canonical arena identity remains `cbe-arena=9` / source HSD scene v33.
- Global extractor revision remains `15`.
- Packed arena runtime sidecars remain format `6`.
- Existing Relic source cache, Outskirts cache, audio, trainers, Pokemon, MoveFX, capture and Hard Cache Save remain reusable.

## Validation boundary

The package validates the source-forest selection and 360 render contract statically, preserves all existing camera/foreground-occlusion regressions, and passes the complete packaged test suite. Live Gen1Recomp rendering remains the authority for final visual spacing/density of the newly repeated source tree motifs.
