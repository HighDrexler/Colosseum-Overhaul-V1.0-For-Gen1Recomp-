CameraFX Test 2 — secondary-status hotfix

Replace the previous CBE ZIP with this build and restart the game. Keep the existing UI and source cache; no extraction rebuild is needed.

Fix: Gen I doubles replaced native animNext with a no-op returning nil. EffectRegistry.lua:105 annotates the returned animation row when a player's damaging move inflicts burn, freeze or paralysis; poison also expects a row on either side. The adapter now returns a fresh native-shaped animation record without adding singles HUD animation rows to the doubles presentation queue. Native status, damage and PP logic remains intact.

The exact line-105 error was reproduced before the fix. Regression cases now exercise burn, freeze, paralysis and poison from both attacking sides through the real native move pipeline, checking recipient status, damage, PP, partner isolation and no extra singles status HUD rows. Native Gen I/II integration passes 242 assertions; presentation/UI tests pass 382 assertions. All Lua parses and 31 focused suites pass. Full installed-game playback has not been repeated.

All CameraFX Test 1 changes are retained byte-for-byte outside this adapter fix, version metadata and tests. See CAMERAFX_TEST_1.md for free-look controls, release cries, camera/FX changes and remaining fidelity limits.
