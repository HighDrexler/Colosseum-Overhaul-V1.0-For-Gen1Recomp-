local count=0;local function test(v,m)count=count+1;assert(v,m)end
for _,gen in ipairs{1,2}do
 local reads={};local V={Abilities={enabledBattle=function()return false end},AbilityEffectsGen1={},AbilityEffectsGen2={}}
 V.engineRequire=function(name)
  reads[name]=(reads[name]or 0)+1
  test(name==(gen==1 and 'src.battle.BattleState'or 'src.battle.gen2.Battle'),'foreign kernel requested on Gen '..gen..': '..name)
  return gen==1 and {resolveTurn=function()end,endOfTurn=function()end}or{takeTurn=function()end,closeTurn=function()end,spikesDamage=function()end}
 end
 local L=assert(loadfile('lib/AbilityLifecycle.lua'))(V);L.install(nil,gen);L.install(nil,gen)
 local n=0;for _,v in pairs(reads)do n=n+v end;test(n==1,'generation hooks not idempotent')
end
local W=assert(loadfile('lib/AbilityWeather.lua')){engineRequire=function(name)error('Gen1 weather required foreign module: '..name)end}
local b={};W.set(b,1,'sandstorm',{turns=3});local damage=0
W.tick(b,1,{actives=function()return{{mon={hp=80},types=function()return{'NORMAL'}end,maxHp=function()return 80 end,dealDamage=function(d)damage=d end}}end})
test(damage==10 and W.get(b,1).turns==2,'Gen1 weather standalone contract')
local f=assert(io.open('main.lua','rb'));local s=f:read('*a');f:close()
test(s:find('if abilityGeneration==2 then AbilityEffectsGen2.installGlobal()',1,true)and s:find('AbilityLifecycle.install(mod,abilityGeneration)',1,true),'production generation dispatch absent')
print('AbilityGenerationBoundaryTests: '..count..' assertions PASS')
