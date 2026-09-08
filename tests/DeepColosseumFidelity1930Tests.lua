local function read(path)
  local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s
end
local catalog=read("lib/ArenaCatalog.lua")
local arena=read("lib/Arena.lua")
local builder=read("extract/ArenaBuilder.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")
local main=read("main.lua")

local currentVersion=assert(read('manifest.json'):match('"version"%s*:%s*"([^"]+)"'))
assert(main:find(currentVersion,1,true),"current build id missing")
-- The earlier Deep fidelity contract must remain during all-source color migration.
assert(builder:find('local A={arenaRevision=16}',1,true),"current arena refresh revision missing")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true',1,true),"Deep retail render-pass filtering missing")
assert(builder:find('maxVertices=460000,maxDisplayOps=2600000,maxSceneRoots=64,maxJobjs=30000,maxDobjs=90000,maxPobjs=150000',1,true),"Deep source traversal budgets not widened")
assert(builder:find('deep_colosseum={sceneRadiusRaw=12000,maxGroupSpanRaw=32000,vertexRadiusRaw=11500}',1,true),"Deep runtime outer shell still clipped")
assert(builder:find('if arena.sourceFsys then',1,true),"arena migration must cover all source arenas")
assert(builder:find('complete and "all-source-colors" or "full"',1,true),"all-source arena repair report missing")

assert(catalog:find('sceneRadiusRaw=12000,maxGroupSpanRaw=32000,vertexRadiusRaw=11500',1,true),"Deep catalog shell mismatch")
assert(catalog:find('figureScale=0.300',1,true),"Deep actor scale still too dominant")
assert(catalog:find('height=12.2',1,true) and catalog:find('lookY=4.8',1,true),"Deep low retail camera missing")
assert(catalog:find('shotHeightScale=0.60',1,true) and catalog:find('maxPitch=14',1,true),"Deep high-angle compression missing")

assert(arena:find('1.9.25 double-darkened it',1,true),"old Deep green/double-darkening path not replaced")
assert(not arena:find('float metalBreak=.5+.5*sin(worldPos.x*.029',1,true),"synthetic Deep metal mud remains")
assert(arena:find('deepProfile ? 620.0',1,true) and arena:find('deepProfile ? 1400.0',1,true),"Deep fog still starts inside readable architecture")
assert(arena:find('deepProfile ? vec3(.026,.029,.027)',1,true),"Deep fog color still green/muddy")
assert(arena:find('deepProfile ? .018',1,true) and arena:find('deepProfile ? .015',1,true),"Deep fog strength remains excessive")
assert(arena:find('empty gaps are essentially black',1,true),"Deep neutral-black chamber fallback missing")

assert(pipeline:find('deep=retail-renderpass-filter+outer-shell-v4+source-neutral-lighting+long-depth-clarity',1,true),"pipeline Deep marker missing")
assert(cache:find('deep=retail-renderpass-filter+outer-shell-v4+source-neutral-lighting+long-depth-clarity',1,true),"cache Deep marker missing")
assert(pipeline:find('Refreshing source arena fidelity: native texture transforms, material colors and scene instances',1,true),"source arena migration UI message missing")
-- Canonical audio/trainers/MoveFX and arena extraction stay intact.
-- Test 2 separately advances the Pokemon sampler/cache epoch to revision 37.
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"global extractor revision changed")
assert(read("extract/PokemonExtractor.lua"):find('local P={revision=37}',1,true),"1.9.29 Pokemon animation rollback was not preserved")

print("DeepColosseumFidelity1930Tests PASS")
return true
