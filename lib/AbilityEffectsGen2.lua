






local V=... or {}
local unpack=unpack or table.unpack
local function pack(...)return {n=select('#',...),...}end
local req=V.engineRequire or require
local Abilities=V.Abilities or error("AbilityEffectsGen2 requires Abilities to load first")
local Weather=V.AbilityWeather or error("AbilityEffectsGen2 requires AbilityWeather to load first")
local M={}
local installed=false
local Effects


local function enabled(battle)
return Abilities.enabledBattle(battle)
end

local function dexOf(battle, mon)
if not mon then return nil end
local def=battle and battle.data and battle.data.pokemon and battle.data.pokemon[mon.species]
return Abilities.dexOf(mon, def)
end



local function abilityOf(battle, mon)
if not mon then return nil end
return Abilities.current(battle, mon, dexOf(battle, mon))
end

local function hasAbility(battle, mon, id)
return abilityOf(battle, mon)==id
end

local function fieldHasAbility(battle,id)
for _,value in ipairs(Abilities.actives(battle) or {}) do
local mon=value and (value.mon or value)
if mon and abilityOf(battle,mon)==id then return true end
end
return false
end

local PHYSICAL_TYPES={NORMAL=true,FIGHTING=true,FLYING=true,POISON=true,GROUND=true,
ROCK=true,BUG=true,GHOST=true,STEEL=true}
local function isPhysical(move)
if not move then return false end


return PHYSICAL_TYPES[move.type]==true
end

local function shallow(t)
local out={}
for k,v in pairs(t or {}) do out[k]=v end
return out
end

local LOW_HP_TYPE={}
for id,meta in pairs(Abilities.data.byId) do
if meta.category=="low_hp_power" then LOW_HP_TYPE[id]=meta.moveType end
end
local STATUS_VETO={}
for id,meta in pairs(Abilities.data.byId) do
if meta.category=="status_veto" then STATUS_VETO[id]=meta.status end
end
local STAT_VETO={}
for id,meta in pairs(Abilities.data.byId) do
if meta.category=="stat_veto" then STAT_VETO[id]=meta.stat end
end
local CONTACT_REACTIVE={}
local CONTACT_DAMAGE={}
for id,meta in pairs(Abilities.data.byId) do
if meta.category=="contact_reactive" and meta.effect~="ATTRACT" then
CONTACT_REACTIVE[id]={effect=meta.effect, chance=meta.chance, options=meta.options}
elseif meta.category=="contact_damage" then
CONTACT_DAMAGE[id]=meta.fraction or (1/16)
end
end







local function statusEquals(a, b)
if not (a and b) then return a==b end
local names={BRN="BURN",PSN="POISON",TOX="TOXIC",PAR="PARALYZE",SLP="SLEEP",FRZ="FREEZE",CONFUSION="CONFUSE"}
a=tostring(a):upper();b=tostring(b):upper()
a=names[a] or a;b=names[b] or b
return a==b or (a=="POISON" and b=="TOXIC")
end








local function installDealDamage(Battle)
local orig=Battle.dealDamage
Battle.dealDamage=function(self, attacker, defender, damage, opts)
if not enabled(self) then return orig(self, attacker, defender, damage, opts) end
local atkAbility=abilityOf(self, attacker)
local defAbility=abilityOf(self, defender)
local moveDef=opts and (opts.move or opts.def)
local moveType=opts and (opts.type or (moveDef and moveDef.type))

if defAbility then
local meta=Abilities.meta(defAbility)
if meta and (meta.category=="type_immune" or meta.category=="type_immune_boost")
and meta.moveType==moveType then
if meta.category=="type_immune_boost" then Abilities.runtime(self,defender).flashFire=true end
Abilities.message(self,Abilities.displayName(defAbility).." blocked the move!")
return 0
end
if meta and meta.category=="type_absorb_heal" and meta.moveType==moveType then
if defender.hp then
defender.hp=math.min(Abilities.maxHP(defender), defender.hp+math.max(1,math.floor(Abilities.maxHP(defender)*(meta.healFraction or 0.25))))
end
return 0
end
end

