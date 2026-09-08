-- Execute the real repair selection, canonical-cache fingerprinting, sidecar
-- reuse and pipeline marker commit/retry against an in-memory cache backend.
local savedLove=love
love={data={pack=function(kind,fmt,...)assert(kind=='string');return string.pack('<'..fmt,...)end}}
local function up(fn,name,value,set)
  for i=1,100 do local n,v=debug.getupvalue(fn,i);if not n then break end
    if n==name then if set then debug.setupvalue(fn,i,value) end;return v end
  end
  error('missing upvalue '..name)
end
local function put(fn,name,value)return up(fn,name,value,true)end
local priorLine='relic-chamber=retail-renderpass-filter+central-overhang-reject+source-half-shell+understory-ground-detail+dapple-light+camera-guard-v4'
local currentLine='relic-chamber=retail-source-complete+native-scale-compensation+source-material-color+cave-scale-compensation-v5'
-- Captured verbatim from the delivered checkpoint's BuildPipeline.arenaMarker.
-- Keep this fixture independent of the final build's marker derivation.
local checkpointFile=assert(io.open('tests/fixtures/fidelity_checkpoint_arena_marker.txt','rb'))
local checkpointMarker=checkpointFile:read('*a');checkpointFile:close()
local relic='cache/M3_shrine_1F_bf_cache.lua'
local cave='cache/M3_cave_1F_1_bf_cache.lua'
local relicRuntime='cache/runtime_mesh_v7/arenas/relic_chamber/'
local caveRuntime='cache/runtime_mesh_v7/arenas/relic_cave/'
local function canonical(value)
  return 'return {source="fixture",bounds={min={0,0,0},max={1,1,0}},groups={{alpha=1,xlu=false,noz=false,vertices={{0,0,0,0,0},{'..value..',0,0,1,0},{0,1,0,0,1}}}}}'
