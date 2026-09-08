# Colosseum Inspired UI Overhaul 2.3.4

## Progressive-quality Colosseum model previews

2.3.4 keeps the static-first / scheduler-isolated information-model architecture from 2.3.3, but removes its largest visual compromise: a selected Colosseum model no longer remains permanently on the same low-resolution target used while rapidly scrolling.

- **Cheap scan tier stays fast.** Rapid PC/Pokédex browsing still uses the existing bounded low-resolution shared target, and CBE still does not synchronously extract a cold species from the menu draw path.
- **Sharper settled tier.** After a short deliberate-selection dwell (PC 0.30 s, Pokédex 0.26 s, Summary 0.16 s), the same already-resident model is repainted once into a sharper shared target before authored idle animation is promoted.
- **Desktop fidelity.** Settled previews can reach 92-100% of the information pod resolution, capped at 384 px. Material-heavy models use conservative 336 px / scale caps.
- **Android balance.** Settled previews use 64-72% resolution, capped at 256 px (224 px for very material-heavy models), retaining a meaningful quality improvement without returning to large per-row GPU uploads.
- **Two shared targets, not per-Pokémon canvases.** Every information surface keeps one scan and one detail target. The selected species owns the appropriate target, so quality promotion does not grow VRAM with browsing history.
- **Animation remains delayed separately.** The longer 2.3.3 authored-idle dwell remains intact (PC 0.90 s, Pokédex 0.82 s, Summary 0.62 s). Higher visual resolution is therefore available well before the UI asks CBE to animate a large idle bank.
- **Bounded redraw cadence.** Settled desktop models can render up to 30 Hz and Android up to 15 Hz, with lower caps for high material-group counts. User orbit/zoom remains responsive without making every static frame a full-rate render.
- **Source texture fidelity is untouched.** CBE continues to provide the full source model/material textures; 2.3.4 changes the UI render target and presentation cadence rather than lowering or replacing model assets.

When paired with CBE 1.9.31+, the UI uses the new explicit showroom animation gate. Older compatible CBE information actors retain the existing fallback path.
