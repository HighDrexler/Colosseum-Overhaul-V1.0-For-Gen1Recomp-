# Colosseum Inspired UI Overhaul 2.2.12

- **PC 3D viewer root-cause fix:** the PC continues to reuse the exact Pokédex CBE information-model actor slot, but the HUD ownership cleanup now recognizes PC/storage states as legitimate owners of that shared slot. 2.2.11/early 2.2.12 logic was releasing the Pokédex slot at the beginning of every PC HUD frame and reacquiring it later in the same frame, resetting animation time, orbit and zoom continuously.
- The selected PC model can now retain its source idle clock between frames and preserve mouse/touch rotation and zoom state exactly like the working Pokédex/Summary viewers.
- CBE ownership remains strict: with Colosseum Pokémon Models disabled or CBE unavailable, PC surfaces fall back to the active resolved 2D presentation.
- **Battle move header geometry:** the active Pokémon name is now fitted and vertically centered from the actual font metrics inside its dedicated upper tab. Large text profiles, window scaling and long names no longer push the label into the top divider.
- Keeps the 2.2.11/2.2.10 selector, dialogue, location-banner, PC-layout and cross-generation fixes.
