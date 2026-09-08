local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end

local trainer=read("extract/TrainerExtractor.lua")
for _,stem in ipairs({"akami_m","akami_f","agb_m","agb_f"}) do
  assert(trainer:find('exactArchive="pkx_'..stem..'_a1.fsys"',1,true),'portable battle archive missing')
end
assert(trainer:find('want(target.exactArchive)',1,true),'exact PKX containers never opened')
local player=read("lib/PlayerTrainer.lua")
local enemy=read("lib/Trainer.lua")
local cache=read("lib/CacheManager.lua")
local bp=read("extract/BuildPipeline.lua")
local arena=read("extract/ArenaBuilder.lua")
local main=read("main.lua")
local actors=read("lib/PokemonActors.lua")
local runtime=read("lib/BattleRuntime.lua")
local warm=read("lib/ResidentPrewarm.lua")
local movefx=read("extract/MoveFXExtractor.lua")

-- Battle-source guardrails: never regress to field-model banks.
assert(trainer:find('exactName="ken_a1.dat"',1,true),"Wes battle source bank is missing")
assert(trainer:find("dense%-clipfamilies%-v8%-retail%-motion%-role%-filter"),"trainer cache is not tagged with the source-role-filter format")
assert(trainer:find("nativeInferredLocomotionClips",1,true) and trainer:find("locomotionLike",1,true),
  "unknown trainer banks do not have a conservative locomotion rejection path")
assert(trainer:find("upper%) or 0%)%*%.78") or trainer:find("upper or 0",1,true),
  "reaction source scoring no longer appears upper-body-led")

-- Trainer packed meshes must be generated during extraction, not promoted only
-- after the first UI/battle view.
assert(trainer:find("cache/runtime_mesh_v1/trainers/%s/base_%02d.f32",1,true),"trainer extraction-time f32 sidecar missing")
assert(trainer:find("cache/runtime_mesh_v1/trainers/%s/base.lua",1,true),"trainer extraction-time runtime metadata missing")
assert(player:find("runtime_mesh_v1/trainers/",1,true) and player:find("RuntimeMeshCache.meshFromPath",1,true),
  "player trainer runtime does not consume packed trainer sidecars")
assert(trainer:find("runtimeOK and #runtimeBins==#%(model.groups or {}%)") and enemy:find('or 0',1,true) and player:find('or 0',1,true),
  "metadata-less trainer extraction/runtime still requires a canonical byte-size field")
assert(player:find("releaseScene",1,true) and enemy:find("releaseLoveObject",1,true),
  "trainer runtimes do not explicitly release replaced GPU objects")

-- Narrow migration identities: trainer + arena fast-cache changes must not force
-- unrelated audio/MoveFX cache regeneration.
assert(cache:find("cbe%-trainer%-identity=16") and bp:find("cbe%-trainer%-identity=16"),"trainer cache identity v16 missing")
assert(cache:find("%.cbe%-trainer%-identity%-v16%.complete") and bp:find("%.cbe%-trainer%-identity%-v16%.complete"),
  "trainer v16 completion marker missing")
assert(bp:find("%.cbe%-arena%-runtime%-sidecars%-v2%.complete") and bp:find("sidecarsOnly",1,true),
  "one-time arena sidecar migration path missing")
assert(cache:find("arenaRuntimeSidecarMarker",1,true) and cache:find("ARENA_RUNTIME_SIDECAR_MARKER",1,true),
  "cache inspector can report visual-ready without the arena fast-cache marker")
assert(arena:find("function A.runtimeSidecars",1,true) and arena:find("cache/runtime_mesh_v7/arenas/",1,true),
  "build-time arena packed sidecar generation missing")

-- No game-ready bulk GPU wall. Every heavyweight resident warm is queued
-- behind one stable-overworld coordinator; exact action banks remain separately
-- paced during stable battle frames.
assert(main:find("ResidentPrewarm.queueStartup",1,true),"game.ready does not queue the coordinated resident warm")
assert(not main:find("PokemonActors.prewarmPartyBase",1,true),"game.ready still synchronously uploads all party base bodies")
assert(not main:find("Arena.prewarmAutoPair",1,true) and not main:find("PlayerTrainer.prewarm",1,true),
  "game.ready still directly materializes arena/player trainer resources")
