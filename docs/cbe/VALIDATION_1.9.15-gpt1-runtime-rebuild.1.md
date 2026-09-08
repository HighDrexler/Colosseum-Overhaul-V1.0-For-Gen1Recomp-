# CBE 1.9.15-gpt1-runtime-rebuild.1 validation

## Why this build exists

1.9.14 repaired several outer WazaSequence assumptions but live presentation barely changed. A full LÖVE 11.5 / Gen1Recomp VM test with the supplied Yellow ROM/save exposed that the remaining failure was systemic and downstream: WZX serialized records were still being read from the wrong locations, GPT1 was still translated into a synthetic emitter runtime, and extracted PKX native action pages were rejected by a render-group topology mismatch.

## Real source corpus gate

The GC6E01 CISO was replayed directly through the corrected WZX parser.

- WZX files parsed: **627/627**
- Serialized entries parsed: **2,825**
- Source moves found: **251/251**
- Fully executable visual chains: **232/251**
- Unique GameSound IDs: **403**
- Malformed WZX files after correction: **0**

The broken pre-fix parser produced only **70/251** fully executable chains and **5** distinct GameSound IDs. One concrete example was a sound row containing a real GameSound ID such as 457 being shifted and interpreted as sound ID 2.

## WZX root/layout repair

Retail WZX sequence metadata is rooted at file offset 0. Numbered entries begin later, after the fixed header and aligned embedded resource. CBE had incorrectly promoted numbered entry 1 to the sequence root. This corrupted `sequenceKind` and other root semantics even after common-entry offsets were partially repaired.

The corrected parser preserves the actual root and reads typed payloads from their proper post-common-record locations. Dig's source root resolves to sequence kind 3, which maps to Charizard's `physicalB` source PKX action instead of the erroneous `idle` selection.

## GPT1 runtime rebuild

The old runtime effectively performed:

`Waza Type-3 -> parsed record -> synthetic CBE emitter -> guessed particle bytecode`

The rebuilt runtime follows:

`Waza Type-3 -> PSGeneratorState -> source emission -> PSParticle -> particle bytecode`

Key changes include:

- FieldParticleFile `description`, object/texture data and bank-data lookup sections retain their retail roles.
- Generator identity is the real bank-local script ID.
- The old fabricated per-script REF identity table is removed.
- Generator `maxLife`, particle repeat/lifetime, emission rate, gravity, friction, velocity, radius, angle, particle size and shape fields are sourced separately.
- Child generator/particle references use bank-local scripts and source lookup tables.
- AC consumes time + two floats; F1 consumes u16 table index + u8 argument; F2/AA/F1 table dispatch follows source lookup semantics.
- Unknown/unresolved runtime cases are recorded as faults instead of silently inventing a replacement program.

## Native PKX action materialization repair

Live VM testing showed Charizard loaded 13 indexed native action slots but every attack/damage/faint materialization failed. The resident body had 14 retained render groups while dense native pages still had 17 source groups. The lazy materializer requires group-index parity and aborted the whole action bank.

Pokemon extractor revision 34 applies the same retained group mapping to the resident body and every dense action page. The regenerated Charizard cache is 14 groups for the base and 14 groups per `physicalA`, `physicalB`, `special`, `damage` and `faint` page.

## Live LÖVE 11.5 acceptance proof

Environment:

- LÖVE 11.5 x86_64
- supplied Gen1Recomp dev runtime
- supplied Pokémon Yellow ROM and save
- Gen-3-inspired UI overhaul 2.1.27
- Battle Art Voxel Fork 1.10.1
- real GC6E01 source CISO
- CBE Colosseum models enabled

A deterministic VM-only battle trigger called Gen1Recomp's normal `WorldAPI:startWildBattle()` so battle state/events/rendering remained genuine; that hook and all tracing are **not present in the packaged production tree**.

Observed Dig (move 91) trace:

- Waza spec resolved: `anawohoru`
- requested PKX action: `physicalB`
- native action materialized: `sampled=true`, `native=true`, slot 3, clip 4
- attack GPT1 start: 1 generator, 42 decoded textures
- next update: 2 generators / 10 particles
- peak observed attack population: **265 particles**
- actual `FX DRAW` recorded during the attack phase
- attack VM opcode faults: **0**
- separate damage GPT1 bank started on impact
- observed damage population reached **230 particles**
- actual `FX DRAW` recorded during the damage phase
- damage VM opcode faults: **0**

This is the first live acceptance proof in this series that source non-idle Pokémon motion and source GPT1 particle execution/drawing occur in the same real move window.

## Portable audio fix

Gen1Recomp portable mode can report `{type="file"}` without a `size` field. The v9 transactional ledger previously interpreted this as a truncated WAV. Newly committed WAVs are now read back once and byte-count verified before their ledger entry is written. Completed v9 caches may rely on the verified ledger plus file existence on metadata-less backends; normal backends continue to compare filesystem sizes directly.

## Automated validation

- Lua syntax: **PASS / 0 failures**
- `AudioParityContractTests.lua`: PASS
- `BattleExitBoundaryTests.lua`: PASS
- `HSDScaleTests.lua`: PASS
- `MoveFXAttackHandoffTests.lua`: PASS
- `MoveFXRetailParticleRuntimeTests.lua`: PASS
- `MoveFXSourceChainTests.lua`: PASS
- `PokemonReactionQueueTests.lua`: PASS
- `WazaSfxMappingTests.lua`: PASS
- Total regression suites: **8/8 PASS**

## Revisions

- WazaSequenceExtractor: **12**
- MoveFXExtractor: **30**
- PokemonExtractor: **34**
- MoveFXVM: **13**
- full MoveFX cache marker: v4 / extractor 30 / Waza 12

## Remaining fidelity boundary

This package is intentionally labeled a test build. It does **not** claim every source move is already 1:1 with GameCube rendering. Nineteen source visual chains remain incomplete. Full AppSRT/Euler/camera-basis generator behavior, exact GX primitive/form rendering, some Type-4/procedural Waza behavior, complete PKX material/texture animation and exact battle-camera choreography still require additional fidelity work.