if atkAbility and damage>0 then




local activeMeta=Abilities.meta(atkAbility)
if activeMeta and activeMeta.category=="type_immune_boost" and activeMeta.moveType==moveType
and Abilities.runtime(self,attacker).flashFire then
damage=math.floor(damage*(activeMeta.multiplier or 1.5))
end
end
return orig(self, attacker, defender, damage, opts)
end
end






local function installAccuracy(Battle,Damage)
local orig=Battle.accuracyRoll
Battle.accuracyRoll=function(self,def,attacker,defender,accuracy)
if not enabled(self) then return orig(self,def,attacker,defender,accuracy) end
local a=abilityOf(self,attacker);local d=abilityOf(self,defender)
local active=a=="COMPOUNDEYES" or (a=="HUSTLE" and isPhysical(def)) or d=="SAND_VEIL"
local origRoll=Damage and Damage.rollHit
if not (active and origRoll and Damage.stageMultiplier) then return orig(self,def,attacker,defender,accuracy) end
Damage.rollHit=function(base,accuracyStage,evasionStage,random)
if not base or base<=0 then return true end


local num,den=Damage.stageMultiplier(accuracyStage or 0)
local value=math.floor(base*num/den)
num,den=Damage.stageMultiplier(-(evasionStage or 0))
value=math.floor(value*num/den)
value=math.max(1,math.min(100,value))
if a=="COMPOUNDEYES" then value=math.floor(value*130/100) end
if d=="SAND_VEIL" then
if Weather.sandAccuracyMultiplier(self,2,function(mon)return hasAbility(self,mon,"CLOUD_NINE")end)<1 then
value=math.floor(value*80/100)
end
end
if a=="HUSTLE" and isPhysical(def) then value=math.floor(value*80/100) end
return origRoll(value,0,0,random)
end
local result=pack(pcall(orig,self,def,attacker,defender,accuracy))
Damage.rollHit=origRoll
if not result[1] then error(result[2],0) end
return unpack(result,2,result.n)
end
end





local function installStatus(Battle)
local orig=Battle.applyStatus
Battle.applyStatus=function(self, mon, status, source)
if not enabled(self) then return orig(self, mon, status, source) end
local ability=abilityOf(self, mon)
local veto=ability and STATUS_VETO[ability]
if veto and statusEquals(veto, status) then
return false
end
local before=mon.status
local ok=orig(self, mon, status, source)
local after=mon.status
if ok and after and after~=before and not self.__cbeSynchronizing
and (statusEquals(status,"BRN") or statusEquals(status,"PSN") or statusEquals(status,"PAR")) then



local sourceMon=(type(source)=="table" and source.species) and source or nil
if sourceMon and sourceMon~=mon and hasAbility(self, mon, "SYNCHRONIZE") then
local prior=self.__cbeSynchronizing;self.__cbeSynchronizing=true
local ok,err=pcall(self.applyStatus,self,sourceMon,status,mon)
self.__cbeSynchronizing=prior
if not ok then error(err,0) end
end
end
return ok
end
if type(Battle.applyConfusion)=="function" then
local confuse=Battle.applyConfusion
Battle.applyConfusion=function(self,mon,...)
if enabled(self) and hasAbility(self,mon,"OWN_TEMPO") then return false end
return confuse(self,mon,...)
end
end
end









local function installStatStage(Battle)
local orig=Battle.changeStageAgainstMist
if not orig then return end
Battle.changeStageAgainstMist=function(self, attacker, target, stat, stages)
if enabled(self) and target~=attacker and stages<0 then
local ability=abilityOf(self, target)
local veto=ability and STAT_VETO[ability]
if veto=="ALL" or veto==stat then
return false
end
end
return orig(self, attacker, target, stat, stages)
end
end





local function installOhko(Battle)



