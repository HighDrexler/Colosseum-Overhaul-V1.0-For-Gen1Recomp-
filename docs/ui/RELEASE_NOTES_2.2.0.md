# Colosseum Inspired UI Overhaul 2.2.0

## Performance / cleanup
- Gen I Pokédex Strategy Memo no longer runs through the legacy donor-screen color adapter; 3D provider draws reach their private canvas directly.
- Resident information-model actors now stay on a true hot path: provider discovery, Dex-number resolution, information-context creation, and camera matrix construction are reused until their actual inputs change.
- The active CBE Colosseum information provider is cached for the current presentation epoch while per-species availability remains provider-owned.
- 3D menu preview canvases update at a bounded 60 Hz and are reblitted between ticks; orbit/zoom invalidates immediately.
- Removed the redundant provider `available()` preflight before `acquire()`, avoiding duplicate cache/filesystem probes.
- Gen I Pokédex encounter rows, Strategy Memo metadata, description wrapping, preview-mon wrappers, text metrics, UI options, and layout metrics are cached with bounded/event-driven invalidation.
- Battle Arts/custom sprite provider settings and display-mode resolution reuse the same presentation epoch.
- Repeated battle HUD option reads now use the shared cached settings facade.
- Confirmed-dead legacy Pokédex renderers and an unreachable Gen II entry repaint were removed.
- Old release-note/validation debris and the packaged `main.lua.bak` were removed from the distributable.

## Preserved behavior
- Gen I and Gen II support.
- Shiny sprite/model handling and CBE shiny variant requests.
- CBE, Stadium/portable 3D, Battle Arts, Crystal/custom, and vanilla presentation fallback rules.
- 3D model viewers in Stats/Summary and Pokédex.
- Custom Egg presentation.
- Gen I player/rival naming and intro-flow fixes.
- Fixed-size battle HP cards with collision-safe internal metrics and font-aware battle menu selectors.
- Universal Gen II battle-overlay widescreen inheritance for Bag, Party, Summary, Pokédex, naming, dialogue, item targeting, move learning, and other overhaul-owned transparent battle UI.

CBE is not bundled or modified by this release.
