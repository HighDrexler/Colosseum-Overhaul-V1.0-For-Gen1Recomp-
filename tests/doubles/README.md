# Headless regression suite

Run from the supplied Gen1Recomp engine checkout, not from the mod directory.
Set `CBE_DOUBLES_MOD_DIR` and `CBE_DOUBLES_UI_DIR` to the extracted test mods.

```sh
POKEPORT_DATA_DIR=tests/fixture_data \
CBE_DOUBLES_MOD_DIR=/path/to/CBE \
CBE_DOUBLES_UI_DIR=/path/to/UI \
texlua /path/to/CBE/tests/doubles/RegressionTests.lua
```

The suite executes the actual Gen I and Gen II native move kernels and battle-end paths using ROM-free test fixtures. LÖVE graphics, audio and GPU-backed actors are stubbed. The bit compatibility shim is test-only. This is not a live rendering, frame-rate or device-compatibility test. Native loader smoke testing was performed separately on the full UI entry.
