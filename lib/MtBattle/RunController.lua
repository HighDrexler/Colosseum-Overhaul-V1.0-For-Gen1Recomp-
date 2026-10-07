



local V=... or {}
local SaveState=V.MtBattleSaveState
local SeedManager=V.MtBattleSeedManager
local XPBank=V.MtBattleXPBank
local ChallengeBag=V.MtBattleChallengeBag
local Difficulty=V.MtBattleDifficulty
local AntiRepeat=V.MtBattleAntiRepeat
local TeamGenGen1=V.MtBattleTeamGenGen1
local TeamGenGen2=V.MtBattleTeamGenGen2
local AreaLeaderManager=V.MtBattleAreaLeaderManager
local RecordsManager=V.MtBattleRecordsManager
local PlayerBehaviorTracker=V.MtBattlePlayerBehaviorTracker
local LevelClone=V.MtBattleLevelClone
local Fingerprint=V.MtBattleFingerprint
local BattleData=V.MtBattleBattleData
local SummitVariation=V.MtBattleSummitVariation
local RC={}

RC.TOTAL_FIGHTS=100
RC.FIGHTS_PER_AREA=10
RC.SUPPORTED_TOTAL_FIGHTS=(SaveState and SaveState.SUPPORTED_TOTAL_FIGHTS) or {3,5,10,25,50,100}

local function normalizeTotalFights(value)
if SaveState and type(SaveState.normalizeTotalFights)=="function" then
return SaveState.normalizeTotalFights(value)
end
local n=tonumber(value)
for _,allowed in ipairs(RC.SUPPORTED_TOTAL_FIGHTS) do
if n==allowed then return allowed end
end
return RC.TOTAL_FIGHTS
end

local function supportedTotalFights(value)
if SaveState and type(SaveState.isSupportedTotalFights)=="function" then
return SaveState.isSupportedTotalFights(value)
end
local n=tonumber(value)
for _,allowed in ipairs(RC.SUPPORTED_TOTAL_FIGHTS) do
if n==allowed then return true end
end
return false
end

function RC.totalFights(gameOrSave)
local save=gameOrSave
if type(gameOrSave)=="table" and gameOrSave.save then save=SaveState.state(gameOrSave) end
return normalizeTotalFights(type(save)=="table" and save.totalFights or nil)
end







function RC.difficultyFightIndex(fightIndex,totalFights)
totalFights=normalizeTotalFights(totalFights)
fightIndex=math.max(1,math.min(totalFights,math.floor(tonumber(fightIndex) or 1)))
if totalFights<=1 or totalFights==RC.TOTAL_FIGHTS then return fightIndex end
return math.max(1,math.min(RC.TOTAL_FIGHTS,
math.floor(1+((fightIndex-1)*(RC.TOTAL_FIGHTS-1))/(totalFights-1)+.5)))
end

local function areaForFight(fightIndex,totalFights)
totalFights=normalizeTotalFights(totalFights)
fightIndex=math.max(1,math.min(totalFights,math.floor(tonumber(fightIndex) or 1)))
return math.floor((fightIndex-1)/RC.FIGHTS_PER_AREA)+1
end





function RC.intermissionFor(completedFightIndex,totalFights)
totalFights=normalizeTotalFights(totalFights)
completedFightIndex=math.max(1,math.floor(tonumber(completedFightIndex) or 1))
local complete=completedFightIndex>=totalFights
local area=areaForFight(completedFightIndex,totalFights)
local areaBreak=(completedFightIndex%RC.FIGHTS_PER_AREA)==0
local nextFight
if not complete then nextFight=completedFightIndex+1 end
local nextIsAreaLeader=nextFight and AreaLeaderManager and AreaLeaderManager.isAreaLeader(nextFight) or false



local nextIsFinale=totalFights==RC.TOTAL_FIGHTS and nextFight==RC.TOTAL_FIGHTS
return {
kind=complete and "complete" or (areaBreak and "areaBreak" or "between"),
result="win",completedFight=completedFightIndex,nextFight=nextFight,
area=area,areaProgress=((completedFightIndex-1)%RC.FIGHTS_PER_AREA)+1,
areaBreak=areaBreak,complete=complete,totalFights=totalFights,
isFinale=complete and totalFights==RC.TOTAL_FIGHTS or false,
nextArea=nextFight and areaForFight(nextFight,totalFights) or nil,
nextIsAreaLeader=nextIsAreaLeader==true,nextIsFinale=nextIsFinale==true,
}
end







function RC.beginChallenge(game,generation,rosterSource,bagOverrides,moveOverrides,runOptions,rulesetId)
local requestedTotal,requestedRuleset
if type(runOptions)=="table" then
requestedTotal=runOptions.totalFights
if requestedTotal==nil then requestedTotal=runOptions.format end
requestedRuleset=runOptions.rulesetId or runOptions.ruleset
else
requestedTotal=runOptions
end
if rulesetId~=nil then requestedRuleset=rulesetId end
if requestedTotal~=nil and not supportedTotalFights(requestedTotal) then
error("unsupported Mt. Battle format: "..tostring(requestedTotal),0)
end
if requestedRuleset~=nil and type(requestedRuleset)~="string" then
error("invalid Mt. Battle ruleset id",0)
end
local save=SaveState.reset(game)
save.generation=generation
save.totalFights=normalizeTotalFights(requestedTotal)
save.rulesetId=requestedRuleset


