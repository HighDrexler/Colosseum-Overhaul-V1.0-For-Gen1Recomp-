# Validation — 1.9.14-waza-runtime-repair.1

## Why this build exists

Recent live captures showed that individual MoveFX fixes were not producing proportional visual improvement. The root cause was systemic: source WZX archives were being discovered and cached, but the 1.9.x Waza parser had drifted away from the retail GC6E01 common-node layout. Multiple independent presentation fields were therefore wrong at the same time.

## Retail-backed corrections

The repair was cross-checked against the public GC6E01 decomp in `dougchansan/pkmn-colosseum`, principally `wazaSequence.c`, `wazaSequenceEntry.c`, `wazaSequence_exact_801DBB10.c`, `sequence.c`, and `gs_range_801DE698.c`.

The restored serialized common-node fields are:

- `+0x08` linked/anchor entry key
- `+0x0C` local timing-point index
- `+0x10` anchor/global timing-point index
- `+0x14` timing/loader index
- `+0x18` retained source state/resource-link field
- `+0x1C` flags
- `+0x20` attachment selector
- `+0x24` part index
- `+0x28` position mode
- `+0x2C..+0x68` sixteen source timing points

The serialized common header also has the retail variable sizes: normal `0x70`, mode 1 `0x6C`, mode 2 `0x68`.

The WZX sequence root/sentinel is now preserved before numbered entry 1. Its sequence kind and flags are retained. Retail `wazaSequenceStart` copies the sequence kind into the Pokemon owner's PKX animation-table index before `wazaSequencePokemonMotionStart`; CBE now uses the same source selector for attack and damage chapters.

## Runtime behavior corrected

- Dependency timing uses the restored link/local/anchor fields.
- Forward-linked entries resolve before scheduling.
- Negative authored starts normalize the whole chapter instead of being individually clamped.
- Type-1 modes 1/2 no longer behave as fake timed sequence stops.
- Type-3 remains a particle-bank resource path; nested GPT1 resources are correlated to the exact Type-3 row.
- Type-2 and Type-4 model artifacts keep their dedicated HSD model paths.
- Attack WZX sequence kind selects the matching PKX body row.
- Damage WZX sequence kind selects the matching target PKX reaction row, including queued multi-hit reactions.
- Waza transforms run in source-strict geometry mode and use the active PKX row's body-map anchors.

## Cache behavior

- `MoveFXExtractor.revision = 27`
- `WazaSequenceExtractor.revision = 10`
- `PokemonExtractor.revision = 33`
- canonical soundtrack cache remains v9 and is not invalidated by this build

The intended first-run migration is therefore MoveFX/Waza-only. Existing v9 music/SFX audio cache data remains reusable.

## Static validation

All Lua chunks compile under the local LuaTeX Lua runtime. The following regression suites pass from the release tree:

- `AudioParityContractTests.lua`
- `BattleExitBoundaryTests.lua`
- `HSDScaleTests.lua`
- `MoveFXAttackHandoffTests.lua`
- `MoveFXSourceChainTests.lua`
- `PokemonReactionQueueTests.lua`
- `WazaSfxMappingTests.lua`

New/expanded assertions cover:

- retail Waza common-node offsets and variable common sizes
- WZX root kind/flags retention
- forward dependency timing
- missing dependency rejection
- source WZX kind -> attacker PKX slot selection
- source WZX kind -> target Damage/Damage-B slot selection
- queued multi-hit reaction preservation
- Type-3 particle-bank ownership instead of the superseded direct-HSD interpretation

## What this does not certify

This build should materially change broad move execution because it repairs the common data contract shared by all Waza chapters. It is not yet proof of complete 1:1 presentation. Remaining known source-parity work includes:

- retail battle-camera pattern/state-machine reproduction rather than CBE's current source-informed camera approximation
- unresolved/fuzzy Type-4 and owner-controller semantics
- complete PKX material/texture animation playback where present
- exact source animation start-frame/repetition behavior where the decomp is still fuzzy
- live GC6E01-vs-CBE capture comparison for per-move timing, scale, orientation, camera, screen filters and sound
- waveform-level MusyX comparison on Windows and Android before claiming absolute audible 1:1 parity

The release should therefore be judged first on whether previously skeletal moves now execute more of their authored sequence graph consistently across unrelated move families.
