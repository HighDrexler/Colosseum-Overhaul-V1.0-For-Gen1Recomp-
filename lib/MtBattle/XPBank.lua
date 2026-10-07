
















local V=... or {}
local req=V.engineRequire or require
local XP={}

local function experience() return req("src.battle.Experience") end
local function gen2Mon() return req("src.battle.gen2.Mon") end
local function runtime() return req("src.mods.Runtime") end

local ZERO_STATS_G1={hp=0,attack=0,defense=0,speed=0,special=0}









function XP.computeShare(generation,data,defeatedDef,level,participants)
local real
if generation==2 then
real=gen2Mon().experienceGain(defeatedDef,level,participants,true,{})
else
real=experience().gainFor(defeatedDef,level,true,participants,false,data and data.constants)
end
return math.floor((real or 0)*0.5)
end




function XP.accrue(game,SaveState,share)
if not share or share<=0 then return end
local s=SaveState.state(game)
s.xpBank=(s.xpBank or 0)+share
end




function XP.forfeit(game,SaveState)
local s=SaveState.state(game)
s.xpBank=0
end








local function withoutEvents(fn)
local R=runtime()
local original=R.emit
R.emit=function() end
local ok,a,b,c=pcall(fn)
R.emit=original
if not ok then error(a,0) end
return a,b,c
end




local function deepCopy(t)
if type(t)~="table" then return t end
local out={}
for k,v in pairs(t) do out[k]=deepCopy(v) end
return out
end






function XP.preview(generation,data,mon,amount)
local fromLevel,fromStats=mon.level,mon.stats
if not amount or amount<=0 then
return {fromLevel=fromLevel,toLevel=fromLevel,fromStats=fromStats,toStats=fromStats}
end
local clone=deepCopy(mon)
withoutEvents(function()
if generation==2 then
gen2Mon().gainExperience(clone,amount,data)
else
local defeatedDef={baseExp=amount,baseStats=ZERO_STATS_G1}
experience().apply(data,clone,defeatedDef,7,false,1,false)
end
end)
return {fromLevel=fromLevel,toLevel=clone.level,fromStats=fromStats,toStats=clone.stats}
end





function XP.commit(generation,data,mon,amount)
if not amount or amount<=0 then return end
if generation==2 then
gen2Mon().gainExperience(mon,amount,data)
else
local defeatedDef={baseExp=amount,baseStats=ZERO_STATS_G1}
experience().apply(data,mon,defeatedDef,7,false,1,false)
end
end

return XP