local original=Battle.moveEffectRecordFor
if not original then return end
Battle.moveEffectRecordFor=function(data,effect)
local record=original(data,effect)
if effect~="EFFECT_OHKO" or not record or type(record.run)~="function" then return record end
local out={};for k,v in pairs(record)do out[k]=v end
out.run=function(self,attacker,defender,...)
if enabled(self) and hasAbility(self,defender,"STURDY") then
self:markMissed();Abilities.message(self,"STURDY blocked the one-hit KO!");return
end
return record.run(self,attacker,defender,...)
end
return out
end
end





local function installPressure(Battle)
local orig=Battle.useMove
if not orig then return end
Battle.useMove=function(self,attacker,defender,moveId)
if not enabled(self) then return orig(self,attacker,defender,moveId) end
local move=self:findMove(attacker,moveId);local pp=move and move.pp
local def=self:moveDef(moveId)
local oldMoveDef=rawget(self,"moveDef");local resolve=self.moveDef
local adjusted
if def then
adjusted={};for key,value in pairs(def) do adjusted[key]=value end
if hasAbility(self,attacker,"SERENE_GRACE") and type(adjusted.effectChance)=="number" then
adjusted.effectChance=math.min(100,adjusted.effectChance*2)
end
local onHit=Effects and Effects.STAT_CHANGES_ON_HIT and Effects.STAT_CHANGES_ON_HIT[def.effect]
if hasAbility(self,defender,"SHIELD_DUST") and def.effect~="EFFECT_ALL_UP_HIT" and not (onHit and onHit[3]=="self") then adjusted.effectChance=0 end
if hasAbility(self,defender,"INNER_FOCUS") and def.effect=="EFFECT_FLINCH_HIT" then adjusted.effectChance=0 end


if hasAbility(self,attacker,"ROCK_HEAD") and def.effect=="EFFECT_RECOIL_HIT" and moveId~="STRUGGLE" then adjusted.effect="EFFECT_NORMAL_HIT" end
self.moveDef=function(b,id) if id==moveId then return adjusted end return resolve(b,id) end
end
local oldOoze=self.__cbeLiquidOozeRedirect
if def and Effects and Effects.DRAIN and Effects.DRAIN[def.effect] and def.effect~="EFFECT_DREAM_EATER" and hasAbility(self,defender,"LIQUID_OOZE") then self.__cbeLiquidOozeRedirect=attacker end
local oldWeather=self.weather
local suppressed=Weather.isSuppressed(self,function(mon)return hasAbility(self,mon,"CLOUD_NINE")end)
local weatherMove=def and (def.effect=="EFFECT_RAIN_DANCE" or def.effect=="EFFECT_SUNNY_DAY" or def.effect=="EFFECT_SANDSTORM")
if suppressed and not weatherMove then self.weather=nil end







local soundBlocked=defender and defender~=attacker and hasAbility(self,defender,"SOUNDPROOF")
and Abilities.isSoundMove and Abilities.isSoundMove(def)
local savedRecordResolver=Battle.moveEffectRecordFor
if soundBlocked and type(savedRecordResolver)=="function" then
local blockedEffect=(adjusted or def).effect
Battle.moveEffectRecordFor=function(data,effect)
if effect==blockedEffect then
return {kind="full",run=function(battle)
if type(battle.markMissed)=="function" then battle:markMissed() end
Abilities.message(battle,"SOUNDPROOF blocked the move!")
end}
end
return savedRecordResolver(data,effect)
end
end
local result=pack(pcall(orig,self,attacker,defender,moveId))
if soundBlocked and type(savedRecordResolver)=="function" then Battle.moveEffectRecordFor=savedRecordResolver end
if suppressed and not weatherMove then self.weather=oldWeather end
if weatherMove and self.weatherTurns~=nil then self.weatherAbilityLocked=false end
self.moveDef=oldMoveDef;self.__cbeLiquidOozeRedirect=oldOoze
if not result[1] then error(result[2],0) end
if not self.__cbeDoublesKernel and move and type(pp)=="number" and move.pp<pp and defender~=attacker and hasAbility(self,defender,"PRESSURE") then move.pp=math.max(0,move.pp-1) end
return unpack(result,2,result.n)
end
end












