local Runtime=assert(loadfile("lib/WazaSequenceRuntime.lua"))({
  MoveFXVM={hasEntry=function() return true end,hasRole=function() return true end},
})
local Extractor=assert(loadfile("extract/WazaSequenceExtractor.lua"))()
local PokemonExtractor=assert(loadfile("extract/PokemonExtractor.lua"))({})
local PKXMetadata=assert(loadfile("extract/PKXMetadata.lua"))({})
local PokemonActors=assert(loadfile("lib/PokemonActors.lua"))({})
local CurrentSpriteModels=assert(loadfile("lib/CurrentSpriteModels.lua"))({})
local PortableMusyX=assert(loadfile("extract/PortableMusyX.lua"))()

-- The shader consumes frame 1 from packed scalars 9..11.  A one-scalar shift
-- makes every source attack pose cross-wire into the next frame channel.
local packed={}
for i=1,44 do packed[i]=0 end
packed[9],packed[10],packed[11]=101,102,103
packed[12],packed[13],packed[14]=201,202,203
local normalized=PokemonExtractor._test.normalizedVertexRow(packed)
assert(normalized[9]==101 and normalized[10]==102 and normalized[11]==103
  and normalized[12]==201 and normalized[13]==202 and normalized[14]==203,
  "PKX morph positions were packed one scalar late")

assert(PKXMetadata.slotKeys[1]=="specialA" and PKXMetadata.slotKeys[2]=="physicalA"
  and PKXMetadata.slotKeys[6]=="specialB" and PKXMetadata.slotKeys[12]=="specialC",
  "PKX attack-slot labels regressed")
assert(PokemonActors._test.moveSlot({type="DARK",power=60})=="specialA",
  "Gen-III Bite did not select the retail Dark-type Special-A bank")
assert(PokemonActors._test.moveSlot({type="NORMAL",power=60})=="physicalA",
  "Gen-III Normal type did not select PKX Physical-A")
assert(PokemonActors._test.moveSlot({type="FIRE",power=95})=="specialA",
  "Gen-III special type did not select PKX Special-A")
assert(PokemonActors._test.moveSlot({type=20,power=95})=="specialA"
  and PokemonActors._test.moveSlot({type=0,power=60})=="physicalA",
  "cartridge-native numeric type did not select the retail PKX A bank")

-- Retail wazaSequenceStart sets owner->index from sequence->kind before the
-- Pokemon motion starts. A decoded WZX root must therefore outrank the old
-- move-type fallback when selecting the native PKX body bank.
local sourceSlot,sourceKind=CurrentSpriteModels._test.sourceNativeSlot({wazaPhases={
  {name="attack",sequenceKind=3,entries={{identifier=1}}},
}},"attack")
assert(sourceSlot=="physicalB" and sourceKind==3,
  "WZX sequence kind did not select the matching PKX native animation slot")

-- A complete Waza timeline and the Pokemon's body bank run together. The old
-- sourceWazaPoseLock deliberately erased nativeAction for source-ready moves,
-- which left Larvitar idling while Bite's effect sequence advanced.
local fakeSpecial={groups={{}},duration=1.25}
local actor=PokemonActors._test.Actor.new(246,"normal",{actions={specialA=fakeSpecial},bounds={min={0,0,0},max={1,1,1}}},{})
actor.sourceMetadata={bodyMap={mouth=2},slots={specialA={index=1,animationIndex=3,duration=1.25,timing={0,.3,.7,1.25},bodyMap={mouth=9,chest=5}}}}
assert(actor:attack(44,{type="DARK",power=60},{sourceWaza=true})==true,
  "source-ready Bite did not enter the attack state")
assert(actor.nativeAction==fakeSpecial and actor.nativeSlotSampled==true and actor.sourceWazaPoseLock==false,
  "source-ready Waza discarded the selected PKX body animation")
assert(actor:bodyMap().mouth==9 and actor:bodyMap().chest==5,
  "active Waza anchors used the idle PKX body map instead of the selected attack slot")

local function be16(n) return string.char(math.floor(n/256)%256,n%256) end
local function be32(n)
  return string.char(math.floor(n/16777216)%256,math.floor(n/65536)%256,
    math.floor(n/256)%256,n%256)
