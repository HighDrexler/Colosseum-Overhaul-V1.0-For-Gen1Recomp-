# Colosseum Inspired UI Overhaul 2.2.9

## PC ACCESS focus correction
- The selected row and its text are now laid out from one measured font row.
- The font is fitted to the available row height before the highlight is drawn.
- Both the highlight rail and glyph top are centered inside the same row, fixing the vertical drift visible on BILL's PC / CARL's PC / PROF. OAK's PC.

## Pokédex model latency correction
- Removed the deliberate 160 ms cold-row dwell from Pokédex 3D acquisition.
- A selected Pokédex species now begins provider acquisition immediately.
- Resident CBE actors still use `peek` / `acquireCached` first.
- PC retains only a 35 ms repeat-key guard for genuinely cold rows.

## Paired CBE path
Use with CBE 1.9.4-information-ui-motion-cache.1. That build avoids source-disc PKX metadata inspection for read-only information viewers and materializes the cached idle bank when a base scene has no animation samples, so PC models animate without changing battle motion behavior.
