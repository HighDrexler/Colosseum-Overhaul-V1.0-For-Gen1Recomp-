









local AR={}






AR.SPECIES_WINDOW=15
AR.ARCHETYPE_WINDOW=5

local function recency(usedTable,key,fightIndex,window)
local last=usedTable[key]
if not last then return 1.0 end
local age=fightIndex-last
if age>=window then return 1.0 end


return 0.1+0.9*(age/window)
end


function AR.speciesWeight(save,species,fightIndex)
return recency(save.usedSpecies,species,fightIndex,AR.SPECIES_WINDOW)
end

function AR.archetypeWeight(save,archetypeId,fightIndex)
return recency(save.usedArchetypes,archetypeId,fightIndex,AR.ARCHETYPE_WINDOW)
end






function AR.weightedPick(stream,candidates,weightFn)
if not candidates or #candidates==0 then return nil end
local total=0
local weights={}
for i,c in ipairs(candidates) do
local w=math.max(0,weightFn(c) or 0)
weights[i]=w;total=total+w
end
if total<=0 then return stream:pick(candidates) end
local roll=stream:nextFloat()*total
local acc=0
for i,c in ipairs(candidates) do
acc=acc+weights[i]
if roll<=acc then return c end
end
return candidates[#candidates]
end







function AR.record(save,fightIndex,speciesList,archetypeId)
for _,species in ipairs(speciesList or {}) do
save.usedSpecies[species]=fightIndex
save.speciesUseCount[species]=(save.speciesUseCount[species] or 0)+1
end
if archetypeId then save.usedArchetypes[archetypeId]=fightIndex end
end



















AR.MAX_USES=4

function AR.useCount(save,species)
local counts=save and save.speciesUseCount
return type(counts)=="table" and (counts[species] or 0) or 0
end



function AR.canUse(save,species)
return AR.useCount(save,species)<AR.MAX_USES
end


function AR.unusedSpecies(save,eligibleSpeciesIds)
local out={}
for _,id in ipairs(eligibleSpeciesIds or {}) do
if AR.useCount(save,id)==0 then out[#out+1]=id end
end
return out
end







function AR.minRemainingSlots(fromFightIndex,Difficulty,totalFights)
totalFights=totalFights or 100
local total=0
for f=fromFightIndex,totalFights do
total=total+Difficulty.tierFor(f).rosterMin
end
return total
end

















function AR.forcedCoverageCount(save,fightIndex,teamSize,eligibleSpeciesIds,Difficulty,totalFights)
totalFights=totalFights or 100
local unused=#AR.unusedSpecies(save,eligibleSpeciesIds)
local futureMin=fightIndex<totalFights
and AR.minRemainingSlots(fightIndex+1,Difficulty,totalFights) or 0
local need=unused-futureMin
if need<0 then need=0 end
if need>teamSize then need=teamSize end
return need
end

return AR
