












local V=... or {}
local req=V.engineRequire or require
local LevelClone=V.MtBattleLevelClone
local TrainerPoolG1=V.MtBattleTrainerPoolG1
local Difficulty=V.MtBattleDifficulty
local BattleObserver=V.MtBattleBattleObserver
local PlayerBehaviorTracker=V.MtBattlePlayerBehaviorTracker
local SaveState=V.MtBattleSaveState
local BattleData=V.MtBattleBattleData
local BL={}
local LEVEL_LOCK=(LevelClone and tonumber(LevelClone.LEVEL_LOCK)) or 50




local GEN2_BATTLETYPE_CANLOSE=1




local function normalizeGen2ChallengeRules(battle)
if not battle or battle.__cbeMtBattleBadgeRules then return battle end
local obedience=battle.checkObedience
local battleStat=battle.battleStat
local typeBoost=battle.badgeTypeBoost
battle.checkObedience=function(self,...)
if self.cbeMtBattleChallenge then return false end
return obedience(self,...)
end
battle.battleStat=function(self,mon,key,...)
if self.cbeMtBattleChallenge then return (mon and mon.stats or {})[key] or 1 end
return battleStat(self,mon,key,...)
end
battle.badgeTypeBoost=function(self,...)
if self.cbeMtBattleChallenge then return false end
return typeBoost(self,...)
end
battle.__cbeMtBattleBadgeRules=true
return battle
end

local function applyPersistentTeamState(game,clones,data)
if not (SaveState and type(SaveState.state)=="function" and type(clones)=="table") then return clones end
data=data or (BattleData and type(BattleData.data)=="function" and BattleData.data(game)) or (game and game.data)
if type(SaveState.repairTeamPP)=="function" then SaveState.repairTeamPP(game,data) end
local save=SaveState.state(game)
local team=type(save.lastTeamStatus)=="table" and save.lastTeamStatus or {}
for i,mon in ipairs(clones) do
local row=team[i]
if type(row)=="table" and (row.species==nil or row.species==mon.species) then
local maxHp=tonumber(mon.maxHp or mon.maxHP) or (type(mon.stats)=="table" and tonumber(mon.stats.hp)) or tonumber(row.maxHp) or 1
maxHp=math.max(1,math.floor(maxHp))
mon.hp=math.max(0,math.min(maxHp,math.floor(tonumber(row.hp) or maxHp)))
mon.status=(row.status~=nil and row.status~="") and row.status or nil
local savedMoves=type(row.moves)=="table" and row.moves or {}
for j,mv in ipairs(type(mon.moves)=="table" and mon.moves or {}) do
local saved=savedMoves[j]
if type(mv)=="table" and type(saved)=="table" and (saved.id==nil or saved.id==mv.id) then
local maxPp,ups
if type(SaveState.movePPLimit)=="function" then maxPp,ups=SaveState.movePPLimit(mv,data,saved)
else
local def=data and data.moves and data.moves[mv.id]
ups=math.max(0,math.min(3,math.floor(tonumber(mv.ppUps or saved.ppUps) or 0)))
maxPp=tonumber(mv.maxPp or mv.maxPP)
if not maxPp or maxPp<=0 then
local base=tonumber(def and def.pp) or 0
maxPp=base+ups*math.floor(base/5)
end
if maxPp<=0 then maxPp=math.max(tonumber(saved.maxPp) or 0,tonumber(saved.pp) or 0,tonumber(mv.pp) or 0) end
end
maxPp=math.max(0,math.floor(maxPp or 0))
mv.maxPp=maxPp;mv.maxPP=maxPp;mv.ppUps=ups or 0
mv.pp=math.max(0,math.min(maxPp,math.floor(tonumber(saved.pp) or maxPp)))
end
end
end
end
return clones
end







function BL.activateGen1(game,battle)
if not (game and game.stack and battle) then return false,"missing game stack or battle" end
local overworld=game.overworld
if type(overworld)=="table" and type(overworld.pushBattle)=="function" then
local ok,why=pcall(overworld.pushBattle,overworld,battle)
if not ok then
if BattleData and BattleData.restoreHostTypes then BattleData.restoreHostTypes(battle) end
return false,tostring(why)
end
return true
end
local states=game.stack.states
if type(states)=="table" then
for i=#states,1,-1 do
local state=states[i]
if state~=battle and type(state)=="table" and type(state.pushBattle)=="function" then
local ok,why=pcall(state.pushBattle,state,battle)
if not ok then
if BattleData and BattleData.restoreHostTypes then BattleData.restoreHostTypes(battle) end
return false,tostring(why)
end
return true
end
end
end