save.generationPreference="all"
save.rosterSource=rosterSource
if LevelClone and LevelClone.snapshotRoster then
local snapshot,why=LevelClone.snapshotRoster(game,generation,rosterSource,moveOverrides)
if not snapshot then error("Mt. Battle roster lock failed: "..tostring(why),0) end
save.rosterSnapshot=snapshot
end
if Fingerprint and type(Fingerprint.analyze)=="function" then
save.fingerprint=Fingerprint.analyze(game and game.data or {},save.rosterSnapshot)
end
save.currentFight=1
save.fightsWon=0
save.continuesTotal=1
save.continuesUsed=0
save.pendingIntermission=nil
save.lastTeamStatus={}
save.awaitingFinale=false
ChallengeBag.resetToDefault(game,SaveState,bagOverrides,save.totalFights)
SeedManager.roll(game,SaveState)
if V.MtBattleBattlePoints then V.MtBattleBattlePoints.ensureRun(game,save) end




if SummitVariation and type(SummitVariation.ensure)=="function" then
SummitVariation.ensure(save,save.totalFights)
end
if RecordsManager and type(RecordsManager.recordRunStarted)=="function" then
RecordsManager.recordRunStarted(game,save.rosterSnapshot,{
totalFights=save.totalFights,generation=save.generation,rulesetId=save.rulesetId,
generationPreference=save.generationPreference,
})
end
return save
end











function RC.currentEncounter(game,data,eligibleSpeciesIds,adapter)
local save=SaveState.state(game)
local fightIndex=save.currentFight
local totalFights=RC.totalFights(save)
if fightIndex>totalFights then error("Mt. Battle run is complete; no next encounter",0) end
if save.currentEncounter and save.currentEncounter.fightIndex==fightIndex then
if save.currentEncounter.summitVariation==nil and SummitVariation and type(SummitVariation.forSave)=="function" then
save.currentEncounter.summitVariation=SummitVariation.forSave(save,fightIndex)
end
return save.currentEncounter
end
local subSeed=SeedManager.subSeed(save.masterSeed,fightIndex)
local stream=SeedManager.newStream(subSeed)





local isAreaLeader=AreaLeaderManager and AreaLeaderManager.isAreaLeader(fightIndex)
local difficultyFightIndex=RC.difficultyFightIndex(fightIndex,totalFights)
local tier=Difficulty.tierFor(difficultyFightIndex)
if isAreaLeader and AreaLeaderManager then tier=AreaLeaderManager.applyBudget(tier,fightIndex) end
local challengeData=data
local filteredEligible=eligibleSpeciesIds
if BattleData and type(BattleData.data)=="function" and type(BattleData.eligibleSpecies)=="function" then
local projected=BattleData.data(game)
local all=BattleData.eligibleSpecies(game)
if projected and type(all)=="table" and #all>0 then
challengeData=projected
filteredEligible=all
end
end
if #(filteredEligible or {})==0 then
error("Mt. Battle has no source-backed eligible species",0)
end
local Gen=(save.generation==2) and TeamGenGen2 or TeamGenGen1
local result=Gen.generate(stream,challengeData,save,fightIndex,tier,filteredEligible,adapter,nil,isAreaLeader)
local encounter={fightIndex=fightIndex,difficultyFightIndex=difficultyFightIndex,subSeed=subSeed,tierId=tier.id,
totalFights=totalFights,isRunFinal=fightIndex==totalFights,
generationPreference=save.generationPreference,
isFinale=totalFights==RC.TOTAL_FIGHTS and fightIndex==RC.TOTAL_FIGHTS,
archetype=result.archetype,
personality=result.personality,identity=result.identity,
isAreaLeader=result.isAreaLeader,aceSlot=result.aceSlot,aceSlots=result.aceSlots,
summitVariation=SummitVariation and type(SummitVariation.forSave)=="function" and SummitVariation.forSave(save,fightIndex) or nil,
rows=result.rows,
mons=result.mons,
speciesUsed=result.speciesUsed}
save.currentEncounter=encounter
AntiRepeat.record(save,fightIndex,result.speciesUsed,result.archetype)
SaveState.snapshotBag(game)
if SaveState.snapshotTeam then SaveState.snapshotTeam(game) end
return encounter
end










function RC.recordWin(game,data,defeatedDefs,participants,behaviorSummary,bpEvidence)
local save=SaveState.state(game)
for _,def in ipairs(defeatedDefs or {}) do
local share=XPBank.computeShare(save.generation,data,def,50,participants or 1)
XPBank.accrue(game,SaveState,share)
end





if RecordsManager then
local enc=save.currentEncounter
local species,shinyFlags={},{}
if enc then
local slots=enc.rows or enc.mons or {}
for i,slot in ipairs(slots) do species[i]=slot.species;shinyFlags[i]=slot.shiny end
end
RecordsManager.recordFightWon(game,species,shinyFlags,save.currentEncounter and save.currentEncounter.isAreaLeader,
save.currentEncounter and save.currentEncounter.aceSlot)
end
if PlayerBehaviorTracker and behaviorSummary then
PlayerBehaviorTracker.recordFight(save,behaviorSummary)
end

