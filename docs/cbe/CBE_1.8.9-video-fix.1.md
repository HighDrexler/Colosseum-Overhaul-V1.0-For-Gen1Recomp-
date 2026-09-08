# Colosseum Battle Environments 1.8.9-video-fix.1

Targeted test build for the supplied MoveFX reference video.

- Preserves the retail GPT1 `PSParticleScript.animIndex` container selector instead of flattening all particle textures in a bank.
- Resolves particle imagery as bank -> source container -> source texture index, preventing one generator from wrapping into unrelated particle artwork.
- Bumps MoveFX extraction revision to 22, forcing a fresh source-backed MoveFX cache.
- Source-backed Waza attacks no longer render a guessed generic Physical-A/Special-C clip when an exact motion selector is unavailable; PKX timing is retained while the battle-facing base pose remains stable.
