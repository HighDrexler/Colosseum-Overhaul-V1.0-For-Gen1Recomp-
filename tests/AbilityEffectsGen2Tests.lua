-- Wrapper signatures/state isolation only. Native recoil, status and secondary
-- semantics are tested against actual useMove/hitOnce in the native suite.
local Data=assert(loadfile('lib/AbilityData.lua'))()
local A=assert(loadfile('lib/Abilities.lua')){AbilityData=Data}
local E={WEATHER_TURNS=5,DRAIN={EFFECT_LEECH_HIT=true}}
local W=assert(loadfile('lib/AbilityWeather.lua')){Gen2Effects=E}
local count=0;local function check(v,msg)count=count+1;assert(v,msg)end
local marker={};local Damage={rollCritical=function()return true end};local records={EFFECT_OHKO={run=function(ctx)return marker end}}
local def={id='TEST',type='NORMAL',power=40,accuracy=70,effect='EFFECT_NORMAL_HIT'}
local B={moveEffectRecordFor=function(data,id)return records[id]end}
function B.dealDamage(self,a,d,n,o)d.hp=d.hp-n;return n end
function B.heal(self,m,n)m.hp=math.min(m.maxHp,m.hp+n)end
function B.emit(self,e)end
function B.accuracyRoll(self,m,a,d,n)self.seenAccuracy=n or m.accuracy;return false,marker end
function B.applyStatus(self,m,s,source)m.status=s;return true end
function B.applyConfusion(self,m,n)m.confusion=n;return true end
function B.changeStageAgainstMist(self,a,d,s,n)return marker end
function B.moveDef(self,id)return def end
function B.findMove(self,m,id)return m.moves[1]end
function B.useMove(self,a,d,id)self.seenDef=self:moveDef(id);if self.fail then error('native move failure')end;a.moves[1].pp=a.moves[1].pp-1;return nil,marker,nil end
function B.hitOnce(self,a,d,m,o)if self.fail then error('native hit failure')end;return Damage.rollCritical()and 80 or 40,marker end
function B.volatile(self,m)m.volatile=m.volatile or{};return m.volatile end
function B.markMissed(self,id)self.missed=true end
function B.tickWeather(self)self.weatherTurns=self.weatherTurns-1 end
local M=assert(loadfile('lib/AbilityEffectsGen2.lua')){Abilities=A,AbilityWeather=W}
M.installGlobal{Battle=B,Damage=Damage,Effects=E}
local b=setmetatable({save={colosseumBattle={abilitiesEnabled=true}},data={pokemon={}},say=function()end},{__index=B})
local u={species='TEST',hp=70,maxHp=100,abilityId='COMPOUNDEYES',moves={{id='TEST',pp=20}}}
local t={species='TEST',hp=70,maxHp=100,abilityId='RUN_AWAY',moves={{id='TEST',pp=20}}};b.player=u;b.enemy=t
local hit,ret=b:accuracyRoll(def,u,t);check(hit==false and ret==marker,'accuracy veto/returns lost');check(b.seenAccuracy==91 and def.accuracy==70,'accuracy data mutated')
t.abilityId='WATER_VEIL';check(b:applyStatus(t,'burn',u)==false and t.status==nil,'actual Gen2 burn keyword not vetoed')
t.abilityId='OWN_TEMPO';check(b:applyConfusion(t,4)==false and t.confusion==nil,'native confusion bypassed veto')
t.abilityId='RUN_AWAY';check(b:applyStatus(t,'burn',u)==true and t.status=='burn','native status not delegated')
t.abilityId='BATTLE_ARMOR';local original=Damage.rollCritical;local d,i=b:hitOnce(u,t,def,{});check(d==40 and i==marker,'hit info/crit contract lost');check(Damage.rollCritical==original,'crit hook not restored')
b.fail=true;check(not pcall(b.hitOnce,b,u,t,def,{})and Damage.rollCritical==original,'hit failure leaked crit hook')
u.abilityId='SERENE_GRACE';def.effectChance=30;def.effect='EFFECT_BURN_HIT'
local method=rawget(b,'moveDef');check(not pcall(b.useMove,b,u,t,'TEST')and rawget(b,'moveDef')==method,'moveDef leaked on failure');check(def.effectChance==30,'shared move definition mutated')
b.fail=nil;local function pack(...)return{n=select('#',...),...}end
local r=pack(b:useMove(u,t,'TEST'));check(r.n==3 and r[1]==nil and r[2]==marker and r[3]==nil,'nil-bearing return arity changed')
check(b.seenDef.effectChance==60 and def.effectChance==30,'call-local secondary chance not isolated')
check(rawget(b,'moveDef')==method,'moveDef leaked after success')
t.abilityId='WATER_ABSORB';t.hp=40;b:hitOnce(u,t,{type='WATER',power=40},{});check(t.hp==65 and b.missed,'absorption must mark non-damaging result')
u.abilityId='RUN_AWAY';t.abilityId='PRESSURE';local before=u.moves[1].pp;b:useMove(u,t,'TEST');check(u.moves[1].pp==before-2,'native single Pressure charge incorrect')
b.save.colosseumBattle.abilitiesEnabled=false;t.abilityId='BATTLE_ARMOR';check(b:hitOnce(u,t,def,{})==80,'OFF changed hit damage')
local offRecord=B.moveEffectRecordFor(b.data,'EFFECT_OHKO');check(offRecord.run({battle=b,attacker=u,defender=t})==marker and records.EFFECT_OHKO.run~=offRecord.run,'OFF custom record delegate/immutable registry changed')
t.abilityId='WATER_VEIL';t.status=nil;check(b:applyStatus(t,'burn',u)==true,'OFF status changed')
u.abilityId='COMPOUNDEYES';b:accuracyRoll(def,u,t);check(b.seenAccuracy==70,'OFF accuracy changed')
local meth=B.useMove;M.installGlobal{Battle=B,Damage=Damage,Effects=E};check(B.useMove==meth,'duplicate wrapping on reinstallation')
print('AbilityEffectsGen2Tests: '..count..' wrapper contracts PASS; native mechanics covered by the native suite')
