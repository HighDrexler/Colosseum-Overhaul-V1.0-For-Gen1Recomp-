# Colosseum Battle Environments 1.9.7-pokemon-action-pack-layout.1

## Source PKX morph stream correction

The 1.9.6 baseline selected Larvitar's real source Bite body bank, but the
extractor wrote each sampled position one scalar late in the 44-float vertex
row. That disagreed with `PokemonActors.lua`'s nine-`vec4` shader unpacker:
frame 1 was read as `{0, x, y}` and subsequent frames mixed coordinates across
frame boundaries. The result was a visibly distorted, under-animated attack.

Extractor revision 31 now preserves the intended layout: eight base
position/UV/normal scalars followed by thirty-six contiguous authored position
scalars (`FramePack1` through `FramePack9`). The existing source slot mapping,
four timing points, Waza attack/damage chain, PC idle loop, audio identity, and
battle-exit latch are unchanged. Existing species caches must rebuild once.
