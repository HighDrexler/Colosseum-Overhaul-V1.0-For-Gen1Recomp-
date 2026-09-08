-- Shipped planner/controller/work scheduler. Disk preparation is controlled here;
-- QuickCachePersistenceTests separately exercises real artifact persistence.
local function M(p,v)return assert(loadfile(p))(v)end
local checks=0;local function yes(v,m)checks=checks+1;assert(v,m)end
local function eq(a,b,m)checks=checks+1;assert(a==b,m..': '..tostring(a)..' ~= '..tostring(b))end
local now,keys,disk,attempts=0,{},{},{}
love={timer={getTime=function()return now end},system={getOS=function()return 'Android'end}}
local V={mod={cache={write=function()return true end}},ShinySupport=M('lib/ShinySupport.lua'),
 ColosseumDex=M('lib/ColosseumDex.lua'),GenerationCompat={current=function()return 2 end}}
V.ModelIdentity=M('lib/ModelIdentity.lua',V);V.QuickCachePlanner=M('lib/QuickCachePlanner.lua',V);V.WorkBudget=M('lib/WorkBudget.lua')
local function modelKey(d,v)return tostring(V.ColosseumDex.modelKey(d,v))end
local pendingFail,slow,prepared=25,false,{}
V.PokemonActors={sessionCacheIdentity=function()return 'epoch' end,
 peek=function(_,d,v)return {resident=prepared[d..':'..v]}end,
 persistentModelState=function(d,v,checkpoint)
  now=now+.0001;checkpoint('inventory');return disk[modelKey(d,v)]==true
 end,
 prepareSessionModel=function(d,v,checkpoint)
  local k=modelKey(d,v);attempts[k]=(attempts[k]or 0)+1
  if pendingFail==d then return false,'read/write failure' end
  if slow then for i=1,5 do now=now+.01;checkpoint('slow model')end end
  disk[k]=true;prepared[d..':'..v]=true;return true,'prepared'
 end}
V.engineRequire=function(name)if name=='src.core.GameVersion'then return {get=function()return 'gold'end}end;error('unneeded import '..name)end
local C=M('lib/BattleCache.lua',V)
local stack={};function stack:top()return self[#self]end;function stack:push(s)self[#self+1]=s end;function stack:pop()return table.remove(self)end
local game={stack=stack,data={pokemon={}},input={wasPressed=function(_,k)return keys[k]end}}
local save={party={{dex=25,level=18}},pokedex={seen={},caught={}}}
local title={};stack:push(title)
local function tick()now=now+.02;stack:top():update();keys={}end
local function runUntil(pred)
 for _=1,1000 do if pred()then return end;tick()end;error('controller stalled')
end
assert(C.openQuick(game,save));yes(stack:top().planning,'inventory on resumable worker, not in draw')
local first=stack:top();runUntil(function()return not first.planning end)
eq(#first.rows,30,'30-model plan');eq(first.rows[1].dex,25,'uncached team member priority')
runUntil(function()return first.error~=nil end);eq(first.index,1,'failed model not counted')
yes(not C.status().catalogDiskReady,'failure cannot claim completion')
pendingFail=nil;keys.a=true;tick();runUntil(function()return first.complete end)
eq(first.index,31,'completed all 30');eq(C.status().cachedModels,30,'completed-unit inventory')
yes(not C.ready(),'one batch is not a full GPU catalog')
keys.a=true;tick();eq(stack:top(),title,'completion returns to actual menu');yes(not C.busy(),'no automatic second batch')
-- Repeated selection advances. Cached team members are excluded, not included
-- in a 30-row total that leaves room for only 24 new models.
assert(C.openQuick(game,save));local second=stack:top();runUntil(function()return not second.planning end)
eq(#second.rows,30,'another 30 genuinely new units')
for _,r in ipairs(second.rows)do yes(not disk[modelKey(r.dex,r.variant)],'no completed model selected again')end
slow=true;runUntil(function()return second.index>2 end)
local count=0;for _ in pairs(disk)do count=count+1 end
yes(second.index<31,'second pass only partly complete')
keys.b=true;tick();eq(stack:top(),title,'cancel returns safely')
C._test.reset();prepared={};attempts={};slow=false
assert(C.openQuick(game,save));local resumed=stack:top();runUntil(function()return not resumed.planning end)
eq(C.status().cachedModels,count,'fresh controller remembers disk-only partial work')
for _,r in ipairs(resumed.rows)do yes(not disk[modelKey(r.dex,r.variant)],'partial completed units skipped')end
keys.b=true;tick()
-- Quota does not turn plain Continue into another automatic batch.
assert(C.openStartup(game,save));local startup=stack:top()
eq(#startup.rows,1,'Continue only warms exact team')
runUntil(function()return not C.busy()end);eq(stack:top(),title,'Continue warm ends without bulk enqueue')
-- All-complete message has no work and cannot start a new write.
for _,r in ipairs(V.QuickCachePlanner.units())do disk[modelKey(r.dex,r.variant)]=true end
local before=0;for _,n in pairs(attempts)do before=before+n end
assert(C.openQuick(game,save));local final=stack:top();runUntil(function()return final.complete end)
eq(#final.rows,0,'complete catalog has no uncached entries');eq(C.status().cachedAppearances,502,'complete appearances')
local after=0;for _,n in pairs(attempts)do after=after+n end;eq(after,before,'all-complete selection does no preparation')
keys.b=true;tick();eq(stack:top(),title,'all-complete B returns')
print('QuickCacheBatchControllerTests: '..checks..' checks PASS; manual selection, quota, partial cancel/restart, errors, completion and Continue boundary')
