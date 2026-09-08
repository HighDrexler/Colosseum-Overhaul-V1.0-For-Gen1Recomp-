# Colosseum Inspired UI Overhaul 2.2.8

## PC focus geometry
- PC ACCESS selection plates are centered from the active font's measured height instead of fixed vertical offsets.
- The selected label now owns the middle of its focus plate across text profiles/scales.

## CBE PC showroom
- PC inspector is a first-class animated/orbitable showroom surface, using the same actor update + mouse/touch orbit path as Summary/Pokédex.
- Desktop PC models render at 60 Hz; Android keeps a bounded 30/36 Hz cadence on the private downsampled model canvas.
- Re-selected cached actors explicitly resume the source idle bank.
- PC actor LRU increased from 8 to 12 recently used species.
- If the CBE provider exposes `peek` / `acquireCached`, resident models bypass cold acquisition immediately.
- A 55 ms guard applies only to genuinely cold PC species so fast cursor repeats do not synchronously materialize every intermediate row.

## Preserved
- CBE 3D priority only when Colosseum Pokémon Models are equipped.
- Exact Battle Arts/custom/default 2D fallback when CBE models are off/unavailable.
- Evolution/egg CBE reveal paths from 2.2.7.
- Switch prompt, elevator floor listing, Mart TM/HM names, PC move/stat layout and all previous cross-generation behavior.
