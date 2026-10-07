# Colosseum Overhaul 3.0.1

Combined release for Gen 1, Gen 2, FireRed, LeafGreen, Ruby, Sapphire and Emerald. Ruby/Sapphire require a Gen1Recomp release with native support; runtime verification uses v0.3.52.

3.0.1 fixes accelerated starter model animations in Ruby/Sapphire/Emerald. The three imported models advance once per display update in real time; native starter input and confirmation retain their game speed. Animation pauses are capped to prevent a sudden pose jump on resume. Existing features and generated caches are retained.

## Install or update

Import this ZIP through the launcher, replace your existing Colosseum Overhaul package and enable one combined copy. Keep your imported Pokémon Colosseum USA source and generated caches. Existing cache identities, formats and completion markers are retained; no global cache wipe is required. Reopen Mt. Battle after updating. Missing models, Castform weather bodies and battle action banks prepare from the existing source import.

The launcher validates required imports before loading the mod. Source audio preparation must finish successfully; interrupted builds can be retried. Game ROMs, source disc images, saves and generated caches are not included.

## Features and controls

- Colosseum arenas, all 386 Pokémon models and portraits, source trainer actors, Waza move effects, faint/return presentation and source music.
- Eligible trainer doubles, battle camera and speed settings, readable dialogue, menus, party/PC/summary screens and Gen 3 level-up stat gains/totals.
- Model catalog, party move preparation, cache controls, expanded encounters and optional EXP Share. Gen 3: START → COLOSSEUM.
- Added-species save, PC and move-learning support in Gen 1/2. START → COLOSSEUMDEX appears after the native Pokédex unlock with the revamped UI enabled.
- Native game-specific behavior: Emerald Match Call, Ruby/Sapphire Trainer's Eyes, FireRed/LeafGreen opening dialogue and starter previews, naming, input and save rules.
- Castform uses the four source normal/sunny/rainy/snowy bodies, with separate weather caches and native normal/shiny presentation. Form hints stay outside owned Pokémon save records. Empty PC cells have no slot numbers.

## Mt. Battle

Gen 1/2: START → BATTLE → MT. BATTLE. Gen 3: START → COLOSSEUM → MT. BATTLE. All enter the shared Summit/setup or resume controls with source Mt. Battle menu music. Climb formats (3/5/10/25/50/100), six-Pokémon team building, party/PC/all-386 rentals, saved custom teams and suspend/resume are retained. Detached challenge Pokémon use progression-independent obedience/stat rules, allowing entry before the Elite Four.

## Caches and performance

Generated assets are shared across game saves and generations. The 386-model catalog prepares source bodies and idle poses; exact battle action banks remain selective. Previously unseen assets require initial cooperative preparation.

Presentation advances once per displayed update, independently of accelerated native logic. Required move, linked model-part, faint-return, particle and audio resources prepare before actions proceed. Source lookup plans and material/frame data are reused with dependency invalidation. Speculative bench work and periodic diagnostic writes remain outside prepared combat. Android/iOS arena surfaces use the 1280-axis / approximately 720p budget and two-scene residency limit; UI retains display resolution. Resizing/rotation releases old arena buffers immediately. Desktop arena resolution is retained.

## Package and verification

The release contains runtime modules, recipes, assets and required licenses. Development tests, reports, logs, patches, tools and historical release notes stay outside the playable package. Lua comments/redundant whitespace are removed with executable tokens, source line numbers and compiled bytecode checked against development source. Runtime code/assets are compared with the preceding build to preserve compatibility.

Verification covers native Yellow/Crystal/Emerald/Ruby/Sapphire/LeafGreen runtimes, source move/faint/multi-hit/Castform presentation, save/cache compatibility, level-up final pixels and platform/rotation policies. Direct device runtime tests use Windows; mobile policy branches draw source assets on Windows GL. Android/iOS/Linux/macOS hardware and complete campaigns were not available for validation. The Amuse license is included at third_party/amuse/LICENSE.txt.
