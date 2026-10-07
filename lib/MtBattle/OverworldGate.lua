

















local V=... or {}
local req=V.engineRequire or require
local EntryFlow=V.MtBattleEntryFlow
local OG={}

OG.TAG="mtBattleGate"



OG.liveGame=nil
OG.trainerModel="wes"

local function wrapTalkTo(target,onGate)
if type(target)~="table" or type(target.talkTo)~="function" then return false end
if target.__mtbWrapped then return true end
local original=target.talkTo
target.talkTo=function(self,npc)
if npc and npc.def and npc.def[OG.TAG] then
return onGate(self,npc) and true or false
end
return original(self,npc)
end
target.__mtbWrapped=true
return true
end





function OG.installTalkHook(onGate)
local ok,OverworldState=pcall(req,"src.world.OverworldController")
if ok then wrapTalkTo(OverworldState,onGate) end
end









function OG.spawn(mod,mapId,x,y,spriteId,textId)
if not (mod and mod.world and mod.world.spawnNpc) then return nil,"mod.world unavailable" end
return mod.world:spawnNpc(mapId,{
sprite=spriteId,x=x,y=y,range="ANY_DIR",movement="STILL",
text=textId,[OG.TAG]=true,
})
end










local function defaultOnGateOpened(overworld)
if not EntryFlow then return false,"Mt. Battle entry flow unavailable" end
local game,why
if type(EntryFlow.resolveGame)=="function" then
game,why=EntryFlow.resolveGame(nil,overworld)
else
game=OG.liveGame or (OG.mod and OG.mod.game)
end
if not game then
OG.lastEntryError=why or "Mt. Battle live game unavailable"
local log=OG.mod and OG.mod.log
if log and type(log.warn)=="function" then
pcall(log.warn,log,"MTB ENTRY FIX 1: %s",OG.lastEntryError)
end
return false,OG.lastEntryError
end
OG.liveGame=game
local open=EntryFlow.showOffer or EntryFlow.start
local ok,detail=open(game,OG.trainerModel)

OG.lastEntryError=ok==false and detail or nil
return ok~=false,detail
end
OG.onGateOpened=defaultOnGateOpened

function OG.install(mod,opts)
if OG.installed then return end
OG.installed=true
OG.mod=mod
opts=opts or {}

local function observeGame(game)
if EntryFlow and type(EntryFlow.observeGame)=="function" then
OG.liveGame=EntryFlow.observeGame(game)
else
OG.liveGame=game
end
end



if mod.hooks and type(mod.hooks.wrap)=="function" then
mod.hooks:wrap("input.step",function(next,game,dt,...)
observeGame(game)
return next(game,dt,...)
end,10000)
end






















local defaultSprite=opts.spriteId or "SPRITE_SCIENTIST"
local defaultText=opts.textId or "TEXT_MTBATTLE_VR_OFFER"
local gates=opts.gates or {
{mapId="INDIGO_PLATEAU_LOBBY",x=2,y=9},
{mapId="INDIGO_PLATEAU_POKECENTER_1F",x=1,y=12},
}

if opts.mapId then
gates={{mapId=opts.mapId,x=opts.x or 1,y=opts.y or 12}}
end
if opts.trainerModel then OG.trainerModel=opts.trainerModel end
if opts.onGateOpened then OG.onGateOpened=opts.onGateOpened end

OG.installTalkHook(function(overworld,npc)
if type(OG.onGateOpened)=="function" then OG.onGateOpened(overworld,npc) end
return true
end)

if mod.world and type(mod.world.talkTo)=="function" then
wrapTalkTo(mod.world,function(overworld,npc)
if type(OG.onGateOpened)=="function" then OG.onGateOpened(overworld,npc) end
return true
end)
end

if mod.events and type(mod.events.on)=="function" then
mod.events:on("game.ready",function(payload)
local game=type(payload)=="table" and payload.game or nil
observeGame(game)
end)
mod.events:on("map.entered",function(payload)
local enteredMapId=type(payload)=="table" and (payload.mapId or payload.id) or nil
if not enteredMapId then return end
for _,gate in ipairs(gates) do
if enteredMapId==gate.mapId then
OG.spawn(
mod,
gate.mapId,
gate.x,
gate.y,
gate.spriteId or defaultSprite,
gate.textId or defaultText
)
break
end
end
end)
end
end

return OG
