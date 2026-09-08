# Colosseum Inspired UI Overhaul 2.3.3

## Static-first 3D information models

2.3.3 keeps the 2.3.2 performance architecture but removes the visible 2D-sprite handoff while CBE information models are being prepared.

- **No 2D flash during CBE model promotion.** When Colosseum 3D models own the PC / Pokédex / Summary information pod, that pod remains on the 3D path instead of briefly substituting the resolved sprite.
- **Static 3D first.** Once CBE's hard-cached compact body becomes resident, the real source model is drawn immediately in a frozen pose. Orbit / zoom interaction still works normally.
- **Animation only after deliberate dwell.** PC waits about 0.90 s, Pokédex 0.82 s and Summary 0.62 s on the same Pokémon before the authored idle animation is allowed to promote. Evolution / hatch use shorter dwell windows because they are not high-churn lists.
- **Static means static GPU work too.** Before promotion the model canvas is rendered once, then repainted only for explicit orbit / zoom input. The UI does not redraw the same frozen pose 12–24 times per second.
- **Rapid scrolling stays base-body only.** The non-resident body request debounce remains, slightly tightened so a deliberate selection reaches its static 3D model sooner while rows crossed during fast navigation are still discarded.
- **Hard Cache v2 is still valid.** No CBE cache-format change is required; this build is designed to use the compact body + idle sidecars already produced by CBE 1.9.18 Hard Cache Save v2.

True 2D fallback still works when no 3D provider is selected/available. Battle models, battle animation timing, gameplay, audio, save behavior, and all 2.3.1 Gen I parity fixes are unchanged.
