# Colosseum Inspired UI Overhaul 2.2.11

- PC 3D actors now advance their source actor clock every visible UI frame instead of tying animation updates to the private canvas redraw throttle.
- PC/storage restores the same direct read-only LÖVE mouse/touch polling already proven by Summary and Pokédex. Left-drag rotates, right-drag zooms, middle-click resets, and one-finger touch orbits inside the model pod.
- The 2.2.10 `input.pointer` wrapper is no longer registered for information models because modal PC/storage states can consume that event before the replacement renderer receives it.
- Fallback party/storage icon renderers are always asked to draw unselected art; selection is represented only by the dedicated orange locator immediately left of the portrait, preventing the old duplicate orange mark from overlapping the Pokémon name.
- Native Gen II location-banner suppression from 2.2.10 remains intact.
- Intended pair: CBE 1.9.6-pc-idle-audio-exit-latch.1, which fixes the CBE dense idle-page loop itself.
