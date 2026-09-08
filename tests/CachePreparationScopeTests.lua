local checks=0;local function eq(a,b,l)checks=checks+1;assert(a==b,l..': '..tostring(a)..' ~= '..tostring(b))end
love={system={getOS=function()return 'Android'end}}
local Dex={supported=function(d)return tonumber(d) and tonumber(d)>=1 and tonumber(d)<=251 end}
local A=assert(loadfile('lib/PokemonActors.lua'))({mod={},Mat4={},ColosseumDex=Dex})
local game={data={pokemon={A={dex=1},B={dex=2},C={dex=3}}},save={party={{species='A',moves={}}},boxes={{{species='B'},{species='B'}},{{species='C'},{species='A'}}}}}
eq(A.queueHardCache(game,'team'),4,'team base/idle/damage/faint only');eq(A.hardCacheStatus().scope,'team','team status')
eq(A.queueHardCache(game,'full'),6,'full adds unique storage species');eq(A.hardCacheStatus().scope,'full','full status')
local now=0;love.timer={getTime=function()return now end}
local paths={['build/hard_cache_v5.complete']='existing-full',['build/hard_cache_team_v1.complete']='existing-team',
 ['build/generated_paths.lua']='return {"one","two","one"}'}
local reads,validated,queued,worked=0,0,0,0;local pending,done=0,0
local assets={read=function(p)reads=reads+1;return paths[p]end,delete=function(p)paths[p]=nil;return true end,
 write=function(p,v)paths[p]=v;return true end,exists=function(p)return paths[p]~=nil end,
 saveInfoRegistry=function()return true end,revalidateInfo=function()validated=validated+1 end}
local actor={queueHardCache=function(_,scope)queued=queued+1;pending=4;done=0;return pending end,
 hardCacheStatus=function()return {pending=pending,done=done}end,cancelHardCache=function()pending=0 end,
 pumpHardCache=function()worked=worked+1;now=now+.0035;pending=pending-1;done=done+1;return {pending=pending,processed=1}end}
local S=assert(loadfile('lib/ResidentPrewarm.lua'))({PokemonActors=actor,GeneratedAssets=assets})
local C=assert(loadfile('lib/CacheManager.lua'))({mod={},ResidentPrewarm=S,GeneratedAssets=assets})
eq(C.hardCacheSave(game,'team'),true,'team request accepted');eq(reads,0,'team skips installation-wide registry scan')
eq(paths['build/hard_cache_v5.complete'],'existing-full','team keeps full marker');eq(paths['build/hard_cache_team_v1.complete'],nil,'team marker invalid until completion')
S.pump(game);eq(worked,1,'one bounded source slice')
eq(S.pauseHardCache(true),true,'pause accepted');local before=worked;now=now+.01;S.pump(game);eq(worked,before,'paused job does no CPU work')
local count,why=S.queueHardCache(game,'full');eq(why,'already-running','duplicate request preserves scope');eq(queued,1,'duplicate does not reset worker');eq(S.status().hardCache.scope,'team','running scope unchanged')
eq(S.pauseHardCache(false),true,'resume accepted')
for i=1,30 do now=now+.016;S.pump(game);if not S.hardCacheRunning()then break end end
eq(S.status().hardCache.completed,true,'team completes');eq(paths['build/hard_cache_team_v1.complete']~=nil,true,'team marker written');eq(paths['build/hard_cache_v5.complete'],'existing-full','full marker unmodified')
eq(validated,0,'no boxed/install registry work in team pass');eq(C.hardCacheStatus().teamReady,true,'UI reads team readiness')
C.hardCacheSave(game,'full');eq(reads,1,'full reads registry once');eq(paths['build/hard_cache_team_v1.complete']~=nil,true,'full retains prepared team')
for i=1,30 do now=now+.016;S.pump(game);if not S.hardCacheRunning()then break end end
eq(validated,2,'full validates unique registry paths');eq(S.status().hardCache.completed,true,'full completes');eq(C.hardCacheStatus().ready,true,'full ready reported')
eq(now<1.1,true,'fixture slices not throttled by .9 second per-job sleeps')
print('CachePreparationScopeTests: '..checks..' checks passed')
