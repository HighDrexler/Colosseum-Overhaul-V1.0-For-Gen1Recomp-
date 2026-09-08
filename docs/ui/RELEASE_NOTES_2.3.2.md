# Colosseum Inspired UI Overhaul 2.3.2

## 3D information-menu performance pass

This build targets the multi-second PC / Pokédex / Summary stalls reported when Colosseum 3D models are enabled. The problem was not only raw model complexity: the UI and CBE could both schedule expensive work onto the same main-thread menu frame.

### UI changes

- **No synchronous cold CBE acquisition from menu draw.** A non-resident CBE species now stays on the exact resolved 2D portrait while the resident model path is prepared. Older CBE builds also fail safe to 2D instead of forcing a cold draw-time load.
- **Cooperative CBE 1.9.18 bridge.** The visible 3D viewer leases CBE's resident scheduler so unrelated arena, trainer, MoveFX and other background jobs cannot land on the same menu input/audio frame.
- **High-churn list debounce.** PC and Pokédex wait for a deliberate selection before requesting a non-resident model, so held/rapid navigation does not prepare every row crossed.
- **One shared depth canvas per information surface.** Cached species no longer retain their own off-screen depth target. This sharply reduces accumulated VRAM/driver pressure during long PC/Pokédex sessions.
- **Bounded model-preview rendering.** Both generations use smaller private 3D targets and device/model-aware update/redraw caps. The final UI panel is still composited at its normal size.
- **No redundant CBE actor LRU.** CBE already owns the shared per-species GPU scene; UI-side stale actor handles are released when a species leaves the active surface.
- **Provider/platform hot-path caches.** Repeated provider discovery, OS queries and PC provider resolution are removed from ordinary display frames.
- **Fallback fidelity preserved.** While 3D is warming, the portrait is the same resolved Battle Arts / custom / native 2D source the UI would otherwise use, not a placeholder asset.

### Preserved from 2.3.1

- Gen I Save screen parity with Gen II.
- Gen I overworld dialogue cleanup.
- Gen I Pokédex LOCATION list presentation in place of the old map view.
- All battle presentation, gameplay, save logic and external sprite-source behavior remain unchanged.

### Recommended pairing

Use **CBE 1.9.18-ui-model-performance.1** for the full scheduler/hard-cache path. UI 2.3.2 remains fail-safe with older CBE versions, but it deliberately refuses to cold-load their non-resident models from a menu frame.
