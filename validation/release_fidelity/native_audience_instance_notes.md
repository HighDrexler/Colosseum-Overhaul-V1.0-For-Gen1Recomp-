# Native audience instance validation

Final visual inspection exposed an additional Water defect beyond the removed crowd sway: two banks floated above their balconies because the extractor interpreted `JOBJ_INSTANCE` references as ordinary child hierarchies. It included the referenced root's siblings, applied the template root transform again, and suppressed later instances through global deduplication.

The native rule is documented by [`HSD_JObjDispAll`](https://raw.githubusercontent.com/doldecomp/melee/master/src/sysdolphin/baselib/jobj.c): instance rendering uses the instance world matrix relative to the referenced target world matrix, and dispatches only that target subtree. Ordinary templates also remain visible when reached through their genuine owning hierarchy. The extraction agent implemented this through `nativeSceneInstances`, enabled only for source arena extraction.

The complete retail audit found eight instances in Water and two in Deep; all other eight retail arenas have none. Water has 140 cards across its eight instances plus 57 cards from normally owned templates, for 197 source cards. The old 57-card output represented three incorrectly placed template banks, not the complete native audience.

Independent validation did not reuse the production matrix or traversal code. `water_native_expected.lua` reads the raw source parent/target SRT values and analytically applies their Y rotations to the saved prior source geometry, producing the expected 197 cards. `water_native_reference_test.lua` passes 11,231 assertions for actual extraction placement, topology, source atlas, UV, and row data. Maximum XYZ difference is 0.000010703 raw units from cache decimal serialization.

`water_native_grounding_test.lua` intersects each card's bottom edge with actual submitted source support triangles. 196 card bottoms meet the source support within 0.65 raw units (0.1625 rendered world units); the remaining bottom is embedded beneath a source stair tread within one authored four-unit riser. No card is unsupported above its source architecture.

Four actual LÖVE views show the formerly floating center bank inside its correct balcony, with the additional native banks present around the venue. Independent-reference and production GPU images match exactly in views 1–2; views 3–4 differ by only one and ten pixels, respectively, each by one color level from decimal serialization. Source and packed rendering match pixel-for-pixel in all eight checked Water/Deep views. Deep's four views retain their prior presentation; only a small native-instance detail at the top edge of view 3 changes.

Evidence files: `arena_instance_audit.tsv`, `water_native_reference_test.lua`, `water_native_grounding_test.lua`, `water-native-complete-production-1..4.png`, `water-native-complete-packed-1..4.png`, `deep-native-complete-production-1..4.png`, and `deep-native-complete-packed-1..4.png`. These private source-derived diagnostics are not release assets.