end
local function put32(blob,offset,value)
  return blob:sub(1,offset)..be32(value)..blob:sub(offset+5)
end

local sfxProj=string.rep("\0",74)
sfxProj=put32(sfxProj,0,74);sfxProj=sfxProj:sub(1,4)..be16(5)..be16(1)..sfxProj:sub(9)
sfxProj=put32(sfxProj,28,40);sfxProj=put32(sfxProj,8,0);sfxProj=put32(sfxProj,12,0)
sfxProj=sfxProj:sub(1,40)..be16(3).."\0\0"
for i=0,2 do sfxProj=sfxProj:sub(1,44+i*10)..be16(201+i)..be16(300+i)..string.char(1,2,127,64,60,0)..sfxProj:sub(55+i*10) end
local sfxIndex=PortableMusyX._test.parseSfxProject(sfxProj)
assert(sfxIndex.entries[0]==nil and sfxIndex.entries[2]==nil
  and sfxIndex.entries[201].sourceId==201 and sfxIndex.entries[203].obj==302,
  "SFX project invented unverified ordinal aliases")
local SfxBuilder=assert(loadfile("extract/WazaSfxBuilder.lua"))({})
local definitions=put32(string.rep("\0",0x14BF3C),0x14BF38,1236)
definitions=put32(definitions,0x141654+133*12,0x8005010A)
definitions=put32(definitions,0x141654+133*12+4,248*65536)
definitions=put32(definitions,0x141654+1163*12,0x8005010A)
definitions=put32(definitions,0x141654+1163*12+4,823*65536)
local sounds=SfxBuilder._test.parseGameSounds(definitions)
assert(sounds[133].sfx and sounds[133].groupId==5 and sounds[133].sourceId==248
  and sounds[1163].sourceId==823 and not sounds[0].sfx,
  "GameSound-to-SFX definition lookup regressed")
assert(not pcall(SfxBuilder._test.parseGameSounds,definitions:sub(1,-2)),"truncated GameSound table accepted")
local soundRow=string.rep("\0",0x80)
-- Serialized Waza common node source layout (NOT runtime WazaSequenceNode):
-- +08 attachment, +0C position type, +10 linked entry key, +14/+18/+1C
-- timing selectors, +20..+5C timing[16], +60 flags, +64 part, +68 layout,
-- +6C shared-resource link only for layout 2. Typed payload begins at +70
-- for layout 0/2 and +6C for layout 1.
for offset,value in pairs({[0]=1,[4]=5,[8]=11,[12]=12,[16]=13,[20]=2,[24]=3,[28]=4,
  [32]=7,[92]=19,[96]=21,[100]=22,[104]=2,[108]=23,[112]=133,[116]=2}) do
  soundRow=put32(soundRow,offset,value)
end
local soundEntry,soundEnd=Extractor._internal.parseEntry(soundRow,0,1)
assert(soundEntry.soundId==133 and soundEntry.soundMode==2 and soundEnd==0x78
  and soundEntry.anchorEntry==13 and soundEntry.localPoint==2 and soundEntry.anchorPoint==3
  and soundEntry.timingIndex==4 and soundEntry.state==23 and soundEntry.flags==21
  and soundEntry.attachment==11 and soundEntry.positionType==12 and soundEntry.partIndex==22
  and soundEntry.timingPoints[1]==7 and soundEntry.timingPoints[16]==19,
  "serialized Waza offsets confused with runtime node layout")
-- mode-1 source rows omit the shared-resource word and begin typed payload at +0x6C.
soundRow=put32(soundRow,104,1);soundRow=put32(soundRow,108,134);soundRow=put32(soundRow,112,1)
soundEntry,soundEnd=Extractor._internal.parseEntry(soundRow,0,1)
assert(soundEntry.soundId==134 and soundEntry.state==0 and soundEnd==0x74,
  "mode-1 Waza payload did not start at 0x6C")

