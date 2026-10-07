













local V=... or {}
local HS={}
local SaveState=V.MtBattleSaveState
local SummitVariation=V.MtBattleSummitVariation
local GenerationCompat=V.GenerationCompat

local function standaloneHost() return V.StandaloneHost end






local function hostApi()
local host=standaloneHost()
if type(host)~="table" then return nil end
if type(host.begin)=="function" or type(host.finish)=="function" then return host end
if type(host.H)=="table" then return host.H end
return nil
end






function HS.forcePresentation(game)
local prefs=game and game.save and game.save.colosseumBattle
if type(prefs)~="table" then
game.save=game.save or {}
prefs={}
game.save.colosseumBattle=prefs
end
local original={arena=prefs.arena,doubleBattlesEnabled=prefs.doubleBattlesEnabled,
arenasEnabled=prefs.arenasEnabled}
prefs.arena="mt_battle_summit"
prefs.doubleBattlesEnabled=true
prefs.arenasEnabled=true
return function()
prefs.arena=original.arena
prefs.doubleBattlesEnabled=original.doubleBattlesEnabled
prefs.arenasEnabled=original.arenasEnabled
end
end







function HS.placeholderBattle(game,trainerModel,label)
local variation,number
local generation=tonumber(game and game.save and game.save.generation)
if GenerationCompat and type(GenerationCompat.current)=="function" then
local ok,value=pcall(GenerationCompat.current)
if ok and tonumber(value) then generation=tonumber(value) end
end
generation=generation or 1
local save=SaveState and type(SaveState.state)=="function" and SaveState.state(game)
or (game and game.save and game.save.mtBattleChallenge)
if save and save.active==true and SummitVariation and type(SummitVariation.forSave)=="function" then
number=math.max(1,math.min(math.floor(tonumber(save.totalFights) or 100),math.floor(tonumber(save.currentFight) or 1)))
variation=SummitVariation.forSave(save,number)
end
return {
game=game,kind="trainer",oppClass="MTB_HUB",
trainer={name=label or "MT. BATTLE",cbeBossIntro=false,playerModel=trainerModel},
player=nil,enemy=nil,
__mtbHub=true,__cbeGeneration=generation,
cbeMtBattleSummitVariation=variation,cbeMtBattleNumber=number,
}
end



function HS.beginBeat(game,trainerModel,label)
local host=hostApi()
if not (host and type(host.begin)=="function") then return false,"StandaloneHost.begin unavailable" end
return host.begin(HS.placeholderBattle(game,trainerModel,label))
end






function HS.endSession(reason)
local host=hostApi()
if host and type(host.finish)=="function" then host.finish(reason or "hub-closed") end
end

return HS
