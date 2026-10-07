






















local PBT={}

PBT.ADAPTATION_START_FIGHT=50
PBT.MAX_LEAN=0.15

local function tracker(save)
save.behaviorTracker=save.behaviorTracker or {
leadSpecies={},moveTypesUsed={},switches=0,fightsObserved=0,
statusMovesUsed=0,setupMovesUsed=0,repeatWinConditions={},
}
return save.behaviorTracker
end



function PBT.recordFight(save,summary)
if not summary then return end
local t=tracker(save)
t.fightsObserved=t.fightsObserved+1
if summary.leadSpecies then
t.leadSpecies[summary.leadSpecies]=(t.leadSpecies[summary.leadSpecies] or 0)+1
end
for moveType,count in pairs(summary.moveTypes or {}) do
t.moveTypesUsed[moveType]=(t.moveTypesUsed[moveType] or 0)+count
end
t.switches=t.switches+(summary.switches or 0)
t.statusMovesUsed=t.statusMovesUsed+(summary.statusMovesUsed or 0)
t.setupMovesUsed=t.setupMovesUsed+(summary.setupMovesUsed or 0)
if summary.winConditionSpecies then
t.repeatWinConditions[summary.winConditionSpecies]=
(t.repeatWinConditions[summary.winConditionSpecies] or 0)+1
end
end




function PBT.dominantMoveType(save)
local t=save.behaviorTracker
if not t then return nil end
local best,bestCount=nil,0
for moveType,count in pairs(t.moveTypesUsed) do
if count>bestCount then best,bestCount=moveType,count end
end
return best
end









function PBT.typeLean(save,fightIndex,candidateType)
if fightIndex<PBT.ADAPTATION_START_FIGHT then return 1.0 end
local t=save.behaviorTracker
if not t or t.fightsObserved==0 then return 1.0 end
local dominant=PBT.dominantMoveType(save)
if not dominant or candidateType~=dominant then return 1.0 end


local progress=math.min(1,(fightIndex-PBT.ADAPTATION_START_FIGHT)/50)
return 1.0+PBT.MAX_LEAN*progress
end

return PBT