local function installHeal(Battle)
local orig=Battle.heal
if not orig then return end
Battle.heal=function(self, mon, amount, opts)
if enabled(self) and self.__cbeLiquidOozeRedirect==mon then
self.__cbeLiquidOozeRedirect=nil
local before=mon.hp or 0;mon.hp=math.max(0,before-math.max(0,math.floor(amount or 0)))
self:emit({kind="damage",side=self:sideOf(mon),amount=before-mon.hp,hp=mon.hp,anim=false})
Abilities.message(self,"LIQUID OOZE hurt the draining Pokemon!")
return -(before-mon.hp)
end
return orig(self, mon, amount, opts)
end
end

local function installHitOnce(Battle, Damage)
local orig=Battle.hitOnce
if not orig then return end
Battle.hitOnce=function(self,attacker,defender,def,opts)
if not enabled(self) then return orig(self,attacker,defender,def,opts) end
local atkAbility=abilityOf(self,attacker)
local defAbility=abilityOf(self,defender);local meta=Abilities.meta(defAbility)


if meta and meta.moveType==def.type and (meta.category=="type_immune" or meta.category=="type_immune_boost" or meta.category=="type_absorb_heal") then
if meta.category=="type_immune_boost" then Abilities.runtime(self,defender).flashFire=true end
if meta.category=="type_absorb_heal" then self:heal(defender,math.max(1,math.floor(Abilities.maxHP(defender)*(meta.healFraction or .25)))) end
self:markMissed();Abilities.message(self,Abilities.displayName(defAbility).." blocked the move!")
return 0,{critical=false,crit=false,effectiveness=0,typeMult=0,ability=defAbility}
end
local origCrit=Damage and Damage.rollCritical
if meta and meta.category=="crit_immune" and origCrit then Damage.rollCritical=function()return false end end




local origCalc=Damage and Damage.calc
if origCalc then
Damage.calc=function(calc)
local c=shallow(calc);c.attacker=shallow(calc and calc.attacker);c.defender=shallow(calc and calc.defender)
local physical=isPhysical(def)
if physical then
local attack=tonumber(c.attacker.attack)


