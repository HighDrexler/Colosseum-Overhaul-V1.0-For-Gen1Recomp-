













local V=... or {}
local Difficulty=V.MtBattleDifficulty
local GenerationCompat=V.GenerationCompat
local G1={}

G1.SLOT_COUNT=100
G1.SLOT_PREFIX="MTB_G1_"
G1.LEVEL_LOCK=50







function G1.levelLockedRoster(roster)
if type(roster)~="table" then return roster end
local out={}
for i,row in ipairs(roster) do
if type(row)=="table" then
local copy={}
for k,v in pairs(row) do copy[k]=v end
copy.level=G1.LEVEL_LOCK
out[i]=copy
else
out[i]=row
end
end
return out
end

function G1.slotId(fightIndex)
return G1.SLOT_PREFIX..string.format("%03d",fightIndex)
end

function G1.fightIndexOf(oppClass)
if type(oppClass)~="string" then return nil end
local n=oppClass:match("^"..G1.SLOT_PREFIX.."(%d%d%d)$")
return n and tonumber(n) or nil
end










function G1.setRosterProvider(fn)
G1.rosterProvider=fn
end













function G1.install(mod,placeholderSpecies)





if GenerationCompat and type(GenerationCompat.current)=="function" then
local ok,generation=pcall(GenerationCompat.current)
if ok and tonumber(generation)==2 then return false,"gen1-only" end
end
if G1.installed then return end
G1.installed=true
placeholderSpecies=placeholderSpecies or "FIXMON_A"

for _,tier in ipairs(Difficulty.TIERS) do
mod.content.ai_classes:register(tier.id,tier.gen1Class)












for _,personality in ipairs(Difficulty.PERSONALITIES) do
local combinedId=Difficulty.combinedAiClassId(tier.id,personality.id)
mod.content.ai_classes:register(combinedId,Difficulty.combinedGen1Class(tier,personality))
end
end

for i=1,G1.SLOT_COUNT do
local tier=Difficulty.tierFor(i)
local record={
id=G1.slotId(i),name="MT. BATTLE",
aiClass=tier.id,aiMods=tier.aiMods,
parties={{{species=placeholderSpecies,level=50}}},
}







if i==G1.SLOT_COUNT then
record.cbeBossIntro=true
record.cbeBossCategory="champion"
end
mod.content.trainers:register(G1.slotId(i),record)
end

mod.hooks:wrap("trainer.party",function(next,oppClass,partyIndex,party)
local fightIndex=G1.fightIndexOf(oppClass)
if fightIndex and G1.rosterProvider then
local roster=G1.rosterProvider(fightIndex)
if roster then return G1.levelLockedRoster(roster) end
end
return next(oppClass,partyIndex,party)
end,100,"mtbattle")
end

return G1
