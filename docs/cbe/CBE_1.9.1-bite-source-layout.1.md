# Colosseum Battle Environments 1.9.1-bite-source-layout.1

This update fixes the empty Bite presentation reported with Larvitar.

The live extractor-23 cache showed Bite (`kamituku`) as incomplete: its attack
Type-3 HSD effect was mistaken for a zero-sized shared particle, its Type-2
damage HSD size was read from the wrong descriptor word, and the resulting
resynchronization decoded arbitrary model bytes as Waza controllers. Parser 8
uses the verified GC6E01 layouts: Type-2 size at `payload+0x24`; normal and
mode-2 direct-GPT Type-3 prefixes; and the Type-3 embedded scene_data HSD form.

With the retained Bite source bytes, the corrected chain extracts a 2,229-vertex
attack effect model, a 2,853-vertex damage model, the direct GPT1 damage bank,
the authored Type-4 stages, controllers, and sounds. All three discovered Bite
phases parse completely with zero unsupported entries.

The cache compiler now also stores `timeline.name`. This prevents damage banks
from being classified as attack banks. Timeline queries require the same
complete-chain ownership check as sequence start, so a partial source table can
no longer disable Pokémon action playback merely because it contains rows.

Cache identity is extractor 24 / Waza parser 8. The MoveFX cache rebuild is
mandatory. Soundtrack, MusyX, Amuse, arena, trainer, capture, and Pokémon cache
identities are unchanged.