assert(runtime:find("ResidentPrewarm.pump",1,true),"stable-overworld resident prewarm coordinator pump missing")
assert(warm:find("PokemonActors.queuePartyPrewarm",1,true) and warm:find("Trainer.queuePrewarm",1,true),
  "coordinator does not own party/enemy trainer queues")
assert(warm:find("Arena.prewarmDefinition",1,true) and warm:find("PlayerTrainer.prewarm",1,true),
  "coordinator does not own arena/player trainer warm jobs")
assert(warm:find("MoveFXExtractor.pumpPrefetch,1",1,true),"MoveFX cache promotion is not bounded to one coordinated job")
assert(runtime:find("PokemonActors.pumpActionPrewarm,1",1,true),"battle action-bank prewarm is not bounded to one job")
assert(movefx:find('collectgarbage,"step",48',1,true) and not movefx:find('collectgarbage,"collect"',1,true),
  "Android MoveFX prefetch still performs stop-the-world garbage collection")
assert(actors:find("out.benchDeferred=true",1,true),"bench roster is still bulk-materialized at battle entry")
assert(actors:find("prewarmBattler%(game,battler,side,true,false%)"),"active battle actors still eagerly upload action banks")
assert(actors:find("ANDROID_RUNTIME and 0.16 or 0.07",1,true),"cross-platform action-bank pacing missing")
assert(actors:find("ANDROID_RUNTIME and 0.55 or 0.20",1,true),"cross-platform party-body pacing missing")
assert(actors:find("metadata%-less cache backend") and arena:find("if size and %(size<144 or size%%48~=0%)"),
  "metadata-less runtime sidecar acceptance is missing")

