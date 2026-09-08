# Colosseum Inspired UI Overhaul 2.2.3

## Gen I Pokédex 2.52 compatibility hotfix

- Restores the Colosseum Strategy Memo/Pokédex presentation on current Gen1Recomp Gen I builds.
- Gen1Recomp 2.52+ uses the dedicated `src.ui.PokedexMenu` CONTENTS state; 2.2.2 was still only adapting the older generic `ListMenu` path, which allowed Gen I to render fully vanilla.
- The dedicated Gen I Pokédex now stays native for input, scrolling, DATA/CRY/AREA actions and callbacks while the Colosseum UI owns only its presentation.
- Preserves the shared Pokémon presentation priority from 2.2.2: Colosseum models first when enabled, then Battle Art/current custom sprite providers, native ROM sprites last.
- Keeps Gen I SELECT location-page browsing on the Strategy Memo.
- Gen II Pokédex behavior and its working dedicated integration are unchanged.
