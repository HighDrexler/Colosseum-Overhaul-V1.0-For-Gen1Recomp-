


local V=... or {}
local req=V.engineRequire or require
local W={}

local gen1Rules={WEATHER_TURNS=5,
sandstormDamage=function(hp)return math.max(1,math.floor((hp or 8)/8))end,
sandstormHits=function(types)
for _,kind in ipairs(types or {})do
if kind=="ROCK" or kind=="GROUND" or kind=="STEEL" then return false end
end
return true
end,
}
local function weatherRules(generation)
if generation==1 then return gen1Rules end
return V.Gen2Effects or req('src.battle.gen2.Effects')
end

local function stateFor(battle, generation)
if generation==2 then return battle end
battle.field=battle.field or {}
return battle.field
end

function W.get(battle, generation)
local s=stateFor(battle, generation)
if not s.weather then return nil end
return {kind=s.weather, turns=s.weatherTurns, abilityLocked=s.weatherAbilityLocked==true}
end



function W.set(battle, generation, kind, opts)
local s=stateFor(battle, generation)
s.weather=kind
if opts and opts.abilityLocked then
s.weatherTurns=nil
s.weatherAbilityLocked=true
else
s.weatherTurns=(opts and opts.turns) or weatherRules(generation).WEATHER_TURNS
s.weatherAbilityLocked=false
end
end

function W.clear(battle, generation)
local s=stateFor(battle, generation)
s.weather=nil
s.weatherTurns=nil
s.weatherAbilityLocked=false
end





function W.isSuppressed(battle, hasCloudNine)
if type(hasCloudNine)~="function" then return false end
local values=V.Abilities and V.Abilities.actives(battle) or {battle.player,battle.enemy}
for _,value in ipairs(values) do
local mon=value and (value.mon or value)
if mon and (mon.hp or 0)>0 and hasCloudNine(value) then return true end
end
return false
end



function W.speedMultiplierFor(battle, generation, mon, hasCloudNine, weatherKind, multiplier)
local w=W.get(battle, generation)
if not w or w.kind~=weatherKind then return 1 end
if W.isSuppressed(battle, hasCloudNine) then return 1 end
return multiplier or 2
end



function W.sandAccuracyMultiplier(battle, generation, hasCloudNine, multiplier)
local w=W.get(battle, generation)
if not w or w.kind~="sandstorm" then return 1 end
if W.isSuppressed(battle, hasCloudNine) then return 1 end
return multiplier or 0.8
end







function W.tick(battle, generation, ctx)
local s=stateFor(battle, generation)
if not s.weather then return end

if s.weatherAbilityLocked and s.weatherTurns~=nil then s.weatherAbilityLocked=false end
if not s.weatherAbilityLocked then
s.weatherTurns=(s.weatherTurns or 1)-1
if s.weatherTurns<=0 then
local old=s.weather;W.clear(battle,generation)
if ctx.message then ctx.message("The "..old.." ended.") end
return
end
end
if s.weather=="sandstorm" and not W.isSuppressed(battle,ctx.hasCloudNine) then
local Effects=weatherRules(generation)
for _,entry in ipairs(ctx.actives()) do
if (not entry.mon or (entry.mon.hp or 0)>0) and (not entry.isImmune or not entry.isImmune())
and Effects.sandstormHits(entry.types and entry.types() or {}) then
local dmg=Effects.sandstormDamage(entry.maxHp and entry.maxHp())
entry.dealDamage(dmg)
end
end
end
end

return W