if atkAbility=="GUTS" and attacker and attacker.status
and type(self.battleStat)=="function" then
attack=tonumber(self:battleStat(attacker,"attack")) or attack
end
if attack then
if atkAbility=="HUGE_POWER" or atkAbility=="PURE_POWER" then attack=attack*2
elseif atkAbility=="HUSTLE" then attack=math.floor(attack*150/100)
elseif atkAbility=="GUTS" and attacker and attacker.status then attack=math.floor(attack*150/100) end
c.attacker.attack=attack
end
end
if meta and meta.category=="type_damage_half" then
for _,t in ipairs(meta.moveTypes or {}) do
if t==def.type and c.attacker.specialAttack then
c.attacker.specialAttack=math.floor(c.attacker.specialAttack/2)
break
end
end
end
local partnerMeta=atkAbility and Abilities.meta(atkAbility)
if partnerMeta and partnerMeta.category=="field_partner_special_boost"
and fieldHasAbility(self,partnerMeta.partnerAbility) and c.attacker.specialAttack then
c.attacker.specialAttack=math.floor(c.attacker.specialAttack*(partnerMeta.multiplier or 1.5))
end
if defAbility=="MARVEL_SCALE" and defender and defender.status and c.defender.defense then
c.defender.defense=math.floor(c.defender.defense*150/100)
end
local lowHpType=atkAbility and LOW_HP_TYPE[atkAbility]
if lowHpType and def.type==lowHpType and attacker and attacker.hp
and attacker.hp<=math.floor(Abilities.maxHP(attacker)/3)
and tonumber(c.power) and c.power>0 then
c.power=math.floor(c.power*150/100)
end
local damage,info=origCalc(c)
if defAbility=="WONDER_GUARD" and damage and damage>0
and (tonumber(info and (info.effectiveness or info.typeMult)) or 10)<=10 then
local blocked=type(info)=="table" and shallow(info) or {}
blocked.ability=defAbility;blocked.wonderGuard=true;blocked.effectiveness=0;blocked.typeMult=0;blocked.immune=true
return 0,blocked
end
return damage,info
end
end
local substitute=self.volatile and (self:volatile(defender).substitute or 0)>0
local result=pack(pcall(orig,self,attacker,defender,def,opts))
if origCrit then Damage.rollCritical=origCrit end
if origCalc then Damage.calc=origCalc end
if not result[1] then error(result[2],0) end
local dealt=result[2]
local info=result[3]
if info and info.wonderGuard then Abilities.message(self,"WONDER GUARD blocked the move!") end
if dealt and dealt>0 and not substitute and (attacker.hp or 0)>0 and Abilities.isContactMove(def.id,def) then
local fraction=defAbility and CONTACT_DAMAGE[defAbility]
if fraction then
self:dealDamage(defender,attacker,math.max(1,math.floor(Abilities.maxHP(attacker)*fraction)),{ability=defAbility,indirect=true})
Abilities.message(self,Abilities.displayName(defAbility).." hurt the attacker!")
return unpack(result,2,result.n)
end
local reactive=defAbility and CONTACT_REACTIVE[defAbility]
if reactive and Abilities.random(self)<reactive.chance then
local status=reactive.effect=="RANDOM_MINOR" and reactive.options[Abilities.pick(self,#reactive.options)] or reactive.effect
status=({BRN="burn",PSN="poison",PAR="paralyze",SLP="sleep"})[status] or status
self:applyStatus(attacker,status,defender)
end
end
return unpack(result,2,result.n)
end
end










function M.tickWeather(battle,actives)
Weather.tick(battle,2,{
hasCloudNine=function(mon)return hasAbility(battle,mon,"CLOUD_NINE")end,
actives=function()
local out={}
for _,mon in ipairs(actives or Abilities.actives(battle)) do
if (mon.hp or 0)>0 then out[#out+1]={mon=mon,
maxHp=function()return Abilities.maxHP(mon)end,
types=function()return Abilities.types(battle,mon)end,
isImmune=function()return battle:volatile(mon).vanished or hasAbility(battle,mon,"SAND_VEIL")end,
dealDamage=function(damage)
local before=mon.hp;mon.hp=math.max(0,mon.hp-damage)
Abilities.message(battle,(battle:monName(mon) or "Pokemon").." is buffeted by the sandstorm!")
battle:emit({kind="damage",side=battle:sideOf(mon),amount=before-mon.hp,hp=mon.hp,anim="ANIM_IN_SANDSTORM"})
end}
end
end
return out
end,
message=function(text)Abilities.message(battle,text)end})
end
local function installTickWeather(Battle)
local orig=Battle.tickWeather
if orig then Battle.tickWeather=function(self)
if not enabled(self) then


if self.weatherAbilityLocked and self.weatherTurns==nil then self.weatherTurns=5;self.weatherAbilityLocked=nil end
return orig(self)
end
return M.tickWeather(self,Abilities.actives(self))
end end
local speed=Battle.effectiveSpeed
if speed then Battle.effectiveSpeed=function(self,mon)
local value=speed(self,mon);local meta=Abilities.meta(abilityOf(self,mon))
if meta and meta.category=="weather_speed" then
value=value*Weather.speedMultiplierFor(self,2,mon,function(m)return hasAbility(self,m,"CLOUD_NINE")end,meta.weather,meta.multiplier)
end
return value
end end
local spikes=Battle.spikesDamage
if spikes then Battle.spikesDamage=function(self,mon)
if enabled(self) and hasAbility(self,mon,"LEVITATE") then return end
return spikes(self,mon)
end end
local locked=Battle.switchLocked
if locked then Battle.switchLocked=function(self)
if locked(self) then return true end
if not enabled(self) or not self.player or (self.player.hp or 0)<=0 then return false end
local a=abilityOf(self,self.enemy);local types=Abilities.types(self,self.player);local flying,steel=false,false
for _,t in ipairs(types) do flying=flying or t=="FLYING";steel=steel or t=="STEEL" end
return a=="SHADOW_TAG" or (a=="ARENA_TRAP" and not flying and not hasAbility(self,self.player,"LEVITATE")) or (a=="MAGNET_PULL" and steel)
end end
end




local function installEarlyBird(Battle)
local orig=Battle.canAct
if not orig then return end
Battle.canAct=function(self,mon)
if enabled(self) and mon and mon.status=="sleep" and abilityOf(self,mon)=="EARLY_BIRD" then
local vol=self.volatile and self:volatile(mon) or nil


if not (vol and vol.recharge) then mon.statusTurns=(mon.statusTurns or 1)-1 end
end
return orig(self,mon)
end
end





function M.installGlobal(ctx)
if installed then return true end
local req2=(ctx and ctx.engineRequire) or req
local Battle=(ctx and ctx.Battle) or req2('src.battle.gen2.Battle')
local Damage=(ctx and ctx.Damage) or req2('src.battle.gen2.Damage')
Effects=(ctx and ctx.Effects) or req2('src.battle.gen2.Effects')
installDealDamage(Battle)
installAccuracy(Battle,Damage)
installStatus(Battle)
installStatStage(Battle)
installOhko(Battle)
installPressure(Battle)
installHeal(Battle)
installHitOnce(Battle, Damage)
installTickWeather(Battle)
installEarlyBird(Battle)
installed=true
return true
end






function M.onEnter(battle, mon, opponents)
if not enabled(battle) or not mon or (mon.hp or 0)<=0 then return end
local ability=abilityOf(battle, mon)
if not ability then return end
local meta=Abilities.meta(ability)
if not meta then return end
local list=opponents
if list and list.species then list={list} end
if meta.category=="switch_in_stat" then
Abilities.message(battle,"INTIMIDATE activated!")
for _,opp in ipairs(list or {}) do
battle:changeStageAgainstMist(mon, opp, meta.stat, meta.stages or -1)
end
elseif meta.category=="switch_in_weather" then
Weather.set(battle, 2, meta.weather, {abilityLocked=meta.turns=="infinite"})
Abilities.message(battle,"SAND STREAM stirred up a sandstorm!")
elseif meta.category=="switch_in_copy_ability" then
local pool={}
for _,opp in ipairs(list or {}) do
local oppAbility=abilityOf(battle, opp)
if oppAbility and oppAbility~="TRACE" then pool[#pool+1]=oppAbility end
end
if #pool>0 then
Abilities.runtime(battle,mon).trace=pool[Abilities.pick(battle,#pool)]
Abilities.message(battle,"TRACE copied "..(Abilities.displayName(Abilities.runtime(battle,mon).trace) or "an ability").."!")
M.onEnter(battle,mon,list)
end
end
end

function M.onLeave(battle, mon)
if not mon then return end
if not enabled(battle) then Abilities.reset(battle,mon);return end
if hasAbility(battle, mon, "NATURAL_CURE") then
Abilities.cure(battle,mon)
end
Abilities.reset(battle,mon)
end









function M.onEndOfTurn(battle, actives)
if not enabled(battle) then return end
for _,mon in ipairs(actives or {}) do
local ability=(mon.hp or 0)>0 and abilityOf(battle, mon)
if ability=="SHED_SKIN" and mon.status and Abilities.random(battle)<1/3 then
Abilities.cure(battle,mon)
elseif ability=="SPEED_BOOST" then
battle:changeStage(mon, "speed", 1)
end
end
end

M.enabled=enabled
M.abilityOf=abilityOf
M.hasAbility=hasAbility
M.dexOf=dexOf

return M
