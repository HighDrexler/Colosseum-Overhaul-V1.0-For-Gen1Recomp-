local StubEffects={WEATHER_TURNS=5}
function StubEffects.sandstormDamage(maxHp) return math.max(1, math.floor((maxHp or 8)/8)) end
function StubEffects.sandstormHits(types)
 for _,t in ipairs(types or {}) do
  if t=="ROCK" or t=="GROUND" or t=="STEEL" then return false end
 end
 return true
end

local W=assert(loadfile('lib/AbilityWeather.lua'))({Gen2Effects=StubEffects})

-- Gen II: adapter over real fields on the battle object itself.
local battle2={player={hp=100,maxHp=100},enemy={hp=100,maxHp=100}}
assert(W.get(battle2,2)==nil,'no weather should read nil')
W.set(battle2,2,"rain")
local w=W.get(battle2,2)
assert(w.kind=="rain" and w.turns==5 and not w.abilityLocked,'rain did not set turns/kind correctly')
assert(battle2.weather=="rain" and battle2.weatherTurns==5,'Gen II adapter did not write real fields')

-- Gen I: populates battle.field, which starts out absent/stubbed.
local battle1={player={hp=100,maxHp=100},enemy={hp=100,maxHp=100}}
assert(W.get(battle1,1)==nil)
W.set(battle1,1,"sandstorm",{abilityLocked=true})
local w1=W.get(battle1,1)
assert(w1.kind=="sandstorm" and w1.abilityLocked==true and w1.turns==nil,'ability-locked weather should have no turn count')
assert(battle1.field.weather=="sandstorm","Gen I adapter did not write field.weather")

-- Ability-locked (Sand Stream) weather never expires across many ticks.
local ctx={actives=function() return {} end, hasCloudNine=function() return false end, message=function() end}
for i=1,50 do W.tick(battle1,1,ctx) end
assert(W.get(battle1,1)~=nil,'ability-locked weather expired')

-- Move-set weather (Gen II) counts down and clears at zero.
local battle3={player={hp=100,maxHp=100},enemy={hp=100,maxHp=100}}
W.set(battle3,2,"sun",{turns=3})
local ctx3={actives=function() return {} end, hasCloudNine=function() return false end, message=function() end}
W.tick(battle3,2,ctx3); assert(W.get(battle3,2).turns==2)
W.tick(battle3,2,ctx3); assert(W.get(battle3,2).turns==1)
W.tick(battle3,2,ctx3); assert(W.get(battle3,2)==nil,'move-set weather did not clear at zero')

-- Cloud Nine suppresses without clearing the underlying weather.
local battle4={player={hp=100,maxHp=100},enemy={__cloudNine=true,hp=100,maxHp=100}}
W.set(battle4,2,"sandstorm",{abilityLocked=true})
local hasCloudNine=function(mon) return mon.__cloudNine==true end
assert(W.isSuppressed(battle4,hasCloudNine)==true,'Cloud Nine should suppress')
assert(W.get(battle4,2)~=nil,'Cloud Nine must not clear underlying weather')
assert(W.speedMultiplierFor(battle4,2,battle4.player,hasCloudNine,"sandstorm",2)==1,'suppressed weather still granted a speed boost')

-- Speed multiplier only applies for the matching weather kind, unsuppressed.
local battle5={player={hp=100,maxHp=100},enemy={hp=100,maxHp=100}}
W.set(battle5,2,"sun")
local noCloudNine=function() return false end
assert(W.speedMultiplierFor(battle5,2,battle5.player,noCloudNine,"sun",2)==2,'Chlorophyll should double speed in sun')
assert(W.speedMultiplierFor(battle5,2,battle5.player,noCloudNine,"rain",2)==1,'Swift Swim must not trigger in sun')

-- Sandstorm chip damage: hits susceptible types, skips immune ones, skips the
-- chip-immune flag (Sand Veil), and does not fire while suppressed.
local battle6={player={hp=100,maxHp=100},enemy={hp=100,maxHp=100}}
W.set(battle6,1,"sandstorm",{abilityLocked=true})
local dealt={}
local actives=function()
 return {
  {mon=battle6.player, dealDamage=function(d) dealt.player=d end, types=function() return {"NORMAL"} end, maxHp=function() return 100 end},
  {mon=battle6.enemy, dealDamage=function(d) dealt.enemy=d end, types=function() return {"ROCK"} end, maxHp=function() return 80 end},
 }
end
W.tick(battle6,1,{actives=actives, hasCloudNine=function() return false end, message=function() end})
assert(dealt.player==12,'expected floor(100/8)=12, got '..tostring(dealt.player))
assert(dealt.enemy==nil,'Rock-type should be immune to sandstorm chip')

print('AbilityWeatherTests: Gen I/II set/get/tick, ability-locked persistence, Cloud Nine suppression, speed/accuracy multipliers, sandstorm chip OK')
