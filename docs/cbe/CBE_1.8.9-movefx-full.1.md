# Colosseum Battle Environments 1.8.9-movefx-full.1

MoveFX hard-push test build based on the recovered 1.8.8 runtime.

This pass replaces single-bank/partial Waza ownership with complete authored-phase coverage and an all-or-nothing executable-chain gate. Source Waza types 1 through 6 now have concrete runtime paths: sequence controllers, embedded HSD models, GPT1 particles, procedural Type-4 effects, GameSound rows, and owner/model controllers.

Type-4 extraction now decodes all 13 GC6E01 effect descriptor families and preserves every embedded model/texture artifact. Serialized GStexture resources are converted through the source GX format/TLUT rules and cached as RGBA instead of being replaced by generic art. World-space runtime support now includes source-textured electron/lightning/TraceFX/billboard paths, source HSD leaf/effect models, and source-driven aura/surface behavior. Filter, blur, and distortion run as framebuffer post-process passes after the complete battle scene is rendered.

The MoveFX cache identity is bumped to v3 / extractor 21 / Waza parser 6. Existing v1/v2 MoveFX caches are not accepted. Fresh extraction writes `build/movefx_coverage.txt`, records the count of fully executable visual chains, and keeps native presentation ownership when any required source entry/artifact for a role cannot execute.