-- The WZX file begins with the sequence-root common record.  The numbered
-- SequenceEntry list starts independently at 0xA0 + aligned root-resource size.
-- The 1.9.14 regression incorrectly treated numbered entry 1 as the root and
-- read its typed payload as sequence kind/flags.  Keep the fixture shaped like
-- a real WZX: root at file offset zero, row 1 at 0xA0.
local rootWzx=string.rep("\0",0x220)
local rootAt=0
rootWzx=put32(rootWzx,rootAt+0x68,0) -- normal 0x70-byte root common record
local rootPayload=rootAt+0x70
rootWzx=put32(rootWzx,rootPayload,3)       -- sequence kind -> PKX Physical-B
rootWzx=put32(rootWzx,rootPayload+4,2)     -- root + one numbered entry
rootWzx=put32(rootWzx,rootPayload+8,0x2000)
rootWzx=put32(rootWzx,rootPayload+0x0C,0)
rootWzx=put32(rootWzx,rootPayload+0x10,1)
rootWzx=put32(rootWzx,rootPayload+0x14,0)  -- no embedded root resource
-- These are also the public WZX header fields used by the extractor.
rootWzx=put32(rootWzx,0x74,2)
rootWzx=put32(rootWzx,0x84,0)
local rowAt=0xA0
rootWzx=put32(rootWzx,rowAt,1)
rootWzx=put32(rootWzx,rowAt+4,6)
rootWzx=put32(rootWzx,rowAt+0x68,0)
rootWzx=put32(rootWzx,rowAt+0x70,0) -- type-6 owner controller
rootWzx=put32(rootWzx,rowAt+0x74,0)
local rootTimeline,rootErr=Extractor.parse(rootWzx,{phase="attack",member="fixture"})
assert(rootTimeline and not rootErr and rootTimeline.complete==true
  and rootTimeline.rootOffset==0 and rootTimeline.sequenceOffset==0xA0
  and rootTimeline.sequenceKind==3 and rootTimeline.sequenceFlags==0x2000
  and rootTimeline.parsedCount==1 and rootTimeline.entries[1].entryType==6,
  "WZX sequence root kind/flags were not decoded from the file-leading root")

