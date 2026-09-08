-- Wrapper contract tests. These supersede the donor's inaccurate boolean-status
-- and legacy effect-table fixtures. Real mechanics are tested separately against
-- the supplied native kernels by tests/doubles/NativeAbilitiesTests.lua.
local Data=assert(loadfile('lib/AbilityData.lua'))()
local A=assert(loadfile('lib/Abilities.lua')){AbilityData=Data}
local W=assert(loadfile('lib/AbilityWeather.lua')){Gen2Effects={WEATHER_TURNS=5}}
local count=0;local function check(v,msg)count=count+1;assert(v,msg)end
local marker={};local Damage={critRoll=function()return true end}
local Status={inflict=function(b,t,s,o)t.mon.status=s;return{'native status'}end}
local Effects={changeStage=function(b,t,stat,n,from)t.stages=t.stages or{};t.stages[stat]=(t.stages[stat]or 0)+n;return{'native stat'}end}
local records={CUSTOM={kind='primary',run=function(ctx)return {'custom handler'},marker end},OHKO_EFFECT={kind='full',gate=function(ctx)return true,'native gate'end}}
local B={}
function B.computeDamage(self,u,t,m,o)if self.fail then error('upstream compute failed')end;return Damage.critRoll()and 80 or 40,marker end
function B.accuracyRoll(self,m,u,t)self.seenAccuracy=m.accuracy;return false,marker end
function B.effectRecord(self,e)return records[e]end
function B.performMove(self,u,t,m,called)if self.fail then error('upstream perform failed')end;m.pp=m.pp-1;return nil,marker,nil end
function B.resolveSwitch(self,m)self.switched=m;return marker end
local M=assert(loadfile('lib/AbilityEffectsGen1.lua')){Abilities=A,AbilityWeather=W}
M.installGlobal{Damage=Damage,StatusRegistry=Status,MoveEffects=Effects,BattleState=B}
local b=setmetatable({game={save={colosseumBattle={abilitiesEnabled=true}}},data={pokemon={}},rng=function(lo,hi)return lo end,say=function()end},{__index=B})
local u={mon={hp=80,stats={hp=100},abilityId='COMPOUNDEYES',species='TEST'},stages={}}
local t={mon={hp=80,stats={hp=100},abilityId='RUN_AWAY',species='TEST'},stages={}};b.player=u;b.enemy=t
local move={id='UNLISTED',accuracy=70,pp=20,type='NORMAL'}
local a,ret=b:accuracyRoll(move,u,t);check(a==false and ret==marker,'existing accuracy veto/returns lost')
check(b.seenAccuracy==91 and move.accuracy==70,'accuracy input must be detached')
u.mon.abilityId='RUN_AWAY';t.mon.abilityId='WATER_VEIL'
local msg=Status.inflict(b,t,'BRN',{});check(type(msg)=='table'and #msg==0 and t.mon.status==nil,'native Gen1 status veto must be an empty message array')
t.mon.abilityId='RUN_AWAY';msg=Status.inflict(b,t,'BRN',{});check(msg[1]=='native status'and t.mon.status=='BRN','native status result altered')
t.mon.status=nil;t.mon.abilityId='BATTLE_ARMOR';local crit=Damage.critRoll
local damage,info=b:computeDamage(u,t,move,{});check(damage==40 and info==marker,'crit gate dropped native result')
check(Damage.critRoll==crit,'crit function not restored')
b.fail=true;local success=pcall(b.computeDamage,b,u,t,move,{});check(not success and Damage.critRoll==crit,'crit hook leaked on error')
local source={};b.__cbeAbilitySource=source;success=pcall(b.performMove,b,u,t,move,false)
check(not success and b.__cbeAbilitySource==source,'source identity leaked on error');b.fail=nil
local function pack(...)return {n=select('#',...),...}end
local result=pack(b:performMove(u,t,move,false));check(result.n==3 and result[1]==nil and result[2]==marker and result[3]==nil,'nil-bearing upstream returns lost')
check(b.__cbeAbilitySource==source,'source identity not restored after success')
local rec=b:effectRecord('CUSTOM');local r,k=rec.run{battle=b,user=u,target=t};check(r[1]=='custom handler'and k==marker,'custom native record was replaced')
check(records.CUSTOM~=rec and records.CUSTOM.run~=rec.run,'shared native record must not be mutated')
b.game.save.colosseumBattle.abilitiesEnabled=false;t.mon.abilityId='BATTLE_ARMOR'
check(b:computeDamage(u,t,move,{})==80,'OFF modified native damage')
check(b:effectRecord('CUSTOM')==records.CUSTOM,'OFF must preserve exact custom record')
t.mon.abilityId='WATER_VEIL';msg=Status.inflict(b,t,'BRN',{});check(msg[1]=='native status','OFF intercepted status')
u.mon.abilityId='COMPOUNDEYES';b:accuracyRoll(move,u,t);check(b.seenAccuracy==70,'OFF modified accuracy')
local original=B.performMove;M.installGlobal{Damage=Damage,StatusRegistry=Status,MoveEffects=Effects,BattleState=B};check(original==B.performMove,'install is not idempotent')
print('AbilityEffectsGen1Tests: '..count..' wrapper contracts PASS; native mechanics covered by the native suite')
