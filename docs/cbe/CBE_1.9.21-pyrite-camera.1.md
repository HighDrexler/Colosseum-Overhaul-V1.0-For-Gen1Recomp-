# CBE 1.9.21-pyrite-camera.1

Focused Pyrite Colosseum camera correction built directly from 1.9.20-arena-source-parity.1.

## Pyrite Colosseum

The source venue geometry was already correct; the camera volume was not. Generic CBE master shots used roughly 55-65 world-unit camera radii and higher elevations. In Pyrite that places the lens in the spectator gallery, so railings, crowd cards, and upper architecture can fill the foreground even though the battle floor itself is correct.

This build gives Pyrite a venue-specific lower-bowl camera contract:

- host/fallback base camera moved inside the arena floor envelope (side 39 / back 12 / height 15.5)
- authored automatic shots receive 0.72 radial and elevation compression before safety clamping
- Pyrite camera radius is constrained to 24-43 world units
- camera eye height is constrained to 6.5-22.5
- maximum positive pitch is constrained to 19 degrees
- lens remains in the normal 31-50 degree source-style range
- source crowd/rail/architecture is NOT deleted to solve the problem; the camera is kept where the retail venue expects it to be

## Camera safety repair

A pre-existing lexical binding issue in `lib/Camera.lua` meant the combat readability guard could reference `arenaPoint` / `other` before their local bindings existed. The helper pair is now explicitly forward-declared and bound before runtime use.

A second boundary issue allowed the *target* shot to be safely clamped while the actual blended pose between the host base camera and that target could still pass through an illegal volume. The final blended pose is now re-clamped before being handed to the renderer. This is the specific path that could let Pyrite's opening/send-out camera begin in the balcony even after the destination camera was safe.

## Cache compatibility

No arena extraction, trainer, Pokemon, MoveFX, capture, audio, or hard-cache revision is changed. Existing 1.9.20 generated assets remain reusable; this is a runtime camera-only update.