local completedFightIndex=save.currentFight
local bpAward
if V.MtBattleBattlePoints then
bpAward=V.MtBattleBattlePoints.recordWin(game,save,completedFightIndex,bpEvidence)
end
local totalFights=RC.totalFights(save)
save.fightsWon=save.fightsWon+1
save.currentFight=save.currentFight+1
save.currentEncounter=nil
save.pendingIntermission=RC.intermissionFor(completedFightIndex,totalFights)
if type(bpAward)=="table" then save.pendingIntermission.bpAward=bpAward end

if completedFightIndex==totalFights and RecordsManager then
local team=nil
if LevelClone and save.rosterSource then
team={}
for i,entry in ipairs(save.rosterSource) do
local locked=save.rosterSnapshot and save.rosterSnapshot[i]
if locked and locked.species then
team[i]=locked.species
else
local mon=LevelClone.resolveSource(game,save.generation,entry)
team[i]=mon and mon.species or nil
end
end
end
local itemsUsed=V.MtBattleChallengeBag and V.MtBattleChallengeBag.totalConsumed(game,SaveState) or nil


local history=save.battleHistory or {}
local last=history[#history]
local appended=last and last.fightIndex==completedFightIndex
and (last.result=="win" or last.result==nil)
local attemptCount=math.max(save.fightsWon,#history+(appended and 0 or 1))
RecordsManager.recordCompletion(game,save.continuesUsed,itemsUsed,save.xpBank,team,{
totalFights=totalFights,generation=save.generation,rulesetId=save.rulesetId,
fightsWon=save.fightsWon,battlesPlayed=attemptCount,
})
end

return save.xpBank
end





function RC.recordLoss(game)
local save=SaveState.state(game)
local fightIndex=save.currentFight
local totalFights=RC.totalFights(save)
local canContinue=save.continuesUsed<save.continuesTotal
if canContinue then
save.pendingIntermission={
kind="continue",result="lose",completedFight=nil,nextFight=fightIndex,
area=areaForFight(fightIndex,totalFights),areaProgress=((fightIndex-1)%RC.FIGHTS_PER_AREA)+1,
continueAvailable=true,complete=false,totalFights=totalFights,
nextIsAreaLeader=AreaLeaderManager and AreaLeaderManager.isAreaLeader(fightIndex) or false,
nextIsFinale=totalFights==RC.TOTAL_FIGHTS and fightIndex==RC.TOTAL_FIGHTS,
}
return save.pendingIntermission
end




RC.forfeit(game,{battlesPlayed=#(save.battleHistory or {})+1})
save.pendingIntermission={
kind="failed",result="lose",completedFight=nil,nextFight=nil,
failedFight=fightIndex,area=areaForFight(fightIndex,totalFights),
areaProgress=((fightIndex-1)%RC.FIGHTS_PER_AREA)+1,
continueAvailable=false,complete=false,totalFights=totalFights,
}
return save.pendingIntermission
end

function RC.clearIntermission(game)
local save=SaveState.state(game)
local previous=save.pendingIntermission
save.pendingIntermission=nil
return previous
end







function RC.acknowledgeCompletion(game)
local save=SaveState.state(game)
if not RC.isComplete(game) then return false,"run is not complete" end
save.pendingIntermission=nil
save.awaitingFinale=true
return true
end







function RC.useContinue(game)
local save=SaveState.state(game)
if save.continuesUsed>=save.continuesTotal then return false end
save.continuesUsed=save.continuesUsed+1
ChallengeBag.restore(game,SaveState)
if SaveState.restoreTeam then SaveState.restoreTeam(game) end
return true
end

function RC.hasContinueAvailable(game)
local save=SaveState.state(game)
return save.continuesUsed<save.continuesTotal
end



function RC.forfeit(game,opts)
opts=opts or {}
local save=SaveState.state(game)
local forfeitedXp=save.xpBank or 0
local itemsUsed=ChallengeBag and type(ChallengeBag.totalConsumed)=="function"
and ChallengeBag.totalConsumed(game,SaveState) or nil
XPBank.forfeit(game,SaveState)
if RecordsManager then RecordsManager.recordFailure(game,save.fightsWon,{
totalFights=RC.totalFights(save),generation=save.generation,rulesetId=save.rulesetId,
battlesPlayed=opts.battlesPlayed~=nil and opts.battlesPlayed or #(save.battleHistory or {}),continuesUsed=save.continuesUsed,
itemsUsed=itemsUsed,xpBank=forfeitedXp,failedFight=save.currentFight,
}) end
save.active=false
return save
end

function RC.isComplete(game)
local save=SaveState.state(game)
return save.currentFight>RC.totalFights(save)
end





function RC.finish(game)
local save=SaveState.state(game)
save.active=false
save.xpDistributed=true
save.awaitingFinale=false
save.pendingIntermission=nil
return save
end

return RC