local moveRows={string.rep("\0",0x38)}
for id=1,251 do
  local row=string.rep("\0",0x38)
  local secondary=1000+id
  row=row:sub(1,0x1E)..be16(secondary)..row:sub(0x21)
  row=row:sub(1,0x32)..be16(id)..row:sub(0x35)
  moveRows[#moveRows+1]=row
end
local commonRel=string.rep("\0",0x11E010)..table.concat(moveRows)
local archive={
  list=function() return {{name="common_rel.fdat"}} end,
  extract=function() return commonRel end,
}
local MoveFX=assert(loadfile("extract/MoveFXExtractor.lua"))({
  FSYS={open=function() return archive end},
  WazaSequenceExtractor=Extractor,
})
assert(MoveFX._test.directEmbeddedType3({kind="particle",state=0,dataSize=128,dataMagic="\0\0\0\0"})==false
  and MoveFX._test.directEmbeddedType3({kind="particle",state=0,dataSize=128,dataMagic="GPT1"})==false,
  "Type-3 particle-bank resource was incorrectly routed to HSD classification")

local sourceRows,sourceMeta=MoveFX._test.extractSourceMoveRows({file=function(_,name)
  return name=="common.fsys" and {name=name} or nil
end})
assert(sourceMeta.count==251 and sourceMeta.base==0x11E010 and sourceMeta.stride==0x38,
  "common_rel move table metadata was not retained")
assert(sourceRows[1].primaryAnimationId==1 and sourceRows[1].secondaryAnimationId==1001
  and sourceRows[251].primaryAnimationId==251 and sourceRows[251].secondaryAnimationId==1251,
  "common_rel animation selectors were read from the wrong row offsets")

local type2=string.rep("\0",0x200)
type2=put32(type2,0,1);type2=put32(type2,4,2)
type2=put32(type2,0x70+0x1C,0x40)
local modelEntry,modelEnd=Extractor._internal.parseEntry(type2,0,1)
assert(modelEntry.embeddedSize==0x40 and modelEntry.dataOffset==0xA0 and modelEnd==0xE0,
  "Type-2 HSD size/data layout regressed")

local type3GPT=string.rep("\0",0x200)
type3GPT=put32(type3GPT,0,1);type3GPT=put32(type3GPT,4,3);type3GPT=put32(type3GPT,0x68,2)
-- layout 2 retains its +6C shared-resource word; the Type-3 payload starts at +70.
type3GPT=put32(type3GPT,0x6C,0)
type3GPT=put32(type3GPT,0x70,2) -- generator selector
type3GPT=put32(type3GPT,0x74,0) -- animation mode
type3GPT=put32(type3GPT,0x78,0x20);type3GPT=put32(type3GPT,0x7C,4)
type3GPT=type3GPT:sub(1,0x80).."GPT1"..type3GPT:sub(0x85)
local particleGPT,particleGPTEnd=Extractor._internal.parseEntry(type3GPT,0,1)
assert(particleGPT.selector==2 and particleGPT.dataOffset==0x80 and particleGPT.dataSize==0x20
  and particleGPT.dataMagic=="GPT1" and particleGPTEnd==0xA0,
  "Type-3 mode-2 direct GPT1 layout regressed")

local function entry(id,anchor,points)
  return {identifier=id,anchorEntry=anchor or 0,localPoint=0,anchorPoint=anchor and 1 or 0,
    timingPoints=points or {0,0,0,0},kind="type1",subtype=0}
end

-- A valid source row may link forward. The scheduler must resolve the complete
-- graph before it calculates start frames rather than degrading to frame zero.
local forward={entry(1,2,{0,0,0,0}),entry(2,nil,{0,12,0,0})}
local rows,timing=Runtime._test.resolveEntryStarts(forward,{0,0,0,0})
assert(timing.unresolved==0,"forward Waza dependency was not resolved")
assert(rows[1].startFrame==12 and rows[2].startFrame==0,"forward dependency produced the wrong authored start")

local missing={entry(1,99,{0,0,0,0})}
local _,missingTiming=Runtime._test.resolveEntryStarts(missing,{0,0,0,0})
assert(missingTiming.unresolved==1,"missing dependency was silently accepted")
assert(missingTiming.unresolvedDetails[1].reason=="missing-anchor-entry","missing dependency reason was not retained")

local incomplete={wazaPhases={{name="attack",complete=false,parseError="truncated",entries={entry(1)}}}}
local owns,why=Runtime:canOwn(incomplete,"attack")
assert(owns==false and tostring(why):find("incomplete",1,true),"incomplete phase claimed presentation ownership")
assert(Runtime:hasTimeline(incomplete,"attack")==false,
  "mere Waza row presence enabled an incomplete presentation timeline")

local damageOnly={wazaPhases={{name="damage",complete=true,entries={entry(1)}}}}
assert(Runtime:hasTimeline(damageOnly,"damage")==true and Runtime:hasTimeline(damageOnly,"attack")==false,
  "damage Waza phase was misclassified as an attack timeline")

local missingTexture={wazaPhases={{name="attack",complete=true,entries={{kind="type4",effectType=3,
  effectSupported=true,effectRequiredArtifact="texture",effectRuntimeReady=true}}}}}
owns,why=Runtime:canOwn(missingTexture,"attack")
assert(owns==false and tostring(why):find("texture",1,true),"texture-backed Type-4 family claimed ownership without its source texture")

local families=Extractor._internal.type4Families
for family=0,12 do assert(type(families[family])=="table","missing Type-4 family "..family) end
assert(families[1].artifact=="texture" and families[3].artifact=="texture" and families[4].artifact=="texture"
  and families[12].artifact=="texture","texture-backed Type-4 family contract regressed")
assert(families[5].artifact=="model" and families[6].artifact=="model" and families[7].artifact=="model"
  and families[11].artifact=="model","model-backed Type-4 family contract regressed")

assert(loadfile("tests/PokemonReactionQueueTests.lua"))()
assert(loadfile("tests/HSDScaleTests.lua"))()
assert(loadfile("tests/BattleExitBoundaryTests.lua"))()
assert(loadfile("tests/WazaSfxMappingTests.lua"))()

return true
