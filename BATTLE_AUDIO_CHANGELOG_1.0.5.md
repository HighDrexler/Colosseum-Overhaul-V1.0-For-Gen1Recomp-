# Colosseum Overhaul 1.0.5 — battle reward audio

- Source-backed Colosseum level-up fanfare for level-ups and successful in-battle move learning in Gen I and Gen II.
- Original Colosseum EXP-gauge effect, resolved from GameSound 1232 to general-bank SFX 975 / SoundMacro 390. The native 48 ms cycle loops while Gold's EXP bar moves; Gen I and bench rewards use bounded feedback at the gain message.
- Colosseum victory fanfare plays once per encounter. Fanfare serialization avoids overlapping level/victory melodies, and native music ducking resumes the selected battle track. Native map restoration remains authoritative.
- BATTLE SOUNDS setting: COLOSSEUM by default; ORIGINAL restores the host cues. SFX volume and mute remain authoritative, independently of the battle music setting.
- Three additional cue files, with per-file verification and resumable preparation. Valid model, arena, move-audio and v9 soundtrack caches are not invalidated.
- Four reusable static audio Sources are prepared before playback. Sound triggers do not read, decode, or construct Sources.
- Fixed absent-section handling in the MusyX SFX POOL parser and bounded layer counts. Absent keymap/layer offsets no longer reinterpret source headers as enormous layers.
- Complete merge over 1.0.4: shiny support, camera/cinematics, release orientation, Gen II loading/menu preparation, cache controls, Orre structures, Water audience, singles switch prompts/cancellation, and doubles top-card target selection retained.

No extracted Colosseum audio or disc data is added to this mod archive. Cue preparation uses the retained required source import.
