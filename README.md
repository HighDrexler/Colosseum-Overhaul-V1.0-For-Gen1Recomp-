# Colosseum Overhaul 1.0 for Gen1Recomp

**Current release:** 1.0

Colosseum Overhaul is the combined Colosseum Battle Environments + Colosseum-inspired UI package for Gen1Recomp, targeting both Gen I and Gen II.

This repository is the canonical home for the true **1.0** combined release. The release package keeps CBE arena/camera/battle presentation and the Colosseum UI in a single mod ID (`COLOSSEUM_OVERHAUL`) so users should not enable the older standalone CBE/UI packages alongside it.

## 1.0 startup/cache behavior

- Existing generated model caches persist across launches.
- When at least 30 valid cached model units already exist, the Battle Cache chooser offers **REUSE CACHE** as the top option instead of forcing another 30-model Quick Start batch.
- Quick Start remains an explicit batch of up to 30 new model units.
- Full Catalog remains optional.
- The UI no longer flashes `MODEL ERROR` during the short handoff before a Colosseum model is drawable; the model cell remains empty until presentation is ready.

## Installation

The repository is being populated from the validated 1.0 release build. Once the release tree is complete, download the repository ZIP and install the folder/package through Gen1Recomp with `main.lua` and `manifest.json` at the package root.

Keep your existing Colosseum source import and generated cache when updating. Do **not** clear the cache unless troubleshooting a genuinely invalid cache.

## Release identity

Validated release archive SHA-256:

`0d4c5a58e9155d6dcf9363d4586256c6d5ddf18e74ea2345cf48790bcd311699`

The source package identifies itself as version `1.0` and mod ID `COLOSSEUM_OVERHAUL`.