end
local function fixture()
  local f={files={},calls={},failed=false,fail=nil,stateWrites=0}
  local mod={cache={},imports={info=function()return {size=1459978240}end,
    read=function(_,id,offset,length)return string.rep('\0',length)end}}
  function mod.cache:read(path)return f.files[path]end
  function mod.cache:info(path)local value=f.files[path];return value and {type='file',size=#value}end
  function mod.cache:delete(path)f.files[path]=nil;return true end
  function mod.cache:write(path,value)
    if path=='build/state.txt' then
      f.stateWrites=f.stateWrites+1
      if f.fail=='late-state' and f.stateWrites==2 then f.failed=true;return nil,'late state write failed' end
    end
    f.files[path]=value;return true
  end
  local V={ArenaCacheIdentity=assert(loadfile('lib/ArenaCacheIdentity.lua'))()}
  local A=assert(loadfile('extract/ArenaBuilder.lua'))(V)
  put(A.repair,'buildSourceArenaFromDisc',function(_,disc,progress,generated,spec)
    f.calls[#f.calls+1]=spec.id
    assert(mod.cache:write(spec.cache,canonical('2')))
    generated[#generated+1]=spec.cache
    if f.fail=='source' and not f.failed then f.failed=true;error('source interruption')end
    return {groups=1,vertices=3,textures=0,source='fixture'}
  end)
  for _,spec in ipairs(A._test.arenas)do f.files[spec.cache]=canonical('1')end
  assert(A.runtimeSidecars(mod,function()end,{}).built==11)
  local sidecarBuilder=A.runtimeSidecars
  A.runtimeSidecars=function(...)
    if f.fail=='sidecars' and not f.failed then f.failed=true;error('sidecar interruption')end
    return sidecarBuilder(...)
  end
  V.ArenaBuilder=A;V.GameCubeDisc={open=function()return {}end}
  local B=assert(loadfile('extract/BuildPipeline.lua'))(V)
  B.ensureFormatProbe=function()return true end
  local arenaRepair=up(B.run,'arenasOnly')
  put(arenaRepair,'audioReady',function()return true end)
  put(B.run,'captureSourceReady',function()return true end)
  put(B.run,'moveFxReady',function()return true end)
  for _,p in ipairs(B.visualCore)do f.files[p]=f.files[p] or 'retained '..p end
  f.files['.cbe-visual-v2.complete']=B.marker
  f.files['.cbe-runtime-v2.complete']=B.marker
  f.files['.cbe-trainer-identity-v16.complete']=B.trainerIdentityMarker
  f.previous=B.arenaMarker:gsub('relic%-chamber=[^\n]+',priorLine,1)
  assert(B.arenaMarker:find(currentLine,1,true))
  assert(B.arenaMarker:find('source-texture-state=static-tobj-uv+color-stage-v1',1,true))
  f.shippingPrevious=f.previous:gsub('source%-texture%-state=[^\n]+\n','',1):gsub('source%-instances=[^\n]+\n','',1)
  f.checkpointPrevious=checkpointMarker
  assert(B.arenaMarker:gsub('source%-instances=[^\n]+\n','',1)==checkpointMarker,'saved checkpoint marker compatibility changed')
  f.files['.cbe-arena-v10.complete']=f.previous
  f.files['.cbe-arena-runtime-sidecars-v2.complete']=up(arenaRepair,'ARENA_RUNTIME_SIDECAR_MARKER')
  f.files['cache/pokemon/25/model_cache.lua']='retained pokemon'
  f.files['assets/audio/themes/normal_battle_loop.wav']='retained audio'
  f.files['cache/movefx/index.lua']='retained movefx'
  f.before={};for p,bytes in pairs(f.files)do f.before[p]=bytes end
  f.B=B;f.A=A;f.mod=mod
  function f.inspect()
    local C=assert(loadfile('lib/CacheManager.lua'))({mod=mod,GeneratedAssets={
      read=function(p)return f.files[p]end,exists=function(p)return f.files[p]~=nil end,
      info=function(p)return mod.cache:info(p)end,
    }})
    return C.inspect()
  end
  return f
end
local function intact(f,scoped)
  for p,bytes in pairs(f.before)do
    local unrelated=p:find('cache/trainers/',1,true) or p:find('cache/pokemon/',1,true)
      or p:find('assets/audio/',1,true) or p:find('cache/movefx/',1,true)
    if scoped and p:find('cache/',1,true) and p~=relic and p~=cave
      and not p:find(relicRuntime,1,true) and not p:find(caveRuntime,1,true)then unrelated=true end
    if unrelated then assert(f.files[p]==bytes,'unrelated cache changed: '..p)end
  end
end

do
  local f=fixture()
  local before=f.inspect();assert(not before.visualReady and before.arenaUpgradeScope=='relic-scenes')
  local r=f.B.run(f.mod);assert(r.state=='READY' and r.visualReady)
  assert(#f.calls==2 and f.calls[1]=='relic_chamber' and f.calls[2]=='relic_cave','complete prior build extracted an unrelated venue')
  local sidecars=assert(load(f.files['build/arena_runtime_sidecars.lua']))()
  assert(sidecars.built==2 and sidecars.reused==9,'unchanged sidecar fingerprints were not reused')
  local repair=assert(load(f.files['build/arena_repair.lua']))()
  assert(repair.mode=='relic-scenes' and repair.relic_chamber and repair.relic_cave and not repair.water,'wrong scoped report')
  intact(f,true)
  assert(f.files['.cbe-arena-v10.complete']==f.B.arenaMarker,'current marker not committed')
  assert(f.inspect().visualReady,'cache inspector does not accept committed marker')
  f.B.run(f.mod);assert(#f.calls==2,'second boot repeated the completed Relic migration')
end

for _,failure in ipairs({'source','sidecars','late-state'})do
  local f=fixture();f.fail=failure
  local r=f.B.run(f.mod);assert(r.state=='ARENA CACHE REPAIR FAILED',failure..' did not fail safely')
  assert(f.files['.cbe-arena-v10.complete']==f.previous,failure..' lost scoped retry eligibility')
  assert(not f.inspect().visualReady and f.inspect().arenaUpgradeScope=='relic-scenes',failure..' incorrectly marked ready')
  assert(f.files['.cbe-runtime-v2.complete']==nil,'failed migration left full ready marker')
  intact(f,true)
  f.fail=nil;r=f.B.run(f.mod);assert(r.state=='READY',failure..' failed to retry')
  assert(#f.calls==(failure=='source' and 3 or 4),failure..' unexpected retry extraction count')
  for _,id in ipairs(f.calls)do assert(id=='relic_chamber' or id=='relic_cave',failure..' retry expanded to unrelated arenas')end
  intact(f,true)
end

do
  local f=fixture();f.files['cache/M2_earth_colo_cache.lua']=nil
  assert(f.inspect().arenaUpgradeScope==nil,'missing venue allowed scoped migration')
  local r=f.B.run(f.mod);assert(r.state=='READY','missing venue fell through to global rebuild')
  assert(#f.calls==10 and f.files['cache/M2_earth_colo_cache.lua'],'incomplete install did not use full arena repair')
  intact(f,false)
end
do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.previous..'unknown-contract=1\n'
  assert(f.inspect().arenaUpgradeScope==nil,'near-match prior marker allowed scoped migration')
  local r=f.B.run(f.mod);assert(r.state=='READY' and #f.calls==10,'unknown prior schema was treated as Relic-only')
  intact(f,false)
end
do
  -- Defend the builder boundary as well as pipeline eligibility. A caller
  -- cannot request a scoped repair if another venue's cache is absent.
  local f=fixture();f.files['cache/M2_earth_colo_cache.lua']=nil
  f.A.repair(f.mod,{},function()end,{}, {scope='relic-scenes'})
  assert(#f.calls==10,'repair bypassed its own complete-cache guard')
end

-- The actual released baseline lacks the global TOBJ metadata contract, so
-- it must refresh every source-backed venue once (Wildlands stays reusable).
do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.shippingPrevious
  assert(f.inspect().arenaUpgradeScope==nil,'shipping baseline incorrectly selected only Relic')
  local r=f.B.run(f.mod);assert(r.state=='READY' and #f.calls==10,'shipping baseline did not refresh all source arenas')
  local stats=assert(load(f.files['build/arena_runtime_sidecars.lua']))()
  assert(stats.built==10 and stats.reused==1,'source refresh did not preserve Wildlands sidecar')
  assert(f.files['cache/outdoor_wild_cache.lua']==f.before['cache/outdoor_wild_cache.lua'],'authored Wildlands was rebuilt')
  intact(f,false)
  f.B.run(f.mod);assert(#f.calls==10,'completed global texture-state migration repeated')
end

for _,failure in ipairs({'source','sidecars','late-state'})do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.shippingPrevious;f.fail=failure
  local r=f.B.run(f.mod);assert(r.state=='ARENA CACHE REPAIR FAILED','shipping '..failure..' did not fail safely')
  assert(f.files['.cbe-arena-v10.complete']==f.shippingPrevious,'shipping '..failure..' lost retry marker')
  intact(f,false)
  f.fail=nil;r=f.B.run(f.mod);assert(r.state=='READY','shipping '..failure..' did not recover')
  assert(#f.calls==(failure=='source' and 11 or 20),'shipping retry lost full-arena scope')
  intact(f,false)
end

do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.shippingPrevious
  f.files['cache/M2_earth_colo_cache.lua']=nil
  assert(f.B.run(f.mod).state=='READY' and #f.calls==10,'incomplete shipping baseline fell through to global cleanup')
  intact(f,false)
end
-- The delivered checkpoint already has corrected texture/Relic caches. Its
-- exact saved marker permits Water+Deep instance repair, never actor/audio or
-- other venue invalidation. Failed and incomplete installs remain retryable.
for _,failure in ipairs({'none','source','sidecars','late-state'})do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.checkpointPrevious
  assert(f.inspect().arenaUpgradeScope=='source-instances' and not f.inspect().visualReady,'checkpoint did not select instance migration')
  f.fail=failure~='none' and failure or nil
  local r=f.B.run(f.mod)
  if f.fail then
    assert(r.state=='ARENA CACHE REPAIR FAILED','checkpoint '..failure..' did not fail safely')
    assert(f.files['.cbe-arena-v10.complete']==f.checkpointPrevious,'checkpoint '..failure..' lost retry marker')
    assert(f.inspect().arenaUpgradeScope=='source-instances' and not f.inspect().visualReady,'checkpoint failure lost exact scope')
    assert(f.files['.cbe-runtime-v2.complete']==nil,'checkpoint failure remained runtime ready')
    f.fail=nil;r=f.B.run(f.mod)
  end
  assert(r.state=='READY' and f.inspect().visualReady,'checkpoint migration did not finish')
  assert(#f.calls==(failure=='none' and 2 or (failure=='source' and 3 or 4)),'checkpoint instance scope expanded')
  for _,id in ipairs(f.calls)do assert(id=='water' or id=='deep_colosseum','checkpoint rebuilt unrelated source venue')end
  for _,spec in ipairs(f.A._test.arenas)do if spec.id~='water' and spec.id~='deep_colosseum' then
    assert(f.files[spec.cache]==f.before[spec.cache],'checkpoint changed unrelated canonical arena')
    local prefix='cache/runtime_mesh_v7/arenas/'..spec.id..'/'
    for path,bytes in pairs(f.before)do if path:find(prefix,1,true)==1 then assert(f.files[path]==bytes,'checkpoint changed unrelated packed sidecar')end end
  end end
  if failure=='none' then
    local stats=assert(load(f.files['build/arena_runtime_sidecars.lua']))()
    assert(stats.built==2 and stats.reused==9,'checkpoint did not reuse nine unchanged sidecars')
  end
  assert(assert(load(f.files['build/arena_repair.lua']))().mode=='source-instances','checkpoint report scope wrong')
  intact(f,false)
  local calls=#f.calls;f.B.run(f.mod);assert(#f.calls==calls,'completed checkpoint migration repeated')
end
do
  local f=fixture();f.files['.cbe-arena-v10.complete']=f.checkpointPrevious;f.files['cache/M2_earth_colo_cache.lua']=nil
  assert(f.inspect().arenaUpgradeScope==nil,'missing checkpoint venue permitted scoped repair')
  assert(f.B.run(f.mod).state=='READY' and #f.calls==10,'missing checkpoint venue did not select full arena-only repair')
  intact(f,false)
end
do
  local f=fixture();f.files['cache/M2_earth_colo_cache.lua']=nil
  f.A.repair(f.mod,{},function()end,{}, {scope='source-instances'})
  assert(#f.calls==10,'builder permitted instance-only scope with missing venue')
end
love=savedLove
print('RelicScopedMigrationTests: original ten-arena, Relic two-scene and captured-checkpoint Water/Deep migrations passed; unrelated caches/sidecars, exact scope, interruption retry and incomplete-install recovery preserved')
return true
