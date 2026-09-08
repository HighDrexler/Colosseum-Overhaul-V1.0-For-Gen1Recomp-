-- Reuse-cache startup contract: a persisted cache with at least 30 valid model
-- units advertises reuse without launching another 30-model Quick Start batch.
local function M(p,v)return assert(loadfile(p))(v)end
local checks=0
local function yes(v,m)checks=checks+1;assert(v,m)end
local function eq(a,b,m)checks=checks+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local now=0
love={timer={getTime=function()return now end},system={getOS=function()return 'Android'end}}
local V={ShinySupport=M('lib/ShinySupport.lua'),GenerationCompat={current=function()return 1 end}}
V.ColosseumDex=M('lib/ColosseumDex.lua')
V.QuickCachePlanner=M('lib/QuickCachePlanner.lua',V)
V.WorkBudget=M('lib/WorkBudget.lua')
V.ModelIdentity={resolve=function(_,mon)
  mon=type(mon)=='table' and (mon.mon or mon) or {}
  return tonumber(mon.dex or mon.species),mon.shiny and 'shiny' or 'normal'
end}
local disk,resident={},{}
local units=V.QuickCachePlanner.units()
for i=1,30 do disk[tostring(V.ColosseumDex.modelKey(units[i].dex,units[i].variant))]=true end
local probes,builds,prewarms=0,0,0
V.PokemonActors={
  sessionCacheIdentity=function()return 'reuse-test-session'end,
  sessionResidentCount=function()local n=0;for _ in pairs(resident)do n=n+1 end;return n end,
  peek=function(_,d,v)return {resident=resident[tostring(d)..':'..tostring(v)]==true}end,
  persistentModelState=function(d,v,checkpoint)
    probes=probes+1;if checkpoint then checkpoint('read-only reuse probe')end
    return disk[tostring(V.ColosseumDex.modelKey(d,v))]==true
  end,
  prepareSessionModel=function(d,v)
    builds=builds+1;resident[tostring(d)..':'..tostring(v)]=true
    disk[tostring(V.ColosseumDex.modelKey(d,v))]=true
    return true,'disk-complete'
  end}
V.ResidentPrewarm={cancel=function()end,queueStartup=function()prewarms=prewarms+1 end}
V.mod={cache={write=function()error('reuse path must not write diagnostics')end}}
V.engineRequire=function(name)
  if name=='src.core.GameVersion'then return {get=function()return 'red'end}end
  error('unneeded import '..tostring(name))
end
local C=M('lib/BattleCache.lua',V)
local stack={}
function stack:top()return self[#self]end
function stack:push(s)self[#self+1]=s end
function stack:pop()return table.remove(self)end
local keys={}
local game={stack=stack,data={pokemon={}},input={
  wasPressed=function(_,k)return keys[k]==true end,
  isDown=function()return false end}}
local title={};stack:push(title)
local save={party={{dex=1,level=5}},colosseumBattle={pokemonModelsEnabled=true}}
game.save=save
local continued=0
local function tick()
  now=now+.02;local top=stack:top();if top.update then top:update()end;keys={}
end
-- Fresh controller, no lastInventory: the chooser proves >=30 from persisted files.
yes(C.openMenu(game,save,{save=save,onDone=function()continued=continued+1 end,newGame=false}),'open contextual chooser')
local selector=stack:top();tick()
yes(selector.reuseChecked and selector.reuseEligible,'30 valid disk units enable reuse')
eq(selector.reuseInfo.cachedModels,30,'reuse probe stops exactly at threshold')
yes(probes>=30,'persisted units were validated')
eq(builds,0,'reuse eligibility performs no model preparation')
-- Top choice is reuse; selecting it warms only the required team and continues.
keys.a=true;tick()
local startup=stack:top();yes(startup~=title and startup.mode=='startup','top reuse enters narrow startup warm, not quick batch')
eq(#startup.rows,1,'reuse only requires current team')
for _=1,50 do if not C.busy()then break end;tick()end
eq(builds,1,'reuse prepared at most the one required team model in this fixture')
eq(continued,1,'reuse resumes Continue once')
eq(stack:top(),title,'reuse returns to native title state after required warm')
-- Generic automatic/manual chooser also exposes reuse. Selecting it must warm
-- only the required team (never a 30-new batch), so Continue does not prompt twice.
resident={};builds=0;continued=0;local preBefore=prewarms
yes(C.openMenu(game,save),'open generic chooser')
selector=stack:top();tick();yes(selector.reuseEligible,'generic chooser sees reusable cache')
keys.a=true;tick()
local genericWarm=stack:top();yes(genericWarm~=title and genericWarm.mode=='startup','generic reuse enters narrow team warm')
eq(#genericWarm.rows,1,'generic reuse scope is current team only')
for _=1,50 do if not C.busy()then break end;tick()end
eq(stack:top(),title,'generic reuse returns to main menu after team warm')
eq(builds,1,'generic reuse prepares only one required team model in this fixture')
eq(prewarms,preBefore+1,'completed generic reuse queues normal resident prewarm')
local before=builds;yes(C.requestStartup(game,save,function()continued=continued+1 end,false),'Continue after reuse accepted')
eq(continued,1,'Continue proceeds immediately after generic reuse')
eq(builds,before,'Continue after generic reuse starts no second cache work')
-- Below the 30-model threshold, reuse is intentionally unavailable.
C._test.reset();disk={};resident={};probes=0;builds=0
for i=1,29 do disk[tostring(V.ColosseumDex.modelKey(units[i].dex,units[i].variant))]=true end
yes(C.openMenu(game,save,{save=save,onDone=function()end,newGame=false}),'open sub-threshold chooser')
selector=stack:top();tick();yes(selector.reuseChecked and not selector.reuseEligible,'29 valid units do not enable reuse')
eq(selector.reuseInfo.cachedModels,29,'sub-threshold inventory is exact after full scan')
eq(builds,0,'sub-threshold scan still performs no preparation')
stack:pop();C._test.reset()
-- Full catalog is naturally eligible because it exceeds the same threshold.
disk={};for _,r in ipairs(units)do disk[tostring(V.ColosseumDex.modelKey(r.dex,r.variant))]=true end
probes=0
yes(C.openMenu(game,save),'open full-cache chooser');selector=stack:top();tick()
yes(selector.reuseEligible,'full persisted cache enables reuse')
eq(selector.reuseInfo.cachedModels,30,'full-cache detection stops after proving threshold, avoiding exhaustive startup scan')
print('CacheReuseStartupTests: '..checks..' checks PASS; >=30 reuse, generic/contextual flow, no forced 30-new batch, 29-unit boundary, full-cache shortcut')
