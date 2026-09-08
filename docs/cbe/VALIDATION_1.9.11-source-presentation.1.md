# Source presentation candidate 1.9.11-source-presentation.1

## Verified corrections

### Pokemon shape and source action sampling

The previous HSD hierarchy multiplied rotated local transforms directly by
non-uniformly scaled parents. It omitted the parent-scale compensation used by
HSD_MtxSRT/HSD_JObjMakeMatrix. Larvitar's Bite source animation combines a parent
Y scale of approximately 0.35 with a child scale of approximately 2.99; omission
made the horn/body stretch. The decoder now preserves cumulative and classical
scale behavior and uses the same corrected transforms for rendering and joints.
This is enabled for Pokemon, not globally imposed on other asset families.

CPU source-mesh inspection of the formerly stretched pose reduced its vertical
extent from about 24.79 to 13.34 source units (idle about 16). This is diagnostic
mesh evidence, not an in-game screenshot or a claim of pixel-perfect animation.

Pokemon extractor revision 32 invalidates old species caches. Non-idle source
actions now use up to 144 source intervals, in overlapping 12-interval pages.
Larvitar extraction verified: attack 130 intervals/11 pages, damage 103/9,
faint 119/10. All exported coordinates were finite and adjacent page endpoints
matched within 0.001 source units. Idle keeps the previous lower sampling density.
Longer clips above the cap still interpolate; cache sizes and loading costs rise.

Primary HSD implementation references:
- https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/jobj.c
- https://github.com/doldecomp/melee/blob/master/src/sysdolphin/baselib/mtx.c

### Waza source loader correction

Retail GC6E01 DOL inspection established:
- Common loader 0x801DC46C: mode 1 payload at +0x6C, otherwise +0x70.
- Serialized attachment +0x08, position type +0x0C, link +0x10, timing indices
  +0x14/+0x18/+0x1C, sixteen timing values +0x20, flags +0x60, part +0x64,
  layout +0x68, and resource link +0x6C only in mode 2.
- Type-2 loader 0x801DCBC8: size at payload +0x1C, embedded data at
  align32(payload +0x24).
- Type-3 loader 0x801DCAA0: resource size +0x08, format +0x0C; data at +0x10
  with an additional word for format 3. Linked resources do not embed a new bank.

Previous parsing confused runtime node offsets with serialized source offsets.
Correcting the loader removes false model boundaries and incorrect timing,
attachments, and sound IDs. MoveFX revision 25 and Waza revision 9 invalidate
old effects; the full-build readiness marker also requires these revisions.

### GameSound identity and audio caches

The sound start path at 0x80166AB8 indexes twelve-byte GameSound records.
common_rel initialization relocations install its section-4 +0x13FE08 table
(file +0x141654), with 1,236 definitions; SFX flag is bit 7 of byte 0, group
is byte 1, and MusyX define ID is the halfword at +4. The battle SFXGroup is 5.

Examples verified from the supplied disc:
- Bite GameSound 133/134 -> SFX 248/249.
- Ice Beam GameSound 116/117/118 -> SFX 231/232/233.
- Ember GameSound 437 -> SFX 552.
- Flamethrower GameSound 461 -> SFX 576.
- Thunderbolt GameSound 1163 -> SFX 823; GameSound 492 -> SFX 607.

The old ordinal aliases were incorrect. Rendering now resolves definitions,
checks the correct group, and keeps output filenames keyed by GameSound ID.
Version-3 audio rebuilds old WAVs even if they have valid RIFF headers, deletes
failed/unmapped stale outputs, and runtime playback requires verified membership
in the new index. The all-or-native audio ownership policy remains intact.

All 403 referenced GameSound IDs resolved and rendered non-silent WAVs through
the existing portable MusyX renderer. This proves identity lookup and nonzero
render output, not audible equivalence of every MusyX macro/effect or timing.

### Crystal exit handoff

The supplied host's finishBattle starts a fade; completeBattle removes the
screen after that fade. CBE previously released its presentation after the first
call. It now wraps completeBattle where available, retaining finishBattle only
as a legacy-host fallback. Cleanup occurs after successful completion, not after
an error. Stub lifecycle regressions cover the fade, completion, legacy host,
and exception cases. The reported flash still requires live confirmation with
the complete companion-mod stack.

## Coverage and tests

- Supplied CISO MD5: a2d58d82c6b76b42653dcd25c8966de7; GC6E01, 1,872 FST files.
- Source moves: 251/251 found. Executable chains: 232/251, up from 185/251.
- Nineteen moves remain incomplete. Remaining failures concern HSD model
  decoding/type-4 model artifacts, including shape-backed resources. No
  readiness threshold was lowered to conceal these failures.
- MoveFXSourceChainTests passes, including HSDScaleTests,
  PokemonReactionQueueTests, BattleExitBoundaryTests and WazaSfxMappingTests.
- Tests cover serialized header sentinels/modes, GameSound lookup, stale-cache
  replacement and rejection, source scale math, dense action sample counts,
  reaction/faint queue ordering, and the exit boundary.
- Headless execution uses the installed LOVE LuaJIT library, production parsers,
  and an isolated file-backed cache. No disc, ROM, extracted models, or source
  sound assets are included in the mod ZIP.

## Reference scope and remaining work

The supplied 36.37-second video was visually sampled. It shows trainer staging,
sendout, Houndoom's Flamethrower, Shroomish taking damage and fainting, and the
next sendout. It does not establish electric or ice move behavior. No new
camera choreography or sendout implementation is claimed in this candidate.

The LOVE executable failed filesystem initialization in this environment, so
interactive GPU battles and audio playback were not validated. CPU extraction,
synthetic lifecycle tests, and non-silent WAV checks cannot certify 1:1 parity.
The UI and Battle Art companion mods and the host were not modified.

Required next live tests:
1. Larvitar Bite from both sides: body/horn proportions, contact timing, recovery.
2. Flamethrower against the video: camera cuts, flame trajectory, damage timing,
   lingering fire, lethal reaction and collapse/removal order.
3. Ember, Ice Beam, Blizzard, Thunderbolt and Thunder: attachments, effect
   texture/color/opacity, source sounds, frame pacing, and effect cleanup.
4. Multi-hit damage followed by faint; simultaneous events and late duplicates.
5. Crystal victory, loss, escape and trainer transitions: no native field
   flash throughout the exit fade with both companion mods enabled.
6. Denser action-bank memory use, first-encounter loading and page transitions.

Continue with the nineteen incomplete model chains, GPU visual comparison,
source camera behavior, sendout choreography and audible macro fidelity.
