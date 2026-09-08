# Colosseum Overhaul 1.0.7

- Fixed music note ownership: layers of one instrument no longer release each
  other, and different drum notes no longer collide through sample-pitch reuse.
- Preserved earlier authored note-offs and sustain-pedal release handling;
  keygroup hard stops use exact sample frames instead of mixer-block starts.
- Rerendered overloaded songs with constant headroom before PCM quantization,
  with one shared gain for intro and loop. No EQ, compressor or live DSP added.
- Reduced EXP bar and bar-end SFX gain by 25%.
- Reduced source-backed Pokémon release SFX gain by 15%, without reducing cries
  or unrelated attack effects and without cumulative attenuation on repeated use.
- Corrected the actual source Poké Ball front from the previously assumed -Z to
  verified +Z. Both trainers use the Pokémon's field-facing direction throughout
  send-out; the doubles open prop uses that same direction in both lanes.
- Removed the opponent send-out's arbitrary ball spin and routed its prop through
  the shared retail Poké Ball renderer. Capture ball rolling/shaking is unchanged.
- Added renderer provenance so reapplying HIGH replaces v1.0.6's cached audio.
- Retained the complete v1.0.6 package and previous gameplay/UI/arena/shiny fixes.

Install over the combined v1.0.6 package. Reapply HIGH under START > BATTLE >
AUDIO FIDELITY, confirm the next-launch update and restart. No full cache wipe.

Corrected code and source checks are not a certificate of original-game piano
fidelity; a listening/reference comparison remains necessary.
