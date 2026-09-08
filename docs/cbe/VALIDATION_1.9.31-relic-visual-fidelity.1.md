# Validation — CBE 1.9.31-relic-visual-fidelity.1

Validation is code/package-level. Live GC6E01 rendering on the user's device remains the acceptance test for final visual parity.

## Static and regression validation

- PASS: all 85 packaged Lua files parse with LuaTeX/texlua `loadfile()`.
- PASS: all 26 packaged regression suites.
- PASS: manifest and `main.lua` report `1.9.31-relic-visual-fidelity.1`.
- PASS: Pokémon extractor remains revision 36; the removed 1.9.26 global idle-group rewrite is not reintroduced.
- PASS: global extractor revision remains 15 and Hard Cache v3 contract is unchanged.
- PASS: complete-install arena repair is isolated to Relic Chamber.
- PASS: Relic source envelope is `7800 / 20000 / 7400` in both extraction and runtime catalog contracts.
- PASS: Relic forest completion uses a coherent 180-degree source half rather than the 1.9.28 four-trunk/five-foliage ring replication.
- PASS: low source ground/root/rock/understory detail is retained for sparse perimeter depth.
- PASS: denser seven-ring low-relief continuity land, restrained dapple lighting and clearer Relic fog contract are present.
- PASS: existing Relic camera-volume and projected foreground-occlusion protections remain present.
- PASS: Deep Colosseum 1.9.30 fidelity contract and separate Outskirts work remain present.
- PASS: information-model bridge v6 exposes only showroom animation gating; live battle animation paths are not changed by that bridge.

## Regression suite result

`26 PASS / 0 FAIL`

The suite covers arena parity, audio contracts, battle-animation rollback, battle exit, Deep Colosseum fidelity, hard-cache scheduling, information-menu performance, MoveFX source/runtime chains, Pokémon presentation/reactions, Pyrite camera safety, Relic camera/presentation/source/fidelity contracts, trainer source caching and Waza SFX mapping.
