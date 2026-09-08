local function read(path) local f=assert(io.open(path,"rb"));local s=f:read("*a");f:close();return s end
local builder=read("extract/ArenaBuilder.lua")
local catalog=read("lib/ArenaCatalog.lua")
local arena=read("lib/Arena.lua")
local pipeline=read("extract/BuildPipeline.lua")
local cache=read("lib/CacheManager.lua")

assert(builder:find('sourceFsys="M3_shrine_1F_bf.fsys"',1,true) and builder:find('sourceMember="M3_shrine_1F_bf.dat"',1,true),
  "Relic Chamber is not bound to the retail shrine battlefield")
assert(builder:find('honorRenderPass=true,skipShadowMaterials=true',1,true),
  "Relic extraction still draws source helper/pass geometry retail does not submit")
assert(builder:find('honorRenderPass=spec.honorRenderPass==true',1,true) and builder:find('skipShadowMaterials=spec.skipShadowMaterials==true',1,true),
  "Relic render-pass policy is declared but not passed into HSD extraction")
assert(builder:find('relic_chamber={sceneRadiusRaw=7800,maxGroupSpanRaw=20000,vertexRadiusRaw=7400}',1,true),
  "Relic packed runtime still truncates the retail scene shell")
assert(catalog:find('sourceShellOnly=true,worldShell="source"',1,true),"Relic complete retail scene missing")
assert(not catalog:find('worldShell="forest"',1,true),"legacy procedural Relic forest shell remains enabled")
assert(builder:find('nativeScaleCompensation=spec.nativeScaleCompensation==true',1,true),"Relic native scales are not passed into source extraction")
assert(not builder:find('rejectBattleOverhang',1,true),"compensated source still uses an overhang deletion filter")
assert(arena:find('if activeDef.sourceShellOnly then return end',1,true),"complete Relic scene still adds a synthetic ground layer")
assert(arena:find('A quiet daylight forest haze fills only holes',1,true) or catalog:find('A quiet daylight forest haze fills only holes',1,true),
  "Relic fallback backdrop contract missing")

-- The Relic source contract remains present. 1.9.31 targets only Relic Chamber
-- for the canonical refresh without invalidating unrelated caches.
assert(builder:find('complete and "all-source-colors" or "full"',1,true),"current targeted arena migration mode missing")
assert(builder:find('if arena.sourceFsys then',1,true),"arena refresh must be isolated to source arenas")
assert(pipeline:find('relic-chamber=retail-source-complete+native-scale-compensation+source-material-color+cave-scale-compensation-v5',1,true),
  "arena marker does not invalidate the old bad Relic cache")
assert(cache:find('relic-chamber=retail-source-complete+native-scale-compensation+source-material-color+cave-scale-compensation-v5',1,true),
  "runtime cache inspector does not share the new Relic identity")
assert(pipeline:find('local B={cacheVersion=2,extractorRevision=15}',1,true),"global extraction revision changed")

print("RelicRetailSource1926Tests PASS")
return true
