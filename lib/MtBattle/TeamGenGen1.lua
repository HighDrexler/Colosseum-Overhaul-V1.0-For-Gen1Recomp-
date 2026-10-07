




local V=... or {}
local Archetypes=V.MtBattleArchetypes
local AntiRepeat=V.MtBattleAntiRepeat
local RosterCore=V.MtBattleRosterCore
local Difficulty=V.MtBattleDifficulty
local ShinyRollManager=V.MtBattleShinyRollManager
local TrainerIdentityGenerator=V.MtBattleTrainerIdentityGenerator
local PlayerBehaviorTracker=V.MtBattlePlayerBehaviorTracker
local SpecialFights=V.MtBattleSpecialFights
local BattleData=V.MtBattleBattleData
local req=V.engineRequire or require
local G1={}

local function behaviorCtx()
if not PlayerBehaviorTracker then return nil end
local ok,TypeChart=pcall(req,"src.battle.TypeChart")
if not ok then return nil end
return {PlayerBehaviorTracker=PlayerBehaviorTracker,TypeChart=TypeChart}
end




function G1.movePool(data,speciesDef,adapter)
local seen,out={},{}
local function add(id)
if id and not seen[id] then
local mdef=data.moves and data.moves[id]
if mdef and Archetypes.isMoveAllowed(id,mdef,adapter) then
seen[id]=true;out[#out+1]=id
end
end
end
for _,id in ipairs((speciesDef and speciesDef.level1Moves) or {}) do add(id) end
for _,entry in ipairs((speciesDef and speciesDef.learnset) or {}) do




if not tonumber(entry.level) or tonumber(entry.level)<=100 then add(entry.move) end
end
for _,id in ipairs((speciesDef and speciesDef.tmhm) or {}) do add(id) end
if #out==0 then
local fallback=BattleData and BattleData.fallbackMove and BattleData.fallbackMove(data,speciesDef)
out={fallback or "TACKLE"}
end
return out
end









function G1.buildRoster(stream,data,save,fightIndex,tier,archetype,eligibleSpeciesIds,adapter,personality)
local rosterSize=6
local gated=SpecialFights and SpecialFights.gateEligible(eligibleSpeciesIds,fightIndex) or eligibleSpeciesIds


local speciesPerSlot
if SpecialFights and SpecialFights.isEeveelutionFight(fightIndex) then
speciesPerSlot=SpecialFights.eeveelutionSpeciesList(data,rosterSize,stream,eligibleSpeciesIds)
if #speciesPerSlot==0 then
speciesPerSlot=RosterCore.pickRosterSpecies(stream,AntiRepeat,Difficulty,save,fightIndex,data,
archetype,rosterSize,gated,behaviorCtx(),tier)
end
elseif SpecialFights then
speciesPerSlot=RosterCore.pickRosterSpecies(stream,AntiRepeat,Difficulty,save,fightIndex,data,
archetype,rosterSize,gated,behaviorCtx(),tier)
else


speciesPerSlot={}
for i=1,rosterSize do
local role=archetype.roles[((i-1)%#archetype.roles)+1]
speciesPerSlot[i]=RosterCore.pickSpecies(stream,AntiRepeat,save,fightIndex,data,role,gated,behaviorCtx())
end
end
local rows,speciesUsed,roles={},{},{}
local teamCoveredTypes={}
local teamMoveBudget={counts={status=0,evasion=0,stall=0},caps=Archetypes.FRUSTRATION_CAPS}
for i=1,rosterSize do
local species=speciesPerSlot[i]
if species then
local role=archetype.roles[((i-1)%#archetype.roles)+1]
local def=data.pokemon[species]
local pool=G1.movePool(data,def,adapter)
local memberTypes={}
for _,t in ipairs(def.types or {}) do memberTypes[t]=true end
local moves=RosterCore.pickMoveset(stream,data,pool,role,memberTypes,Archetypes,1,personality,
teamCoveredTypes,teamMoveBudget,tier)
rows[#rows+1]={species=species,level=50,moves=moves}
speciesUsed[#speciesUsed+1]=species
roles[#rows]=role
end
end
return {rows=rows,speciesUsed=speciesUsed,roles=roles,frustrationCounts=teamMoveBudget.counts}
end



function G1.frustrationCounts(data,rows)
local counts={status=0,evasion=0,stall=0}
for _,row in ipairs(rows) do
for _,id in ipairs(row.moves) do
local mdef=data.moves and data.moves[id]
if mdef then
if Archetypes.effectCategory(Archetypes.STATUS_EFFECTS,1,mdef.effect) then counts.status=counts.status+1 end
if Archetypes.effectCategory(Archetypes.EVASION_EFFECTS,1,mdef.effect) then counts.evasion=counts.evasion+1 end
if Archetypes.effectCategory(Archetypes.STALL_EFFECTS,1,mdef.effect) then counts.stall=counts.stall+1 end
end
end
end
return counts
end

function G1.withinFrustrationCaps(counts)
local caps=Archetypes.FRUSTRATION_CAPS
return counts.status<=caps.statusMovesPerTeam
and counts.evasion<=caps.evasionMovesPerTeam
and counts.stall<=caps.stallMovesPerTeam
end












function G1.generate(stream,data,save,fightIndex,tier,eligibleSpeciesIds,adapter,maxAttempts,isAreaLeader)
local archetype=(RosterCore and RosterCore.pickArchetype)
and RosterCore.pickArchetype(stream,Archetypes,AntiRepeat,save,fightIndex,tier)
or Archetypes.pickArchetype(stream)
local personality=Difficulty and Difficulty.personalityFor(stream:nextInt(1,#Difficulty.PERSONALITIES)) or nil
local identity=(TrainerIdentityGenerator and personality)
and TrainerIdentityGenerator.generate(stream,fightIndex,isAreaLeader,personality) or nil
local result,bestScore
local attempts=maxAttempts or (tier and tier.optimizationAttempts) or 5
for _=1,attempts do
local candidate=G1.buildRoster(stream,data,save,fightIndex,tier,archetype,eligibleSpeciesIds,adapter,personality)
local counts=G1.frustrationCounts(data,candidate.rows)
if #candidate.rows==6 and G1.withinFrustrationCaps(counts) then
local quality=(RosterCore and RosterCore.teamQuality)
and RosterCore.teamQuality(data,candidate.rows,candidate.roles,tier,
{Archetypes=Archetypes,generation=1,archetype=archetype.id}) or 0
if not result or quality>bestScore then result,bestScore=candidate,quality end
end
end
if not result or #result.rows~=6 then
error(("Mt. Battle Gen 1 fight %d failed to build a legal six-Pokemon roster after %d attempts")
:format(fightIndex,attempts),0)
end
result.qualityScore=bestScore
result.archetype=archetype.id
result.personality=personality and personality.id
result.identity=identity
result.isAreaLeader=isAreaLeader and true or false
if ShinyRollManager then



local aceCount=0
if isAreaLeader then
aceCount=(SpecialFights and SpecialFights.aceCountFor(fightIndex)) or 1
end
local shiny,aceSlot,aceSlots=ShinyRollManager.assign(stream,#result.rows,aceCount,archetype,
function(i) return result.roles[i] end)
for i,row in ipairs(result.rows) do row.shiny=shiny[i] end
result.aceSlot=aceSlot
result.aceSlots=aceSlots
end
return result
end

return G1
