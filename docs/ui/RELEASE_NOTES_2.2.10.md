# Colosseum Inspired UI Overhaul 2.2.10

- PC party/storage selection orange locator now sits in a dedicated gutter immediately left of the Pokémon portrait; the old orange footer that could overlap names is removed.
- 3D information-model manipulation now uses Gen1Recomp `input.pointer` for real mouse and touch events. PC models receive the same orbit/pitch and right-drag zoom behavior as Summary/Pokédex even while a modal PC state owns normal menu input.
- Model pointer hit rectangles are refreshed from the real window-space pod on every draw; stale hidden viewers cannot steal input.
- Crystal/Gen II native `MapNameSign.draw` is suppressed only while the custom AREA BANNER UI is enabled, preventing the vanilla location sign from appearing alongside the Colosseum banner. Turning the custom banner option off restores native rendering.
- Intended pair: CBE 1.9.5-information-ui-idle.1, which forces source idle-bank materialization for information actors after first-pixel display.