-- RuntimeMeshCache must be usable by extraction/build code with only the pack
-- API present. GPU APIs are deliberately absent in this headless test.
do
  local oldLove=rawget(_G,"love")
  _G.love={data={pack=function(kind,fmt,...)
    assert(kind=="string")
    if string.pack then return string.pack("<"..fmt,...) end
    -- LuaJIT supplies FFI, not Lua 5.3 string.pack; the target is little-endian.
    local ffi=require("ffi");local n=select('#',...);local values=ffi.new('float[?]',n)
    for i=1,n do values[i-1]=select(i,...) end
    return ffi.string(values,n*4)
  end}}
  local R=assert(loadfile("lib/RuntimeMeshCache.lua"))({GeneratedAssets={}})
  assert(R.packSupported()==true,"headless runtime packing is unavailable")
  assert(R.supported()==false,"GPU runtime support incorrectly reports true in headless mode")
  local bytes,err=R.packRows({{1,2,3},{4,5,6},{7,8,9}},3)
  assert(bytes and not err and #bytes==36,"headless packed-row output has wrong size")
  _G.love=oldLove
end

-- Build-time arena promotion must create reusable v3 sidecars from canonical
-- cache content without graphics. This is the one-time upgrade existing users
-- receive instead of paying canonical Lua parsing at their first battle view.
do
  local oldLove=rawget(_G,"love")
  _G.love={data={pack=function(kind,fmt,...)
    assert(kind=="string")
    if string.pack then return string.pack("<"..fmt,...) end
    -- LuaJIT supplies FFI, not Lua 5.3 string.pack; the target is little-endian.
    local ffi=require("ffi");local n=select('#',...);local values=ffi.new('float[?]',n)
    for i=1,n do values[i-1]=select(i,...) end
    return ffi.string(values,n*4)
  end}}
  local store={}
  local source=[[return {source="synthetic",bounds={min={0,0,0},max={1,1,0}},groups={{alpha=1,xlu=false,noz=false,vertices={{0,0,0,0,0},{1,0,0,1,0},{0,1,0,0,1}}}}}]]
  for _,path in ipairs({"cache/M1_water_cache.lua","cache/orre_colosseum_cache.lua","cache/M3_shrine_1F_bf_cache.lua","cache/M3_cave_1F_1_bf_cache.lua","cache/S1_out_bf_cache.lua","cache/M2_earth_colo_cache.lua","cache/M4_bottom_colo_cache.lua","cache/D1_labo_B1_bf_cache.lua","cache/realgam_colosseum_cache.lua","cache/outdoor_wild_cache.lua","cache/D2_mt_battle_platform100_cache.lua"}) do store[path]=source end
  local mod={cache={}}
  function mod.cache:read(path)return store[path] end
  function mod.cache:write(path,data)store[path]=data;return true end
  function mod.cache:info(path)local v=store[path];return v and {type="file",size=#v} or nil end
  local A=assert(loadfile("extract/ArenaBuilder.lua"))({ArenaCacheIdentity=assert(loadfile("lib/ArenaCacheIdentity.lua"))()})
  local first=A.runtimeSidecars(mod,function()end,{})
  assert(first.ready and first.built==11 and first.reused==0,"arena sidecar first-pass promotion failed")
  -- Mirror cache backends that intentionally omit byte size metadata. Existing
  -- sidecars must still be recognized; actual binary stride is checked when read.
  function mod.cache:info(path)local v=store[path];return v and {type="file"} or nil end
  local second=A.runtimeSidecars(mod,function()end,{})
  assert(second.ready and second.built==0 and second.reused==11,"arena sidecar reuse validation failed")
  _G.love=oldLove
end

-- The coordinator must execute at most one heavyweight job per stable pump,
-- including recurring trainer/Pokemon/MoveFX queues. This protects against a
-- future refactor accidentally restoring simultaneous game-ready uploads.
do
  local oldLove=rawget(_G,"love")
  local now=0
  _G.love={system={getOS=function() return "Linux" end},timer={getTime=function() return now end}}
  local heavy=0
  local trainerPending=2
  local partyPending=2
  local fxPending=2
  local arena={prewarmDefinition=function() heavy=heavy+1;return true end}
  local catalog={enabled=function()return true end,selected=function()return "auto" end,definition=function(id)return {id=id} end}
  local player={prewarm=function()heavy=heavy+1;return true end}
  local trainer={queuePrewarm=function()return trainerPending end,pumpPrewarm=function()heavy=heavy+1;trainerPending=trainerPending-1;return true,trainerPending end}
  local actors={queuePartyPrewarm=function()return partyPending end,pumpPartyPrewarm=function()heavy=heavy+1;partyPending=partyPending-1;return true,partyPending end,cancelPartyPrewarm=function()end}
  local sprites={prewarm=function()heavy=heavy+1;return true end}
  local handlers={prewarm=function()heavy=heavy+1;return true end}
  local fx={queueParty=function()return {queued=fxPending} end,pumpPrefetch=function()heavy=heavy+1;fxPending=fxPending-1;return {pending=fxPending} end}
  local S=assert(loadfile("lib/ResidentPrewarm.lua"))({Arena=arena,ArenaCatalog=catalog,PlayerTrainer=player,Trainer=trainer,
    PokemonActors=actors,CurrentSpriteModels=sprites,WazaHandlers=handlers,MoveFXExtractor=fx})
  local queued=S.queueStartup({save={party={}}})
  assert(queued>=8,"coordinator did not queue the complete startup resident set")
  local before=heavy
  local ran=S.pump()
  assert(ran==false and heavy==before,"coordinator ignored its startup breathing window")
  local maxDelta=0
  for _=1,40 do
    now=now+0.25
    local prior=heavy
    S.pump()
    local delta=heavy-prior
    if delta>maxDelta then maxDelta=delta end
    if S.status().pending==0 then break end
  end
  assert(S.status().pending==0,"coordinator did not drain its bounded startup queue")
  assert(maxDelta<=1,"coordinator executed more than one heavyweight job in a single pump")
  assert(heavy==11,"unexpected coordinated heavy-job count: "..tostring(heavy))
  _G.love=oldLove
end

print("TrainerSourceCacheTests: OK")
return true