if type(game.stack.push)=="function" then
local ok,why=pcall(game.stack.push,game.stack,battle)
if not ok then
if BattleData and BattleData.restoreHostTypes then BattleData.restoreHostTypes(battle) end
return false,tostring(why)
end
return true
end
return false,"no Gen 1 battle activation path"
end






local function attachBehaviorObserver(game,generation,battle)
if V.MtBattleBattlePoints then V.MtBattleBattlePoints.bindBattle(game,battle,SaveState.state(game).currentEncounter) end
if not (BattleObserver and PlayerBehaviorTracker and SaveState) then return end
local detach=BattleObserver.attach(battle,generation,function(summary)
PlayerBehaviorTracker.recordFight(SaveState.state(game),summary)
end)



battle.__cbeMtBattleDetachObserver=detach
end















function BL.launchGen1(game,fightIndex,rosterSource,encounter)
local BattleState=req("src.battle.BattleState")
local challengeData=(BattleData and BattleData.data and BattleData.data(game)) or game.data
local locked=SaveState and SaveState.state(game).rosterSnapshot or nil
local clones,err=LevelClone.playerParty(game,1,LEVEL_LOCK,challengeData,rosterSource,locked)
if not clones then return nil,err end
applyPersistentTeamState(game,clones,challengeData)
local challengeGame,gameErr
if BattleData and type(BattleData.game)=="function" then challengeGame,gameErr=BattleData.game(game,clones) end
challengeGame=challengeGame or game
if gameErr and challengeGame==game then return nil,gameErr end

local slotId=TrainerPoolG1.slotId(fightIndex)


local record=challengeData.trainers[slotId]
if not record then return nil,"Mt. Battle trainer slot unavailable in challenge view" end




local hostRecord=(challengeData==game.data)
local originalRecord=hostRecord and {
aiClass=record.aiClass,aiMods=record.aiMods,name=record.name,
} or nil
if encounter and encounter.tierId and encounter.personality and Difficulty then
local personality=nil
for _,p in ipairs(Difficulty.PERSONALITIES) do if p.id==encounter.personality then personality=p end end
if personality then
record.aiClass=Difficulty.combinedAiClassId(encounter.tierId,personality.id)
record.aiMods=personality.gen1Mods
end
end
if encounter and encounter.identity and encounter.identity.name then
record.name=encounter.identity.name
end







local Pokemon=req("src.pokemon.Pokemon")
local originalPokemonNew=Pokemon.new
if BattleData and type(BattleData.newGen1Mon)=="function" then
Pokemon.new=function(data,species,level,rng)
local def=data and data.pokemon and data.pokemon[species]
if def and def.__cbeMtBattleSource then
local Stats=req("src.pokemon.Stats")
local dvs=Stats.randomDVs(rng)
return BattleData.newGen1Mon(data,species,level,dvs)
end
return originalPokemonNew(data,species,level,rng)
end
end







local previousRosterProvider,temporaryRosterProvider
if encounter and type(encounter.rows)=="table" and TrainerPoolG1
and type(TrainerPoolG1.setRosterProvider)=="function" then
previousRosterProvider=TrainerPoolG1.rosterProvider
TrainerPoolG1.setRosterProvider(function(index)
if tonumber(index)==tonumber(fightIndex) then return encounter.rows end
if previousRosterProvider then return previousRosterProvider(index) end
return nil
end)
temporaryRosterProvider=true
end
local ok,battle=pcall(BattleState.newTrainer,challengeGame,slotId,1,{})
if temporaryRosterProvider then TrainerPoolG1.setRosterProvider(previousRosterProvider) end
Pokemon.new=originalPokemonNew
if originalRecord then
record.aiClass=originalRecord.aiClass
record.aiMods=originalRecord.aiMods
record.name=originalRecord.name
end
if not ok then



local TypeChart=req("src.battle.TypeChart");pcall(TypeChart.load,game.data)
return nil,tostring(battle)
end





local enemyLevelMismatch=false
for _,mon in ipairs(battle.enemyParty or {}) do
if tonumber(mon.level)~=LEVEL_LOCK then enemyLevelMismatch=true;break end
end
if enemyLevelMismatch then
if not (LevelClone and type(LevelClone.opponentParty)=="function") then
return nil,"Mt. Battle opponent level-lock clone unavailable"
end
local normalized,why=LevelClone.opponentParty(battle.enemyParty,1,LEVEL_LOCK,challengeData)
if not normalized then return nil,why end
battle.enemyParty=normalized
end




