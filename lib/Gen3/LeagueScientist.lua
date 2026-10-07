



local V=...
local req=V.engineRequire or require
local S={installed=false,TAG='__cbeLeagueScientist',LOCAL_ID=190}
S.GATES={
FR_INDIGO_PLATEAU_POKEMON_CENTER_1F={x=2,y=13,graphicsId=55},
EM_EVER_GRANDE_CITY_POKEMON_LEAGUE_1F={x=2,y=9,graphicsId=46},
}

function S.template(mapId)
local gate=S.GATES[mapId]
if not gate then return nil end
return {localId=S.LOCAL_ID,index=S.LOCAL_ID,x=gate.x,y=gate.y,
graphicsId=gate.graphicsId,graphics=gate.graphicsId,
sprite='SPRITE_SCIENTIST',elevation=3,flag=0,kind=0,
movement='STAY',range='DOWN',rangeX=0,rangeY=0,
scriptKey='cbe:mt_battle_scientist',trainerType=0,trainerRange=0,
[S.TAG]=true}
end

function S.withTemplate(mapId,mapDef,space,load)
local template=S.template(mapId)
if not template then return load() end
local events=space and space.bundle and space.bundle.events
local event=events and events[mapId]
local owner=event or mapDef
if type(owner)~='table' then return load() end
local key=event and (event.objects and 'objects' or event.objectEvents and 'objectEvents' or 'objects') or 'objects'
local original=owner[key]
if type(original)~='table' then return load() end
for _,def in ipairs(original) do
if def[S.TAG] or tonumber(def.localId or def.index)==S.LOCAL_ID then return load() end
end
local rows={};for i,def in ipairs(original) do rows[i]=def end
rows[#rows+1]=template
owner[key]=rows
local result={pcall(load)}
owner[key]=original
if not result[1] then error(result[2],0) end
return unpack(result,2)
end

function S.talk(eo)
if not (eo and eo.def and eo.def[S.TAG]) then return false end
local Objects=req('src.core.game3.objects')
local Message=req('src.ui.game3.message')
local Choice=req('src.ui.game3.choice')
Objects.freeze(S.LOCAL_ID)
Objects.facePlayer(S.LOCAL_ID,V.mod.game)
Message.show('I study virtual battles at Mt. Battle.\nWant to enter the challenge?',function()
Choice.yesNo(function(yes)
Message.close()
Objects.unfreeze(S.LOCAL_ID)
if yes then V.Gen3Challenge.open() end
end)
end)
return true
end

function S.install()
if S.installed then return true end
local Objects=req('src.core.game3.objects')
if not Objects.__cbeLeagueScientistLoadMap then
local original=Objects.loadMap
Objects.loadMap=function(game,mapId,mapDef,...)
local args={...}
return S.withTemplate(mapId,mapDef,req('src.core.game3.scripting.space'),function()
return original(game,mapId,mapDef,unpack(args))
end)
end
Objects.__cbeLeagueScientistLoadMap=original
end
V.mod.hooks:wrap('world.talk',function(next,game,eo,...)
if S.talk(eo) then return true end
return next(game,eo,...)
end,1000)
S.installed=true
return true
end

return S
