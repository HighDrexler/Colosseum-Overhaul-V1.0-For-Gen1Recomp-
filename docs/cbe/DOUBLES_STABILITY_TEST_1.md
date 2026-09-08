Doubles Stability Test 1

Install
Replace the previous CBE ZIP and restart the game. Keep the existing doubles-items UI and imported source cache. No source rebuild is needed. All CameraFX Test 2 presentation changes, release cries, automatic progression, item support and the secondary-status crash fix remain included.

Fixes
- Item execution now safely refuses missing inventory rather than crashing when the inventory table is absent. Stock and target conditions are still rechecked at execution.
- Gen II DIRE HIT/GUARD SPEC already active on the chosen Pokemon are rejected during selection, before committing an action.
- Gen II Full Heal-family item previews no longer create volatile state on the real Pokemon. Confusion-only cures remain usable.
- Forced replacements check the requested slot and occupant identity as well as battle/turn/ticket and party eligibility.
- Gen II trapping effects record the source battler identity. When that source withdraws (including faint removal), its target's wrap lock and residual damage state are cleared. Traps belonging to the other active Pokemon remain intact. Switching the trapped target still clears its own volatile state normally.

Sweep and validation
Native Gen I/II integration passes 930 assertions, up from 242. The new matrix runs 345 cases covering available Gen II fixture moves and Gen I primary/secondary effect families from both sides; item families at active-left, active-right and bench positions; voluntary switches; dual player faints and forced replacements; target-slot continuity after switches; preserved partner stat stages; missing/depleted inventory; changed item targets; no-effect items; status gates over multiple action/residual cycles; confusion-only cures; and trap-source switching. The matrix includes candidate move/item rows excluded by the adapter's existing support rules; it is not 345 distinct fully supported moves. Fixtures use native effect code, not the user's full generated game data.

The missing-inventory crash and persistent trap after switching were reproduced before fixes. Gen I/II presentation/UI tests pass 382 assertions; all CBE Lua parses and 31 focused presentation/FX suites pass. No rendering code changed, so previous GPU results apply to the retained renderer; GPU extraction was not repeated just for this logic patch.

Limits
This is a substantial regression sweep, not proof that every mod combination or battle scenario is crash-free. Full installed-game playback remains unverified. Existing explicitly unsupported special move flows remain unavailable (e.g. Baton Pass, Transform, several copying/delayed/cross-action moves); this build does not silently claim to implement them. Please test a normal battle including a switch, status cure, PP item and forced replacement with the actual installed UI/mod stack.
