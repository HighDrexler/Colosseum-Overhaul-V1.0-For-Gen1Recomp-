# Colosseum Battle Environments 1.9.2-pokemon-motion-handoff.1

This update fixes the attacker-body half of the MoveFX presentation chain.
`Actor:attack()` previously selected a source PKX action and then erased
`nativeAction` whenever the move also had a complete Waza timeline. That made
the best-cached moves animate least: particles, models, controllers, camera and
sound could advance while the Pokémon remained in its base pose.

The pose lock is removed. A Waza timeline and its Pokémon action now start on
the same semantic move boundary, and the selected action's PKX timing points are
passed into the Waza scheduler. Bite selects Larvitar's authored Physical-A
bank (PKX slot 2), so its body motion runs alongside `kamituku` attack and
damage phases instead of being replaced by an idle twitch.

The underlying PKX schema is corrected at the same time. Slots 1 and 6 are
Special A/B, slot 12 is Special C, slots 2-5 and 7 are Physical A-E, and the
remaining battle slots retain Damage, Damage B, Faint, Extra 1-4 and Take
Flight. Every active slot is cached; repeated DAT animation indices become
aliases and do not duplicate the large sampled mesh payload.

Ordinary Colosseum dispatch uses the generation-III type category for its
default body bank: Fire, Water, Grass, Electric, Ice, Psychic, Dragon and Dark
select Special A; all other types select Physical A. Stateful moves may request
their explicit B-E/Extra source variant. If no variant state is exposed, CBE
keeps the correct A bank rather than inventing a stronger/weaker variant.

Pokémon extractor revision 30 invalidates the old per-species action cache.
MoveFX extractor 24 and Waza parser 8 are unchanged. No soundtrack, MusyX,
Amuse, arena, trainer or capture production code was modified.
