# Colosseum Battle Environments 1.9.6-pc-idle-audio-exit-latch.1

This baseline is carried forward unchanged into 1.9.7 except for the
Pokémon action morph-stream packing correction documented in
`CBE_1.9.7-pokemon-action-pack-layout.1.md`.

Test candidate focused on three user-visible regressions without changing battle logic:

1. **PC/information-model motion** — dense source idle pages now loop continuously instead of freezing on the final GPU page.
2. **Cross-platform soundtrack fidelity** — portable MusyX v7 keeps the stable v6 mixer but restores proven retail packed continuous pitch/mod decoding and related source timing/controller semantics. Old portable soundtrack assets are audio-only invalidated and regenerated. Windows Amuse cache identity is also refreshed.
3. **Battle-end native flash** — CBE presentation is retained through the real battle-to-overworld screen handoff and released only after the transition has captured/owned its source frame.

Pair with **Colosseum Inspired UI Overhaul 2.2.11** for the PC viewer's direct mouse/touch orbit and zoom path.
