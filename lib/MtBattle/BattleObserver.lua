

















local V=... or {}
local req=V.engineRequire or require
local Archetypes=V.MtBattleArchetypes
local BO={}

local function isSetupMove(mdef)
local eff=tostring(mdef and mdef.effect or "")
return eff:find("UP1") or eff:find("UP2") or eff:find("_up") or eff:find("Up")
end











function BO.attach(battle,generation,onComplete)
local Runtime=req("src.mods.Runtime")
local summary={moveTypes={},switches=0,statusMovesUsed=0,setupMovesUsed=0,
leadSpecies=nil,winConditionSpecies=nil,lastPlayerBattlerId=nil,
playerKnockouts={},enemyKnockouts={}}
local unsubs={}
local detached=false



battle.__cbeMtBattleKOTracking=true
battle.__cbeMtBattlePlayerKnockouts=summary.playerKnockouts
battle.__cbeMtBattleEnemyKnockouts=summary.enemyKnockouts
local function model(value) return type(value)=="table" and (value._model or value) or value end
local function isOurs(payload) return payload and model(payload.battle)==model(battle) end

unsubs[#unsubs+1]=Runtime.events:on("battle.move_used",function(payload)
if not isOurs(payload) then return end
local user=payload.user
if not (user and user.isPlayer) then return end
if not summary.leadSpecies and user.mon then summary.leadSpecies=user.mon.species end
local mdef=payload.move
if mdef and mdef.type then
summary.moveTypes[mdef.type]=(summary.moveTypes[mdef.type] or 0)+1
end
if mdef and Archetypes and Archetypes.effectCategory(Archetypes.STATUS_EFFECTS,generation,mdef.effect) then
summary.statusMovesUsed=summary.statusMovesUsed+1
end
if mdef and isSetupMove(mdef) then
summary.setupMovesUsed=summary.setupMovesUsed+1
end
end,0,"mtbattle-behavior")

unsubs[#unsubs+1]=Runtime.events:on("battle.battler_switched",function(payload)
if not isOurs(payload) then return end





local isPlayer=payload.isPlayer
if isPlayer==nil and payload.battler then isPlayer=payload.battler.isPlayer end
if isPlayer==nil and payload.side then isPlayer=(payload.side=="player") end
if isPlayer then summary.switches=summary.switches+1 end
end,0,"mtbattle-behavior")

local function partyIndexFor(mon,party)
for i,row in ipairs(party or {}) do if row==mon then return i end end
return nil
end

unsubs[#unsubs+1]=Runtime.events:on("battle.fainted",function(payload)
if not isOurs(payload) then return end
local battler=payload.battler
local mon=(type(battler)=="table" and battler.mon) or battler
if type(mon)~="table" then return end
local playerParty=battle.playerParty or battle.party or {}
local enemyParty=battle.enemyParty or {}
local playerIndex=partyIndexFor(mon,playerParty)
local enemyIndex=partyIndexFor(mon,enemyParty)
local isPlayer=(type(battler)=="table" and battler.isPlayer==true) or playerIndex~=nil
if not isPlayer and payload.side and battle.sides and payload.side==battle.sides[1] then
isPlayer=true
end
local row={species=mon.species,nickname=mon.nickname or mon.name,
partyIndex=isPlayer and playerIndex or enemyIndex}
if isPlayer then
summary.playerKnockouts[#summary.playerKnockouts+1]=row
battle.__cbeMtBattlePlayerKnockouts=summary.playerKnockouts
else
summary.enemyKnockouts[#summary.enemyKnockouts+1]=row
battle.__cbeMtBattleEnemyKnockouts=summary.enemyKnockouts
end
end,0,"mtbattle-behavior")

local endedUnsub
endedUnsub=Runtime.events:on("battle.ended",function(payload)
if not isOurs(payload) then return end
if detached then return end
detached=true
for _,u in ipairs(unsubs) do u() end
if endedUnsub then endedUnsub() end




if payload.result=="win" and battle.enemyParty then
local last=battle.enemyParty[#battle.enemyParty]
summary.winConditionSpecies=last and last.species or nil
end
battle.__cbeMtBattleBehaviorSummary=summary
if onComplete then onComplete(summary) end
end,0,"mtbattle-behavior")
unsubs[#unsubs+1]=endedUnsub

return function()
if detached then return end
detached=true
for _,u in ipairs(unsubs) do u() end
end
end

return BO