if BattleData and type(BattleData.gen1Stats)=="function" then
for _,mon in ipairs(battle.enemyParty or {}) do
local def=challengeData.pokemon and challengeData.pokemon[mon.species]
if def and def.__cbeMtBattleSource then
mon.stats=BattleData.gen1Stats(def,mon.level,mon.dvs,mon.statExp)
mon.hp=mon.stats.hp
end
end
end

battle.playerParty=clones
battle.cbeMtBattleLevelLock=true
battle.cbeMtBattleChallenge=true
battle.cbeMtBattleSummitVariation=encounter and encounter.summitVariation or nil
battle.cbeMtBattleNumber=encounter and encounter.fightIndex or fightIndex
battle.player=BattleState.makeBattler(challengeData,clones[1],true,nil)
battle.playerIndex=1
if battle.enemyParty and battle.enemyParty[1] then
battle.enemy=BattleState.makeBattler(challengeData,battle.enemyParty[1],false,nil)
end
if BattleData and type(BattleData.attachGen1Battle)=="function" then BattleData.attachGen1Battle(battle,game) end






if encounter and encounter.rows then
for i,row in ipairs(encounter.rows) do
if row.shiny and battle.enemyParty[i] then battle.enemyParty[i].shiny=true end
end
end

attachBehaviorObserver(game,1,battle)
return battle
end


























function BL.launchGen2(game,rosterSource,opponentMons,trainerMeta,encounter)
local Battle=req("src.battle.gen2.Battle")
local challengeData=(BattleData and BattleData.data and BattleData.data(game)) or game.data
local locked=SaveState and SaveState.state(game).rosterSnapshot or nil
local clones,err=LevelClone.playerParty(game,2,LEVEL_LOCK,challengeData,rosterSource,locked)
if not clones then return nil,err end
applyPersistentTeamState(game,clones,challengeData)
local challengeGame=BattleData and BattleData.game and BattleData.game(game,clones) or nil
local challengeSave=(challengeGame and challengeGame.save) or game.save






if not (LevelClone and type(LevelClone.opponentParty)=="function") then
return nil,"Mt. Battle Gen 2 opponent level-lock clone unavailable"
end
local lockedOpponents,lockErr=LevelClone.opponentParty(opponentMons,2,LEVEL_LOCK,challengeData)
if not lockedOpponents then return nil,lockErr end

local name=(trainerMeta and trainerMeta.name) or "MT. BATTLE"
local attributes=trainerMeta and trainerMeta.attributes
if encounter and encounter.identity and encounter.identity.name then
name=encounter.identity.name
end
if encounter and encounter.tierId and encounter.personality and Difficulty then
local personality=nil
for _,p in ipairs(Difficulty.PERSONALITIES) do if p.id==encounter.personality then personality=p end end
local tier=nil
for _,t in ipairs(Difficulty.TIERS) do if t.id==encounter.tierId then tier=t end end
if personality and tier then
local Ai=req("src.battle.gen2.Ai")
local mergedFlagNames=Difficulty.combinedGen2Flags(tier,personality)
local mergedTier={gen2Flags=mergedFlagNames,gen2SwitchLo=tier.gen2SwitchLo,gen2SwitchHi=tier.gen2SwitchHi}




attributes=Difficulty.gen2Attributes(mergedTier,nil,nil,0,Ai.FLAGS)
end
end

local trainer={name=name,party=lockedOpponents,attributes=attributes}



if trainerMeta then
trainer.cbeBossIntro=trainerMeta.cbeBossIntro
trainer.cbeBossCategory=trainerMeta.cbeBossCategory
end
local battle=Battle.new{data=challengeData,party=clones,trainer=trainer,
save=challengeSave,battleType=GEN2_BATTLETYPE_CANLOSE}
battle.cbeMtBattleLevelLock=true
battle.cbeMtBattleChallenge=true
battle.cbeMtBattleSummitVariation=encounter and encounter.summitVariation or nil
battle.cbeMtBattleNumber=encounter and encounter.fightIndex or nil
normalizeGen2ChallengeRules(battle)
attachBehaviorObserver(game,2,battle)
return battle
end

BL._test=BL._test or {};BL._test.applyPersistentTeamState=applyPersistentTeamState
BL._test.normalizeGen2ChallengeRules=normalizeGen2ChallengeRules
return BL
